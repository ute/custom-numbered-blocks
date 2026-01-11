--[[
Example for a simple appearance definition that works with any format,
since it is solely built on pandoc.
It mimics quartos theorem blocks, but not for latex, where it works without amsthm

author: ute
date: start 1/2026
]]--


local defaultOptions = {
  --  numbered = "true"
}


local render = {
  beginBlock = function(ttt)
    local 
   -- if #ttt.title > 0 then 
      label = ttt.ptyplabelTag.. pspace .. penclose(ttt.title)..pspace
    --end
    return pandoc.Strong(label)
  end,

  endBlock = function(ttt)
    return {}
  end,
  
  -- title on same line as content
  headerinline = true
}

return {
  defaultOptions = defaultOptions,
  html = render,
  pdf = render,
  unknown = render
}