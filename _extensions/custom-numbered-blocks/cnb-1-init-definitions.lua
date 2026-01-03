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
  local minimaldefault = {boxtype = cnbx.defaultboxtype}
  local vv, vp
  local styOpt

  -- first find those without parent style, then set up child styles
  if sty == nil then 
    basestyles = {default = minimaldefault}
  else
    if type(sty) == "table" then
    for k, v in pairs(sty) do
      vv = deInline(v)
      if vv.parent == nil then -- print("no parent") 
        basestyles[k] = vv
      end
    end
    if basestyles.default == nil then
      basestyles.default =  minimaldefault
    end
    -- next round: fill with defaults
    for k, v in pairs(sty) do
      vv = deInline(v)
      if vv.parent ~= nil then
        vp = basestyles[vv.parent]
        basestyles[k] = updateTable(vp, vv)
        basestyles[k].parent = nil
      end
    end  
  end
  
  -- assure there is a boxtype in all styles
  for _, v in pairs(basestyles) do
    if v.boxtype == nil then v.boxtype = cnbx.defaultboxtype end
  end

  --dev.showtable(basestyles, "all base styles")

  -- ensure that options are compatible with boxtype, 
  -- and sort into boxtype and options. 
  -- Then update with default 

  for k, v in pairs(basestyles) do
    --dev.showtable(v, k)
    allstyles[k] = {boxtype = v.boxtype}
    styOpt = deepcopy(v)
    styOpt.boxtype = nil
    local boxOpt = cnbx.boxtypes[v.boxtype].defaultOptions
    styOpt = ute1.filterTable(styOpt, boxOpt)
    styOpt = ute1.updateTable(boxOpt, styOpt)
    if styOpt.numbered ~= nil then 
      allstyles[k].numbered = styOpt.numbered
      styOpt.numbered = nil
    end  
    allstyles[k].options = styOpt
  end
  end
   
  cnbx.styles = allstyles
end


local groups ={}

local initGroupDefaults = function(cnbyaml)
  local grps = cnbyaml.groups
  local groups0 = {}
  local vv
  local grpOpt
  
  -- first find those without parent style, then set up child styles
  if grps ~= nil then 
    if type(grps) == "table" then
      for k, v in pairs(grps) do
        vv = deInline(v)
        groups0[k] = vv
      end
    end
    for _, v in pairs(groups0) do
      if v.style == nil then v.style = "default" end
    end
  end
  
  -- ensure that options are compatible with boxtype, 
  -- and sort into boxtype and options. 
  -- Then update with default 

  for k, v in pairs(groups0) do
    --dev.showtable(v, k)
    local stil = cnbx.styles[v.style]
    local stylOpt = stil.options
    --dev.showtable(stil,"style")
    grpOpt = deepcopy(v)
    grpOpt.style = nil
    local numberd = replaceifnil(grpOpt.numbered, stil.numbered)
    --print("is numbered: "..numberd)
    -- TODO: listin
    groups[k] = {numbered = numberd, listin = grpOpt.listin}
    grpOpt.numbered = nil
    grpOpt.listin = nil
    local bxt = grpOpt.boxtype
    if bxt then 
      local boxOpt = cnbx.boxtypes[btx]  
      if bxt ~= stil.boxtype then-- may conflict with style, overrides style
        --print("has boxtype "..bxt)
        if boxOpt ~= nil then 
          stylOpt = ute1.filterTable(stylOpt, boxOpt)
          stylOpt = ute1.updateTable(boxOpt, stylOpt)
        else 
          stylOpt = nil  
        end  
        groups[k].style = nil
        groups[k].boxtype = bxt
      end
    else 
      groups[k].boxtype = cnbx.styles[v.style].boxtype
    --  print("makkeboxtyp")
    end
    -- update style options for group from remaining options
    if stylOpt ~= nil then
      grpOpt = ute1.filterTable(grpOpt, stylOpt)
      grpOpt = ute1.updateTable(stylOpt, grpOpt)
    end  
    grpOpt.boxtype=nil
    groups[k].options = grpOpt
  end  
  --dev.showtable(groups, "all groups style only")
  
-- muligvis pjat
      
  if groups.default == nil then 
    groups.default = deepcopy(cnbx.styles.default)
  end

  cnbx.groupDefaults = groups
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
  local groupDefaults= cnbx.groupDefaults -- saves a little bit
  --dev.showtable(groupDefaults,"Groupdefaults")
  --dev.showtable(defaultGroup, "defaultgruppe")

  
  cnbx.counter = {unnumbered = 0} -- counter for unnumbered divs 
  -- ! unnumbered not for classes that have unnumbered as default !
  -- cnbx.counterx = {}
  if cunumbl.classes == nil then
        quarto.log.warning("== @%!& == Warning == &!%@ ==\n wrong format for fboxes yaml: classes needed")
        return     
  end
  
-- deInline: simplified copy of yaml data: inlines to string
-- update default values with boxtype defaults and style defaults
  

  for key, val in pairs(cunumbl.classes) do
    -- print("class key "..key)

    local clinfo = deInline(val)
    -- print("0 class info numbered "..replaceifnil(clinfo.numbered,"not given"))
    
  --  pout("==== before after =======");  pout(clinfo)
    -- classinfo[key] = deInline(val)
    table.insert(cnbx.knownclasses, str(key))
    local theGroup = replaceifnil(clinfo.group, "default")
    -- check if a style is defined for the class, and if yes, respect it
    -- if it is different from the group, only use the group for counting,
    -- do not add superflous key value pairs
    local groupDef = deepcopy(groupDefaults[theGroup])
    -- print("0 group info numbered "..replaceifnil(groupDef.numbered,"not given"))
    
    -- first update class from group, then from style if given, then from boxtype if given.
    local ggroup = clinfo.group
    local gstyle = clinfo.style
    local gboxtype = clinfo. boxtype
    local gropt, stylopt, boxopt
    --if key == "TODO" then 
      --dev.showtable(clinfo, "original class info")
    
    -- divide into keepers and options
    if ggroup then
      gropt = cnbx.groupDefaults[ggroup]
      --dev.showtable(gropt, "group defaults")
      clinfo = ute1.updateTable(gropt, clinfo)
    end
    
    --dev.showtable(clinfo, " class info update by group", {})

    if gstyle then
      stylopt = cnbx.styles[gstyle]
      --dev.showtable(stylopt, "style defaults")
      if stylopt.boxtype then if stylopt.boxtype ~= clinfo.boxtype then stylopt.boxtype = nil end end
      clinfo = ute1.updateTable(stylopt, clinfo, {"options"})
          end
    --dev.showtable(clinfo, " class info update by group and style", {})

    if gboxtype then
      boxopt = cnbx.boxtypes[gboxtype].defaultOptions
      --dev.showtable(boxopt, "box defaults")
      clinfo.options = ute1.filterTable(clinfo.options, boxopt)
      clinfo.options = ute1.updateTable(boxopt, clinfo.options)
      if not clinfo.numbered then clinfo.numbered = clinfo.options.numbered end
      clinfo.options.numbered = nil
    end
    --dev.showtable(clinfo, " class info update by group and style and boxtype", {})

  --end
--[[
    if gboxtype then 
      local boxOpt = cnbx.boxtypes[btx]  
      if bxt ~= stil.boxtype then-- may conflict with style, overrides style
        print("has boxtype "..bxt)
        if boxOpt ~= nil then 
          stylOpt = ute1.filterTable(stylOpt, boxOpt)
          stylOpt = ute1.updateTable(boxOpt, stylOpt)
        else 
          stylOpt = nil  
        end  
        groups[k].style = nil
        groups[k].boxtype = bxt
      end
    else 
      groups[k].boxtype = cnbx.styles[v.style].boxtype
    --  print("makkeboxtyp")
    end
    -- update style options for group from remaining options
    if stylOpt ~= nil then
      grpOpt = ute1.filterTable(grpOpt, stylOpt)
      grpOpt = ute1.updateTable(stylOpt, grpOpt)
    end  
    grpOpt.boxtype=nil
]]--
    -- if ggroup then
    --   local ggrpDef = deepcopy(groupDefaults[ggroup])
    --   updateTable(clinfo) 
    -- end  

    --dev.showtable(clinfo, "virgin clinfo "..key)
    local bst = clinfo.style
    if bst ~= nil then 
     -- print("bst = "..bst)
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
    
   --rint("1 class info numbered "..replaceifnil(clinfo.numbered,"not given"))
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
  if cnbx.yaml then 
    initBoxTypes(cnbx.yaml)
  --   dev.showtable(cnbx.boxtypes, "boxtypes")
    initStyles(cnbx.yaml)
   --dev.showtable(cnbx.styles, "styles")
    initGroupDefaults(cnbx.yaml)
   -- dev.showtable(cnbx.groupDefaults, "groups") 
    initClassDefaults(cnbx.yaml) 
   --  dev.showtable(cnbx.classDefaults, "classFefaults")
  end
-- dev.showtable(cnbx, "cnbx")
  return(meta)
end
}