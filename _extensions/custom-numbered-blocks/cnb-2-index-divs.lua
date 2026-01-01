--[[
  In this module, gather information about all custom numbered blocks
  Rewrite this. 
  Gather most information in cnbx-xref. Only add one fbx-id to the blocks 
  attributes.
  Start with ensuring an identifier for all divs that are cnb
]]--

--[[
MIT License

Copyright (c) 2026 Ute Hahn

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


ute1 = require "cnb-utilities"

dev = require "devutils"

local str = pandoc.utils.stringify
local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil

--[[
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
]]--

--- number all custom numbered blocks to create identifiers

local cnbcounter = 0
local chapi = ""
if cnbx.chapno ~= nil then  chapi = "cnbx-"..str(cnbx.chapno) end

local function countDiv (div)
  local autoidx = "a"
  
  if cnbx.is_cunumblo(div) then
    cnbcounter = cnbcounter + 1
    autoidx = chapi..str(cnbcounter)
  end
  
  print(autoidx)
end  


----------------------- oldcode, mostly -------------------------------------


------- numbering and class attributes ------

local function fboxDiv_setAttributes(el, cls, prefix)
  local ela = el.attributes -- shortcut
  local ClassDef = cnbx.classDefaults[cls]
  --local unnumbered = ClassDef.numbered == "false"
  local numbered = ClassDef.numbered ~= "false"
  local tag = ela.tag
  local tagged = tag ~= nil
  local id = el.identifier
  local autoid =""
--  local titl = ela.title
  local cntkey = ClassDef.cntname
  local counter = {}
  local cnts = 0
  local idnumber = "0.0"
   
  print("fboxDiv_seta")

  --  set prefix
  ela._prefix = prefix

  id = replaceifnil(id ,"") 
  tag = replaceifnil(tag ,"") 
  
  --- determine if numbered and / or tagged ------
  
  if tagged then numbered = false end
  if el.classes:includes("unnumbered") then numbered = false end

  if ela.numtag then 
    tag = ela.numtag
  --  print("!!! also hier mal ein numtag.\n")
    numbered = true
    tagged = true
  end

-- make counts ---  
  
  if not numbered then cntkey = "unnumbered" end
    
  cnts = cnbx.counter[cntkey] +1
  cnbx.counter[cntkey] = cnts
 
  idnumber = ifelse(prefix ~= "", prefix .. '.' .. cnts, str(cnts))
  --[[
  if prefix ~="" then  idnumber = prefix .. '.' .. cnts
    else idnumber = str(cnts)
  end    

  if numbered then 
    if  not tagged then tag = idnumber
    else tag = idnumber.."("..tag..")" 
    end  
  end  
]]--
  if numbered then tag = idnumber..ifelse(tagged, "("..tag..")", "" ) end

  if id == "" then
    if numbered then
      autoid = ela._fbxclass..'-'..tag
    else
      autoid = ela._fbxclass..'*-'..idnumber
    end  
    -- changed my mind here: always give autoid
    else autoid = ela._fbxclass..'-id-'..id
  end  
  
  -- do not change identifier el.identifier = id
  
  ela._autoid = autoid 
   
  ela._tag = tag

  ela._file = cnbx.processedfile -- necessary to reference between chapters. At least with  quarto 1.3
 -- pout("tag: "..tag)
 -- pout(ela)
  return(el)
end

-- initial attributes without prefix and counts to allow for inner boxes


-- merged aus divsgetid
local function fboxDiv_mark_for_processing(div)
  local diva=div.attributes
  local cls = cnbx.is_cunumblo(div)
  local ClassDef = cnbx.classDefaults[cls]
  local id = div.identifier
  local el1={}

  print("markfor")
  if cls then
    diva._process_me = "true"
    diva._fbxclass = str(cls)
    diva._prefix = ""
    diva._tag = ""
    diva._collapse = str(replaceifnil(diva.collapse, ClassDef.collapse)) 
    diva._boxstyle = str(replaceifnil(diva.boxstyle, ClassDef.boxstyle)) 
    diva._label = str(replaceifnil(diva.label, ClassDef.label)) 
    diva._reflabel = str(replaceifnil(diva.reflabel, ClassDef.reflabel)) 
  -- local known = getKnownEnv(el.attr.classes)
     
   --if not ela._process_me then return(el) end
   -- pout("--- processing item with id ".. replaceifempty(id, "LEER"))
   
  if id == nil or id =="" then  
    -- try in next header
    el1 = div.content[1]
    if el1.t=="Header" then 
    --    pout("--- looking at header with id "..el1.identifier)
    --    pout("--- still processing item with id ".. replaceifempty(id, "LEER"))
     -- pout("replacing id")
      id = el1.identifier
      div.identifier = id
    end
  end 
  if id == nil or id =="" 
    then  
      -- pout("immer noch leer")
      if div._autoid ~= nil then
      id = div._autoid
      div.identifier = id
    end 
    --else pout("nix autoid in ");pout(ela._autoid)
  end
  -- pout("resulting el:"); pout(el.attr)
 
  return(div)
end
end

local function fboxDiv_mark_for_processing0(div)
  local diva=div.attributes
  local cls = cnbx.is_cunumblo(div)
  local ClassDef = cnbx.classDefaults[cls]
  if(cls) then
    diva._process_me = "true"
    diva._fbxclass = str(cls)
    diva._prefix = ""
    diva._tag = ""
    diva._collapse = str(replaceifnil(diva.collapse, ClassDef.collapse)) 
    diva._boxstyle = str(replaceifnil(diva.boxstyle, ClassDef.boxstyle)) 
    diva._label = str(replaceifnil(diva.label, ClassDef.label)) 
    diva._reflabel = str(replaceifnil(diva.reflabel, ClassDef.reflabel)) 
  end  
  return(div)
end



local function Pandoc_prefix_count(doc)
  -- do evt later: non numeric chapternumbers
  local secno = 0
  local prefix = "" -- was "0" but this looks ugly. maybe give this as an option if need be, later
  local lprefix = ""
  print("Pandoc")
  if cnbx.prefix then prefix = cnbx.prefix 
     elseif cnbx.ishtmlbook then prefix = cnbx.chapno end
 
-- pout("this is a book?"..str(cnbx.ishtmlbook))

 --- make numbering and prep div blocks ---
--[[------- comment -----------
 quarto (1.2) books allow level 1 headings within a chapter. 
  This would give a mess for crossreference numbers: e.g. multiple examples 3.1,
  from chapter 1 (with 2 l1 headers ) and chapter 3.
 Therefore I decided to ignore level 1 headings in chapters.
 This can easily be changed, then the crossref is for the last occurence only.
 Maybe one day when there is more fine tuning concerning individual numbering depth.
 If this happens before quarto 1.4
   
--]]---------- end comment ------------  

--[[------comment----------
adjust prefixing to crossref.chapters in yaml.
This sets the level of numbering depth, either with h1 (level = 1)
or no prefix (level = 0).
In case of no prefix number I would still like to allow overriding.
--]]---------- end comment ------------  

  for i, blk in ipairs(doc.blocks) do
--    print(prefix.."-"..i.." "..blk.t.."\n")
     
     -- allow headers to redefine numberprefix. Maybe this should be restricted to level 1 headers? But comes in handy when numberlevel == 0
    if blk.t=="Header" 
    then 
      if blk.attr.attributes.numberprefix 
      then  prefix = str(blk.attr.attributes.numberprefix)
      else prefix = cnbx.prefix       
      end 
       
    -- reset counter if level is 1, and it is not a html book. Here only resetting by chapter = per document
      if not cnbx.ishtmlbook 
      then 
        creset = (cnbx.numberlevel == 1) and (blk.level == 1)
      -- if creset then print ("reset is because level = "..str(cnbx.numberlevel)) end
      --prefix = ""
        if (creset) 
        then -- increase prefix and renumber     
          if (not blk.classes:includes("unnumbered") ) 
          then 
           --    if blk.attr.attributes.secno then 
             --      prefix = str(blk.attr.attributes.secno)
             --   else 
            secno = secno + 1
            if blk.attr.attributes.numberprefix 
            then prefix = str(blk.attr.attributes.numberprefix)
            else prefix = str(secno)
            end
          end
         -- reset counters in fbx --
         -- this would be more complicated if there are different levels
         -- of numbering depth
         -- then: add a numdepth variable to fbx with a list of keys
          for k in pairs(cnbx.counter) do cnbx.counter[k]=0 end
        end
      end  
    end
      -- problem: only the outer divs are captured 
      -- this is good when cunumblos are nested, because numbering would be ambiguous.
      -- it prevents them though of being processed when in other divs.
      -- TODO: recurse on nested divs, wenn die nicht selbst known dimser sind
      -- see: https://stackoverflow.com/questions/72752648/pandoc-lua-how-to-walk-inside-a-div
    if blk.t=="Div" 
      then 
        local known = cnbx.is_cunumblo(blk)
        if  known then 
           if blk.attr.attributes.numberprefix 
              then lprefix = blk.attr.attributes.numberprefix
              else lprefix = prefix
           end  
           blk = fboxDiv_setAttributes(blk, known, lprefix)
        -- hier könnte das rekursive absuchen stattfinden
        -- evt alles in eine boolsche funktion verpacken
        -- oder zuerst alle divs finden und taggen
      end  
    end
  end  -- for
 
  dev.showtable(cnbx, "2. cnbx nach indexdiv")
 
  return(doc)
end

local function Meta_readxref(meta)
  local file = io.open(cnbx.xreffile,"r")
  print("Meta")
  if file then 
    local xrfjson = file:read "*a"
    file:close()
    --[[
    if xrfjson then meta.fbx.xref = quarto.json.decode(xrfjson)
    else meta.fbx.xref = {} end
   --   pout("eingelesen")
   -- pout(meta.fbx.xref)
  else meta.fbx.xref ={}
    --]]--
    if xrfjson then cnbx.xref = quarto.json.decode(xrfjson)
    else cnbx.xref = {} end
    --  pout("eingelesen")
    --pout(fbx.xref)
  else cnbx.xref ={}
  end  
 
  return(meta) 
end


return({
 --{Div = fboxDiv_mark_for_processing},
 -- {Div = countDiv},
 --{
 Div = fboxDiv_mark_for_processing,  
  Meta = Meta_readxref, 
  Pandoc = Pandoc_prefix_count  
 --}
})