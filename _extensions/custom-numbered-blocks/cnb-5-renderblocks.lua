-- TODO split into formats and render, eventually

cnbx = require "cnb-global"
colut = require "cnb-colors"

uti = require "cnb-utilities"
local ifelse = uti.ifelse

local FileExists = uti.FileExists
local warning = uti.warning
local colorCSSTeX = colut.colorCSSTeX_legacy

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
        else warning("no file "..includefile.." provided")
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

tostringtable = function(tbl)
  local result = {}
  local vv
  for k, v in pairs(tbl) do
    if type(v) == "table" 
      then vv = tostringtable(v)
      else vv = tostring(v)
      end  
    result[k] = vv
  end  
  return result
end

renderDiv = function(thediv) 
  local tt, blinfo, bty, rendr, id, roptions
  
  if cnbx.is_cunumblo(thediv) then
    id = thediv.identifier
      blinfo = cnbx.xref[id]
   
    roptions = tostringtable(blinfo.renderoptions)  
--  dev.showtable(blinfo, "the blinfo of "..id)
-- dev.showtable(cnbx.xref[id], "the xref of "..id)

tt = {id = id,
      type = blinfo.cnbclass, 
      tag = blinfo.refnumber,
      title = pandoc.Inlines(blinfo.pandoctitle), 
      typlabel = blinfo.label,
      typlabelTag = blinfo.label .. ifelse(blinfo.refnumber == "",""," "..blinfo.refnumber),
      mdtitle = blinfo.mdtitle, 
      options = roptions
     -- link = thelink
    } 
  -- dev.showtable(tt, "tt for "..thediv.identifier)
   
    bty = cnbx.classDefaults[blinfo.cnbclass].boxtype
--    print("render "..tt.id.." as ".. bty)
    rendr = cnbx.boxtypes[bty].render
    local beginBlock = rendr.beginBlock(tt)
    local endBlock = rendr.endBlock(tt)
  
    table.insert(thediv.content, 1, beginBlock)
    table.insert(thediv.content, endBlock)
  
  end  
  return(thediv)
end -- function renderDiv

return{
  Div = renderDiv,
  Pandoc = insertBoxtypesPandoc
}