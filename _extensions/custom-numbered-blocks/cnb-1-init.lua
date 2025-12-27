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

local deInline = ute1.deInline
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local findFile = ute1.findFile

--local replaceifempty = ute1.replaceifempty


--- register box styles for rendering. 
--- analyze the yaml, check if styles can be found, include them in cnbx
--- in all cases set up styles/default, if no custom style is given
--- no return value, but side effect
local initBoxStyles = function (cnbyaml)
  local blksty = cnbyaml.blockstyles
  local minimaldefault = {default = "faltbox"}
  if blksty == nil then 
    blksty = minimaldefault
  elseif blksty.default == nil then
    blksty.default = "faltbox"
  end  
  if blksty then
    -- TODO: check if default style present. Otherwise add that one as faltbox
    for stil, fname in pairs(blksty) do
      fnamstr = str(fname)
      findlua = findFile(fnamstr..".lua",{"styles/","styles/"..fnamstr.."/"})
      if findlua.found then 
      --  print("findlua found it: "..findlua.dir.." nemlig".. findlua.path) 
        stilpath = findlua.dir..fnamstr
        cnbx.styles[stil] = require(stilpath)
        cnbx.styles[stil].path = stilpath
       else ute1.warn("file "..fnamstr..".lua".." not found")    
      end
    end
  end
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
  local chapno = nil
  local info = {}
  --if book.render then
    for _, v in pairs(book.render) do
      if str(v.type) == "chapter" then
        last = pandoc.path.split_extension(str(v.file))
        if first == "" then first = last end
        if last == fname then chapno = v.number end
      end
    end
    info.islast = (fname == last)
    info.isfirst = (fname == first)
    info.lastchapter = last
    info.chapno = chapno
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
  -- prepare information for numbering fboxes by class
  -- cnbx.knownClasses ={}
  cnbx.classDefaults ={}
  local groupDefaults = {default = cnbx.styles.default.defaultOptions} -- not needed later???
  cnbx.counter = {unnumbered = 0} -- counter for unnumbered divs 
  -- ! unnumbered not for classes that have unnumbered as default !
  -- cnbx.counterx = {}
  if cunumbl.classes == nil then
        quarto.log.warning("== @%!& == Warning == &!%@ ==\n wrong format for fboxes yaml: classes needed")
        return     
  end
  
-- simplified copy of yaml data: inlines to string
  if cunumbl.groups then
    for key, val in pairs(cunumbl.groups) do
      local ginfo = deInline(val)
      --[[
      pout("==== before after =======");  pout(ginfo)
      if ginfo.boxstyle then
        local mainstyle, substyle = ginfo.boxstyle:match "([^.]*).(.*)"
      --  pout("main "..mainstyle.." :: "..substyle)
        -- TODO: here account for multiple styles
      end
      --]]--
      ginfo = updateTable(cnbx.styles.default.defaultOptions, ginfo)
      --cnbx.
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
    clinfo = updateTable(groupDefaults[theGroup], clinfo)
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
  -- print("going i gang. makke eine "..cnbx.formalla[cnbx.fmt])
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
    initBoxStyles(cnbx.yaml)
    initClassDefaults(cnbx.yaml) 
  end

  --print("default stil path "..cnbx.styles.default.path)
  return(meta)
end
}