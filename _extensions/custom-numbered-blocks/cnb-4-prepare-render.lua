--[[
  adjust attributes
]]--

require("cnb-global")
ute1 = require("cnb-utilities")

local filterAttributes = function(el)
  local id = el.identifier
  if id == "first" then
    local info = cnbx.xref[id]  
    if info == nil then
        print("Div with identifier "..id.." is not a cunumblo")
    else
    print("\n--filter attributes of div "..id)
    -- for k, v in pairs(el.attributes) do
    --   print(k..": "..pandoc.utils.stringify(v))
    -- end  
  
    --local myattributes = ute1.deInline(el.attributes)
    --print("type of my attributes "..type(myattributes))
    local bty = el.attributes.boxtype
    local sty = el.attributes.style
    local cla = info.cnbclass

    --if bty then print ("boxtype given, tsts "..bty) end
    --if sty then print ("style given, tsts "..sty) end
    --print("class is "..cla.." - now get all default options")
    
    local clopt = cnbx.classDefaults[cla]
    local stopt = cnbx.styles[sty]
    local bxtopt = cnbx.boxtypes[bty]
    local bxopt
    local rattribs = {} -- collect attributes that match boxtype etc
    local norattribs = {}
    local norclassdef ={}
    local defaultattribs = {}

    local norendero = {"label", "reflabel", "tag", "style", "boxtype"}
    for k, v in pairs(el.attributes) do
      if not ute1.tablecontains(norendero, k) then
         print(k..": "..pandoc.utils.stringify(v))
         rattribs[k] = v
      else norattribs[k] = v
      end
    end  
    --dev.showtable(clopt,"class options") 
    --dev.showtable(rattribs, "rattribs")
    --dev.showtable(norattribs, "norattribs")

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
          warn("contradiction between style argument and box type") 
        end
      end
    end
    
    bxtopt = cnbx.boxtypes[bty]

    -- get updated default attributes
    defaultattribs = deepcopy(bxtopt.defaultOptions)
    if clopt.boxtype == bty then 
        defaultattribs = ute1.updateTable(defaultattribs, clopt.options)
    end
    if stopt then 
      defaultattribs = ute1.updateTable(defaultattribs, stopt.options)
    end 

    -- dev.showtable(defaultattribs, "kgv attribs")
    -- update with individual attributes
    defaultattribs = ute1.updateTable(defaultattribs, rattribs)
    -- dev.showtable(defaultattribs, "final options")
    
-- zur kontrolle. Müsste so in xref stehen
    for k,_ in pairs(norendero) do
      norclassdef[k] = clopt[k]
    end
    norattribs = ute1.updateTable(norclassdef, norattribs)
    -- dev.showtable(norattribs, "final other attributes")

    -- stackoverflow info = ute1.updateTable(info, norattribs)
    for k, v in pairs(norattribs) do
      info[k] = v
    end
    info.renderoptions = defaultattribs
    
  end  
end  end

return {
  Div = filterAttributes
}