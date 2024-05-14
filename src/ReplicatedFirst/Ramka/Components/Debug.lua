local _storage = {}

return {
    ClearAll = function()
        for i,selectionData in _storage do                
            for i,v in selectionData do
                v:Destroy()
            end
        end
    end,

    Clear = function(selectionData: {})
        for i,v in selectionData do
            v:Destroy()
        end
    end,

    SpawnDebugPart = function() : Part
        local part: Part = Instance.new("Part")
        part.Name = "DebugPart"
        part.Size = Vector3.one
        part.Anchored = true
        part.Color = Color3.fromRGB(255, 70, 70)
        part.CanCollide = false
        part.Parent = workspace

        return part
    end,

    SpawnDebugLine = function(p1 ,p2) : Part
        local part: Part = Instance.new("Part")
        part.Name = "DebugVector"
        part.Anchored = true
        part.Color = Color3.fromRGB(36, 36, 36)
        part.CanCollide = false
        part.Size = Vector3.new(0.2,0.2,(p1 - p2).Magnitude)
        part.Material = Enum.Material.Neon
        part.CFrame = CFrame.lookAt(p1, p2) * CFrame.new(0,0,-(p1 - p2).Magnitude/2)
        part.Parent = workspace

        return part
    end,

    SpawnDebugVector = function(origin, direction, scale: number?) : Part
        local part: Part = Instance.new("Part")
        part.Name = "DebugVector"
        part.Anchored = true
        part.Color = Color3.fromRGB(89, 70, 255)
        part.CanCollide = false
        part.Size = Vector3.new(0.2,0.2,scale or direction.Magnitude)
        part.Material = Enum.Material.Neon
        part.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0,0,(scale or direction.Magnitude)/2)
        part.Parent = workspace
        
        return part
    end,

    Region3 = function(min, max, thickness: number?)
        local size = max - min
        local x, y, z = size.X / 2, size.Y / 2, size.Z / 2
        local lineWidth = thickness or 1
        local relativeOrientation = CFrame.new((min + max) / 2)

        local scaleAxis = {
            X = Vector3.new(size.X + lineWidth, lineWidth, lineWidth),
            Y = Vector3.new(lineWidth, size.Y + lineWidth, lineWidth),
            Z = Vector3.new(lineWidth, lineWidth, size.Z + lineWidth)
        }

        local offsets = {
            {1,1},
            {-1,1},
            {1,-1},
            {-1,-1}
        }

        local ramkaDebug = game.Workspace.Terrain:FindFirstChild("RamkaDebug")
        if not ramkaDebug then
            ramkaDebug = Instance.new("Folder",game.Workspace.Terrain)
            ramkaDebug.Name = "RamkaDebug"
        end

        local function doMult(axis, offset)
            if axis == "X" then
                return Vector3.new(0,offset[1],offset[2]) * Vector3.new(x, y, z)
            elseif axis == "Y" then
                return Vector3.new(offset[1],0,offset[2]) * Vector3.new(x, y, z)
            elseif axis == "Z" then
                return Vector3.new(offset[1],offset[2],0) * Vector3.new(x, y, z)
            end
        end

        local adornments = {} do
            for _, axis in {"X","Y","Z"} do
                for _, offset in offsets do
                    local boxHandleAdornment = Instance.new("BoxHandleAdornment", ramkaDebug)
                    boxHandleAdornment.Size = scaleAxis[axis]
                    boxHandleAdornment.CFrame = relativeOrientation * CFrame.new(doMult(axis, offset))
                    boxHandleAdornment.Color3 = Color3.fromRGB(139, 126, 200)
                    boxHandleAdornment.ZIndex = 1
                    boxHandleAdornment.AdornCullingMode = Enum.AdornCullingMode.Automatic
                    boxHandleAdornment.Adornee = workspace

                    table.insert(adornments, boxHandleAdornment)
                end
            end
        end

        table.insert(_storage, adornments)

        return adornments
    end
}