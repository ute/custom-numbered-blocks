-- this module is for managing colors.
-- it is still in legacy mode.
-- sizes have been added

--- extract colors from Class options, and generate css or tex code
--- 
--- make color information. TODO: this as util, and change the color mechanism

--- for legacy mode: remove leading # from colors 
--- 
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

--- 

local dev=require("devutils")


local legacycolor = function(cols)
  result={}
  for col, colst in pairs(cols) do
    colst = tostring(colst)
    if string.sub(colst, 1, 1) =="#" then
      result[col] = string.sub(colst, 2)
    else result[col] = colst  
    end
  end
  return(result)
end

local colorsizeCSSTeX_legacy = function (fmt, classDefs)
  local result, thecolors, thesizes
  local StyleCSSTeX = {}
  if classDefs ~= nil then
    for cls, options in pairs(classDefs) do
        --quarto.log.output(cls)
       thecolors = options.colors
        --dev.showtable(options,"the classDefs options")
       -- print("los gehts"..pandoc.utils.stringify(options.colors))
        
       -- if only one color is given, store it as colors array. 
       -- todo: call a function that turns color into colors array
       if options.color~=nil then 
         if  thecolors == nil then thecolors = {options.color} end 
       end
       -- make sure both types of color strings are understood, with and without hash 
       if thecolors then  thecolors = legacycolor(thecolors) end
        
       -- handle sizes
       thesizes = options.sizes
       
       if thecolors or thesizes then
         -- make css classes or tex definitions
        if fmt == "html" then
          table.insert(StyleCSSTeX, "."..cls.." {\n")
          if thecolors then
            for key, col in ipairs(thecolors) do
               table.insert(StyleCSSTeX, "  --color"..key..": #"..col..";\n") 
            end 
          end
          if thesizes then
            for k, v in pairs(thesizes) do
               table.insert(StyleCSSTeX, "  --"..k..": "..v..";\n") 
            end 
          end
          table.insert(StyleCSSTeX, "}\n")
        elseif fmt == "pdf" then
          if thecolors then
            for key, col in pairs(thecolors) do
              table.insert(StyleCSSTeX, "\\definecolor{"..cls.."-color"..key.."}{HTML}{"..col.."}\n")
            end
          end
          -- no elegant way to store and recall sizes
          -- if thesizes then
          --   for key, val in pairs(thesizes) do
          --      table.insert(StyleCSSTeX, "\\newcommand{\\"..cls.."size"..key.."}{"..val.."}\n") 
          --   end 
          -- end
        end  
      end  
    end  
  end
  result = pandoc.utils.stringify(StyleCSSTeX)
  -- print(result)
  if fmt == "html" then result = "<style>\n"..result.."</style>" end
  if fmt == "pdf" then result="%%==== colors from yaml ===%\n"..result.."%=============%\n" end
  return(result)
end

return{
    SetVariablesCSSTeX=colorsizeCSSTeX_legacy
}