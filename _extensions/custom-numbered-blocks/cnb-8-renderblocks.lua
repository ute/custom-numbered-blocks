ute1 = require "cnb-utilities"
cnbx = require "cnb-global"

local str = pandoc.utils.stringify
local tt_from_attributes_id = ute1.tt_from_attributes_id

--[[
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local str_sanimath = ute1.str_sanimath
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
--]]--



insertStylesPandoc = function(doc)
  -- TODO: change for a list of styles
  -- if stylez.extractStyleFromYaml then stylez.extractStyleFromYaml() end
  print("doing style insert - this is going to change [big TODO]")
  if cnbx.stylez.insertPreamble and (quarto.doc.is_format("html") or quarto.doc.is_format("pdf"))
    then cnbx.stylez.insertPreamble(doc, cnbx.classDefaults, cnbx.fmt) 
 --  cnbx.stylez.fakeinsertPreamble(doc, cnbx.classDefaults, cnbx.fmt) 
    else print("could not do it")
    end
  return(doc)
end;

renderDiv = function(thediv) 
  -- TODO: change for individual style   
  local A = thediv.attributes
  local tt = {}
  if A._fbxclass ~= nil then
    
    collapsstr = str(A._collapse)
    tt = tt_from_attributes_id(A, thediv.identifier)
    
    local fmt='html'
    if quarto.doc.is_format("pdf") then fmt = "tex" end;
    if #thediv.content > 0 and thediv.content[1].t == "Para" and 
      thediv.content[#thediv.content].t == "Para" then
        table.insert(thediv.content[1].content, 1, 
          pandoc.RawInline(fmt, cnbx.stylez.blockStart(tt, fmt)))
        table.insert(thediv.content,
          pandoc.RawInline(fmt, cnbx.stylez.blockEnd(tt, fmt)))
      else
        table.insert(thediv.content, 1, 
          pandoc.RawBlock(fmt, cnbx.stylez.blockStart(tt, fmt)))
        table.insert(thediv.content,  
          pandoc.RawBlock(fmt, cnbx.stylez.blockEnd(tt, fmt)))
    end  
    --]]
  end  
  -- print("tried to render the div")
  return(thediv)
end -- function renderDiv




return{
  Div = renderDiv,
  Pandoc = insertStylesPandoc
}