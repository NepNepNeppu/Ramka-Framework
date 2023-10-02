local GuiService = {}

GuiService.OrderByName = function (tbl)    
    table.sort(tbl, function(a,b)
        return a.Name < b.Name
    end)
    return tbl
end

GuiService.OrderByLayoutOrder = function (tbl,start: number?)
    for i,v in GuiService.fromInstance(tbl) do
        v.LayoutOrder = (start or 0) + i
    end
    return tbl
end

return GuiService