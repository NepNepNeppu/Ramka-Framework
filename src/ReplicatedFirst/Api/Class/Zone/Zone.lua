local partDetails = { 
	["Ball"] = function(part)
		return "GetPartBoundsInRadius", {part.Position, part.Size.X/2}
	end,
	["Block"] = function(part)
		return "GetPartBoundsInBox", {part.CFrame, part.Size}
	end,
	["Other"] = function(part)
		return "GetPartsInPart", {part}
	end,
}

local function isABasePart(object: BasePart)
    if object:IsA("Part") or object:IsA("MeshPart") or object:IsA("WedgePart") or object:IsA("UnionOperation") then
        return true
    end
end

local function GetCollisionProperties(part,overlapParams,self)
    local success, shapeName = pcall(function()
        return part.Shape.Name 
    end)
    local methodName, args
    if success then
        local action = partDetails[shapeName]
        if action then
            methodName, args = action(part)
        end
    end
    if not methodName then
        methodName, args = partDetails.Other(part)
    end
    if overlapParams then
        table.insert(args, overlapParams)
    end
    return methodName, args, part
end

export type BoundsInBox = {[number] : CFrame | Vector3}
export type BoundsInRadius = {[number] : Vector3 | number}

return function()
    local Zone = {}
    Zone.__index = Zone

    Zone.ActiveZones = {}

    --[[
    local zone = Zone.new("Area")
    
    for i,v in hitboxes do
        zone:AddToWhitelist(v)
    end

    while true do
        zone:SetHitbox(Part)
        zone:GetIntersections()
        task.wait()
    end
    ]]
    function Zone.new(Name)
        local overlapPerms = OverlapParams.new()
        overlapPerms.FilterType = Enum.RaycastFilterType.Include

        local self = setmetatable({
            keyName = Name,

            hitbox = nil,
            perms = overlapPerms,

            isActive = true,

            whitelist = {},

            hitboxBestCase = nil
        },Zone)

        return self
    end

    --[[
        BasePart = [BasePart]
        BoundsInBox = {CFrame: CFrame, Size: Vector3}
        BoundsInRadius = {Position: Vector3, Radius: number}
    ]]
    function Zone:SetHitbox(hitbox: BasePart | BoundsInBox | BoundsInRadius)
        if typeof(hitbox) == "Instance" and isABasePart(hitbox) then
            self.hitbox = hitbox
            self.hitboxBestCase = {GetCollisionProperties(hitbox,self.perms,self)}
        elseif type(hitbox) == "table" and hitbox.CFrame and hitbox.Size then
            self.hitbox = {
                CFrame = hitbox.CFrame,
                Size = hitbox.Size
            }
            self.hitboxBestCase = "BoundsInBox"
        elseif type(hitbox) == "table" then
            self.hitbox = {
                Position = hitbox.Position,
                Radius = hitbox.Radius
            }
            self.hitboxBestCase = "BoundsInRadius"
        end
    end

    function Zone:Pause()
        self.isActive = false
    end

    function Zone:Resume()
        self.isActive = true
    end

    function Zone:AddToWhitelist(object) -- Use to add new intersections (MUST USE)
        if not table.find(self.whitelist,object) and isABasePart(object) then
            table.insert(self.whitelist,object)
        end
    end

    function Zone:RemoveFromWhitelist(object)
        local wasFound = table.find(self.whitelist,object)
        if wasFound then
            table.remove(self.whitelist,wasFound)
        end
    end

    function Zone:GetIntersections() -- Grab new intersections
        if self.hitbox == nil or #self.whitelist == 0 then return {} end
        self.perms.FilterDescendantsInstances = self.whitelist

        if self.hitboxBestCase == "BoundsInBox" then
            Zone.ActiveZones = workspace:GetPartBoundsInBox(self.hitbox.CFrame,self.hitbox.Size,self.perms)
        elseif self.hitboxBestCase == "BoundsInRadius" then
            Zone.ActiveZones = workspace:GetPartBoundsInRadius(self.hitbox.Position,self.hitbox.Radius,self.perms)
        else
            Zone.ActiveZones = workspace[self.hitboxBestCase[1]](workspace,table.unpack(self.hitboxBestCase[2]))
        end

        return Zone.ActiveZones
    end

    return Zone
end