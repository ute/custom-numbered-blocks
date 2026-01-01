
ute1 = require "cnb-utilities"

dev = require "devutils"

local str = pandoc.utils.stringify

--- number all custom numbered blocks to create identifiers

local cnbcounter = 0


local function countDiv (div)
  if cnbx.is_cunumblo(div) then
    local autoidx = "a"
    local prefix = "cnbx-"
    if cnbx.isbook then prefix = prefix..cnbx.processedfile.."-" end
    
    if cnbx.is_cunumblo(div) then
      cnbcounter = cnbcounter + 1
      autoidx = prefix..str(cnbcounter)
    end
    
    print(autoidx)
  end  
end  


return{
    Div = countDiv
}