--[[
 This is a patch to fix the strange behaviour of layout-divs that are nested
 in custom numbered blocks when format is pdf.
 Apparently as a hack for crossreferencing, they are represented by figure environments
 set attribute fig-pos="H" to avoid LaTeX errors due to setting a float within a fixed box

 may be used later to also make a sub-numbering for nested custom numbered blocks

 ]]--

uti = require("cnb-utilities")

local islayout = function(attr)
    if attr ~= nil then
        for k, _ in pairs(attr) do
            if k:sub(1, 6) == "layout" then return(true)
        end end
    end    
    return(false)    
end

--local indi = 0

local parentid =""
local parentisnumbered = true
local childid = 1

local sanitize_nested = {
 traverse ='topdown',
 Div =  function(el)
    local cls, numbered
    if islayout(el.attributes) then
        el.attributes["fig-pos"] = "H"
    else
        cls = cnbx.is_cunumblo(el) 
        if cls then
            el.attributes["_nested"] = parentid -- for later use
            numbered = cnbx.numnest and not uti.hasclass(el, "unnumbered") and
                        cnbx.classDefaults[cls].numbered and parentisnumbered
            if numbered then
               el.attributes["_childid"] = tostring(childid)
               childid = childid + 1
            end
        end    
    end  
    -- el.identifier="nest"..tostring(indi)
    -- indi = indi+1
    return(el)
 end 
}   

local divnest = function(el)
 --   local ela = el.attributes
    local cls = cnbx.is_cunumblo(el)
    if cls then
       parentid = el.identifier
       childid = 1
       parentisnumbered = not uti.hasclass(el, "unnumbered") and cnbx.classDefaults[cls].numbered 
       return el:walk(sanitize_nested), true
    end
end

return{
    Div = divnest
}