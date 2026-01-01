--[[
  number cunumblos and create prefixes, and gather attributes
]]--

ute1 = require("cnb-utilities")
dev = require("devutils")

local numberingfilter={}


local zaehlweiter = true -- increase counters also when secno is given, but non numeric.

local numberdepth = 2
local maxlev = numberdepth
local hcounters = {}
for i=1, maxlev do hcounters[i] = 0 end
local hcounterstring ={}
for i=1, maxlev do hcounterstring[i] = "" end

if cnbx.isbook then
  -- check if chapno is numeric
  if tonumber(cnbx.chapno) then
     hcounters[1] = tonumber(cnbx.chapno)
     hcounterstring[1]= tostring(cnbx.chapno)
  else
    hcounters[1] = 0
    hcounterstring[1] = chapno
  end     
end


local prefix = ""

-- local blkcount = 0

-- fake a chapter number to start with, for use with book chapters
-- counters[1] = 5
-- counterstring[1] = "5"


numberingfilter.traverse = "topdown"
numberingfilter.Block = function(el)
  local lev
  local info
  local secno = {}
  local cls 
  local ClassDef, bxty, BoxDef
  local cntkey, cnts
  local attribs = {}

  if el.t == "Header" then
    lev = el.level
    secno = el.attributes.secno
    if lev <= math.min(numberdepth, maxlev) then 
      --print("reset, prefix is "..prefix) 
      -- reset all counters
     -- blkcount = 0
      for k, _ in pairs (cnbx.counter) do cnbx.counter[k] = 0 end  

      if secno then 
        if zaehlweiter then
          hcounters[lev] = hcounters[lev]+1     
        end
        hcounterstring[lev] = tostring(secno)
      -- elseif not hasclass(el, "unnumbered") then
      else
        hcounters[lev] = hcounters[lev]+1
        hcounterstring[lev] = tostring(hcounters[lev])
      end    
      if lev < maxlev then for i = lev+1, maxlev, 1 do hcounters[i] = 0 end end
      prefix = hcounterstring[1]
      for i = 2, math.min(lev, numberdepth), 1 do prefix = prefix..".".. hcounterstring[i] end 
    end
  end  

  if el.t == "Div" then
    cls = cnbx.is_cunumblo(el)
    if cls then  
      ClassDef = cnbx.classDefaults[cls]
      cntkey = ClassDef.cntname
      
      dev.showtable(ClassDef,"class definitions")
      attribs = el.attributes
      for k, v in pairs(attribs) do
        if string.sub(k, 1, 1) =="_" then attribs[k] = nil end
      end
     
      dev.showtable(attribs, "element attributes")
      bxty = attribs.boxtype -- will most often be nil
      -- update with class defaults, and if there is a different boxtype, with boxtype defaults
      attribs = ute1.updateTable(ClassDef, attribs)
      attribs.cntname = nil
      attribs.group = mil
      if bxty then
        if ClassDef.boxtype ~= bxty then
          BoxDef = cnbx.boxtypes[bxty]
          if BoxDef then
            ute1.updateTable(BoxDef, attribs)
          else
            ute1.warn("boxtype "..bxty.." specified but not registered")
          end    
      end end      
      -- print("use counter "..cntkey)
      info = cnbx.newxref[el.identifier]
      info.boxtype = attribs.boxtype
      attribs.boxtype = nil
      info.attribs = attribs

      info.cnbclass = cls
      if ute1.hasclass(el, "unnumbered") then
        info.prefix = ""
        info.counter = ""
        info.number = ""
      else
        -- blkcount = blkcount + 1
        cnts = cnbx.counter[cntkey] +1
        cnbx.counter[cntkey] = cnts
        info.prefix = prefix
        info.counter = cnts
        if prefix ~="" then info.number = prefix.."."..cnts else info.number = tostring(cnts) end
      end
    end
  end
  return(el)  
end

return( numberingfilter )