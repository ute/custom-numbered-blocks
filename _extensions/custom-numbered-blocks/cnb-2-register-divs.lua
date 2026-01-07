
--[[
screen all cunumblo divs and make identifiers.
register in cnbx.xref, and also add titles. 
if title is given by heading in div, remove this heading because
it otherwise would conflict with numbering
]]--


local registerdivs = {}

dev = require "devutils"
uti = require "cnb-utilities"
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
  local info = {}
  local eltitle
    
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
    info.id = idd
    -- check if there is a header and mark it for removal if there is no title
    -- save the preliminary mark down title without resolved references
    eltitle = nil
    if el.attributes then eltitle = el.attributes.title end
    if eltitle == nil then  
      el1 = el.content[1]
      if el1.t=="Header" then 
          --  tag for later: title-from-header
        el1.identifier = "___doomed-for-removal"
        eltitle = str_md(el1.content)
      end
    end
    info.mdtitle = eltitle or ""
    xref[el.identifier] = info
    -- end 
  end  
  return el
end

return(registerdivs)
  