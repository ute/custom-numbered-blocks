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
      else warning("cannot write to file "..lst.file)  
      end  
    end  
  end

  return(doc)
end


return{
  Div = filterdiv.Div,
  Pandoc = Pandoc_makeListof
}