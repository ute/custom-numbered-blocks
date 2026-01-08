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

uti = require "cnb-utilities"

local ifelse = uti.ifelse

--- keep the pageref thing because one would not like to edit the list twice, for html and pdf

--- init a list of stuff
--- @param stuff string
local initListOfX = function(stuff)
  local stff = pandoc.utils.stringify(stuff)
  result = {
    file = "list-of-"..stff..".qmd",
    contents = ifelse(cnbx.isfirstfile, 
       "`\\providecommand{\\Pageref}[1]{\\hfill p.\\pageref{#1}}`{=latex}\n", "")
  }
  return result
end

--- make entry in list for one div  
local makeEntry = function(blinfo)
  local tt = uti.tt_from_blinfo(blinfo)
  return ("\n [**"..tt.typlabelTag.."**](" .. tt.link ..")" ..
                      ifelse(tt.mdtitle=="","",": "..tt.mdtitle) .. "\\Pageref{".. tt.id .."}\n")
end


-- going through all cnb-divs
local filterdiv = {traverse="topdown"}

filterdiv.Div = function(div)
  local cls, id, listin, clistin, thelist, entry
  cls = cnbx.is_cunumblo(div)
  if cls ~= nil then
    id = div.identifier
    cls = cnbx.xref[id].cnbclass
    listin = {div.attributes.listin}
    clistin = cnbx.classDefaults[cls].listin
    listin = uti.mergeStringLists(clistin, listin)
    entry = makeEntry(cnbx.xref[id])
    for _, listid in ipairs(listin) do
      --print(listid)
      thelist = cnbx.lists[listid]
      if not thelist  then 
        --print(type(thelist).." add list "..listid)  
        thelist = initListOfX(listid)
        cnbx.lists[listid] = thelist
      --else print(type(thelist))
       end
        thelist.contents = thelist.contents .. entry
    end
  end
  return(div)
end


local function Pandoc_makeListof(doc)
  
  local lstfilemode = ifelse(cnbx.isfirstfile, "w", "a")

  --- write to file ---
  for _, lst in pairs(cnbx.lists) do
    if lst.file ~= nil then 
      local file = io.open(lst.file, lstfilemode)
      if file then 
        file:write(lst.contents) 
        file:close()
      else uti.warning("cannot write to file "..lst.file)  
      end  
    end  
  end

  return(doc)
end


return{
  Div = filterdiv.Div,
  Pandoc = Pandoc_makeListof
}