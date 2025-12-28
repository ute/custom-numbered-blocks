-- ps://gist.github.com/ripter/4270799, referred to on stack overflow
-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.

local M = {}


function M.tprint (tbl, indent)
  local vstr
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      M.tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    elseif type(v) =='function' then
      print(formatting.." a function")
    else  
      vstr = pandoc.utils.stringify(v)
      print(formatting .. vstr)
    end
  end
end

return M
