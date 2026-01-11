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

-- shortcuts
local str = pandoc.utils.stringify

cnbx = require "cnb-global"

--cnbx.ute="huhn"

--ute1 = require "cnb-utilities"
dev = require "devutils"

-- local deInline = ute1.deInline
-- local tablecontains = ute1.tablecontains
-- local updateTable = ute1.updateTable
-- local ifelse = ute1.ifelse
-- local replaceifnil = ute1.replaceifnil
-- local findFile = ute1.findFile
-- local warn = ute1.warn

--local replaceifempty = ute1.replaceifempty


--- find chapter number of current file, whether first or last file, and last file for books
--- only sensible for books
--- @param book table yaml entries from quarto
--- @param fname string currently rendered file
--- @return table with keyed entries
---   isfirst, islast: logical
---   lastchapter: name of last chapter
---   chapno: string (at least if ishtmlbook),
---   unnumbered: boolean - initial state of section / chapter
--- if the user has given a chapno yaml entry, then unnumbered = false
--- !!! for pdf, the rendering workflow is very different! ---
--- also find out if lastfile of a book
--- find first and last file of a book, and chapter number of that file 
local chapterinfo =  function (book, fname)
  local first = "" 
  local last = "" 
  local info = {}
  --if book.render then
    for index, v in ipairs(book.render) do
      if str(v.type) == "chapter" then
        last = pandoc.path.split_extension(str(v.file))
        if first == "" then first = last end
        if last == fname then 
          info.chapno = v.number 
          info.chapindex = index  
          --print("---> chapno = "..chapno)
    --      dev.showtable(v, "book.render v")
        end
      end
    end
    info.islast = (fname == last)
    info.isfirst = (fname == first)
    info.lastchapter = last
  --  dev.showtable(info, "chapter info")
    return(info)
end

--- find chapter information in meta table
--- sideeffects: add the following to cnbx:
---     isbook: logical
---     ishtmlbook: logical
---     processedfile: string, filename without extension
---     isfirstfile, islastfile : logical, for htmlbooks
---     xreffile: filename for json file to store crossref information
---     prefix: common prefix for all numbers instead of chapter or section number (if any)
---     chapno: chapter number, if any
--- @param meta table document meta information
local initRenderInfo = function (meta)
  local processedfile = pandoc.path.split_extension(PANDOC_STATE.output_file)
  cnbx.isbook = meta.book ~= nil
  cnbx.ishtmlbook = cnbx.isbook and not quarto.doc.is_format("pdf")
  cnbx.processedfile = processedfile
  -- cnbx.output_file = PANDOC_STATE.output_file -- with extension
  
  cnbx.prefix=""
  if (cnbx.numberlevel ==1) and  meta.numberprefix 
       then cnbx.prefix = str(meta.numberprefix) end
 
 -- print(" now in "..processedfile.." later becomes ".. str(cnbx.output_file))
  cnbx.isfirstfile = not cnbx.ishtmlbook
  cnbx.islastfile = not cnbx.ishtmlbook
  --
   -- for testing only
   cnbx.xreffile= ".test_xref.json"
  ---
  if cnbx.isbook then 
    local chinfo = chapterinfo(meta.book, processedfile)
    if cnbx.ishtmlbook then
      cnbx.xreffile= "._htmlbook_xref.json"
    else 
      cnbx.xreffile= "._pdfbook_xref.json"
      -- cnbx.xreffile= "._"..chinfo.lastchapter.."_xref.json"
    end  
    cnbx.isfirstfile = chinfo.isfirst 
    cnbx.islastfile  = chinfo.islast 
    
    cnbx.unnumbered = false
    -- user set chapter number overrides information from meta
    if meta.chapno then  
      cnbx.chapno = str(meta.chapno)
    else
      if chinfo.chapno ~= nil then
        cnbx.chapno = str(chinfo.chapno)
      else  
        cnbx.chapno = ""
        cnbx.unnumbered = true
      end
    end
  else -- not a book. 
--    cnbx.xreffile ="._"..processedfile.."_xref.json"
    cnbx.chapno = ""
    cnbx.unnumbered = true
  end
end


--- extract custom-numbered-block yaml from meta, according to Michael Canouils new policies
--- https://mickael.canouil.fr/posts/2025-11-06-quarto-extensions-lua/
--- still allowing the old syntax, with 1st level custom-numbered-blocks key
--- @param meta table document meta information
--- @return table cnby: part of meta that belongs to custom-numbered-blocks 
function cunumblo_yaml(meta)
  local cnby = meta["custom-numbered-blocks"]
  if not cnby then
    local extensions_yaml = meta.extensions
    if extensions_yaml then
      cnby = extensions_yaml["custom-numbered-blocks"] 
    else
      cnby = nil
    end
  end  
  if not cnby then
      quarto.log.warning("== @%!& == Warning == &!%@ ==\n missing cunumblo key in yaml")
      return{}
    else 
      return cnby
    end
end



return{
Meta = function(meta)
  
  cnbx.yaml = cunumblo_yaml(meta)
 -- print("1. Init Meta")
 
 -- get numbering depth
  cnbx.numberlevel = 0
  if meta.crossref then
    if tostring(meta.crossref.chapters) == "true" then 
      cnbx.numberlevel = 1 end
  end
  initRenderInfo(meta)
-- dev.showtable(cnbx, "cnbx")
  return(meta)
end
}