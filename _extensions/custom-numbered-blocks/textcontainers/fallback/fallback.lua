--[[
Example for a simple container definition that works with any format
This is also used as fallback if rendering functions are missing

author: ute
date: end 12/2025
]]--


local defaultOptions = {
  --  numbered = "true"
}

local render = {
  beginBlock = function(ttt)
    local typlabelTag = ttt.ptyplabelTag
    if #ttt.title > 0 then typlabelTag = typlabelTag..pcolon end
    return pandoc.Inlines(pandoc.Underline({pandoc.Strong(typlabelTag)}..ttt.title))
-- unfortunately, pandoc messes pdf with underline
--    return pandoc.Inlines({pandoc.Strong(typlabelTag)}..ttt.title)
-- solved by redefining command \ul in pdf
  end,

  endBlock = function(ttt) return {} end,

  headerinline = false -- whether or not the block header is inserted in line with content
}

return {
  defaultOptions = defaultOptions,
  html = render,
  pdf = render,
  unknown = render
}