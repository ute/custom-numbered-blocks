-- TODO: remove dependence from path, make a utility function for this
clu = require "cnb-colors"
local colorCSSTeX = clu.colorCSSTeX_legacy

local htmlblockstart = function(ttt)
  local Open =""
  local bxstyle =" fbx-default closebutton"
  if #ttt.title > 0 then ttt.typlabelTag = ttt.typlabelTag..": " end
  if ttt.collapse =="false" then Open=" open" end
  if ttt.boxstyle =="foldbox.simple" 
    then 
      bxstyle=" fbx-simplebox fbx-default" 
    --    Open=" open" do not force override. Chose this in yaml or individually.
    --    we would want e.g to have remarks closed by default
    end
  result = ('<details class=\"'..ttt.type..bxstyle ..'\"'..Open..'><summary>'..'<strong>'..ttt.typlabelTag..'</strong>'..ttt.title .. '</summary><div>')
  return result
end  

local pdfblockstart = function(ttt)
  local texEnv = "fbx"
  if #ttt.title > 0 then ttt.typlabelTag = ttt.typlabelTag..": " end
  if ttt.boxstyle=="foldbox.simple" then texEnv = "fbxSimple" end
  return('\\begin{'..texEnv..'}{'..ttt.type..'}{'..ttt.typlabelTag..'}{'..ttt.title..'}\n'..
         '\\phantomsection\\label{'..ttt.id..'}\n')
end  


local htmlpreamble = function(doc, classDefs)
  local preamblestuff = colorCSSTeX("html", classDefs)
  -- quarto.log.output(preamblestuff)
  quarto.doc.add_html_dependency({
      name = 'faltbox',
      -- version = '0.0.1',
      stylesheets = {'styles/faltbox.css'}
    })
  if preamblestuff then quarto.doc.include_text("in-header", preamblestuff) end
  return(doc)
end

local pdfpreamble = function(doc, classDefs)
  local preamblestuff = colorCSSTeX("pdf", classDefs)
  -- quarto.log.output(preamblestuff)
  quarto.doc.use_latex_package("tcolorbox","many")
  quarto.doc.include_file("in-header", 'styles/faltbox.tex')
  if preamblestuff then quarto.doc.include_text("in-header", preamblestuff) end
  return(doc)
end



return {
defaultOptions = {
    numbered = "true",
    boxstyle = "foldbox.default", -- this is an extra option of this very box style
    collapse = "true",
    colors   = {"c0c0c0","808080"} 
  },
render = {
   html = {
     blockStart = htmlblockstart,
     blockEnd = function(ttt) return('</div></details>') end,
     insertPreamble = htmlpreamble
   },
   pdf = {
     blockStart = pdfblockstart,
     blockEnd = function(ttt) 
       local texEnv = "fbx"
       if ttt.boxstyle=="foldbox.simple" then texEnv = "fbxSimple" end
       return('\\end{'..texEnv..'}\n')
     end,  
     insertPreamble = pdfpreamble
   }
  }
}