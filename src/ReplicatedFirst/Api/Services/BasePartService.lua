local Ramka = require(game.ReplicatedFirst.Ramka)
local Promise = require(Ramka.GetClasses().Promise)

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

local BasePartService = {}

    --[=[
        @return Promise<Instance>
        Wait for a child to exist within a given parent based on the child name.

        ```lua
        WaitFor.Child(parent, "SomeObject"):andThen(function(someObject)
            print(someObject, "now exists")
        end):catch(warn)
        ```
    ]=]
    BasePartService.Child = function(parent: Instance, childName: string, timeout: number?)
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
    BasePartService.Descendant = function(parent: Instance, descendantName: string, timeout: number?)
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
        WaitFor.String(parent, "SomeObject"):andThen(function(someObject)
            print(someObject, "now exists")
        end):catch(warn)
        ```

        :::note
        colons signifiy peroids if an instance encorperates a peroid
        ex: item name = "the.object"
            "the:object"
        :::
    ]=]
    BasePartService.String = function(globalParent: Instance,extendedName : string, timeout: number?)
        local Format = extendedName:split(".")
        local finalFunc = nil

        local function diveSelf(parent,index)
            local data = string.gsub(Format[index],":",".")
            WaitFor.Child(parent,data,timeout):andThen(function(someObject)
                if index == #Format then
                    finalFunc = WaitFor.Child(parent,data,timeout)
                else
                    diveSelf(someObject,index + 1)
                end
            end):awaitStatus()
        end

        diveSelf(globalParent,1)

        return finalFunc
    end

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