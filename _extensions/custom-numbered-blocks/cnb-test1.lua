print("-----------global test ------------")
filter1 = {
  traverse = "topdown",
  Pandoc = function(d)
    print("filter1-doc")
    return(d)
  end,
  Meta = function(m)
        print("filter1-meta")
        return m
   end
}

filter2 = {
    Meta = function(m)
        print("filter2-meta")
        return m
    end
}

return {
    hallo = {Meta = function()print("hallowelt")end },
--    {Pandoc = filter1.Pandoc,
-- Meta = filter1.Meta} ,
-- {Meta = filter2.Meta}
-- }
  
  filter1=filter1, filter2=filter2}