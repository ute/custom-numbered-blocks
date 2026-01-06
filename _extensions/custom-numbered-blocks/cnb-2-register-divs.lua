
--[[
screen all cunumblo divs and make identifiers.
register in cnbx.xref, and also add titles. 
if title is given by heading in div, remove this heading because
it otherwise would conflict with numbering
]]--


local registerdivs = {}

dev = require "devutils"
cnbx = require "cnb-global"
   


local divcount = 0

--- number all custom numbered blocks to create identifiers

registerdivs.traverse = "topdown"

function registerdivs.Div(el)
  local idd = el.identifier
  local hidd=""
  -- local cls = pandoc.utils.stringify(el.classes)
  local cls = cnbx.is_cunumblo(el)
  local xref = cnbx.xref
  
  if cls then
    divcount = divcount+1
    if idd==nil then idd="" end     
    -- make identifier if not present --
    if idd == "" then 
      el1 = el.content[1]
      if el1.t=="Header" then 
        hidd = el1.identifier
      end
      if hidd == "" then 
        idd = "cnb-"..divcount.."-"..cls
      else idd = hidd
      end
      el.identifier = idd
    end
    local title = ""
    local pandoctitle = {}
    local info = {id = idd}
    --if cnbx.is_cunumblo(el) then --cls == "blk" then
      el1 = el.content[1]
        if el1.t=="Header" then 
          pandoctitle = el1.content
          title = pandoc.utils.stringify(pandoctitle)  -- readable version without math
          -- do not remove this in the first run? or does it work anyway, because the cites are allready resolved, and refs get resolved later?
  --TODO here remove comment
          table.remove(el.content, 1) -- maybe tag for later: title-from-header
        else title = ""
        end
      info.mdtitle = title
      info.pandoctitle = pandoctitle
      xref[el.identifier] = info
    -- end 
  end  
  return el
end

return(registerdivs)
  