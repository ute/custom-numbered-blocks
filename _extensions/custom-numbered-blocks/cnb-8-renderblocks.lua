-- TODO split into formats and render, eventually

ute1 = require "cnb-utilities"
cnbx = require "cnb-global"
colut = require "cnb-colors"

local str = pandoc.utils.stringify
local tt_from_attributes_id = ute1.tt_from_attributes_id
local FileExists = ute1.FileExists
local warn = ute1.warn
local colorCSSTeX = colut.colorCSSTeX_legacy

--[[
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
--]]--


insertStylesPandoc = function(doc)
  -- Done: change for a list of styles
  -- if stylez.extractStyleFromYaml then stylez.extractStyleFromYaml() end
 -- print("doing style insert - this is going to change [big TODO]")

-- TODO: decided on 26.12.25: for pdf and html use standard packages until change needed
-- insert extra css and latex with same name in same directory
  
  local preamblestuff = colorCSSTeX(cnbx.fmt, cnbx.classDefaults)
  local includefile = ""
  
  if cnbx.fmt == "pdf" then
    quarto.doc.use_latex_package("tcolorbox","many")
    for _, val in pairs(cnbx.styles) do
       includefile = val.path..".tex"
       if  FileExists(includefile) then
 --      print("insert preamble for ".. key .." find files here "..val.path)
         quarto.doc.include_file("in-header", val.path..'.tex')
       else warn("no file "..includefile.."provided")
       end
    end  
  end
  
  if cnbx.fmt == "html" then
    for key, val in pairs(cnbx.styles) do
      includefile = val.path..".css"
      if  FileExists(includefile) then
        quarto.doc.add_html_dependency({
           name = key,      -- version = '0.0.1',
           stylesheets = {val.path..".css"}
         })
      else warn("no file "..includefile.." provided")
      end  
  --  print("insert preamble for ".. key .." find files here "..val.path)
 --   val.render[cnbx.fmt].insertPreamble(doc, cnbx.classDefaults)
    end  
  end  
  

  if preamblestuff then quarto.doc.include_text("in-header", preamblestuff) end
  return(doc)
end;



insertStylesPandoc0 = function(doc)
  -- Done: change for a list of styles
  -- if stylez.extractStyleFromYaml then stylez.extractStyleFromYaml() end
 -- print("doing style insert - this is going to change [big TODO]")

-- TODO: decided on 26.12.25: for pdf and html use standard packages until change needed
-- insert extra css and latex with same name in same directory
  for key, val in pairs(cnbx.styles) do
    print("insert preamble for ".. key)
    val.render[cnbx.fmt].insertPreamble(doc, cnbx.classDefaults)
  end  

  return(doc)
end;


renderDiv = function(thediv) 
  -- Done: change for individual style   
  local A = thediv.attributes
  local tt = {}
  if A._fbxclass ~= nil then
    
    collapsstr = str(A._collapse)
    tt = tt_from_attributes_id(A, thediv.identifier)
    
    local fmt=cnbx.fmt
    if fmt=="pdf" then fmt = "tex" end;
    local rendering = cnbx.styles[tt.blockstyle].render[cnbx.fmt]
    
    local blockStart = pandoc.RawInline(fmt, rendering.blockStart(tt))
    local blockEnd = pandoc.RawInline(fmt, rendering.blockEnd(tt))

    if #thediv.content > 0 and thediv.content[1].t == "Para" and 
      thediv.content[#thediv.content].t == "Para" then
        table.insert(thediv.content[1].content, 1, blockStart)
      else
        table.insert(thediv.content, 1, blockStart)
    end   
    table.insert(thediv.content, blockEnd) 
          
    --]]
  end  
  -- print("tried to render the div")
  return(thediv)
end -- function renderDiv

return{
  Div = renderDiv,
  Pandoc = insertStylesPandoc
}