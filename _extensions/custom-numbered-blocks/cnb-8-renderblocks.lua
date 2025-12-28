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


local insertBoxtypesPandoc0 = function(doc)
  -- Done: change for a list of styles
  -- Done: decided on 26.12.25: for pdf and html use standard packages until change needed
-- insert extra css and latex with same name in same directory
  
  local preamblestuff = colorCSSTeX(cnbx.fmt, cnbx.classDefaults)
  local includefile = ""
  local luacontent = require "styles.faltbox.faltbox"
  local lu
  
  if cnbx.fmt == "pdf" then
    quarto.doc.use_latex_package("tcolorbox","many")
    for _, val in pairs(cnbx.styles) do
       includefile = val.headerincludes
       if includefile ~= nil then
         if  FileExists(includefile) then
 --      print("insert preamble for ".. key .." find files here "..val.path)
            quarto.doc.include_file("in-header", val.path..'.tex')
          else warn("no file "..includefile.."provided")
         end
        end   
    end  
  end
  
  if cnbx.fmt == "html" then
    for key, val in pairs(cnbx.boxtypes) do
      print("processing boxtype "..key)
      -- dev.tprint(val)
      print("filepath "..quarto.utils.resolve_path(val.path))
      luacontent = dofile(quarto.utils.resolve_path("styles/foldbox/faltbox.lua"))
      lu = luacontent
      if lu == nil then print("--- nicht geladen") 
      else print(type(lu).." "..#lu) 
      end
      -- if luacontent.stilnam ~= nil then  print("-->"..lucacontent.stilnam) end
      includefile = lu.headerincludes
      if includefile ~= nil then
        print("including "..includefile)
        if  FileExists(includefile) then
        quarto.doc.add_html_dependency({
           name = key,      -- version = '0.0.1',
           stylesheets = {val.path..".css"}
         })
        else warn("no file "..includefile.." provided")
        end
      else print( 'nothing to include')  
      end  
  --  print("insert preamble for ".. key .." find files here "..val.path)
 --   val.render[cnbx.fmt].insertPreamble(doc, cnbx.classDefaults)
    end  
  end  

  if preamblestuff then quarto.doc.include_text("in-header", preamblestuff) end
  return(doc)
end;


local insertBoxtypesPandoc = function(doc)
  -- Done: change for a list of styles
  -- Done: decided on 26.12.25: for pdf and html use standard packages until change needed
-- insert extra css and latex with same name in same directory
  
  local preamblestuff = colorCSSTeX(cnbx.fmt, cnbx.classDefaults)
  
   if cnbx.fmt == "pdf" then
    quarto.doc.use_latex_package("tcolorbox","many")
    for _, val in pairs(cnbx.boxtypes) do
       includefile = val.headerincludes
       if includefile ~= nil then
         if  FileExists(includefile) then
 --      print("insert preamble for ".. key .." find files here "..val.path)
            quarto.doc.include_file("in-header", val.path..'.tex')
          else warn("no file "..includefile.."provided")
         end
        end   
    end  
  end
  
  if cnbx.fmt == "html" then
    for key, val in pairs(cnbx.boxtypes) do
      print("processing boxtype "..key.." information is")
      dev.tprint(val)
      -- dev.tprint(val)
      print("filepath "..quarto.utils.resolve_path(val.path))
      
      -- if luacontent.stilnam ~= nil then  print("-->"..lucacontent.stilnam) end
      includefile = val.render.headerincludes
      if includefile ~= nil then
        includefile = pandoc.path.normalize(val.dir.."/"..includefile)
        print("including "..includefile)
        if  FileExists(includefile) then
        quarto.doc.add_html_dependency({
           name = key,      -- version = '0.0.1',
           stylesheets = {includefile}
         })
        else warn("no file "..includefile.." provided")
        end
      else print( 'nothing to include')  
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
    local rendernew = cnbx.boxtypes[tt.boxtype].render
    
    --local blockStart = pandoc.RawInline(fmt, rendering.blockStart(tt))
    --local blockEnd = pandoc.RawInline(fmt, rendering.blockEnd(tt))

    local beginBlock = rendernew.beginBlock(tt)
    local endBlock = rendernew.endBlock(tt)
    
    -- diagnostics
    --print(" the div " .. thediv.identifier.. " has content lrngth "..#thediv.content.. " and type of first entry is "
    --     .. str(thediv.content[1].t))
    --print(" beginblock has length ".. #beginBlock)     
     --   print("inserting in plain content")
     
    table.insert(thediv.content, 1, beginBlock)--blockStart)  
    table.insert(thediv.content, endBlock)--blockEnd) 
    
   -- print("----")
  end  
  return(thediv)
end -- function renderDiv

return{
  Div = renderDiv,
  Pandoc = insertBoxtypesPandoc
}