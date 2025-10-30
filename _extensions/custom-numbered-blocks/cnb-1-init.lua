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


local str = pandoc.utils.stringify

cnbx = require "cnb-global"

cnbx.ute="huhn"

ute1 = require "cnb-utilities"

local deInline = ute1.deInline
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty



-- find chapter number and file name
-- returns a table with keyed entries
--   processedfile: string, 
--   ishtmlbook: boolean, 
--   chapno: string (at least if ishtmlbook),
--   unnumbered: boolean - initial state of section / chapter
-- if the user has given a chapno yaml entry, then unnumbered = false

-- !!! for pdf, the workflow is very different! ---
-- also find out if lastfile of a book

-- find first and last file of a book, and chapter number of that file 


local chapterinfo =  function (book, fname)
  local first = "" 
  local last = "" 
  local chapno = nil
  local info = {}
  --if book.render then
    for _, v in pairs(book.render) do
      if str(v.type) == "chapter" then
        last = pandoc.path.split_extension(str(v.file))
        if first == "" then first = last end
        if last == fname then chapno = v.number end
      end
    end
    info.islast = (fname == last)
    info.isfirst = (fname == first)
    info.lastchapter = last
    info.chapno = chapno
    return(info)
end


local Meta_findChapterNumber = function (meta)
  local processedfile = pandoc.path.split_extension(PANDOC_STATE.output_file)
  cnbx.isbook = meta.book ~= nil
  cnbx.ishtmlbook = meta.book ~= nil and not quarto.doc.is_format("pdf")
  cnbx.processedfile = processedfile
  
  cnbx.prefix=""
  if (cnbx.numberlevel ==1) and  meta.numberprefix 
       then cnbx.prefix = str(meta.numberprefix) end
 
  cnbx.output_file = PANDOC_STATE.output_file
 -- pout(" now in "..processedfile.." later becomes ".. str(cnbx.output_file))
  
  cnbx.isfirstfile = not cnbx.ishtmlbook
  cnbx.islastfile = not cnbx.ishtmlbook
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
    cnbx.xreffile ="._"..processedfile.."_xref.json"
    cnbx.chapno = ""
    cnbx.unnumbered = true
  end
end

local makeKnownClassDetector = function (knownclasses)
  -- print("making babies "..str(knownclasses))
  return function(div)
    for _, cls in pairs(div.classes) do
      if tablecontains(knownclasses, cls) then return pandoc.utils.stringify(cls) end
    end
    return nil  
  end
end  


local Meta_initClassDefaults = function (meta) 
  -- do we want to prefix fbx numbers with section numbers?
  local cunumbl = meta["custom-numbered-blocks"]
  cnbx.knownclasses = {}
  cnbx.lists = {}
  --[[ TODO later
  if meta.fbx_number_within_sections then
    cnbx.number_within_sections = meta.fbx_number_within_sections
  else   
    cnbx.number_within_sections = false
  end 
  --]] 
  -- prepare information for numbering fboxes by class
  -- cnbx.knownClasses ={}
  cnbx.classDefaults ={}
  local groupDefaults = {default = cnbx.stylez.defaultOptions} -- not needed later
  cnbx.counter = {unnumbered = 0} -- counter for unnumbered divs 
  -- ! unnumbered not for classes that have unnumbered as default !
  -- cnbx.counterx = {}
  if cunumbl.classes == nil then
        print("== @%!& == Warning == &!%@ ==\n wrong format for fboxes yaml: classes needed")
        return     
  end
  
-- simplified copy of yaml data: inlines to string
  if cunumbl.groups then
    for key, val in pairs(cunumbl.groups) do
      local ginfo = deInline(val)
      --[[
      pout("==== before after =======");  pout(ginfo)
      if ginfo.boxstyle then
        local mainstyle, substyle = ginfo.boxstyle:match "([^.]*).(.*)"
      --  pout("main "..mainstyle.." :: "..substyle)
        -- TODO: here account for multiple styles
      end
      --]]--
      ginfo = updateTable(cnbx.stylez.defaultOptions, ginfo)
      --cnbx.
      groupDefaults[key] = ginfo
   --   pout("-----group---"); pout(ginfo)
    end 
  end  
  for key, val in pairs(cunumbl.classes) do
    local clinfo = deInline(val)
  --  pout("==== before after =======");  pout(clinfo)
    -- classinfo[key] = deInline(val)
    table.insert(cnbx.knownclasses, str(key))
    local theGroup = replaceifnil(clinfo.group, "default")
    clinfo = updateTable(groupDefaults[theGroup], clinfo)
    clinfo.label = replaceifnil(clinfo.label, str(key))
    clinfo.reflabel = replaceifnil(clinfo.reflabel, clinfo.label)
    -- assign counter --  
    clinfo.cntname = replaceifnil(clinfo.group, str(key))
    cnbx.counter[clinfo.cntname] = 0 -- sets the counter up if non existing
    cnbx.classDefaults[key] = clinfo
 -- pout("---class----");  pout(clinfo)
  end 
  cnbx.is_cunumblo = makeKnownClassDetector(cnbx.knownclasses)
-- gather lists-of and make filenames by going through all classes
  for _, val in pairs(cnbx.classDefaults) do
  --  pout("--classdefault: "..str(key))
  --  pout(val)
    if val.listin then
      for _,v in ipairs(val.listin) do
        cnbx.lists[v] = {file = "list-of-"..str(v)..".qmd"}
      end
    end
  end
-- initialize lists
  for key, val in pairs(cnbx.lists) do
    val.contents = ifelse(cnbx.isfirstfile, "\\providecommand{\\Pageref}[1]{\\hfill p.\\pageref{#1}}", "")
  -- listin approach does not require knownclass, since listin is in classdefaults
  end
 -- pout(cnbx.lists)
  --]]
-- document can give the chapter number for books in yaml header 
-- this becomes the counter Prefix
end

return{
Meta = function(m)
 -- print("1. Init Meta")
-- get numbering depth
  cnbx.numberlevel = 0
  if m.crossref then
    if m.crossref.chapters then cnbx.numberlevel = 1 end
  end
  if m["custom-numbered-blocks"] then
    Meta_findChapterNumber(m)
    Meta_initClassDefaults(m)
  else
    print("== @%!& == Warning == &!%@ ==\n missing cunumblo key in yaml")  
  end
  -- print("numberlevel is ".. str(cnbx.numberlevel))
  return(m)
end
}