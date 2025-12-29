-- TODO: remove dependence from path, make a utility function for this

local defaultOptions = {
    numbered = "true"
  }

local render = {
  beginBlock = function(ttt)
    local typlabelTag = ttt.typlabelTag
    if #ttt.title > 0 then typlabelTag = typlabelTag..": " end
    return pandoc.Inlines(pandoc.Strong(typlabelTag))..
      pandoc.Inlines(pandoc.Str(ttt.title))
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