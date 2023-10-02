local function getObjectData(object)
    if object.ClassName == "Model" then
        return object:GetBoundingBox(),object:GetExtentsSize()
    elseif object.ClassName == "Part" or object.ClassName == "WedgePart" or object.ClassName == "MeshPart" or object.ClassName == "CornerWedgePart" or object.ClassName == "UnionOperation" then
        return object.CFrame,object.Size
    end
end

local BasePartService = {}

BasePartService.hasProperty = function(basePart: BasePart, property: string)
    local success, result = pcall(function()
        return basePart[property]
    end)
    return success and (result ~= basePart:FindFirstChild(property))
end

-- Can also read into folders
BasePartService.GetAssemblyMass = function(basePart: BasePart)
    local mass = 0

    for _,basepart in basePart:GetDescendants() do
        if basepart:IsA("BasePart") then
            mass += basepart.AssemblyMass
        end
    end

    return mass
end

BasePartService.CancelAssemblyVelocity = function(basePart: BasePart)
    for _,basepart in basePart:GetDescendants() do
        if basepart:IsA("BasePart") then
            basepart.AssemblyLinearVelocity = Vector3.new(0,0,0)
            basepart.AssemblyAngularVelocity = Vector3.new(0,0,0) 
        end
    end
end

BasePartService.RemoveAssemblyMass = function(basePart: BasePart)
    basePart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
    basePart.Massless = true
end

BasePartService.IsInstance = function(instance: string)
    local success = pcall(function()
        Instance.new(instance):Destroy()
    end)
    return success
end

BasePartService.GetListedDescendants = function(Parent: BasePart, keyName: string)
    local listOfItems = {}
    for _,descendant in Parent:GetDescendants() do
        if descendant.Name == keyName then
            table.insert(listOfItems,descendant)
        end
    end
    return listOfItems
end

-- returns CFrame
BasePartService.GetCFrame = function(basePart: BasePart)
    local cframe,size = getObjectData(basePart)
    return cframe
end

-- returns Vector3
BasePartService.GetSize = function(basePart: BasePart)
    local cframe,size = getObjectData(basePart)
    return size
end

-- returns CFrame, Vector3
BasePartService.GetObjectTranslations = function(basePart: BasePart)
    return getObjectData(basePart)
end

BasePartService.Create = function(instance: string, name: string, parent: Instance)
    local Item = Instance.new(instance)
    Item.Name = name
    Item.Parent = parent
    return Item
end

BasePartService.OrderByName = function(tbl: table)
    table.sort(tbl, function(a,b)
        return a.Name < b.Name
    end)
    return tbl
end

return BasePartService