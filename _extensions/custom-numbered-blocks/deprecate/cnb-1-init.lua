--[[
MIT License

Copyright (c) 2023, 2026 Ute Hahn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

-- shortcuts
local str = pandoc.utils.stringify

cnbx = require "cnb-global"

cnbx.ute="huhn"

ute1 = require "cnb-utilities"
dev = require "devutils"

local deInline = ute1.deInline
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local findFile = ute1.findFile
local warn = ute1.warn

--local replaceifempty = ute1.replaceifempty




-- screen all entries in custom-numbered-blocks yaml for rendering styles.
-- check if found and add to list

local initBoxTypes = function (cnbyaml)
  gatherboxtypes = function(tbl, returnval)
    if tbl ~= nil then 
        for k, v in pairs(tbl) do
          if k == "boxtype" then
             returnval[str(v)] = true
          elseif type(v) == "table" then  gatherboxtypes(v, returnval) 
          end
        end
      end
  end
  local findlua, fnamstr
  local allboxtypes, validboxtypes = {}, {}
  local defbx = cnbx.defaultboxtype
  
  gatherboxtypes(cnbyaml.styles, allboxtypes)
  gatherboxtypes(cnbyaml.groups, allboxtypes)
  gatherboxtypes(cnbyaml.classes, allboxtypes)
  
  -- ensure default box type is included
  allboxtypes[defbx] = true
  -- check if default boxtype is available, otherwise it is a fatal error
  defaultlua = findFile(defbx..".lua",{"styles/","styles/"..defbx.."/"})
  if not defaultlua.found then 
    quarto.log.error("Code for default box type "..defbx.." is not available")
  end

  -- include fallback
  allboxtypes.fallback = true

  -- print("boxtypes")
  -- dev.tprint(allboxtypes)
  -- print("=======")
   
  -- verify if boxtypes actually exist. otherwise replace by default
  -- enter valid box types into global list
  -- replace the remaining ones by default type, and issue warning
  for k, _ in pairs(allboxtypes) do
    fnamstr = str(k)
    findlua = findFile(fnamstr..".lua",{"styles/","styles/"..fnamstr.."/"})
    if not findlua.found then 
      warn ("boxstyle "..fnamstr.." not found, replace by default ") 
      findlua = defaultlua
    end
    findlua.found = nil
    findlua.luacode = pandoc.path.split_extension(findlua.path)
    thelua = require(findlua.luacode)
   -- thelua = updateTable(fallback, thelua)
    --  print(thelua.stilnam)
    --   dev.tprint(thelua)
    if k=="fallback" then fallback = thelua.unknown end
    findlua.defaultOptions = thelua.defaultOptions
    findlua.render = thelua[cnbx.fmt]
    -- replace missing functions by fallback version
    validboxtypes[k] = findlua 
  end  
  
  for _, v in pairs(validboxtypes) do
    v.render = updateTable(fallback, v.render)
  end

-- print("---------")
--   dev.tprint(validboxtypes)
-- print("---------")

  cnbx.boxtypes = validboxtypes

end


--- register box styles for rendering. 
--- analyze the yaml, check if styles can be found, include them in cnbx
--- in all cases set up styles/default, if no custom style is given
--- no return value, but side effect
local initStyles = function (cnbyaml)
  local sty = cnbyaml.styles
  local basestyles, allstyles = {}, {}
  local minimaldefault = {default = {boxtype = cnbx.defaultboxtype}}
  if sty == nil then 
    sty = minimaldefault
  elseif sty.default == nil then
    sty.default =  minimaldefault.default
  end  

  -- first find those without parent style, then set up child styles
  if type(sty) == "table" then
    for k, v in pairs(sty) do
      v = deInline(v)
      if v.parent == nil then -- print("no parent") 
        basestyles[k] = v
      end
    end
  -- fill with all known defaults  
    for k, v in pairs (sty) do
      v = deInline(v)
      if v.parent ~= nil then
        local vp = str(v.parent)
        v = updateTable(basestyles[vp], v)
      end
      v.parent = nil
      if v.boxtype == nil then v.boxtype = cnbx.defaultboxtype end
      v.boxtype = str(v.boxtype)
      local defOpt = deepcopy(cnbx.boxtypes[v.boxtype].defaultOptions)
      v= updateTable(defOpt, v)
      -- dev.tprint(cnbx.boxtypes[v.boxtype])
      -- split into base information and rendering options
      local splitted = ute1.splitTable(v, {"boxtype", "numbered"})
      --print("--------- style "..k.."---------")
 --      dev.showtable(splitted.keep, "baseoptions")
  --     dev.showtable(splitted.rest, "renderoptions")
      v = splitted.keep
      v.options = splitted.rest
      --dev.showtable(v, "splitted style")
      allstyles[k] = v
    end
  end
   
  cnbx.styles = allstyles
end

--- find chapter number of current file, whether first or last file, and last file for books
--- only sensible for books
--- @param book table yaml entries from quarto
--- @param fname string currently rendered file
--- @return table with keyed entries
---   isfirst, islast: logical
---   lastchapter: name of last chapter
---   chapno: string (at least if ishtmlbook),
---   unnumbered: boolean - initial state of section / chapter
--- if the user has given a chapno yaml entry, then unnumbered = false
--- !!! for pdf, the rendering workflow is very different! ---
--- also find out if lastfile of a book
--- find first and last file of a book, and chapter number of that file 
local chapterinfo =  function (book, fname)
  local first = "" 
  local last = "" 
  local info = {}
  --if book.render then
    for index, v in ipairs(book.render) do
      if str(v.type) == "chapter" then
        last = pandoc.path.split_extension(str(v.file))
        if first == "" then first = last end
        if last == fname then 
          info.chapno = v.number 
          info.chapindex = index  
          --print("---> chapno = "..chapno)
    --      dev.showtable(v, "book.render v")
        end
      end
    end
    info.islast = (fname == last)
    info.isfirst = (fname == first)
    info.lastchapter = last
  --  dev.showtable(info, "chapter info")
    return(info)
end

--- find chapter information in meta table
--- sideeffects: add the following to cnbx:
---     isbook: logical
---     ishtmlbook: logical
---     processedfile: string, filename without extension
---     isfirstfile, islastfile : logical, for htmlbooks
---     xreffile: filename for json file to store crossref information
---     prefix: common prefix for all numbers instead of chapter or section number (if any)
---     chapno: chapter number, if any
--- @param meta table document meta information
local initRenderInfo = function (meta)
  local processedfile = pandoc.path.split_extension(PANDOC_STATE.output_file)
  cnbx.isbook = meta.book ~= nil
  cnbx.ishtmlbook = meta.book ~= nil and not quarto.doc.is_format("pdf")
  cnbx.processedfile = processedfile
  -- cnbx.output_file = PANDOC_STATE.output_file -- with extension
  
  cnbx.prefix=""
  if (cnbx.numberlevel ==1) and  meta.numberprefix 
       then cnbx.prefix = str(meta.numberprefix) end
 
 -- print(" now in "..processedfile.." later becomes ".. str(cnbx.output_file))
  cnbx.isfirstfile = not cnbx.ishtmlbook
  cnbx.islastfile = not cnbx.ishtmlbook
  if cnbx.isbook then 
    local chinfo = chapterinfo(meta.book, processedfile)
    if cnbx.ishtmlbook then
      cnbx.xreffile= "._htmlbook_xref.json"
    else 
      cnbx.xreffile= "._pdfbook_xref.json"
      -- cnbx.xreffile= "._"..chinfo.lastchapter.."_xref.json"
    end  
    cnbx.isfirstfile = chinfo.isfirst 
    cnbx.islastfile  = chinfo.islast 
    
    cnbx.unnumbered = false
    -- user set chapter number overrides information from meta
    if meta.chapno then  
      cnbx.chapno = str(meta.chapno)
    else
      if chinfo.chapno ~= nil then
        cnbx.chapno = str(chinfo.chapno)
      else  
        cnbx.chapno = ""
        cnbx.unnumbered = true
      end
    end
  else -- not a book. 
--    cnbx.xreffile ="._"..processedfile.."_xref.json"
    cnbx.chapno = ""
    cnbx.unnumbered = true
  end
end


--- "function factory" that detects if a pandoc Div has one of the classes given
--- @param knownclasses table containing strings of classes defined in as custom numbered block
local makeKnownClassDetector = function (knownclasses)
  -- print("making babies "..str(knownclasses))
  return function(div)
    for _, cls in pairs(div.classes) do
      if tablecontains(knownclasses, cls) then return pandoc.utils.stringify(cls) end
    end
    return nil  
  end
end  


-- move option numbered from options to main
local movenumbered = function(tble)
  if type(tble) ~= "table" then print("oehmpf")
  return(tble) end
  if tble.numbered == nil then
    if tble.options.numbered ~= nil then
      tble.numbered = tble.options.numbered
      tble.options.numbered = nil
    else tble.numbered = true
    end
  end
  return(tble)
end

--- Initialize known custom numbered block classes, and their defaults
--- needs to be adapted later to styles
--- side effects: add entries to global table cnbx. Could be encapsulated.
---     is_cunumblo: function that takes a div and returns logic value
---     knownclasses
---     lists
---     classDefaults
---     groupDefaults
---     counter table with counter for each known class, and unnmbered
--- @param cunumbl table yaml entries under custom-numbered-blocks
local initClassDefaults = function (cunumbl) 
  -- do we want to prefix fbx numbers with section numbers?
  --local cunumbl = meta["custom-numbered-blocks"]
  cnbx.knownclasses = {}
  cnbx.lists = {}
  --[[ TODO later
  if meta.fbx_number_within_sections then
    cnbx.number_within_sections = meta.fbx_number_within_sections
  else   
    cnbx.number_within_sections = false
  end 
  --]] 
  cnbx.classDefaults ={}
  local defaultGroup = {style = "default"}
  defaultGroup = updateTable(defaultGroup, cnbx.styles.default)
  defaultGroup = movenumbered(defaultGroup)
  --dev.showtable(defaultGroup, "defaultgruppe")

  local groupDefaults = {default = defaultGroup} -- not needed later???
  cnbx.counter = {unnumbered = 0} -- counter for unnumbered divs 
  -- ! unnumbered not for classes that have unnumbered as default !
  -- cnbx.counterx = {}
  if cunumbl.classes == nil then
        quarto.log.warning("== @%!& == Warning == &!%@ ==\n wrong format for fboxes yaml: classes needed")
        return     
  end
  
-- deInline: simplified copy of yaml data: inlines to string
-- update default values with boxtype defaults and style defaults
  if cunumbl.groups then
    for key, val in pairs(cunumbl.groups) do
      local ginfo = deInline(val)
      local stil = replaceifnil(ginfo.style, "default" )
      ginfo.style = stil
      local stilDefault = deepcopy(cnbx.styles[stil])
      -- TODO user faulty style abfangen
      local bst = replaceifnil(ginfo.boxtype, stilDefault.boxtype)
      ginfo.boxtype = bst
      local splitted = ute1.splitTable(ginfo, {"boxtype","style", "numbered"})
      ginfo = splitted.keep
      ginfo.options = splitted.rest
      --dev.showtable(ginfo, "ginfo "..key)
      
      -- ginfo.options = updateTable(stilDefault.options, ginfo.options)  
      ginfo = updateTable(stilDefault, ginfo)  
      ginfo.options = updateTable(stilDefault.options, ginfo.options) 
      --dev.showtable(ginfo, "ginfo "..key.." after stil defaults")
      
      -- if ginfo.boxtype == stilDefault.boxtype then
      --   print("boxtype passt")
      -- else
      if ginfo.boxtype ~= stilDefault.boxtype then
        local defOpt =  deepcopy(cnbx.boxtypes[bst].defaultOptions)
        --dev.showtable(defOpt, "box default options")
        ginfo.options = ute1.filterTable(ginfo.options, defOpt)
        ginfo.options = updateTable(defOpt, ginfo.options)
        --dev.showtable(ginfo, "ginfo neu "..key)
      end 
     
      groupDefaults[key] = ginfo
   --   pout("-----group---"); pout(ginfo)
    end 
  end  

  

  for key, val in pairs(cunumbl.classes) do
    local clinfo = deInline(val)
  --  pout("==== before after =======");  pout(clinfo)
    -- classinfo[key] = deInline(val)
    table.insert(cnbx.knownclasses, str(key))
    local theGroup = replaceifnil(clinfo.group, "default")
    -- check if a style is defined for the class, and if yes, respect it
    -- if it is different from the group, only use the group for counting,
    -- do not add superflous key value pairs
    local groupDef = deepcopy(groupDefaults[theGroup])
    --dev.showtable(clinfo, "virgin clinfo "..key)
    local bst = clinfo.style
    if bst ~= nil then 
     -- first update from general styles
      if bst ~= groupDef.style then
        if cnbx.styles[bst] == nil then warn("style "..bst.." not defined")
        else  clinfo = updateTable(cnbx.styles[bst], clinfo)  end
    end end
    -- then update from group
    if bst==nil or bst == groupDef.style then
      clinfo = updateTable(groupDef, clinfo)
    end
    --dev.showtable(clinfo, "clinfo "..key.." updated by group defaults")
    
    
    -- now check boxtype ==
    local bxty = clinfo.boxtype
    if bxty ~= nil then if bxty ~= groupDef.boxtype then
       if bxty~= cnbx.styles[clinfo.style].boxtype then
        clinfo.style = nil
      -- print("===> update class info "..key.." according to box type "..bxty)
      local boxDef = deepcopy(cnbx.boxtypes[bxty].defaultOptions)
      -- dev.showtable(boxDef, "the box defaults")
      --dev.showtable(clinfo, "the clinfo before "..key)
      clinfo.options = ute1.filterTable(clinfo.options, boxDef)--, {"group","label","boxtype","numbered"})--, "style"})
      clinfo.options = updateTable(boxDef, clinfo.options)
      -- old style not working anymore if new boxtype
      --dev.showtable(clinfo, "clinfo after")
    end end end

    clinfo.label = replaceifnil(clinfo.label, str(key))
    clinfo.reflabel = replaceifnil(clinfo.reflabel, clinfo.label)
    
    -- assign counter --  
    clinfo.cntname = replaceifnil(clinfo.group, str(key))
    cnbx.counter[clinfo.cntname] = 0 -- sets the counter up if non existing
    cnbx.classDefaults[key] = clinfo
 -- pout("---class----");  pout(clinfo)
  end 
  cnbx.is_cunumblo = makeKnownClassDetector(cnbx.knownclasses)
-- gather lists-of and make filenames by going through all classes
  for _, val in pairs(cnbx.classDefaults) do
  --  pout("--classdefault: "..str(key))
  --  pout(val)
    if val.listin then
      for _,v in ipairs(val.listin) do
        cnbx.lists[v] = {file = "list-of-"..str(v)..".qmd"}
      end
    end
  end
-- initialize lists
  for key, val in pairs(cnbx.lists) do
    val.contents = ifelse(cnbx.isfirstfile, "\\providecommand{\\Pageref}[1]{\\hfill p.\\pageref{#1}}", "")
  -- listin approach does not require knownclass, since listin is in classdefaults
  end
 -- pout(cnbx.lists)
  --]]
-- document can give the chapter number for books in yaml header 
-- this becomes the counter Prefix
end


--- extract custom-numbered-block yaml from meta, according to Michael Canouils new policies
--- https://mickael.canouil.fr/posts/2025-11-06-quarto-extensions-lua/
--- still allowing the old syntax, with 1st level custom-numbered-blocks key
--- @param meta table document meta information
--- @return table cnby: part of meta that belongs to custom-numbered-blocks 
function cunumblo_yaml(meta)
  local cnby = meta["custom-numbered-blocks"]
  if not cnby then
    local extensions_yaml = meta.extensions
    if extensions_yaml then
      cnby = extensions_yaml["custom-numbered-blocks"] 
    else
      cnby = nil
    end
  end  
  if not cnby then
      quarto.log.warning("== @%!& == Warning == &!%@ ==\n missing cunumblo key in yaml")
      return{}
    else 
      return cnby
    end
end



return{
Meta = function(meta)
  
  cnbx.yaml = cunumblo_yaml(meta)
 -- print("1. Init Meta")
 
 -- get numbering depth
  cnbx.numberlevel = 0
  if meta.crossref then
    if meta.crossref.chapters then 
      cnbx.numberlevel = 1 end
  end
  
  initRenderInfo(meta)
  if cnbx.yaml then 
    initBoxTypes(cnbx.yaml)
     dev.showtable(cnbx.boxtypes, "boxtypes")
    initStyles(cnbx.yaml)
     dev.showtable(cnbx.styles, "styles")
    initClassDefaults(cnbx.yaml) 
    -- dev.showtable(cnbx.classDefaults, "classFefaults")
  end
-- dev.showtable(cnbx, "cnbx")
  return(meta)
end
}