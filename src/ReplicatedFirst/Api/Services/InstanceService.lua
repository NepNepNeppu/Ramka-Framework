local Ramka = require(game.ReplicatedFirst.Ramka)
local Promise = require(Ramka.Class.Promise)

local WaitFor = {}
WaitFor.Error = {
	Unparented = "Unparented",
	ParentChanged = "ParentChanged",
}

local function PromiseWatchAncestry(instance: Instance, promise)
	return Promise.race({
		promise,
		Promise.fromEvent(instance.AncestryChanged, function(_, newParent)
			return newParent == nil
		end):andThen(function()
			return Promise.reject(WaitFor.Error.Unparented)
		end),
	})
end

local function getObjectData(object)
    if object.ClassName == "Model" then
        return object:GetBoundingBox(),object:GetExtentsSize()
    elseif object.ClassName == "Part" or object.ClassName == "WedgePart" or object.ClassName == "MeshPart" or object.ClassName == "CornerWedgePart" or object.ClassName == "UnionOperation" then
        return object.CFrame,object.Size
    end
end

local InstanceService = {}

    --[=[
        @return Promise<Instance>
        Wait for a child to exist within a given parent based on the child name.

        ```lua
        WaitFor.Child(parent, "SomeObject"):andThen(function(someObject)
            print(someObject, "now exists")
        end):catch(warn)
        ```
    ]=]
    InstanceService.Child = function(parent: Instance, childName: string, timeout: number?)
        local child = parent:FindFirstChild(childName)
        if child then
            return Promise.resolve(child)
        end
        return PromiseWatchAncestry(
            parent,
            Promise.fromEvent(parent.ChildAdded, function(c)
                return c.Name == childName
            end)
        )
    end

    --[=[
        @return Promise<Instance>
        Wait for a descendant to exist within a given parent. This is similar to
        `WaitFor.Child`, except it looks for all descendants instead of immediate
        children.

        ```lua
        WaitFor.Descendant(parent, "SomeDescendant"):andThen(function(someDescendant)
            print("SomeDescendant now exists")
        end)
        ```
    ]=]
    InstanceService.Descendant = function(parent: Instance, descendantName: string, timeout: number?)
        local descendant = parent:FindFirstChild(descendantName, true)
        if descendant then
            return Promise.resolve(descendant)
        end
        return PromiseWatchAncestry(
            parent,
            Promise.fromEvent(parent.DescendantAdded, function(d)
                return d.Name == descendantName
            end)
        )
    end

    --[=[
        @return Promise<Instance>
        Wait for a child to exist within a given parent based on a an orderd list name.

        ```lua
        WaitFor.String(parent, "SomeObject//Child"):andThen(function(someObject)
            print(someObject, "now exists")
        end):catch(warn)
        ```

        :::caution
        names are separated by //
        ex: part//child//descendant
    ]=]
    InstanceService.String = function(globalParent: Instance,extendedName : string, timeout: number?)
        local Format = extendedName:split('//')
        local finalFunc = nil

        local function diveSelf(parent,index)
            local data = Format[index] --string.gsub(Format[index],":",".")
            InstanceService.Child(parent,data,timeout):andThen(function(someObject)
                if index == #Format then
                    finalFunc = InstanceService.Child(parent,data,timeout)
                else
                    diveSelf(someObject,index + 1)
                end
            end):awaitStatus()
        end

        diveSelf(globalParent,1)

        return finalFunc
    end

    InstanceService.hasProperty = function(basePart: BasePart, property: string)
        local success, result = pcall(function()
            return basePart[property]
        end)
        return success and (result ~= basePart:FindFirstChild(property))
    end

    -- Can also read into folders
    InstanceService.GetAssemblyMass = function(basePart: BasePart)
        local mass = 0

        for _,basepart in basePart:GetDescendants() do
            if basepart:IsA("BasePart") then
                mass += basepart.AssemblyMass
            end
        end

        return mass
    end

    InstanceService.FormConnectionLink = function(instance: BasePart, connections)
        local function clearConnections()
            for i,v in connections do
                v:Disconnect()
            end
        end

        instance.Destroying:Once(clearConnections)
        return clearConnections
    end

    InstanceService.CancelAssemblyVelocity = function(basePart: BasePart)
        for _,basepart in basePart:GetDescendants() do
            if basepart:IsA("BasePart") then
                basepart.AssemblyLinearVelocity = Vector3.new(0,0,0)
                basepart.AssemblyAngularVelocity = Vector3.new(0,0,0) 
            end
        end
    end

    InstanceService.RemoveAssemblyMass = function(basePart: BasePart)
        basePart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        basePart.Massless = true
    end

    InstanceService.IsInstance = function(instance: string)
        local success = pcall(function()
            Instance.new(instance):Destroy()
        end)
        return success
    end

    InstanceService.GetListedDescendants = function(Parent: BasePart, keyName: string)
        local listOfItems = {}
        for _,descendant in Parent:GetDescendants() do
            if descendant.Name == keyName then
                table.insert(listOfItems,descendant)
            end
        end
        return listOfItems
    end

    -- returns CFrame
    InstanceService.GetCFrame = function(basePart: BasePart)
        local cframe,size = getObjectData(basePart)
        return cframe
    end

    -- returns Vector3
    InstanceService.GetSize = function(basePart: BasePart)
        local cframe,size = getObjectData(basePart)
        return size
    end

    -- returns CFrame, Vector3
    InstanceService.GetObjectTranslations = function(basePart: BasePart)
        return getObjectData(basePart)
    end

    InstanceService.Create = function(instance: string, name: string, parent: Instance)
        local Item = Instance.new(instance)
        Item.Name = name
        Item.Parent = parent
        return Item
    end

    InstanceService.OrderByName = function(tbl: table)
        table.sort(tbl, function(a,b)
            return a.Name < b.Name
        end)
        return tbl
    end

    -- a list of instances
    InstanceService.GetBoundingBox = function(models: {[number]: Model}): (CFrame,Vector3)        
        local orientation: CFrame = CFrame.identity
    
        local inf: number = math.huge
        local negInf: number = -inf
    
        local minx, miny, minz = inf, inf, inf
        local maxx, maxy, maxz = negInf, negInf, negInf
    
        local function adjust(part: Model): ()
            local size: Vector3 = part:GetExtentsSize()
            local sx, sy, sz = size.X, size.Y, size.Z
    
            local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = orientation:ToObjectSpace(part:GetPivot()):GetComponents()
            local wsx = 0.5 * (math.abs(R00) * sx + math.abs(R01) * sy + math.abs(R02) * sz)
            local wsy = 0.5 * (math.abs(R10) * sx + math.abs(R11) * sy + math.abs(R12) * sz)
            local wsz = 0.5 * (math.abs(R20) * sx + math.abs(R21) * sy + math.abs(R22) * sz)
    
            minx = if minx > (x - wsx) then x - wsx else minx
            miny = if miny > (y - wsy) then y - wsy else miny
            minz = if minz > (z - wsz) then z - wsz else minz
            
            maxx = if maxx < (x + wsx) then x + wsx else maxx
            maxy = if maxy < (y + wsy) then y + wsy else maxy
            maxz = if maxz < (z + wsz) then z + wsz else maxz
        end
        
        for _, descendant: Instance in models do
            if descendant:IsA("Model") then 
                adjust(descendant)
            end
        end
    
        local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
        return orientation + orientation:PointToWorldSpace((omax + omin) * 0.5), (omax - omin)
    end

return InstanceService