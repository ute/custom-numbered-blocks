
-- count and number divs
local filter1 = {} -- make identifiers
local filter3 = {} -- make prefixes from blocks and put on all divs
local filter2 = {} -- extract render div titles
local filter5 = {} -- render div
local filter6 = {} -- manipuliere strings

local xref = {}

local iscunumblo = function(el)
  local result = false
  for _, cls in pairs(el.classes) do
    if cls == "blk" then 
      result = true
      break
    end  
  end  
  return result
end

local divcount = 0

--- filter 1: make identifier

filter1.traverse  = "topdown"

function filter1.Div(el)
  divcount = divcount+1
  local idd = el.identifier
  local hidd=""
  local cls = pandoc.utils.stringify(el.classes)
  if idd==nil then idd="" end     
  -- make identifier if not present --
  if idd == "" then 
    el1 = el.content[1]
    if el1.t=="Header" then 
      hidd = el1.identifier
    end
    if hidd == "" then 
      idd = "cnb-"..cls.."-"..divcount
    else idd = hidd
    end
    el.identifier = idd
  end
  return(el)
end


-- filter 2: extract titles

filter2.Div = function(el)
  local title = ""
  local pandoctitle = {}
  local info = {}
  if iscunumblo(el) then --cls == "blk" then
    el1 = el.content[1]
      if el1.t=="Header" then 
        pandoctitle = el1.content
        title = pandoc.utils.stringify(pandoctitle)  -- readable version without math
        -- do not remove this in the first run? or does it work anyway, because the cites are allready resolved, and refs get resolved later?
        table.remove(el.content, 1) -- maybe tag for later: title-from-header
      else title = " notitle"
      end
    info.mdtitle = title
    info.pandoctitle = pandoctitle
    xref[el.identifier] = info
  end  
  return el
end


-- filter3 numbering

local maxlev = 4
local counters = {}
for i=1, maxlev do counters[i] = 0 end


local numberdepth = 1
local prefix = ""
local blkcount = 0

filter3.traverse = "topdown"
filter3.Block = function(el)
  local lev
  local info
  if el.t == "Header" then
    lev = el.level
    if lev <= math.min(numberdepth, maxlev) then 
      --print("reset, prefix is "..prefix) 
      blkcount = 0
      counters[lev] = counters[lev]+1
      if lev < maxlev then for i = lev+1, maxlev, 1 do counters[i] = 0 end end
      prefix = pandoc.utils.stringify(counters[1])
      for i = 2, math.min(lev, numberdepth), 1 do prefix = prefix..".".. counters[i] end 
    end
  end  
  if el.t == "Div" then
    if iscunumblo(el) then
        info = xref[el.identifier]
        blkcount = blkcount + 1
        info.prefix = prefix
        info.number = blkcount
    end
  end
  return(el)  
end



filter5.Div = function(el)
  local info = xref[el.identifier]
  local numberstr =""
  if iscunumblo(el) then
    numberstr = info.number 
    if info.prefix ~="" then numberstr = info.prefix .."."..numberstr end
    numberstr = "Block "..numberstr 
    if info.mdtitle ~= "notitle" then table.insert(el.content, 1, info.pandoctitle) 
       numberstr = numberstr..": "
    end
    table.insert(el.content, 1, pandoc.Strong(numberstr))
    el.content = el.content..pandoc.Inlines(pandoc.Underline(pandoc.Str("end..........")))
  end  
  return(el)
end  

filter6.Str = function (elem)
    if elem.text == "{{Tag}}" then
      return pandoc.Emph {pandoc.Str "takker"}
    else
      return elem
    end
  end

return{
   filter1
 , filter2
 , filter3
 , filter5
 , filter6
}