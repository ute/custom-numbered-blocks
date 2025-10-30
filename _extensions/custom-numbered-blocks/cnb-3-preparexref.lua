 

ute1 = require "cnb-utilities"

-- local str = pandoc.utils.stringify
--local ifelse = ute1.ifelse
--local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
--[[]
local str_md = ute1.str_md
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
-- ]]--

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
  if cnbx.xref == nil then cnbx.xref ={} end
  xref = cnbx.xref
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
            file     = pandoc.path.split_extension(cnbx.output_file)
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


return {
    Div = Divs_getid, 
    Pandoc = Pandoc_preparexref
}