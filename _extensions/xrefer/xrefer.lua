
-- count and number divs
local filter0 = {}
local filter1 = {} -- make identifiers
local filter3 = {} -- make prefixes from blocks and put on all divs
local filter2 = {} -- extract render div titles
local filter5 = {} -- render div
local filter6 = {} -- manipuliere strings
local filter12 ={} -- identifiers and remove renderdivs

local xref = {}

local hasclass = function(el, class)
  local result = false
  for _, cls in pairs(el.classes) do
    if cls == class then 
      result = true
      break
    end  
  end  
  return result
end


local iscunumblo = function(el)
   return hasclass(el, "blk")
end

local divcount = 0

filter0.Header = function(el)
  local secno = el.attributes.secno
  if secno then
    print("Header has attribute secno "..secno)
  end
end  

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


filter12.traverse = "topdown"
function filter12.Div(el)
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

local zaehlweiter = true -- increase counters also when secno is given, but non numeric.

local numberdepth = 2
local maxlev = numberdepth
local counters = {}
for i=1, maxlev do counters[i] = 0 end
local counterstring ={}
for i=1, maxlev do counterstring[i] = "" end

local prefix = ""
local blkcount = 0

-- fake a chapter number to start with, for use with book chapters
-- counters[1] = 5
-- counterstring[1] = "5"

filter3.traverse = "topdown"
filter3.Block = function(el)
  local lev
  local info
  local secno = {}

  if el.t == "Header" then
    lev = el.level
    secno = el.attributes.secno
    if lev <= math.min(numberdepth, maxlev) then 
      --print("reset, prefix is "..prefix) 
      blkcount = 0

      if secno then 
        if zaehlweiter then
          counters[lev] = counters[lev]+1     
        end
        counterstring[lev] = tostring(secno)
      -- elseif not hasclass(el, "unnumbered") then
      else
        counters[lev] = counters[lev]+1
        counterstring[lev] = tostring(counters[lev])
      end    
      if lev < maxlev then for i = lev+1, maxlev, 1 do counters[i] = 0 end end
      prefix = counterstring[1]
      for i = 2, math.min(lev, numberdepth), 1 do prefix = prefix..".".. counterstring[i] end 
    end
  end  
  if el.t == "Div" then
    if iscunumblo(el) then
        info = xref[el.identifier]
        if hasclass(el, "unnumbered") then
          info.prefix = ""
          info.counter = ""
          info.number = ""
        else
          blkcount = blkcount + 1
          info.prefix = prefix
          info.counter = blkcount
          if prefix ~="" then info.number = prefix.."."..blkcount else info.number = tostring(blkcount) end
        end
    end
  end
  return(el)  
end


filter5.Div = function(el)
  local info = xref[el.identifier]
  local numberstr =""
  if iscunumblo(el) then
    numberstr = "Block "..info.number 
    if info.mdtitle ~= "notitle" then table.insert(el.content, 1, info.pandoctitle) 
       numberstr = numberstr..": "
    end
    table.insert(el.content, 1, pandoc.Strong(numberstr))
    el.content = el.content..pandoc.Inlines(pandoc.Underline(pandoc.Str("end..........")))
  end  
  return(el)
end  

filter6.Str = function (elem)
  local sayit = ""
  local thinfo = xref['vorletztesdiv']
  if elem.text == "{{Tag}}" then
    if thinfo then sayit= "yes "..thinfo.number else sayit = "no" end
    print(sayit)
    return pandoc.Emph {pandoc.Str ("takker til "..sayit)}
  else
    return elem
  end
  end

return{
  filter0,
 --  filter1
 --, filter2
   filter12
 , filter3
 , filter5
 , filter6
}