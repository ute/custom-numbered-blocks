--[[
MIT License

Copyright (c) 2023-2026 Ute Hahn

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

--[[

initialize storage for box types, appearances, groups, block classes.

]]--


-- shortcuts
local str = pandoc.utils.stringify

cnbx = require "cnb-global"

uti = require "cnb-utilities"
dev = require "devutils"

local tablecontains = uti.tablecontains
local updateTable = uti.updateTable
local ifelse = uti.ifelse
local replaceifnil = uti.replaceifnil
local findFile = uti.findFile
local warning = uti.warning
local mergelists = uti.mergeStringLists

--local replaceifempty = uti.replaceifempty


--[[------------------------------

      BOX TYPES

----------------------------------]]

-- screen all entries in custom-numbered-blocks yaml for rendering appearances.
-- check if found and add to list
-- uses global function gatherentries from cnb-utilities
local initBoxTypes = function (cnbyaml)
  local findlua, fnamstr, fallbackcopy
  local allboxtypes, validboxtypes = {}, {}
  local defbx = cnbx.styles.default.boxtype
  
  gatherentries(cnbyaml.appearances, allboxtypes, "container")
  gatherentries(cnbyaml.groups, allboxtypes, "container")
  gatherentries(cnbyaml.classes, allboxtypes, "container")
  
  --dev.showtable(allboxtypes, "the containers found")
    -- ensure default box type is included in the collection of box types
  allboxtypes[defbx] = true

  defaultlua = findFile(defbx..".lua",{"textcontainers/","textcontainers/"..defbx.."/"})
  
  -- this belongs to checking containers, or just to general sanity checks. 
  -- check if default container type is available, otherwise it is a fatal error
  -- it can only happen if the code has been tampered, or the defaults.
  if not defaultlua.found then 
    quarto.log.error("Code for default text container type "..defbx.." is not available")
  end

  -- include fallback container
  allboxtypes.fallback = true
  
  -- verify if boxtypes actually exist. otherwise replace by fallback
  -- enter valid box types into global list
  -- replace the remaining ones by default type, and issue warning
  for k, _ in pairs(allboxtypes) do
    fnamstr = str(k)
    findlua = findFile(fnamstr..".lua",{"textcontainers/","textcontainers/"..fnamstr.."/"})
    if not findlua.found then 
      warning ("code for text container type "..fnamstr.." not found, replace by default ") 
      findlua = defaultlua
      allboxtypes[k] = false -- if this is of interest later
    end
    findlua.found = nil
    findlua.luacode = pandoc.path.split_extension(findlua.path)
    thelua = require(findlua.luacode)
   -- thelua = updateTable(fallback, thelua)
    --  print(thelua.stilnam)
    --   dev.tprint(thelua)
    findlua.defaultOptions = thelua.defaultOptions
    -- findlua.optionkeys = keynames(thelua.defaultOptions) better to construct this on the fly, otherwise it may get overwritten
    findlua.render = thelua[cnbx.fmt]
    validboxtypes[k] = findlua 
  end  
  
   -- dev.showtable(allboxtypes, "all box types wanted")
  
  -- replace missing functions in contributed box type code by fallback version
  for _, v in pairs(validboxtypes) do
    fallbackcopy = deepcopy(validboxtypes["fallback"].render)
    v.render = updateTable(fallbackcopy, v.render)
  end

  --dev.showtable(validboxtypes, "the box types")

  cnbx.boxtypes = validboxtypes

end



--[[------------------------------

      STYLES

----------------------------------]]


--- register block styles for rendering. 
--- analyze the yaml, check if styles can be found, include them in cnbx
--- in all cases set up styles/default, if no custom style is given
--- no return value, but side effect
local initStyles = function (cnbyaml)
  local sty = cnbyaml.appearances
  local basestyles, allstyles = {}, {}
  --local minimaldefault = cnbx.styles.default --{boxtype = cnbx.defaultboxtype}
  local vv, vp
  --local styOpt

  -- first find those without parent style, then set up child styles
  if sty == nil then 
    basestyles = {default = deepcopy(cnbx.styles.default)}
   -- print("no styles defined")
  else
    -- dev.showtable(sty, "styles yaml")
    if type(sty) == "table" then
    for k, v in pairs(sty) do
      vv = v --deInline(v)
      -- redefine boxtype to container  
      if v.container ~= nil then v.boxtype = v.container end
      if vv.parent == nil then -- print("no parent") 
        basestyles[k] = vv
      end
    end
    if basestyles.default == nil then
      basestyles.default =  cnbx.styles.default
    else cnbx.styles.default = basestyles.default
    end
    -- next round: fill with defaults
    for k, v in pairs(sty) do
      vv = v --deInline(v)
      if vv.parent ~= nil then
        vp = deepcopy(basestyles[vv.parent])
        basestyles[k] = updateTable(vp, vv)
        basestyles[k].parent = nil
      end
    end  
  end
end 
  -- ensure there is a boxtype in all styles
  for _, v in pairs(basestyles) do
    if v.boxtype == nil then v.boxtype = cnbx.styles.default.boxtype end
  end
 -- dev.showtable(basestyles, "all base styles")

  allstyles = deepcopy(basestyles)

  
  cnbx.styles = allstyles
end



--[[------------------------------

      GROUPS

----------------------------------]]

local groups = {}

local initGroupDefaults = function(cnbyaml)
  local grps = cnbyaml.groups
  --local vv
  --local grpOpt
  
  -- first find those without parent style, then set up child styles
  -- expand groups that are just defined as default
  if grps ~= nil then 
    if type(grps) == "table" then
      for k, v in pairs(grps) do
        if v.container ~= nil then v.boxtype = v.container end
        groups[k] = deepcopy(v)
      end
    end
    
    -- make sure that all groups are welldefined, expand "default"
    for k, v in pairs(groups) do
      if type(v) ~= "table" then
        if str(v) == "default" then 
          -- print(k.." is default") 
          v = {appearance = "default", numbered = true}
          groups[k] = v
        end
      elseif v.appearance == nil then v.appearance = "default" 
      end
    end
  end
  
  cnbx.groupDefaults = groups  
end



--[[------------------------------

      CLASSES

----------------------------------]]


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

  cnbx.classDefaults ={}
  -- local groupDefaults= cnbx.groupDefaults -- saves a little bit
  --dev.showtable(groupDefaults,"Groupdefaults")
  --dev.showtable(defaultGroup, "defaultgruppe")

  
  cnbx.counter = {unnumbered = 0} -- counter for unnumbered divs 
  -- ! unnumbered not for classes that have unnumbered as default !
  -- cnbx.counterx = {}
  if cunumbl.classes == nil then
        warning("@%!& == &!%@ ==\n wrong format for fboxes yaml: classes needed")
        return     
  end
  
-- update default values with boxtype defaults and style defaults
   local clinfo = {}

  for key, val in pairs(cunumbl.classes) do
    -- print("class key "..key)
    if val.container ~= nil then val.boxtype = val.container end
    clinfo = deepcopy(val) --deInline(val)
    -- print("0 class info numbered "..replaceifnil(clinfo.numbered,"not given"))
    
  --  pout("==== before after =======");  pout(clinfo)
    -- classinfo[key] = deInline(val)
    table.insert(cnbx.knownclasses, str(key))
     
    -- check if class is set to " default". If yes, set to an empty table to be filled with defaults
    if type (clinfo) ~= "table" then 
      if str(clinfo) == "default" then clinfo = {style = "default", numbered = true} else
        warning("definition of class "..key..' should be a table or the string "default"')
      end  
    end

    -- check if a style is defined for the class, and if yes, respect it
    -- if it is different from the group, only use the group for counting,
    -- do not add superflous key value pairs
    -- first update class from group, then from style if given, then from boxtype if given.
   
    -- dev.showtable(clinfo, "virgin clinfo "..key)
   
    local gropt, stylopt, boxopt, defaultopt 
    
    -- take particular attention to merge the values for listin
    if clinfo.listin == nil then clinfo.listin ={} end

    local ggroup = clinfo.group
    if ggroup ~= nil then
      gropt = deepcopy(cnbx.groupDefaults[ggroup])
      if gropt.listin ~= nil then 
        clinfo.listin = mergelists(clinfo.listin, gropt.listin) 
      end
      clinfo = updateTable(gropt, clinfo, "listin")
    end
    
 --   dev.showtable(clinfo, " class info update by group", {})
    local gstyle = clinfo.appearance
    if gstyle ~= nil  then
      stylopt = deepcopy(cnbx.styles[gstyle])
      clinfo = updateTable(stylopt, clinfo)
    end
    -- dev.showtable(clinfo, " class info "..key.. " update by group and style")
    
    local gboxtype = clinfo.boxtype
    -- there has to be a boxtype, otherwise
    if gboxtype == nil then
      -- warning("class "..key.." has no boxtype. Please file an issue on gh :-)")
      -- update with default style
      defaultopt = deepcopy(cnbx.styles.default)
      clinfo = updateTable(defaultopt, clinfo)
      gboxtype = clinfo.boxtype
    end  
    boxopt = deepcopy(cnbx.boxtypes[gboxtype].defaultOptions)
    clinfo = updateTable(boxopt, clinfo)
     -- no box type specified. use default style box type
    
    -- dev.showtable(clinfo, " class info "..key.. " update by boxtype")
  
    clinfo.label = replaceifnil(clinfo.label, str(key))
    clinfo.reflabel = replaceifnil(clinfo.reflabel, clinfo.label)
    
    -- assign counter --  
    clinfo.cntname = replaceifnil(clinfo.group, str(key))
    cnbx.counter[clinfo.cntname] = 0 -- sets the counter up if non existing
    
  --dev.showtable(clinfo, "updated clinfo "..key)
  
-- now remove all unnecessary entries 
    local keepkeys = {"cntname","numbered", "label", "reflabel", "group", "boxtype", "listin"}
    local optionkeys = keynames(cnbx.boxtypes[clinfo.boxtype].defaultOptions)
    for _,v in pairs(optionkeys) do table.insert(keepkeys, v) end
   -- print(" keep "..table.concat(keepkeys, " , "))
    clinfo = subtable(clinfo, keepkeys)
    -- dev.showtable(clinfo, " final clinfo")
    
    cnbx.classDefaults[key] = clinfo
  end 
    
------ end of making class defaults ---

cnbx.is_cunumblo = makeKnownClassDetector(cnbx.knownclasses)

-- document can give the chapter number for books in yaml header 
-- this becomes the counter Prefix
end


--------------  MAIN   ---------------------
return{
Meta = function(meta)
  
 -- print("1. Init Meta")
  if cnbx.yaml then 
   -- dev.showtable(cnbx.yaml, " yaml table")
 -- reset default style if given 
    if cnbx.yaml.appearances then 
      local userdefault = cnbx.yaml.appearances.default
      if userdefault then
      -- replace default style by user defined
        cnbx.styles.default = updateTable(cnbx.styles.default, userdefault) 
      end
    end
   --  dev.showtable(cnbx.styles.default, "default style")
    initBoxTypes(cnbx.yaml)
   -- dev.showtable(cnbx.boxtypes, "boxtypes")
    initStyles(cnbx.yaml)
  --  dev.showtable(cnbx.styles, "styles")
    initGroupDefaults(cnbx.yaml)
    --dev.showtable(cnbx.groupDefaults, "groups") 
    initClassDefaults(cnbx.yaml) 
   -- dev.showtable(cnbx.classDefaults, "classDefaults")
   
  end
-- dev.showtable(cnbx, "cnbx")
  return(meta)
end
}