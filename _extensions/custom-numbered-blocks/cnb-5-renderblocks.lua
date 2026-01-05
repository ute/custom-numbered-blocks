-- TODO split into formats and render, eventually

uti = require "cnb-utilities"
cnbx = require "cnb-global"
colut = require "cnb-colors"

local str = pandoc.utils.stringify
local tt_from_attributes_id = uti.tt_from_attributes_id
local FileExists = uti.FileExists
local warning = uti.warning
local colorCSSTeX = colut.colorCSSTeX_legacy

--[[
local ifelse = uti.ifelse
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
  
  local preamblestuff = colorCSSTeX(cnbx.fmt, cnbx.classDefaults)
  
   if cnbx.fmt == "pdf" then
    quarto.doc.use_latex_package("tcolorbox","many")
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
        else warn("no file "..includefile.." provided")
        end
     -- else print( 'nothing to include')  
      end  
  --  print("insert preamble for ".. key .." find files here "..val.path)
 --   val.render[cnbx.fmt].insertPreamble(doc, cnbx.classDefaults)
    end  
  end  

  if preamblestuff then quarto.doc.include_text("in-header", preamblestuff) end
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
    
    tt.boxtype = cnbx.classDefaults[tt.type].boxtype
    
    --print("trying to render soemthing ".. tt.boxtype)
    --dev.tprint (cnbx.boxtypes)
    --print( "%%%%%%%%%%%%%%%")
    local rendr = cnbx.boxtypes[tt.boxtype].render
    
    local beginBlock = rendr.beginBlock(tt)
    local endBlock = rendr.endBlock(tt)
    
    -- diagnostics
    --print(" the div " .. thediv.identifier.. " has content lrngth "..#thediv.content.. " and type of first entry is "
    --     .. str(thediv.content[1].t))
    --print(" beginblock has length ".. #beginBlock)     
     --   print("inserting in plain content")
     
    table.insert(thediv.content, 1, beginBlock)
    table.insert(thediv.content, endBlock)
    
   -- print("----")
  end  
  return(thediv)
end -- function renderDiv

return{
  Div = renderDiv,
  Pandoc = insertBoxtypesPandoc
}