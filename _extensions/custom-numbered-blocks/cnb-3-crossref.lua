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
    hcounterstring[1] = cnbx.chapno
  end     
end


local prefix = ""

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
  --local bxty, BoxDef, newattribs, UseAttribs
  
  ---------- headers ---------
  if el.t == "Header" then
    lev = el.level
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
  end  

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
      -- info.boxtype = attribs.boxtype
      -- TODO uncomment later
      -- attribs.boxtype = nil
      -- info.attribs = attribs

      info.cnbclass = cls
      if uti.hasclass(el, "unnumbered") then
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
      reflabel = el.attributes.reflabel
      if reflabel == nil then
        reflabel = ClassDef.reflabel
      end
      info.reflabel = reflabel
      
      label = el.attributes.label
      if label == nil then
        label = ClassDef.label
      end
      info.label = label
      
    --  print("counted a cnbx "..info.reflabel.." "..info.refnumber)
  --[[
    
      -- debugging
      local refset = el.attributes.reflabel
      if refset then 
        dev.showtable(ClassDef,"class definitions")
        dev.showtable(el.attributes, "original element attributes")
      end


      newattribs = deepcopy(el.attributes)
      -- TODO: remove comment later
      for k, _ in pairs(newattribs) do
        if string.sub(k, 1, 1) =="_" then newattribs[k] = nil end
      end
      --debugging
      if refset then 
        dev.showtable(newattribs, "cleaned element attributes")
      end
     
      -- if box type is different from ClassDef, make new box attributes by updating Boxtype attributes with class attributes
      -- otherwise add class attributes as attributes
      --attribs = uti.updateTable(ClassDef, newattribs)
      bxty = newattribs.boxtype -- will most often be nil
      if bxty then
        if ClassDef.boxtype ~= bxty then
           print("--- >  update by  box type")
           BoxDef = deepcopy(cnbx.boxtypes[bxty].defaultOptions)
           dev.showtable(BoxDef, "the boxtype defaults")
           UseAttribs = uti.filterTable(ClassDef, BoxDef)
           dev.showtable(UseAttribs, "kept in Attributes after filtering ")
        end
      else UseAttribs = ClassDef  
      end  
      
      -- UseAttribs = uti.updateTable(newattribs, UseAttribs)
      -- if refset then 
      --   dev.showtable(UseAttribs, "merged element attributes")
      -- end
     
      -- update with elementwise defined attributes

      -- attribs = uti.updateTable(newattribs, ClassDef)
      -- if refset then 
      --   dev.showtable(attribs, "merged element attributes")
      -- end
     

      --[[
      
     
      
      if refset then dev.showtable(newerattribs, "element attributes after update") end
      bxty = newerattribs.boxtype -- will most often be nil
      -- update with class defaults, and if there is a different boxtype, with boxtype defaults
      --newattribs = uti.updateTable(ClassDef, attribs)
      -- TODO later uncomment
      --attribs.cntname = nil 
      --attribs.group = mil
      -- if bxty then
      --   if ClassDef.boxtype ~= bxty then
      --     BoxDef = uti.updateTable(cnbx.boxtypes[bxty],{})
      --     if BoxDef then
      --       uti.updateTable(BoxDef, newattribs)
      --     else
      --       uti.warn("boxtype "..bxty.." specified but not registered")
      --     end    
      -- end end      
      -- -- print("use counter "..cntkey)
--]] 
      
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
        else
          warning("unknown reference "..foundid.. " <=============  inserted ?? instead")
          return pandoc.Inlines({pandoc.Strong(pandoc.Str("??")), pandoc.Str("->["..foundid.."]") }) --,"]<-",pandoc.Strong("??")})
        end  
      end
    end    
  }
end

local writexref = function(filename)
  --print("writing the xref "..filename)
  -- if cnbx.isbook then
  --local xref = cnbx.xref
  local strippedxref ={} -- this is necessary because quarto.json cannot handle pandoc Inlines   
  
  for k, v in pairs(cnbx.xref) do
    strippedxref[k] = {reflabel = v.reflabel, refnumber = v.refnumber, file = v.file, mdtitle = v.mdtitle}
    strippedxref.pandoctitle = nil
  end

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
  dev.showtable(cnbx.xref, "xref")
  doc:walk {Block = doCounting}
  -- doc:walk {RawInline = resolveref}
  dev.showtable(cnbx.xref, "xref")
  writexref(cnbx.xreffile)
  return doc:walk(resolveref(cnbx.xref))
end

return( numberingfilter )