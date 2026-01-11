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
--[[
  process div attributes
  filter out proper render options
]]--

require("cnb-global")
uti = require("cnb-utilities")
local warning = uti.warning 

local tablecontains = uti.tablecontains

local filterAttributes = function(el)
  local id = el.identifier
  local rattribs -- collect attributes for box styling
  local norattribs -- the remaining attributes like label, container, ...
  local ignoreargs
  
  -- TODO this is only looking at "first" example, for debugging. Remove if-then later
  --if id == "first" then
  
  local info = cnbx.xref[id]  
  if info == nil then
  --    print("Div with identifier "..id.." is not a cunumblo")
      return(el)
  end
  
  -- decision: do not allow changing appearance or container. 
  -- this can be achieved by grouping instead on a per element base
  -- classes are coherent in their options.
  -- if users really want this, it could be changed later.
  -- like an icon on a callout

  local cls = info.cnbclass

  --if bty then print ("container given, tsts "..bty) end
  --if sty then print ("appearance given, tsts "..sty) end
  --print("class is "..cla.." - now get all default options")
  
  local clopt = cnbx.classDefaults[cls]
  --local stopt = cnbx.styles[sty]
  --local bxtopt = cnbx.boxtypes[bty]
  -- local bxopt
 
  --local norclassdef ={}
  local elementattribs = {}

  rattribs = {}
  norattribs = {}
  local norendero = {"label", "reflabel", "tag", "appearance", "container", "listin"}
  for k, v in pairs(el.attributes) do
    if tablecontains(norendero, k) then
       -- print(k..": "..pandoc.utils.stringify(v))
        norattribs[k] = v
    else rattribs[k] = v
    end
  end  
  
-- too late here, needs to come with crossref

  --dev.showtable(norattribs, "no render attributes for "..id)
  -- make sure to adjust reflabel to label, if label is given but not reflabel

  -- ignore container type, appearance, color and colors. They cannot be changed per element  
  ignoreargs = ""
  local quotek = ""
  local ignoreo = {"container", "boxtype", "color", "colors", "appearance"}
  for k,_ in pairs(norattribs) do
    if tablecontains(ignoreo, k) then
      quotek = '"'..k..'"'
      if ignoreargs =="" then ignoreargs = quotek 
          else ignoreargs = ignoreargs ..", "..quotek end
       norattribs[k] = nil
    end
  end  
  
 -- print("ignoreargs = "..ignoreargs)
  
  if ignoreargs ~=""  then
    warning("elementwise attributes for block "..id..": "..ignoreargs..
      " are ignored. These can only be specified by class (or group, appearance)")
  end
  
  --dev.showtable(clopt,"class options") 
  --dev.showtable(rattribs, "rattribs")
  --dev.showtable(norattribs, "norattribs")
-- update with individual attributes

  elementattribs = deepcopy(clopt)
  elementattribs = uti.updateTable(elementattribs, rattribs)
  -- dev.showtable(defaultattribs, "final options")
  
  --[[
  no-render attributes are already set with crossreferencing
  for k, v in pairs(norattribs) do
    info[k] = v
  end
  ]]--

  local bty = elementattribs.boxtype
  info.boxtype = bty
  info.renderoptions = subtable(elementattribs, keynames(cnbx.boxtypes[bty].defaultOptions))
  
  --end  -- if first

end  

-- now references have been dereferenced, and we can gather pandoctitles
local makeblocktitle = function(el)
  local id = el.identifier
  local info = cnbx.xref[id]  
  local pandoctitle = {}
  if info == nil then
      return(el)
  end
  if info.mdtitle ~= "" then 
    el1 = el.content[1]
    if el1.t=="Header" then 
      pandoctitle = el1.content
      -- mdtitle = str_md(pandoctitle)
        --  title = pandoc.utils.stringify(pandoctitle)  -- readable version without math
          -- do not remove this in the first run? or does it work anyway, because the cites are allready resolved, and refs get resolved later?
        table.remove(el.content, 1) 
      else 
      -- mdtitle = ""
      pandoctitle = {pandoc.Str(info.mdtitle)}
    end
  end
    --info.mdtitle = mdtitle
  info.pandoctitle = pandoctitle
  return(el)
end  


return {
  Div = function(el)
    el = makeblocktitle(el)
    filterAttributes(el)
    return(el)
  end , 
  Pandoc = function(doc)
    -- dev.showtable(cnbx.xref, "xref")
    return(doc)
  end  
}