-- global utility function for boxtype implementations


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
