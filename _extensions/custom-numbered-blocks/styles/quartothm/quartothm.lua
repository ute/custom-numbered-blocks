--[[
Example for a simple boxtype that works with any format
This is also used as fallback if rendering functions are missing

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
  
  nonewline = true
}

return {
  defaultOptions = defaultOptions,
  html = render,
  pdf = render,
  unknown = render
}