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
-- TODO split into formats and render, eventually

cnbx = require "cnb-global"
colut = require "cnb-colors-sizes"
-- colut = require "cnb-colors"

uti = require "cnb-utilities"
require "cnb-renderfunctions"

--local ifelse = uti.ifelse

local FileExists = uti.FileExists
local warning = uti.warning
local setVariablesCSSTeX = colut.SetVariablesCSSTeX

--[[

local replaceifnil = uti.replaceifnil
local replaceifempty = uti.replaceifempty
local str_md = uti.str_md
local tablecontains = uti.tablecontains
local updateTable = uti.updateTable
local deInline = uti.deInline
--]]--


local insertBoxtypesPandoc = function(doc)
  -- Done: change for a list of styles
  -- Done: decided on 26.12.25: for pdf and html use standard packages until change needed
-- insert extra css and latex with same name in same directory
  
  local preamblestuff = setVariablesCSSTeX(cnbx.fmt, cnbx.classDefaults)
    
   if cnbx.fmt == "pdf" then
    quarto.doc.use_latex_package("tcolorbox","many")
    -- now a workaround for ul from soul that clashes with tcolorbox
    quarto.doc.include_text("in-header", 
       "\\ifdefined\\ul\\renewcommand{\\ul}[1]{\\underline{#1}}\\fi % because soul conflicts with tcolorbox")
    for _, val in pairs(cnbx.boxtypes) do
       includefile = val.render.headerincludes
       if includefile ~= nil then
          includefile = pandoc.path.normalize(val.dir.."/"..includefile)
          if  FileExists(includefile) then
 --      print("insert preamble for ".. key .." find files here "..val.path)
            quarto.doc.include_file("in-header", includefile)
          else warning("no file "..includefile.."provided")
         end
        end   
    end  
  end
  
  if cnbx.fmt == "html" then
    for key, val in pairs(cnbx.boxtypes) do
      --print("processing boxtype "..key.." information is")
      --dev.tprint(val)
      includefile = val.render.headerincludes
      if includefile ~= nil then
        includefile = pandoc.path.normalize(val.dir.."/"..includefile)
       -- print("including "..includefile)
        if  FileExists(includefile) then
        quarto.doc.add_html_dependency({
           name = key,      -- version = '0.0.1',
           stylesheets = {includefile}
         })
        else uti.warning("no file "..includefile.." provided")
        end
     -- else print( 'nothing to include')  
      end  
  --  print("insert preamble for ".. key .." find files here "..val.path)
 --   val.render[cnbx.fmt].insertPreamble(doc, cnbx.classDefaults)
    end  
  end  

  if preamblestuff then quarto.doc.include_text("in-header", preamblestuff) end
  -- dev.showtable(cnbx.xref["first"],"hier sind wir in step 5")
  
  return(doc)
end;

-- for renderoptions: everything to string, because yaml and attributes are inconsistent

--[[ for later italic = {Str= function(elem) return pandoc.Emph(elem) end}]]

renderDiv = function(thediv) 
  local tt, blinfo, bty, id, boxcode --, roptions
  
  if cnbx.is_cunumblo(thediv) then
    id = thediv.identifier
      blinfo = cnbx.xref[id]
      -- dev.showtable(blinfo, "blinfo")
      tt = uti.tt_from_blinfo(blinfo)
    
    bty = cnbx.classDefaults[blinfo.cnbclass].boxtype
--    print("render "..tt.id.." as ".. bty)
    boxcode = cnbx.boxtypes[bty].render
    local beginBlock = boxcode.beginBlock(tt)
    local endBlock = boxcode.endBlock(tt)
    
    if boxcode.headerinline and   
      #thediv.content > 0 and thediv.content[1].t == "Para" and 
      thediv.content[#thediv.content].t == "Para" 
    then
      table.insert(thediv.content[1].content, 1, beginBlock)
    else
    table.insert(thediv.content, 1, beginBlock)
    end
    table.insert(thediv.content, endBlock)
  
  end  
  return(thediv)
end -- function renderDiv

return{
  Div = renderDiv,
  Pandoc = insertBoxtypesPandoc
}