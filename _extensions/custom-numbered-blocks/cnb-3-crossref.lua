--[[
MIT License

Copyright (c) 2023-2026 Ute Hahn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--
--[[
  number cunumblos and create prefixes, and gather attributes
]]--

uti = require("cnb-utilities")
local ifelse = uti.ifelse

dev = require("devutils")

local numberingfilter={}


local zaehlweiter = true -- increase counters also when secno is given, but non numeric.

--local numberdepth = cnbx.numberlevel
local maxlev, numberdepth
local hcounters = {}
local hcounterstring ={}

local baselevel = 0

local prefix = ""

local initcounters = function(chapno)
  maxlev = cnbx.numberlevel
  numberdepth = maxlev
-- print("maxlev is "..tostring(maxlev).. " cnbx.numberlevel is"..cnbx.numberlevel)
  if maxlev > 0 then
  for i=1, maxlev do hcounters[i] = 0 end
  for i=1, maxlev do hcounterstring[i] = "" end
  if cnbx.isbook then
  -- check if chapno is numeric
  --  print("the chapter number is "..chapno)
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
end end

-- local blkcount = 0

-- fake a chapter number to start with, for use with book chapters
-- counters[1] = 5
-- counterstring[1] = "5"


--- add label and reflabel to info
--- @param el userdata (pandoc object: div)
--- @param cls string  class
--- @param info table to attach reflabel and label to
--- @return table info updated table
local makelabels = function(el, cls, info)
  local label, reflabel
  label = el.attributes.label
  if label == nil then
    label = cnbx.classDefaults[cls].label
  end
  info.label = label

  reflabel = el.attributes.reflabel
  if reflabel == nil then
    reflabel = info.label
  end
  info.reflabel = reflabel 
  return(info)      
end

--- make info entries prefix, refnum, counter, tag
--- @param el pandoc object (div)
--- @param cnt integer counter
--- @param prefix string to put in front of counter
--- @param info table to populate with prefix, counter, refnumber, tag
--- @return info updated table
local makerefnum = function(el, cnt, theprefix, info, alpha)
  local prefixstr = ""
  local cntstring = ""
  if alpha 
    then cntstring = string.char(cnt + 96)
    else cntstring = tostring(cnt)
  end
  info.prefix = theprefix
  info.counter = cnt
  if theprefix ~="" then prefixstr = theprefix.."." else prefixstr = "" end
  info.refnumber = prefixstr..cntstring
  if el.attributes.tag ~= nil then 
     info.tag = el.attributes.tag
     if info.tag ~= "" then info.refnumber = info.tag end
  end
  return(info)      
end



--numberingfilter.Block = function(el)
local doCounting = function(el)  
  local lev
  local info
  local secno = {}
  local cls 
  local cntkey, cnts, ClassDef
  local notnumbered
  local headid
  local parentid
  --local bxty, BoxDef, newattribs, UseAttribs
  
  ---------- headers ---------
  if el.t == "Header" then
    headid = el.identifier
    if headid ~=  "___doomed-for-removal" then
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
    end end
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
      
      parentid = el.attributes["_nested"]
     -- if parentid then print("parent is "..parentid) end

      notnumbered = uti.hasclass(el, "unnumbered") or not ClassDef.numbered or parentid ~= nil
      if notnumbered then
        info.prefix = ""
        info.counter = ""
        info.refnumber = ""
      else
        -- blkcount = blkcount + 1
        cnts = cnbx.counter[cntkey] +1
        cnbx.counter[cntkey] = cnts
        info = makerefnum (el, cnts, prefix, info)       
      end
      
      info = makelabels(el, cls, info)
           
    end
  end
  return(el)  
end


local childfilter = {
  traverse="topdown",
  Div = function (el)
    local parentid, childid, info, cls--, alphanum
    -- alphanum = cnbx.yaml.nestednumber
    -- if alphanum == nil then alphanum = false
    -- elseif type(alphanum) == "table" then 
    --   alphanum = (pandoc.utils.stringify(alphanum) == "alpha")
    -- end
       
    cls = cnbx.is_cunumblo(el)
    if cls then
      info = cnbx.xref[el.identifier]
      parentid = el.attributes["_nested"]
      if parentid then -- print("parent is "..parentid) 
        childid = el.attributes["_childid"]
        if childid then -- print("childid = "..childid) 
          info = makerefnum (el, tonumber(childid), cnbx.xref[parentid].refnumber, info, 
          cnbx.alphanum)
        end  
      end      -- getting reflabel and label
      info = makelabels(el, cls, info)
    end
    return(el)
  end  
}


local function resolvelatexref(data)
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

  -- dev.showtable(strippedxref, "I want to store this")
  
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


numberingfilter.traverse = "topdown"

numberingfilter.Pandoc = function(doc)
--  readxref()
  --dev.showtable(cnbx.groupDefaults, "group defaults")
  --dev.showtable(cnbxref, "xref")
  initcounters(cnbx.chapno)
  doc:walk {Block = doCounting}
  doc = doc:walk(childfilter)
  -- doc:walk {RawInline = resolveref}
  --dev.showtable(cnbx.xref, "xref")
  if cnbx.isbook then writexref(cnbx.xreffile) end
  return doc:walk(resolvelatexref(cnbx.xref))
end

return( numberingfilter )