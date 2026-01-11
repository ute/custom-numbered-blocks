-- global utility function for boxtype implementations
-- this will likely change, and is meant to make addition of containers easier

--[[
MIT License

Copyright (c) 2023-2026 Ute Hahn

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

panstr = function(strg) return pandoc.Inlines({pandoc.Str(strg)}) end

penclose = function(innertext, w1, w2)
  if #innertext == 0 then return pandoc.Inlines({}) end 
  w1 = w1 or "("
  w2 = w2 or ")"
  return panstr(w1).. innertext.. panstr(w2)
end

-- try enclose(ttt.title,": ","").

pspace = pandoc.Inlines(pandoc.Space())
pcolon = pandoc.Inlines(pandoc.Str(": "))
pblankline = pandoc.Inlines{pandoc.LineBreak(),pandoc.Space(), pandoc.LineBreak()}
    