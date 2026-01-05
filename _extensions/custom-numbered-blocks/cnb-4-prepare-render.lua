--[[
  adjust attributes
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
  if id == "first" then
  
  local info = cnbx.xref[id]  
  if info == nil then
      print("Div with identifier "..id.." is not a cunumblo")
      return(el)
  end

  print("\n--filter attributes of div "..id)
  -- for k, v in pairs(el.attributes) do
  --   print(k..": "..pandoc.utils.stringify(v))
  -- end  

  --local myattributes = uti.deInline(el.attributes)
  --print("type of my attributes "..type(myattributes))
  -- local bty = el.attributes.boxtype
  -- local sty = el.attributes.style 

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
    if not tablecontains(norendero, k) then
        -- print(k..": "..pandoc.utils.stringify(v))
        rattribs[k] = v
    else norattribs[k] = v
    end
  end  
  
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


  --[[ deprecated: boxtype will always be given through class
  -- find boxtype; this determines what arguments to keep
  if btxopt == nil then
    if stopt == nil then 
        bty = clopt.boxtype
    else bty = stopt.boxtype
    end
  else -- bty given, may devalidate style
    if stopt ~= nil then
      if bty ~= stopt.boxtype then 
        stopt = nil 
        warning("contradiction between style argument and box type") 
      end
    end
  end
  --]]
  
   --[[ deprecate, class defaults are fine
  local bty = clopt.boxtype
  bxtopt = cnbx.boxtypes[bty]

  -- get updated default attributes
  elementattribs = deepcopy(bxtopt.defaultOptions)
  
 
  if clopt.boxtype == bty then 
      elementattribs = uti.updateTable(elementattribs, clopt.options)
  end
  if stopt then 
    defaultattribs = uti.updateTable(defaultattribs, stopt.options)
  end 
  --]]

  -- dev.showtable(defaultattribs, "kgv attribs")
  -- update with individual attributes

  elementattribs = deepcopy(clopt)
  elementattribs = uti.updateTable(elementattribs, rattribs)
  -- dev.showtable(defaultattribs, "final options")
  
  --[[
-- zur kontrolle. Müsste so in xref stehen
  for k,_ in pairs(norendero) do
    norclassdef[k] = clopt[k]
  end
  norattribs = uti.updateTable(norclassdef, norattribs)
  -- dev.showtable(norattribs, "final other attributes")
--]]
  -- stackoverflow info = uti.updateTable(info, norattribs)
  for k, v in pairs(norattribs) do
    info[k] = v
  end

  local bty = elementattribs.boxtype
  info.boxtype = bty
  info.renderoptions = subtable(elementattribs, keynames(cnbx.boxtypes[bty].defaultOptions))
  
  print("---fertig---")
  end  -- if first

end  

return {
  Div = filterAttributes
}