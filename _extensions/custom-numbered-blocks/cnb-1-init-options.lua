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

--[[

initialize storage for box types, styles, groups, block classes.

]]--


-- shortcuts
local str = pandoc.utils.stringify

cnbx = require "cnb-global"

ute1 = require "cnb-utilities"
dev = require "devutils"

local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local findFile = ute1.findFile
local warn = ute1.warn

--local replaceifempty = ute1.replaceifempty


---------- handling box types ------------


-- screen all entries in custom-numbered-blocks yaml for rendering styles.
-- check if found and add to list
-- uses global function gatherentries from cnb-utilities
local initBoxTypes = function (cnbyaml)
  local findlua, fnamstr, fallbackcopy
  local allboxtypes, validboxtypes = {}, {}
  local defbx = cnbx.styles.default.boxtype
  
  gatherentries(cnbyaml.styles, allboxtypes, "boxtype")
  gatherentries(cnbyaml.groups, allboxtypes, "boxtype")
  gatherentries(cnbyaml.classes, allboxtypes, "boxtype")
  
    -- ensure default box type is included in the collection of box types
  allboxtypes[defbx] = true

  defaultlua = findFile(defbx..".lua",{"styles/","styles/"..defbx.."/"})
  
  -- this belongs to checking styles, or just to general sanity checks. 
  -- check if default boxtype is available, otherwise it is a fatal error
  -- it can only happen if the styles have been tampered, or the defaults.
  if not defaultlua.found then 
    quarto.log.error("Code for default box type "..defbx.." is not available")
  end

  -- include fallback style
  allboxtypes.fallback = true
  
  -- verify if boxtypes actually exist. otherwise replace by fallback
  -- enter valid box types into global list
  -- replace the remaining ones by default type, and issue warning
  for k, _ in pairs(allboxtypes) do
    fnamstr = str(k)
    findlua = findFile(fnamstr..".lua",{"styles/","styles/"..fnamstr.."/"})
    if not findlua.found then 
      warn ("code for boxtype "..fnamstr.." not found, replace by default ") 
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
    findlua.render = thelua[cnbx.fmt]
    validboxtypes[k] = findlua 
  end  
  
  -- dev.showtable(allboxtypes, "all box types wanted")
  
  -- replace missing functions in contributed box type code by fallback version
  for _, v in pairs(validboxtypes) do
    fallbackcopy = deepcopy(validboxtypes["fallback"].render)
    v.render = updateTable(fallbackcopy, v.render)
  end

  -- dev.showtable(validboxtypes)

  cnbx.boxtypes = validboxtypes

end


---------- handling styles ------------


--- register block styles for rendering. 
--- analyze the yaml, check if styles can be found, include them in cnbx
--- in all cases set up styles/default, if no custom style is given
--- no return value, but side effect
local initStyles = function (cnbyaml)
  local sty = cnbyaml.styles
  local basestyles, allstyles = {}, {}
  --local minimaldefault = cnbx.styles.default --{boxtype = cnbx.defaultboxtype}
  local vv, vp
  --local styOpt

  -- first find those without parent style, then set up child styles
  if sty == nil then 
    basestyles = {default = cnbx.styles.default}
  else
    -- dev.showtable(sty, "styles yaml")
    if type(sty) == "table" then
    for k, v in pairs(sty) do
      vv = v --deInline(v)
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
        vp = basestyles[vv.parent]
        basestyles[k] = updateTable(vp, vv)
        basestyles[k].parent = nil
      end
    end  
  end
  
  -- ensure there is a boxtype in all styles
  for _, v in pairs(basestyles) do
    if v.boxtype == nil then v.boxtype = cnbx.styles.default.boxtype end
  end
 -- dev.showtable(basestyles, "all base styles")

  allstyles = deepcopy(basestyles)

  end
  cnbx.styles = allstyles
end


---------- handling groups ------------

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
        groups[k] = deepcopy(v)
      end
    end
    
    -- make sure that all groups are welldefined, expand "default"
    for k, v in pairs(groups) do
      if type(v) ~= "table" then
        if str(v) == "default" then 
          print(k.." is default") 
          v = {style = "default", numbered = true}
          groups[k] = v
        end
      elseif v.style == nil then v.style = "default" 
      end
    end
  end
  
  cnbx.groupDefaults = groups  
end


------------- classes -------------


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
        quarto.log.warning("== @%!& == Warning == &!%@ ==\n wrong format for fboxes yaml: classes needed")
        return     
  end
  
-- update default values with boxtype defaults and style defaults
   local clinfo = {}

  for key, val in pairs(cunumbl.classes) do
    -- print("class key "..key)

    clinfo = deepcopy(val) --deInline(val)
    -- print("0 class info numbered "..replaceifnil(clinfo.numbered,"not given"))
    
  --  pout("==== before after =======");  pout(clinfo)
    -- classinfo[key] = deInline(val)
    table.insert(cnbx.knownclasses, str(key))
     
    -- check if class is set to " default". If yes, set to an empty table to be filled with defaults
    if type (clinfo) ~= "table" then 
      if str(clinfo) == "default" then clinfo = {style = "default", numbered = true} else
        warn("definition of class "..key..' should be a table or the string "default"')
      end  
    end

    -- check if a style is defined for the class, and if yes, respect it
    -- if it is different from the group, only use the group for counting,
    -- do not add superflous key value pairs
    -- first update class from group, then from style if given, then from boxtype if given.
   
    -- dev.showtable(clinfo, "virgin clinfo "..key)
   
    local gropt, stylopt, boxopt
    --if key == "TODO" then 
      --dev.showtable(clinfo, "original class info")
    
    local ggroup = clinfo.group
    if ggroup ~= nil then
      gropt = deepcopy(cnbx.groupDefaults[ggroup])
      clinfo = updateTable(gropt, clinfo)
    end
    
 --   dev.showtable(clinfo, " class info update by group", {})
    local gstyle = clinfo.style
    if gstyle ~= nil  then
      stylopt = deepcopy(cnbx.styles[gstyle])
      clinfo = updateTable(stylopt, clinfo)
    end
 --   dev.showtable(clinfo, " class info update by group and style", {})
    
    local gboxtype = clinfo.boxtype
    if gboxtype  ~= nil then
      boxopt = deepcopy(cnbx.boxtypes[gboxtype].defaultOptions)
      clinfo = updateTable(boxopt, clinfo)
     end
   
    clinfo.label = replaceifnil(clinfo.label, str(key))
    clinfo.reflabel = replaceifnil(clinfo.reflabel, clinfo.label)
    
    -- assign counter --  
    clinfo.cntname = replaceifnil(clinfo.group, str(key))
    cnbx.counter[clinfo.cntname] = 0 -- sets the counter up if non existing
    
  --dev.showtable(clinfo, "updated clinfo "..key)
  
-- now remove all unnecessary entries 
    local keepkeys = {"cntname","numbered", "label", "reflabel", "group", "boxtype"}
    local boxoptionkeys = keynames(cnbx.boxtypes[clinfo.boxtype].defaultOptions)
    for _,v in pairs(boxoptionkeys) do table.insert(keepkeys, v) end
   -- print(" keep "..table.concat(keepkeys, " , "))
    clinfo = subtable(clinfo, keepkeys)
    -- dev.showtable(clinfo, " final clinfo")
    
    cnbx.classDefaults[key] = clinfo
  end 
    
------ end of making class defaults ---


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
 
-- document can give the chapter number for books in yaml header 
-- this becomes the counter Prefix
end


return{
Meta = function(meta)
  
 -- print("1. Init Meta")
  if cnbx.yaml then 
   -- dev.showtable(cnbx.yaml, " yaml table")
 -- reset default style if given 
    if cnbx.yaml.styles then 
      local userdefault = cnbx.yaml.styles.default
      if userdefault then
      -- replace default style by user defined
        cnbx.styles.default = updateTable(cnbx.styles.default, userdefault) 
      end
    end
   --  dev.showtable(cnbx.styles.default, "default style")
    initBoxTypes(cnbx.yaml)
  --  dev.showtable(cnbx.boxtypes, "boxtypes")
    initStyles(cnbx.yaml)
    -- dev.showtable(cnbx.styles, "styles")
    initGroupDefaults(cnbx.yaml)
    --dev.showtable(cnbx.groupDefaults, "groups") 
    initClassDefaults(cnbx.yaml) 
    -- dev.showtable(cnbx.classDefaults, "classDefaults")
  end
-- dev.showtable(cnbx, "cnbx")
  return(meta)
end
}