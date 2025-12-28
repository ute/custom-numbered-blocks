-- this module is for managing colors.
-- it is still in legacy mode.

--- extract colors from Class options, and generate css or tex code
--- 
--- make color information. TODO: this as util, and change the color mechanism

local colorCSSTeX_legacy = function (fmt, classDefs)
  local result
  local StyleCSSTeX = {}
  if classDefs ~= nil then
    dev.tprint(classDefs)
    for cls, options in pairs(classDefs) do
        --quarto.log.output(cls)
      if options.colors then
          -- quarto.log.output("  --> Farben!")
        --print("colors are "..type(options.colors))
        --dev.tprint(options.colors)
        if fmt == "html" then
          table.insert(StyleCSSTeX, "."..cls.." {\n")
            for i, col in ipairs(options.colors) do
               table.insert(StyleCSSTeX, "  --color"..i..": #"..col..";\n") 
           end    
          table.insert(StyleCSSTeX, "}\n")
        elseif fmt == "pdf" then
          for i, col in ipairs(options.colors) do
           table.insert(StyleCSSTeX, "\\definecolor{"..cls.."-color"..i.."}{HTML}{"..col.."}\n")
          end  
        end  
      end  
    end  
  end
  result = pandoc.utils.stringify(StyleCSSTeX)
  if fmt == "html" then result = "<style>\n"..result.."</style>" end
  if fmt == "pdf" then result="%%==== colors from yaml ===%\n"..result.."%=============%\n" end
  return(result)
end

return{
    colorCSSTeX_legacy=colorCSSTeX_legacy
}