ute1 = require "cnb-utilities"
dev = require "devutils"


--[[ 
local str = pandoc.utils.stringify
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
--]]--

--- remove all attributes that start with underscore. 
-- could theoretically give clashes with filters that need persistent such attributes
function Div_cleanupAttribs (el)
  if el.attributes._process_me then
    for k, v in pairs(el.attributes) do
      if string.sub(k, 1, 1) =="_" then el.attributes[k] = nil end
    end
  end
  return el
end

return{
 Div = Div_cleanupAttribs
 , Pandoc = function(doc)
  print("-------- the last ----")
 dev.showtable(cnbx.newxref["first"], "the new xref, #first entry")
  return(doc)
 end
}