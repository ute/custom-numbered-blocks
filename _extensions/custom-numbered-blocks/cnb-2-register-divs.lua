--[[
MIT License

Copyright (c) 2023-2026 Ute Hahn

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
    -- info.numbered = not uti.hasclass(el, "unnumbered")

    xref[el.identifier] = info
    -- end 
  end  
  return el
end

return(registerdivs)
  