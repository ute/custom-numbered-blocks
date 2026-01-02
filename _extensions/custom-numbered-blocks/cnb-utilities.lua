--[[
MIT License

Copyright (c) 2023 Ute Hahn

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

-- utility functions ---
--[[]]

local str = pandoc.utils.stringify

-- files 
local function FileExists(fname)
  local file = io.open(quarto.utils.resolve_path(fname),"r")
  if file ~= nil then
    io.close(file)
    return(true)
  end
  return(false)
end

local function findFile(fname, directories)
  local result = ""
  if directories == nil then
    directories = {""}
  end  
  for _, dir in pairs(directories) do
    result = dir..fname
   -- print("try "..result)
    local file = io.open(quarto.utils.resolve_path(result),"r")
    if file ~= nil then
      io.close(file)
      return {found = true, dir = str(dir), path = result}
    end
  end
  return {found = false}
end

-- if then else

local function ifelse(condition, iftrue, iffalse)
  if condition then return iftrue else return iffalse end
end  

local function replaceifnil(existvalue, replacevalue)
  if existvalue ~= nil then return existvalue else return replacevalue end
end  

local function replaceifempty(existvalue, replacevalue)
  if existvalue == nil or existvalue=="" then return replacevalue else return existvalue end
end  

-- tables

local function DeInline(tbl)  
    local result ={}
    for i, v in pairs(tbl) do
        pdtype = pandoc.utils.type(v)   
        if pdtype == "Inlines" or pdtype =="boolean"
        then 
            result[i] = pandoc.utils.stringify(v)
        elseif pdtype == "List" then result[i] = DeInline(v)
        end
    end  
    return(result)
end

local function tablecontains(tbl, val)
  if tbl ~= nil and val ~= nil then
    for _, v in ipairs(tbl) do
      if val == v then return true end
    end
  end
  return false
end  


-- make a deep copy of table and update oldtable
local function updateTable (oldtbl, newtbl, ignorekeys)
  local result = {}
  -- copy old attributes
  --for k, v in pairs(oldtbl) do result[k] = v end
  result = deepcopy(oldtbl)
  if newtbl ~= nil then if type(newtbl) == "table" then
      if newtbl[1] == nil then -- it is an ok table with key value pairs
        for k, v in pairs(newtbl) do
          if not(tablecontains(ignorekeys, k)) then
             result[k] = deepcopy(v)
         end
        end
      -- special: set reflabel to label if not given in attribs
--        if newattribs["reflabel"] == nil then result.reflabel = result.label end 
      -- TODO: do this elsewhere
      end  
    end
  end  
  return(result)
end

-- deep copy, from http://lua-users.org/wiki/CopyTable
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- remove all entries that have no counterpart in newdefaults
local function filterTable (currentdefaults, requireddefaults)
  result = deepcopy(currentdefaults)
  if type(result) == "table" then
    if type(requireddefaults) == "table" then
      for k, _ in pairs(result) do
        if requireddefaults[k] == nil then
          result[k] = nil
        end
      end  
    end
  end   
  return(result)
end  

-- strings, fx make prefix

function stringtable_to_vector(tbl, sep)
  if sep == nil then sep = "" end
  local out = ""
  local outv = ""
  for _, v in pairs(tbl) do
    if out ~= "" then out = out .. sep end
    if pandoc.utils.type(v) == "List" then 
       outv = stringtable_to_vector(v)
    else outv = str(v)
    end
    out = out..outv
  end
  return(out)
end


function keyval_to_vector(tbl)
   local out = ""
   local outv = ""
   local sep = " "
   for k, v in pairs(tbl) do
      out = out .. sep
--     if out ~= "" then out = out .. sep end
     if pandoc.utils.type(v) == "List" then 
        outv = keyval_to_vector(v) -- not sure if this makes sense
     else 
       outv = str(k)..'="'..str(v)..'"'
     end
     out = out..outv
   end
   return(out)
end


-- make markdown, in particular for lists-of

function str_md(theInline)
  local newstring = theInline:walk{
    Math = function(ma)
        if ma.mathtype =="DisplayMath"  
          then return  {'\n$$\n' .. str(ma.text) .. '\n$$'}
          else return  {'$' .. str(ma.text) .. '$'}
          end  
      end,
    Emph = function(em)
        return { '*' .. str(em.content) ..'*' }
      end,
    Strong = function(ong)    
        return { '**' .. str(ong.content) ..'**' }
      end,
    Span = function(spn)
        local spnid = str(spn.identifier)
        local cls=str(stringtable_to_vector(spn.classes, " "))
        local kva= str(keyval_to_vector(spn.attributes))
        if spnid ~= "" then spnid = "#"..spnid.." " end
        if cls ~= "" then cls = 'class="'.. cls..'"' end
        -- print(str(cls))
        return { "[".. str(spn.content) .."]{"..spnid..cls..kva.."}" }
      end,
    RawInline = function(rin)
      return {str(rin.text)}
    end   
  }
  return str(newstring)
end  


--- utility function: stringify and sanitize math, depends on format ---
function str_sanimath(theInline, fmt)
  local newstring = theInline:walk{
    Math = function(ma)
      local mathtxt = str(ma.text)
      if fmt == "html" then 
        return {'<span class="math inline">\\(' .. mathtxt .. '\\)</span>'}
      elseif fmt == "pdf" then 
        return {'\\(' .. mathtxt .. '\\)'}
      elseif fmt == "md" then 
        return  {'$' .. mathtxt .. '$'}
      else return {mathtxt}
      end  
  end  
  }
  return str(newstring)
end  


-- cunumblo pre render

local tt_from_attributes_id = function(A, id)
  --local tyti =""
  --local tt = {}
  --if A._tag == "" then tyti = A._label 
  --else tyti = A._label..' '..A._tag end 
--    print("TYTI: === "..tyti)
local thelink = "#"..id
      if cnbx.ishtmlbook and A._file~=nil then thelink = A._file..".qmd"..thelink end
return {id = id,
      type = A._fbxclass, 
      tag = A._tag,
      title = A._title, 
      typlabel = A._label,
      typlabelTag = A._label .. ifelse(A._tag == "",""," "..A._tag),
      mdtitle = A._mdtitle, 
      collapse = A._collapse,
      boxstyle = A._boxstyle,
      -- boxtype = "default", -- TODO here
      link = thelink
}
  -- pout("====nun====");pout(tt)
  --return(tt)
end


local warn = function(whatswrong)
   quarto.log.warning ("=== [custom-numbered-blocks] === "..whatswrong.."\n") --"..\n===============")
end  

-- pandoc classes

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


--[[-- make all this global later?
---]]
return{
    tablecontains = tablecontains,
    ifelse = ifelse,
    replaceifnil= replaceifnil,
    replaceifempty = replaceifempty,
    updateTable = updateTable,
    filterTable = filterTable,
  --  deepcopy = deepcopy,
    deInline = DeInline,
    str_md = str_md,
    str_sanimath = str_sanimath,
    tt_from_attributes_id = tt_from_attributes_id,
    warn = warn,
    FileExists = FileExists,
    findFile = findFile,
    hasclass = hasclass
}
--]]------
---
