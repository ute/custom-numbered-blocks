--[[
Example for a simple boxtype
This boxtype encloses title and contents of the custom numbered box in a colored box
with inner and outer margins of size 1 em to all sides.
This boxtype supports pdf and html format
author: ute 
date: 29/12/2025
]]--

local postit = {}

postit.defaultOptions = {
    numbered = "true",
    color = "lightgreen"
  }

--[[ for future extension to named colors
postit.colors = {
    lightgreen = colors.hex("90ee90")
]]--

-- rendering ----------------------------------------

--- generate the title line. To be used with both defined formats
--- @param ttt table contains information for the individual rendered block
local pandoctitle = function(ttt)
   local typlabelTag = ttt.typlabelTag
      if #ttt.title > 0 then typlabelTag = typlabelTag..": " end
      return pandoc.Inlines(pandoc.Emph(pandoc.Strong(typlabelTag)))..
             pandoc.Inlines(pandoc.Emph(ttt.title))
end  

postit.pdf = {
  headerincludes = "simpletextbox.tex",
  beginBlock = function(ttt)
    local bgcolor = "DarkSeaGreen1"--postit.defaultOptions.color
    return 
       pandoc.Inlines(pandoc.RawInline("tex", 
           '\\begin{simpletextbox}{'..bgcolor..'}'))
       ..pandoctitle(ttt)
   end,
  endBlock = function(ttt)
   return pandoc.RawInline("tex","\\end{simpletextbox}")
  end 
}

postit.html = {
  headerincludes = "simpletextbox.css",
  beginBlock = function(ttt)
    --dev.showtable(ttt, "thettt")
    local bgcolor = postit.defaultOptions.color
    return 
      pandoc.Inlines(pandoc.RawInline("html", 
          '<div class=simpletextbox style="background-color:'..bgcolor..';">'))
      ..pandoctitle(ttt) 
   end,
  endBlock = function(ttt)
   return pandoc.RawInline("html", '</div>') 
  end 
}

return postit