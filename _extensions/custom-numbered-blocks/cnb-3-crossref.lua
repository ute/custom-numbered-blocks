--[[
  number cunumblos and create prefixes, and gather attributes
]]--

uti = require("cnb-utilities")
local ifelse = uti.ifelse
local warning = uti.warning

dev = require("devutils")

local numberingfilter={}


local zaehlweiter = true -- increase counters also when secno is given, but non numeric.

local numberdepth = 2
local maxlev = numberdepth
local hcounters = {}
local hcounterstring ={}

local baselevel = 0

local prefix = ""

local initcounters = function(chapno)
  for i=1, maxlev do hcounters[i] = 0 end
  for i=1, maxlev do hcounterstring[i] = "" end
  if cnbx.isbook then
  -- check if chapno is numeric
    print("the chapter number is "..chapno)
    baselevel = 1
    prefix = tostring(chapno)
    if tonumber(cnbx.chapno) then
      hcounters[1] = tonumber(chapno)
      hcounterstring[1]= tostring(chapno)
    else
      hcounters[1] = 0
      hcounterstring[1] = chapno
    end     
  end
end





-- local blkcount = 0

-- fake a chapter number to start with, for use with book chapters
-- counters[1] = 5
-- counterstring[1] = "5"


numberingfilter.traverse = "topdown"

--numberingfilter.Block = function(el)
local doCounting = function(el)  
  local lev
  local info
  local secno = {}
  local cls 
  local cntkey, cnts, ClassDef, reflabel
  local prefixstr =""
  local notnumbered
  --local bxty, BoxDef, newattribs, UseAttribs
  
  ---------- headers ---------
  if el.t == "Header" then
    lev = el.level -- + baselevel
    if lev > baselevel then
    secno = el.attributes.secno
    if not secno then secno = el.attributes.numberprefix end
    if lev <= math.min(numberdepth, maxlev) then 
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
  end end 

  --------- custom numbered blocks --------
  if el.t == "Div" then
    cls = cnbx.is_cunumblo(el)
    if cls then  
      -- do the counting --

      ClassDef = deepcopy(cnbx.classDefaults[cls])
      cntkey = ClassDef.cntname
      
      if cnbx.xref == nil then print("öwei") end
      info = cnbx.xref[el.identifier]

      info.file = cnbx.processedfile -- for book crossreferences
      
      info.cnbclass = cls

      notnumbered = uti.hasclass(el, "unnumbered") or not ClassDef.numbered
      if notnumbered then
        info.prefix = ""
        info.counter = ""
        info.refnumber = ""
      else
        -- blkcount = blkcount + 1
        cnts = cnbx.counter[cntkey] +1
        cnbx.counter[cntkey] = cnts
        info.prefix = prefix
        info.counter = cnts
        if prefix ~="" then prefixstr = prefix.."." else prefixstr = "" end
        info.refnumber = prefixstr..cnts 
        -- check if a tag is given 
        if el.attributes.tag ~= nil then 
          info.tag = el.attributes.tag
          if info.tag ~= "" then info.refnumber = info.tag end
        end
        
      end
      
      -- getting reflabel and label
      label = el.attributes.label
      if label == nil then
        label = ClassDef.label
      end
      info.label = label
      
      reflabel = el.attributes.reflabel
      if reflabel == nil then
        reflabel = info.label
      end
      info.reflabel = reflabel
      
      
    --  print("counted a cnbx "..info.reflabel.." "..info.refnumber)
  
      
    end
  end
  return(el)  
end


local function resolveref(data)
  return { 
    RawInline = function(el)
      local refid = el.text:match("\\ref{(.*)}")
      local brefid = el.text:match("\\longref{(.*)}")
      local foundid = ifelse(refid, refid, ifelse(brefid,brefid, nil))
      
      if foundid then
        if data[foundid] then
          
          local target = data[foundid]
          local linktext = target.refnumber 
          if brefid then linktext = target.reflabel.." "..target.refnumber end
          local href = '#'..foundid
            if cnbx.ishtmlbook then 
              href = data[foundid].file .. '.html' .. href 
            end  
           -- print("found "..foundid.." href "..href.." linktext ".. linktext)  
            return pandoc.Link(linktext, href)
        -- else
          -- leave untouched to allow for equation references
          -- warning("unknown reference "..foundid.. " <=============  inserted ?? instead")
         -- return pandoc.Inlines({pandoc.Strong(pandoc.Str("??")), pandoc.Str("->["..foundid.."]") }) --,"]<-",pandoc.Strong("??")})
        end  
      end
    end    
  }
end

local writexref = function(filename)
  --print("writing the xref "..filename)
  -- if cnbx.isbook then
  local strippedxref ={} -- this is necessary because quarto.json cannot handle pandoc Inlines   
  
  for k, v in pairs(cnbx.xref) do
    strippedxref[k] = {
         reflabel = v.reflabel, 
         refnumber = tostring(v.refnumber), 
         file = v.file, 
         md = v.mdtitle}
    strippedxref.pandoctitle = nil
  end

  dev.showtable(strippedxref, "I want to store this")
  
  local xrjson = quarto.json.encode(strippedxref)
  local file = io.open(filename,"w")
  
  if file ~= nil then 
    file:write(xrjson) 
    file:close()
 -- end
  --[[
  if cnbx.islastfile then 
  --  pout(cnbx.processedfile.." -- nu aufräum! aber zack ---") 
    for k, v in pairs(xref) do
      if not v.new then 
  --      print("killed reference "..k)
  --      pout(v)
        xref[k] = nil
      end   
    end
  --  pout("-------- überlebende")
  --  pout(xref)
  end  

  ]]-- not necessary, xref us bit ysed kater
  end
end


numberingfilter.Pandoc = function(doc)
--  readxref()
  --dev.showtable(cnbx.groupDefaults, "group defaults")
  --dev.showtable(cnbxref, "xref")
  initcounters(cnbx.chapno)
  doc:walk {Block = doCounting}
  -- doc:walk {RawInline = resolveref}
  --dev.showtable(cnbx.xref, "xref")
  if cnbx.isbook then writexref(cnbx.xreffile) end
  return doc:walk(resolveref(cnbx.xref))
end

return( numberingfilter )