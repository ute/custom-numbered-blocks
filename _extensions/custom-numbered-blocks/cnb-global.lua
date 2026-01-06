local cnbx={ -- global table, holds information for processing fboxes
   xreffile = "test._xref.json" -- default name, set to lastfile in initial meta analysis
   , -- todo drop this, it is only needed for books
   styles = {default = {numbered = true, boxtype = "foldbox"}},
   boxtypes = {},
   lists = {}
  -- defaultboxtype = "foldbox",
}


if quarto.doc.is_format("html") then cnbx.fmt = "html"
   elseif quarto.doc.is_format("pdf") then cnbx.fmt = "pdf"
--   elseif quarto.doc.is_format("typst") then cnbx.fmt = "typst"
   else cnbx.fmt = "unsupported"
end


return cnbx
