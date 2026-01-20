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
