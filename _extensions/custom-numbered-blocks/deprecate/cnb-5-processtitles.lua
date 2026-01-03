ute1 = require "cnb-utilities"

local str = pandoc.utils.stringify
local replaceifnil = ute1.replaceifnil
-- local str_sanimath = ute1.str_sanimath
local str_md = ute1.str_md

--[[
local ifelse = ute1.ifelse
local replaceifempty = ute1.replaceifempty
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline

--]]--


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
   
--   ClassDef = cnbx.classDefaults[ela._fbxclass]
 
   if titl == nil then  
      el1 = el.content[1]
      if el1.t=="Header" then 
        -- sanitize math inline. depends on format
        ela.title = str(el1.content)  -- readable version without math
        mdtitl = str_md(el1.content) --str_sanimath(el1.content, "md")
        --mdtitl = str_sanimath(el1.content, "md")
        -- if cnbx.fmt ~= "unsupported" 
        --  then 
        titl = str_sanimath(el1.content, cnbx.fmt)
        --  else titl = mdtitl
        --end 
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
  -- print("created mdtitle "..mdtitl)
   ela._title = titl    -- keep the title as attribute for pandoc
   ela._mdtitle = mdtitl    -- for list of
   -- replace empty identifier with autoid
   -- if el.identifier == "" then el.identifier = ela._autoid end
   -- pout("--> sanitarer titel: "..mdtitl)
  -- ela._tag = ""
  -- pout("resulting el:"); pout(el)
   return(el)
 end

   
  
local function Pandoc_finalizexref(doc)
  xref = cnbx.xref -- shortcut
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


return{
  Div = Divs_maketitle,
  Pandoc = Pandoc_finalizexref
}