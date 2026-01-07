--[[
Example for a simple boxtype that works with any format
This is also used as fallback if rendering functions are missing

author: ute
date: start 1/2026
]]--

local enclose = function(innertext, w1, w2)
  if #innertext == 0 then return pandoc.Inlines({}) end 
  w1 = w1 or "("
  w2 = w2 or ")"
  return pandoc.Inlines({pandoc.Str(w1)}.. innertext.. {pandoc.Str(w2)})
end

-- try enclose(ttt.title,": ","").

local space = pandoc.Inlines(pandoc.Space())


local defaultOptions = {
  --  numbered = "true"
}


local render = {
  beginBlock = function(ttt)
    local label = pandoc.Inlines(pandoc.Str(ttt.typlabelTag))
   -- if #ttt.title > 0 then 
      label = label.. space .. enclose(ttt.title)..space
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