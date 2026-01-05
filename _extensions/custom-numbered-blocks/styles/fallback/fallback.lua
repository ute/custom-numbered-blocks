--[[
Example for a simple boxtype that works with any format
This is also used as fallback if rendering functions are missing

author: ute
date: end 12/2025
]]--

local defaultOptions = {
  --  numbered = "true"
}

local render = {
  beginBlock = function(ttt)
    local typlabelTag = ttt.typlabelTag
    if #ttt.title > 0 then typlabelTag = typlabelTag..": " end
    print("block starts "..typlabelTag..pandoc.utils.stringify(ttt.title))
    print("ttt.title has typ"..pandoc.utils.type(ttt.title))
    return pandoc.Inlines(pandoc.Underline({
      pandoc.Strong(typlabelTag)}..ttt.title))
  end,
  endBlock = function(ttt)
    return {}
  end
}

return {
  defaultOptions = defaultOptions,
  html = render,
  pdf = render,
  unknown = render
}