-- TODO: remove dependence from path, make a utility function for this

local defaultOptions = {
   -- numbered = "true",
    boxstyle = "foldbox.default", -- this is an extra option of this very box style
    collapse = "true",
    colors   = {"c0c0c0","808080"} 
  }

local pandoctitle = function(ttt)
  local typlabelTag = ttt.ptyplabelTag
  if #ttt.title > 0 then typlabelTag = typlabelTag..pcolon end
  return pandoc.Inlines({pandoc.Strong(typlabelTag)} .. ttt.title)
end  


local beginBlock_html = function(ttt)
  local Open
  local bxstyle =" fobx-default closebutton"
  if ttt.options.collapse=="true" then Open="" else Open = " open" end
  -- print("collapse for id "..ttt.id.." is "..tostring(ttt.options.collapse).." open is "..Open)
  if ttt.options.boxstyle =="foldbox.simple" 
    then 
      bxstyle=" fobx-simplebox fobx-default" 
    --    Open=" open" do not force override. Chose this in yaml or individually.
    --    we would want e.g to have remarks closed by default
    end
  return 
    {pandoc.RawInline("html", '<details class=\"'..ttt.type..bxstyle ..'\"'..Open..'><summary>')}..
    pandoctitle(ttt)..
    --pandoc.RawInline("html", ttt.title), -- change this later
    {pandoc.RawInline("html", '</summary><div>')}
  
end  

local endBlock_html = function(ttt)
  return({pandoc.RawInline("html","</div></details>")})
end  


local beginBlock_pdf = function(ttt)
  local texEnv = "fobx"
 -- local typlabelTag = ttt.typlabelTag
 -- if #ttt.title > 0 then typlabelTag = typlabelTag..": " end
  if ttt.options.boxstyle=="foldbox.simple" then texEnv = "fobxSimple" end
  return     
    {pandoc.RawInline("tex",'\\begin{'..texEnv..'}{'..ttt.type..'}{')}..
    pandoctitle(ttt) ..
    {pandoc.RawInline("tex" ,'}\n')}
     --{pandoc.RawInline("tex" ,'}\n'..'\\phantomsection\\label{'..ttt.id..'}\n')} -- necessary for crossreferencing
     -- this is no longer necessary :-)), how nice. I suppose it was the quarto crossref overhowl that makes
     -- good anchors for all named ids. also for automatic ids when html. This is fantastic.
     
end  

local endBlock_pdf = function(ttt)
  local texEnv = "fobx"
  if ttt.options.boxstyle=="foldbox.simple" then texEnv = "fobxSimple" end
  return(pandoc.RawInline("tex",'\\end{'..texEnv..'}\n'))
end

return {
  defaultOptions = defaultOptions,
  html = {
    headerincludes = "foldbox.css",
    -- headerincludes = "": future option to modify default = stylename.tex
    beginBlock = beginBlock_html,
    endBlock = endBlock_html
  },
  pdf = {
    headerincludes = "foldbox.tex",
    beginBlock = beginBlock_pdf,
    endBlock = endBlock_pdf
  }
}