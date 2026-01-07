--[[
ute1 = require "cnb-utilities"

 
local str = pandoc.utils.stringify
local ifelse = ute1.ifelse

local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
--]]--


local function Meta_writexref(meta)
  if cnbx.isbook then
  local xref = cnbx.xref
  local xrjson = quarto.json.encode(cnbx.xref)
  local file = io.open(cnbx.xreffile,"w")
  if file ~= nil then 
    file:write(xrjson) 
    file:close()
  end
  if cnbx.islastfile then 
  --  pout(cnbx.processedfile.." -- nu aufräum! aber zack ---") 
    for i, v in ipairs(xref) do
      if not v.neu then 
  --      pout("killed")
  --      pout(v)
        xref[i] = nil
      end   
    end
  --  pout("-------- überlebende")
  --  pout(xref)
  end  
end
end


return{
  Meta = Meta_writexref
}
