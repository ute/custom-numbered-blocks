-- TODO: remove dependence from path, make a utility function for this

local defaultOptions = {
    numbered = "true",
    boxstyle = "foldbox.default", -- this is an extra option of this very box style
    collapse = "true",
    colors   = {"c0c0c0","808080"} 
  }

local beginBlock_html = function(ttt)
  local Open =""
  local bxstyle =" fbx-default closebutton"
  local typlabelTag = ttt.typlabelTag
  if #ttt.title > 0 then typlabelTag = typlabelTag..": " end
  if ttt.collapse =="false" then Open=" open" end
  if ttt.boxstyle =="foldbox.simple" 
    then 
      bxstyle=" fbx-simplebox fbx-default" 
    --    Open=" open" do not force override. Chose this in yaml or individually.
    --    we would want e.g to have remarks closed by default
    end
  return {
    pandoc.RawInline("html", '<details class=\"'..ttt.type..bxstyle ..'\"'..Open..'><summary>'..'<strong>'..typlabelTag..'</strong>'),
    pandoc.RawInline("html", ttt.title), -- change this later
    pandoc.RawInline("html", '</summary><div>')
  }
end  

local endBlock_html = function(ttt)
  return({pandoc.RawInline("html","</div></details>")})
end  


local beginBlock_pdf = function(ttt)
  local texEnv = "fbx"
  local typlabelTag = ttt.typlabelTag
  if #ttt.title > 0 then typlabelTag = typlabelTag..": " end
  if ttt.boxstyle=="foldbox.simple" then texEnv = "fbxSimple" end
  return {
    pandoc.RawInline("tex",'\\begin{'..texEnv..'}{'..ttt.type..'}{'..typlabelTag..'}{'),
    pandoc.RawInline("tex", ttt.title), -- change this later
    pandoc.RawInline("tex" ,'}\n'..'\\phantomsection\\label{'..ttt.id..'}\n') -- necessary for crossreferencing
  }
end  

local endBlock_pdf = function(ttt)
  local texEnv = "fbx"
  if ttt.boxstyle=="foldbox.simple" then texEnv = "fbxSimple" end
  return(pandoc.RawInline("tex",'\\end{'..texEnv..'}\n'))
end

return {
  defaultOptions = defaultOptions,
  html = {
    -- headerincludes = "": future option to modify default = stylename.tex
    beginBlock = beginBlock_html,
    endBlock = endBlock_html
  },
  pdf = {
    beginBlock = beginBlock_pdf,
    endBlock = endBlock_pdf
  }
}