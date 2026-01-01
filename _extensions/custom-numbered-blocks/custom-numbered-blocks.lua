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
-- pre-pre-release
-- 
-- partial rewrite, complete later

-- nice rename function learned from shafayetShafee :-)
--local str = pandoc.utils.stringify
--local pout = quarto.log.output

-- important quasi global variables


-- TODO encapsulate stylez into a doc thing or so
-- maybe later allow various versions concurrently. 
-- this could probably be problematic because of option clashes in rendered header?
--    encapsulate options in a list 

--- TODO: better encapsulation (luxury :-P)

cnbx = require "cnb-global"
util = require "cnb-utilities"

if cnbx.fmt == "unsupported" then
  util.warn ("format "..FORMAT.." not supported")
  return
end  

--print(cnbx.ute)


-- debugging stuff
--[[

local function pandocblocks(doc)
  for k,v in pairs(doc.blocks) do
    pout(v.t)
  end
end

local function pandocdivs(div)
  pout(div.t.." - "..div.identifier)
  pout(div.attributes)
end
]]--


return{
    require("cnb-1-init") -- Meta: set up chapter numbers and classes
    
   ,  require("cnb2-1-numbering") 
   
   , require("cnb-2-initxref")
   
  --, {Meta = Meta_readxref, Div=fboxDiv_mark_for_processing,
  --   Pandoc = Pandoc_prefix_count} 
 -- , {Div=pandocdivs, Pandoc=pandocblocks}
  --[[ ]]
  , require("cnb-3-preparexref")
  
 -- , {Div = Divs_getid, Pandoc = Pandoc_preparexref}
  , require("cnb-4-resolvexref")
--  , {Pandoc = Pandoc_resolvexref}
  , require("cnb-5-processtitles")
--  , {Div = Divs_maketitle}
--  , {Pandoc = Pandoc_finalizexref}
  , require("cnb-6-storexref")
  , require("cnb-7-listof")  
--  , {Meta = Meta_writexref, Pandoc = Pandoc_makeListof}
  , require("cnb-8-renderblocks")  
 -- , {Div = renderDiv,  Pandoc = insertStylesPandoc}
  , require("cnb-9-cleanup")  
 -- , {Div = Div_cleanupAttribs}
}

