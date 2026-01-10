--[[
Example for a simple appearance definition with styling
This example encloses title and contents of the custom numbered box in a colored box
with inner and outer margins of size 1 em to all sides.
simpletextbox supports pdf and html format
it is also an example for what you can do with pandoc functions, 
see the local function pandoctitle

author: ute 
date: 29/12/2025
]]--

local txtbx = {}

txtbx.defaultOptions = {
    colors = {"#cccccc"}, 
    sizes={margin = '0.5em', padding = '0.5em'},
    underlineheader = true}
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
  local header
  if #ttt.title > 0 then typlabelTag = typlabelTag..pcolon end
  header = {pandoc.Strong(typlabelTag)}..ttt.title
  if ttt.options.underlineheader=="true"
    then header = pandoc.Underline(header) 
    else header = header .. pblankline
    end
  return pandoc.Inlines(header)
end  


txtbx.pdf = {
  headerincludes = "textbox.tex",
  beginBlock = function(ttt)
    local size=ttt.options.sizes
    return 
      {pandoc.RawInline("tex", '\\begin{textbox}{'..ttt.type..'}{'..
         size.padding..'}{'..size.margin..'}')}
       ..pandoctitle(ttt)
   end,
  endBlock = function(ttt)
    return pandoc.RawInline("tex","\\end{textbox}")
  end 
}

txtbx.html = {
  headerincludes = "textbox.css",
  beginBlock = function(ttt)
    return 
      pandoc.Inlines(pandoc.RawInline("html", 
        '<div class=textbox class=\"'..ttt.type..'\">'))..
      pandoctitle(ttt)
   end,
  endBlock = function(ttt)
   return pandoc.RawInline("html", '</div>') 
  end 
}

return txtbx