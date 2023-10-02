local ArrayService = {}

-- reverses order of indecies while keeping values in the same place
ArrayService.invert = function(tbl: table)
    local oldTable = table.clone(tbl)
    for i,v in oldTable do
        tbl[-i + #oldTable] = v
    end
    return tbl
end

return ArrayService