--[[
 read  crossref information
  
]]--

require "cnb-global"


local readxref = function(filename)
  local xrefs ={}
  -- print("reading the xref "..filename)
  
  --if cnbx.isbook then
    local file = io.open(filename,"r")
    if file ~= nil then 
      local xrfjson = file:read "*a"
      file:close()
      if xrfjson then xrefs = quarto.json.decode(xrfjson) end
    -- else print ("file nicht gefunden")
    end
   return(xrefs) 
end  


return{
  Meta = function(met)
    local xrefs = {}
    -- cnbx.xreffile = "testing.json"
    if cnbx.isbook then xrefs = readxref(cnbx.xreffile) end
    cnbx.xref = xrefs
    -- print("xrefs are "..type(cnbx.xref))
    return(met)
  end
}
