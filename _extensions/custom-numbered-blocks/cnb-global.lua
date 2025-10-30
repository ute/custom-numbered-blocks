local cnbx={ -- global table, holds information for processing fboxes
   xreffile = "._xref.json" -- default name, set to lastfile in initial meta analysis
   ,
   ute = "hahn"
}


if quarto.doc.is_format("html") then cnbx.fmt = "html"
   elseif quarto.doc.is_format("pdf") then cnbx.fmt = "pdf"
--   elseif quarto.doc.is_format("typst") then cnbx.fmt = "typst"
   else cnbx.fmt = "unsupported"
end


return cnbx
