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
  extract the custom-numbered-blocks part of the yaml and append it in 
  usable form to the global table cnbx
]]--

cnbx = require "cnb-global"

dev = require "devutils"

--- takes a meta table from pandoc and turns it hopefully into a plain lua table
depandoc = function(tbl)
  local result = {}
  local vv, vt
  for k, v in pairs(tbl) do
    vt = pandoc.utils.type(v)
    if vt == "Inlines"
      then 
        vv = pandoc.utils.stringify(v) 
        --print(k.." is inlines "..vv)
      else
        if vt == "List" or type(v) == "table" 
           then vv = depandoc(v)
           else vv = v 
        end
    end
    result[k] = vv
  end  
  return result
end


--- extract custom-numbered-block yaml from meta, according to Michael Canouils new policies
--- https://mickael.canouil.fr/posts/2025-11-06-quarto-extensions-lua/
--- still allowing the old syntax, with 1st level custom-numbered-blocks key
--- @param meta table document meta information
--- @return table cnby: part of meta that belongs to custom-numbered-blocks 
local function cunumblo_yaml(meta)
  local cnby = meta["custom-numbered-blocks"]
  local result ={}
  if cnby == nil then
    -- print(" indirect ")
    local extensions_yaml = meta.extensions
    if extensions_yaml ~= nil then
      cnby = extensions_yaml["custom-numbered-blocks"] 
    else
      cnby = nil
      quarto.log.warning("== @%!& == Warning == &!%@ ==\n missing cunumblo key in yaml")
      return{}
    end  
  end
 
  -- now depandoc the found table
  result = depandoc(cnby)
  -- dev.showtable(result, " cnb yaml extracted")
  return result
end



return{
Meta = function(meta)
  local myyaml, nestnum

  --print("1. Init Meta get the yaml")
  myyaml = cunumblo_yaml(meta)
  cnbx.yaml = myyaml
 
-- decide if nested blocks should be counted, and if the counter should be alpha
  nestnum = myyaml.nestednumber
  cnbx.numnest = true
  cnbx.alphanum = false  
  if nestnum ~= nil then 
    if type(nestnum) == "table" 
    then nestnum = pandoc.utils.stringify(nestnum)
    else nestnum = tostring(nestnum)      
    end
    if nestnum ~= "false" then 
      cnbx.alphanum = nestnum == "alpha"
    else cnbx.numnest = false  
    end
  end  

--  -- get numbering depth
--   cnbx.numberlevel = 0
--   if meta.crossref then
--     if meta.crossref.chapters then 
--       cnbx.numberlevel = 1 end
--   end
--   initRenderInfo(meta)
  --dev.showtable(cnbx, "cnbx")
  return(meta)
end
}