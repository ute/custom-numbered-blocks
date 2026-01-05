--[[
  process div attributes
  filter out proper render options
]]--

require("cnb-global")
uti = require("cnb-utilities")
local warning = uti.warning 

local tablecontains = uti.tablecontains

local filterAttributes = function(el)
  local id = el.identifier
  local rattribs -- collect attributes for box styling
  local norattribs -- the remaining attributes like label, boxtype, ...
  local ignoreargs

  
  -- TODO this is only looking at "first" example, for debugging. Remove if-then later
  --if id == "first" then
  
  local info = cnbx.xref[id]  
  if info == nil then
  --    print("Div with identifier "..id.." is not a cunumblo")
      return(el)
  end
  
  -- decision: do not allow changing style or boxtype. 
  -- this can be achieved by grouping instead on a per element base
  -- classes are coherent in their options.
  -- if users really want this, it could be changed later.
  -- like an icon on a callout

  local cls = info.cnbclass

  --if bty then print ("boxtype given, tsts "..bty) end
  --if sty then print ("style given, tsts "..sty) end
  --print("class is "..cla.." - now get all default options")
  
  local clopt = cnbx.classDefaults[cls]
  --local stopt = cnbx.styles[sty]
  --local bxtopt = cnbx.boxtypes[bty]
  -- local bxopt
 
  --local norclassdef ={}
  local elementattribs = {}

  rattribs = {}
  norattribs = {}
  local norendero = {"label", "reflabel", "tag", "style", "boxtype"}
  for k, v in pairs(el.attributes) do
    if tablecontains(norendero, k) then
        -- print(k..": "..pandoc.utils.stringify(v))
        norattribs[k] = v
    else rattribs[k] = v
    end
  end  
  
-- too late here, needs to come with crossref

  --dev.showtable(norattribs, "no render attributes for "..id)
  -- make sure to adjust reflabel to label, if label is given but not reflabel

  -- ignore boxtype, style, color and colors. They cannot be changed per element  
  ignoreargs = ""
  local quotek = ""
  local ignoreo = {"boxtype", "color", "colors", "style"}
  for k,_ in pairs(norattribs) do
    if tablecontains(ignoreo, k) then
      quotek = '"'..k..'"'
      if ignoreargs =="" then ignoreargs = quotek 
          else ignoreargs = ignoreargs ..", "..quotek end
       norattribs[k] = nil
    end
  end  
  
 -- print("ignoreargs = "..ignoreargs)
  
  if ignoreargs ~=""  then
    warning("elementwise attributes for block "..id..": "..ignoreargs..
      " are ignored. These can only be specified by class (or group, style)")
  end
  
  --dev.showtable(clopt,"class options") 
  --dev.showtable(rattribs, "rattribs")
  --dev.showtable(norattribs, "norattribs")
-- update with individual attributes

  elementattribs = deepcopy(clopt)
  elementattribs = uti.updateTable(elementattribs, rattribs)
  -- dev.showtable(defaultattribs, "final options")
  
  --[[
  no-render attributes are already set with crossreferencing
  for k, v in pairs(norattribs) do
    info[k] = v
  end
  ]]--

  local bty = elementattribs.boxtype
  info.boxtype = bty
  info.renderoptions = subtable(elementattribs, keynames(cnbx.boxtypes[bty].defaultOptions))
  
  --end  -- if first

end  

return {
  Div = filterAttributes
}