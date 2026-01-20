--[[
MIT License

Copyright (c) 2023 Ute Hahn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--
-- pre-release
-- 
-- partial rewrite, complete later

-- important quasi global variables


cnbx = require "cnb-global"
util = require "cnb-utilities"

if cnbx.fmt == "unsupported" then
  util.warning ("format "..FORMAT.." not supported")
  return
end  

return{
    require("cnb-1-init-yaml") 
  , require("cnb-1-init-options")  -- Meta: set up classes, groups etc
  , require("cnb-1-init-chapters") -- Meta: set up chapter numbers and classes   
  , require("cnb-1-init-xref")     -- Meta: for books read crossref information from other chapters
  , require("cnb-2-register-divs") -- make indices for all cunumblo divs, register raw title
  , require("cnb-2-fix-nested-layout-divs") -- fix the floating figure type for nested layout blocks
  , require("cnb-3-crossref")      -- follow headers and count cross references. Resolve \ref
  , require("cnb-4-prepare-render") -- filter element attributes and register rendered titles 
  , require("cnb-5-renderblocks")  -- do the rendering, register colors 
  , require("cnb-6-listof")        -- generate List-of qmd files
}

