--[[
  number cunumblos and create prefixes, and gather attributes
]]--

ute1 = require("cnb-utilities")
local ifelse = ute1.ifelse
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
  local bxty, BoxDef, newattribs, UseAttribs
  
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
    
      info = cnbx.newxref[el.identifier]

      info.file = cnbx.processedfile -- for book crossreferences

      -- info.boxtype = attribs.boxtype
      -- TODO uncomment later
      -- attribs.boxtype = nil
      -- info.attribs = attribs

      info.cnbclass = cls
      if ute1.hasclass(el, "unnumbered") then
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
      
      -- getting reflabel
      reflabel = el.attributes.reflabel
      if reflabel == nil then
        reflabel = ClassDef.reflabel
      end
      info.reflabel = reflabel
      
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
      --attribs = ute1.updateTable(ClassDef, newattribs)
      bxty = newattribs.boxtype -- will most often be nil
      if bxty then
        if ClassDef.boxtype ~= bxty then
           print("--- >  update by  box type")
           BoxDef = deepcopy(cnbx.boxtypes[bxty].defaultOptions)
           dev.showtable(BoxDef, "the boxtype defaults")
           UseAttribs = ute1.filterTable(ClassDef, BoxDef)
           dev.showtable(UseAttribs, "kept in Attributes after filtering ")
        end
      else UseAttribs = ClassDef  
      end  
      
      -- UseAttribs = ute1.updateTable(newattribs, UseAttribs)
      -- if refset then 
      --   dev.showtable(UseAttribs, "merged element attributes")
      -- end
     
      -- update with elementwise defined attributes

      -- attribs = ute1.updateTable(newattribs, ClassDef)
      -- if refset then 
      --   dev.showtable(attribs, "merged element attributes")
      -- end
     

      --[[
      
     
      
      if refset then dev.showtable(newerattribs, "element attributes after update") end
      bxty = newerattribs.boxtype -- will most often be nil
      -- update with class defaults, and if there is a different boxtype, with boxtype defaults
      --newattribs = ute1.updateTable(ClassDef, attribs)
      -- TODO later uncomment
      --attribs.cntname = nil 
      --attribs.group = mil
      -- if bxty then
      --   if ClassDef.boxtype ~= bxty then
      --     BoxDef = ute1.updateTable(cnbx.boxtypes[bxty],{})
      --     if BoxDef then
      --       ute1.updateTable(BoxDef, newattribs)
      --     else
      --       ute1.warn("boxtype "..bxty.." specified but not registered")
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
          quarto.log.warning("unknown reference ",foundid, " <=============  inserted ?? instead")
          return({pandoc.Strong("??"),"->[",foundid,"]"}) --,"]<-",pandoc.Strong("??")})
        end  
      end
    end    
  }
end

local readxref = function()
  print("reading the xref")
end  
-- numberingfilter.Meta = function(meta)
local writexref = function()
  print("writing the xref")
  if cnbx.isbook then
  --local xref = cnbx.newxref
  local xrjson = quarto.json.encode(cnbx.newxref)
  local file = io.open(cnbx.xreffile,"w")
  if file ~= nil then 
    file:write(xrjson) 
    file:close()
  end
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
  readxref()
  doc:walk {Block = doCounting}
  writexref()
  -- doc:walk {RawInline = resolveref}
  return doc:walk(resolveref(cnbx.newxref))
  
end

return( numberingfilter )