ute1 = require "cnb-utilities"

local ifelse = ute1.ifelse
local tt_from_attributes_id = ute1.tt_from_attributes_id

--[[
local str = pandoc.utils.stringify
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local str_sanimath = ute1.str_sanimath
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
--]]--




local function Pandoc_makeListof(doc)
  local tt = {}
  local thelists = {}
  local zeile = ""
  local lstfilemode = ifelse(cnbx.isfirstfile, "w", "a")
  if not cnbx.lists then return(doc) end
  for i, blk in ipairs(doc.blocks) do
    --[[ -- this may require manual deletion of headers in the list-of.qmd
    -- and does in this form not help with html books anyway --
    if blk.t=="Header" then 
      if blk.level==1 then 
        zeile = "\n\n## "..str(blk.content).."\n"
      --- add to all lists
        for _, lst in pairs (cnbx.lists) do
          lst.contents = lst.contents..zeile
        end
      end
      elseif blk.t=="Div" then 
     ]]-- 
     if blk.t=="Div" then 
      if blk.attributes._process_me then
        thelists = cnbx.classDefaults[blk.attributes._fbxclass].listin
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
            cnbx.lists[lst].contents = cnbx.lists[lst].contents..zeile
          end 
        end
      end 
    end
  end
  --- write to file ---
  for nam, lst in pairs(cnbx.lists) do
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
  Pandoc = Pandoc_makeListof 
}