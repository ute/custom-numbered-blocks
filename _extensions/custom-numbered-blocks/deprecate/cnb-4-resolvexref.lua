ute1 = require "cnb-utilities"

--local str = pandoc.utils.stringify
local ifelse = ute1.ifelse
--[[ 
local replaceifnil = ute1.replaceifnil
local replaceifempty = ute1.replaceifempty
local str_md = ute1.str_md
local str_sanimath = ute1.str_sanimath
local tablecontains = ute1.tablecontains
local updateTable = ute1.updateTable
local deInline = ute1.deInline
]]--
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
          print("found "..foundid)
          local target = data[foundid]
          local linktext = target.refnumber 
          if brefid then linktext = target.reflabel.." "..target.refnumber end
          local href = '#'..foundid
            if cnbx.ishtmlbook then 
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

-- Done: with filenames for books


return{
   Pandoc = function(doc)
    return doc:walk(resolveref(cnbx.newxref))
   end 
}