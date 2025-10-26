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
-- pre-pre-release
-- 
-- partial rewrite, complete later

-- nice rename function learned from shafayetShafee :-)
local str = pandoc.utils.stringify
local pout = quarto.log.output

-- important quasi global variables

local ishtml = quarto.doc.is_format("html")
local ispdf = quarto.doc.is_format("pdf")
local fmt=""
if ishtml then fmt="html" elseif ispdf then fmt = "pdf" end

-- TODO encapsulate stylez into a doc thing or so
-- maybe later allow various versions concurrently. 
-- this could probably be problematic because of option clashes in rendered header?
--    encapsulate options in a list 

--- TODO: better encapsulation (luxury :-P)

fbx = require "cnb-global"

local stylename="foldbox"

fbx.stylez = require("style/"..stylename)




ute1 = require "cnb-utilities"

local ifelse = ute1.ifelse
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local str_sanimath = ute1.str_sanimath



print(fbx.ute)

---- init step ---------------------------
--init = require ("cnb-init")
--print(fbx.ute)


----------------------- oldcode, mostly -------------------------------------


------- numbering and class attributes ------

local function fboxDiv_setAttributes(el, cls, prefix)
  local ela = el.attributes -- shortcut
  local ClassDef = fbx.classDefaults[cls]
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
    
  cnts = fbx.counter[cntkey] +1
  fbx.counter[cntkey] = cnts
 
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

  ela._file = fbx.processedfile -- necessary to reference between chapters. At least with  quarto 1.3
 -- pout("tag: "..tag)
 -- pout(ela)
  return(el)
end

-- initial attributes without prefix and counts to allow for inner boxes

local function fboxDiv_mark_for_processing(div)
  local diva=div.attributes
  local cls = fbx.is_cunumblo(div)
  local ClassDef = fbx.classDefaults[cls]
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
  if fbx.prefix then prefix = fbx.prefix 
     elseif fbx.ishtmlbook then prefix = fbx.chapno end
 
-- pout("this is a book?"..str(fbx.ishtmlbook))

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
      else prefix = fbx.prefix       
      end 
       
    -- reset counter if level is 1, and it is not a html book. Here only resetting by chapter = per document
      if not fbx.ishtmlbook 
      then 
        creset = (fbx.numberlevel == 1) and (blk.level == 1)
      -- if creset then print ("reset is because level = "..str(fbx.numberlevel)) end
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
          for k in pairs(fbx.counter) do fbx.counter[k]=0 end
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
        local known = fbx.is_cunumblo(blk)
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
  return(doc)
end

-- if no id, get from first included header, if possible
local function Divs_getid(el)
  -- local known = getKnownEnv(el.attr.classes)
   local ela = el.attributes
   local id = el.identifier
   
   if not ela._process_me then return(el) end
   -- pout("--- processing item with id ".. replaceifempty(id, "LEER"))
   
   if id == nil or id =="" then  
    -- try in next header
    el1 = el.content[1]
    if el1.t=="Header" then 
    --    pout("--- looking at header with id "..el1.identifier)
    --    pout("--- still processing item with id ".. replaceifempty(id, "LEER"))
     -- pout("replacing id")
      id = el1.identifier
      el.identifier = id
    end
  end 
  if id == nil or id =="" 
    then  
      -- pout("immer noch leer")
      if ela._autoid ~= nil then
      id = ela._autoid
      el.identifier = id
    end 
    --else pout("nix autoid in ");pout(ela._autoid)
  end
  -- pout("resulting el:"); pout(el.attr)
  return(el)
end




----------- title of divs ----------------
local function Divs_maketitle(el)
  -- local known = getKnownEnv(el.attr.classes)
   local ela = el.attributes
   local titl = ela.title
   local mdtitl = replaceifnil(ela.title, "")
   local ClassDef = {}
   -- local id = el.identifier
   
   if not ela._process_me then return(el) end
  -- pout("--- processing item with id ".. replaceifempty(el.identifier, "LEER"))
   
   ClassDef = fbx.classDefaults[ela._fbxclass]
 
   if titl == nil then  
      el1 = el.content[1]
      if el1.t=="Header" then 
        -- sanitize math inline. depends on format
        ela.title = str(el1.content)  -- readable version without math
        mdtitl = str_sanimath(el1.content, "md")
        if ishtml then titl = str_sanimath(el1.content, "html")
          elseif ispdf then titl = str_sanimath(el1.content, "pdf")
          else titl = mdtitl
        end 
    --    pout("--- looking at header with id "..el1.identifier)
    --    pout("--- still processing item with id ".. replaceifempty(id, "LEER"))
    --[[    
    if id =="" or id == nil then
            pout("replacing id")
            id = el1.identifier
            el.identifier = id
        end  
        ]]--
        table.remove(el.content, 1)
      else titl = ""
      end
   end
   ela._title = titl    -- keep the title as attribute for pandoc
   ela._mdtitle = mdtitl    -- for list of
   -- replace empty identifier with autoid
   -- if el.identifier == "" then el.identifier = ela._autoid end
   -- pout("--> sanitarer titel: "..mdtitl)
  -- ela._tag = ""
  -- pout("resulting el:"); pout(el)
   return(el)
 end
 
---------------- initialize xref ----------
-- xrefinit = require ("fbx3")

-- xref split into prepare and finalize to allow xref in titles (future)
local function Pandoc_preparexref(doc)
 -- local xref={}
  local id = ""
  local cnt = 0
  local bla={}
  local xinfo={}
  local file_autoid = {}
  local exists = false
  if fbx.xref == nil then fbx.xref ={} end
  xref = fbx.xref
  cnt = #xref  
  if cnt > 0 then
    for i, xinf in ipairs(xref) do
      file_autoid[xinf.file..xinf.autoid] = i
    end  
  -- pout(autoids)  
  end  
    for _, blk in ipairs(doc.blocks) do
      if blk.attributes then
        bla = blk.attributes
        if bla._process_me then 
          --pout("fbox "..blk.attributes._tag) 
          ------------- an fbox :) ------------
          if blk.identifier == nil then id = ""
            else id = blk.identifier end
          xinfo = {
            id       = id,
            autoid   = bla._autoid,
            cls      = bla._fbxclass,
            label    = bla._label,
            reflabel = bla._reflabel,
            reftag   = bla._tag,
            refnum   = replaceifempty(bla._tag, "??"), 
            file     = pandoc.path.split_extension(fbx.output_file)
          }
          -- if not xinfo.reftag then xinfo.reftag ="" end
          -- if xinfo.refnum == ""  then xinfo.refnum ="??" end
          --[[
          if bla._tag 
              then 
                if bla._tag ~="" then xinfo.refnum = bla._tag else xinfo.reftag="??" end
              end 
           ]]--   
          --- check if autoid already exist in database. otherwise update 
          oldxrefno = file_autoid[xinfo.file..xinfo.autoid]
          if oldxrefno == nil then         
            cnt = cnt+1
            bla._xrefno = cnt
            table.insert (xref, cnt, xinfo)
          else
            bla._xrefno = oldxrefno
            xref[oldxrefno] = xinfo
          end
        end 
      end   
    end
    return(doc)
  end  
  
  
local function Pandoc_finalizexref(doc)
  xref = fbx.xref -- shortcut
  local bla = {}
   -- pout("------- finale ----")
    for i, blk in ipairs(doc.blocks) do
      bla = blk.attributes
      --pout(bla)
      if bla then
        if bla._process_me == "true" then 
          ------------- an fbox :) ------------
          xindex = tonumber(bla._xrefno)
          if xindex then
            xref[xindex].neu = true -- mark as new entry
            if bla._title then xref[xindex].title = bla._title end
          end
         
        --  else pout("ochje.")
        end  
      end   
    end
 -- pout(xref)
  --- write to disc --
  --- check if this was the last file to process ---
  return(doc)
end  


local function Meta_writexref(meta)
  local xref = fbx.xref
  local xrjson = quarto.json.encode(fbx.xref)
  local file = io.open(fbx.xreffile,"w")
  if file ~= nil then 
    file:write(xrjson) 
    file:close()
  end
  if fbx.islastfile then 
  --  pout(fbx.processedfile.." -- nu aufräum! aber zack ---") 
    for i, v in ipairs(xref) do
      if not v.neu then 
  --      pout("killed")
  --      pout(v)
        xref[i] = nil
      end   
    end
  --  pout("-------- überlebende")
  --  pout(xref)
  end  
end

  
local function Meta_readxref(meta)
  local file = io.open(fbx.xreffile,"r")
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
    if xrfjson then fbx.xref = quarto.json.decode(xrfjson)
    else fbx.xref = {} end
    --  pout("eingelesen")
    --pout(fbx.xref)
  else fbx.xref ={}
  end  
  return(meta)
end
-------------- render -------------------
-- render = require ("fbx4")

local tt_from_attributes_id = function(A, id)
  --local tyti =""
  --local tt = {}
  --if A._tag == "" then tyti = A._label 
  --else tyti = A._label..' '..A._tag end 
--    print("TYTI: === "..tyti)
local thelink = "#"..id
      if fbx.ishtmlbook and A._file~=nil then thelink = A._file..".qmd"..thelink end
return {id = id,
      type = A._fbxclass, 
      tag = A._tag,
      title = A._title, 
      typlabel = A._label,
      typlabelTag = A._label .. ifelse(A._tag == "",""," "..A._tag),
      mdtitle = A._mdtitle, 
      collapse = A._collapse,
      boxstyle = A._boxstyle,
      link = thelink
}
  -- pout("====nun====");pout(tt)
  --return(tt)
end

insertStylesPandoc = function(doc)
  -- TODO: change for a list of styles
  -- if stylez.extractStyleFromYaml then stylez.extractStyleFromYaml() end
  if fbx.stylez.insertPreamble and (quarto.doc.is_format("html") or quarto.doc.is_format("pdf"))
    then fbx.stylez.insertPreamble(doc, fbx.classDefaults, fmt) end
  return(doc)
end;

renderDiv = function(thediv) 
  -- TODO: change for individual style   
  local A = thediv.attributes
  local tt = {}
  if A._fbxclass ~= nil then
    
    collapsstr = str(A._collapse)
    tt = tt_from_attributes_id(A, thediv.identifier)
    
    local fmt='html'
    if quarto.doc.is_format("pdf") then fmt = "tex" end;
    if #thediv.content > 0 and thediv.content[1].t == "Para" and 
      thediv.content[#thediv.content].t == "Para" then
        table.insert(thediv.content[1].content, 1, 
          pandoc.RawInline(fmt, fbx.stylez.blockStart(tt, fmt)))
        table.insert(thediv.content,
          pandoc.RawInline(fmt, fbx.stylez.blockEnd(tt, fmt)))
      else
        table.insert(thediv.content, 1, 
          pandoc.RawBlock(fmt, fbx.stylez.blockStart(tt, fmt)))
        table.insert(thediv.content,  
          pandoc.RawBlock(fmt, fbx.stylez.blockEnd(tt, fmt)))
    end  
    --]]
  end  
  return(thediv)
end -- function renderDiv


------------- xrefs
-- learned from nameref extension by shafayeedShafee
-- TODO: make everything with walk. Looks so nice
local function resolveref(data)
  return { 
    RawInline = function(el)
      local refid = el.text:match("\\ref{(.*)}")
      local brefid = el.text:match("\\longref{(.*)}")
      local foundid = ifelse(refid, refid, ifelse(brefid,brefid, nil))
      
      if foundid then
        if data[foundid] then
          local target = data[foundid]
          local linktext = target.refnum
          if brefid then linktext = target.reflabel.." "..target.refnum end
          local href = '#'..foundid
            if fbx.ishtmlbook then 
              href = data[foundid].file .. '.html' .. href 
            end  
            return pandoc.Link(linktext, href)
        else
          quarto.log.warning("unknown reference ",foundid, " <=============  inserted ?? instead")
          return({pandoc.Strong("??"),"->[",foundid,"]"}) --,"]<-",pandoc.Strong("??")})
        end  
      end
    end    
  }
end

-- TODO: with filenames for books

function Pandoc_resolvexref(doc)
  local xrefdata = {}
  local xref = fbx.xref
  for _, xinf in pairs(xref) do
    if xinf.id then if xinf.id ~= "" then
      xrefdata[xinf.id] = xinf
  end  end
end
-- pout(xrefdata)
  return doc:walk(resolveref(xrefdata))
end  
-----------

--- remove all attributes that start with underscore. 
-- could theoretically give clashes with filters that need persistent such attributes
function Div_cleanupAttribs (el)
  if el.attributes._process_me then
    for k, v in pairs(el.attributes) do
      if string.sub(k, 1, 1) =="_" then el.attributes[k] = nil end
    end
  end
  return el
end

-- debugging stuff
--[[

local function pandocblocks(doc)
  for k,v in pairs(doc.blocks) do
    pout(v.t)
  end
end

local function pandocdivs(div)
  pout(div.t.." - "..div.identifier)
  pout(div.attributes)
end
]]--

local function Pandoc_makeListof(doc)
  local tt = {}
  local thelists = {}
  local zeile = ""
  local lstfilemode = ifelse(fbx.isfirstfile, "w", "a")
  if not fbx.lists then return(doc) end
  for i, blk in ipairs(doc.blocks) do
    --[[ -- this may require manual deletion of headers in the list-of.qmd
    -- and does in this form not help with html books anyway --
    if blk.t=="Header" then 
      if blk.level==1 then 
        zeile = "\n\n## "..str(blk.content).."\n"
      --- add to all lists
        for _, lst in pairs (fbx.lists) do
          lst.contents = lst.contents..zeile
        end
      end
      elseif blk.t=="Div" then 
     ]]-- 
     if blk.t=="Div" then 
      if blk.attributes._process_me then
        thelists = fbx.classDefaults[blk.attributes._fbxclass].listin
        if thelists ~= nil and thelists ~="" then
          tt = tt_from_attributes_id (blk.attributes, blk.identifier)
          -- pout("thett------");pout(tt)
        --  zeile = ("\n[**"..tt.typtitel.."**](#"..blk.identifier..")"..ifelse(tt.mdtitle=="","",": "..tt.mdtitle)..
        --      " \\Pageref{"..blk.identifier.."}\n")
        -- TODO: should be like [**R-tip 1.1**](intro.qmd#Rtip-install)
          --zeile = ("\n[**"..tt.titeltyp.." \\ref{"..blk.identifier.."}**]" ..
            --       ifelse(tt.mdtitle=="","",": "..tt.mdtitle) ..
              --     " \\Pageref{"..blk.identifier.."}\n") 
            zeile = ("\n [**"..tt.typlabelTag.."**](" .. tt.link ..")" ..
                     ifelse(tt.mdtitle=="","",": "..tt.mdtitle) .. "\\Pageref{".. tt.id .."}\n")                               
          for _, lst in ipairs (thelists) do
            fbx.lists[lst].contents = fbx.lists[lst].contents..zeile
          end 
        end
      end 
    end
  end
  --- write to file ---
  for nam, lst in pairs(fbx.lists) do
    if lst.file ~= nil then 
      local file = io.open(lst.file, lstfilemode)
      if file then 
        file:write(lst.contents) 
        file:close()
      else pout("cannot write to file "..lst.file)  
      end  
    end  
  end
  return(doc)
end

return{
    require("cnb-init") -- Meta: set up chapter numbers and classes
    
    --[[
    ,{Pandoc = function(d)
      for k, v in pairs(fbx.stylez) do
        pout(k..":  ".. type(v))
      end 
      for k, v in pairs(fbx) do
        pout(k..":  ".. type(v))
      end 
      
    end 
    }
    --]]--
  , {Meta = Meta_readxref, Div=fboxDiv_mark_for_processing,
     Pandoc = Pandoc_prefix_count} 
 -- , {Div=pandocdivs, Pandoc=pandocblocks}
  --[[ ]]
   
  , {Div = Divs_getid, Pandoc = Pandoc_preparexref}
  , {Pandoc = Pandoc_resolvexref}
  , {Div = Divs_maketitle}
  , {Pandoc = Pandoc_finalizexref}
  , {Meta = Meta_writexref, Pandoc = Pandoc_makeListof}
  , {Div = renderDiv}
  , {Pandoc = insertStylesPandoc}
  , {Div = Div_cleanupAttribs}
--[[
  
  -- ]]
}

