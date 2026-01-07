--[[
Example for a simple boxtype with styling
This boxtype encloses title and contents of the custom numbered box in a colored box
with inner and outer margins of size 1 em to all sides.
simpletextbox supports pdf and html format
it is also an example for what you can do with pandoc functions, 
see the local function pandoctitle

author: ute 
date: 29/12/2025
]]--

local postit = {}

postit.defaultOptions = {
   -- numbered = "true",
    color = "#D2E787",
    colors={"#9AE787"}
  }

--[[ for future extension to named colors
postit.colors = {
    lightgreen = colors.hex("90ee90")
]]--

-- rendering ----------------------------------------

--- generate the title line. To be used with both defined formats
--- title is set as underlined, and emphasized; 
--- type label and number are set as strong
--- @param ttt table contains information for the individual rendered block
local pandoctitle = function(ttt)
  local typlabelTag = ttt.ptyplabelTag
  if #ttt.title > 0 then typlabelTag = typlabelTag..pcolon end
  --return pandoc.Inlines(pandoc.Underline({pandoc.Strong(typlabelTag)}..ttt.title))
  return pandoc.Inlines({pandoc.Strong(typlabelTag)}..ttt.title)
end  

-- !!! unforunately, pandoc creates problems with underline for pdf. See also https://github.com/quarto-dev/quarto-cli/issues/6962

postit.pdf = {
  headerincludes = "simpletextbox.tex",
  beginBlock = function(ttt)
  --  local bgcolor = ttt.options.color
    return 
      {pandoc.RawInline("tex", '\\begin{simpletextbox}{'..tt.type..'}')}
       ..pandoctitle(ttt)
   end,
  endBlock = function(ttt)
    return pandoc.RawInline("tex","\\end{simpletextbox}")
  end 
}

postit.html = {
  headerincludes = "simpletextbox.css",
  beginBlock = function(ttt)
    local bgcolor = ttt.options.color
    return 
      pandoc.Inlines(pandoc.RawInline("html", 
        '<div class=simpletextbox style="background-color:'..bgcolor..';">'))..
      pandoctitle(ttt)
   end,
  endBlock = function(ttt)
   return pandoc.RawInline("html", '</div>') 
  end 
}

return postit