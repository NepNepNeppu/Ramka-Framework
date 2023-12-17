--[[

	Terrain Save & Load API

	local TerrainSaveLoad = require(thisModule)

	API:
		TerrainSaveLoad.Save(): TerrainRegion
		TerrainSaveLoad.Load(region: TerrainRegion)

	General notes:
		- `Save` is only useful in plugin environments.
		- `Load` will clear the existing terrain.
		- `Load` must be called server-side, as TerrainRegion
			objects do not replicate their internal data to clients.
		- Use this API within whatever map loading system you have.

--]]

local TerrainSaveLoad = {}

local function SaveTerrainProperty(terrainProperty: string, class: string, parent: Instance)
	local valHold = Instance.new(class) :: ValueBase
	valHold.Name = terrainProperty
	valHold.Value = workspace.Terrain[terrainProperty]
	valHold.Parent = parent
end

local function LoadTerrainProperty(terrainRegion: TerrainRegion, terrainProperty: string)
	local propVal = terrainRegion:FindFirstChild(terrainProperty)
	if propVal then
		workspace.Terrain[terrainProperty] = propVal.Value
	end
end

local function AttemptGetMaterialColor(material: Enum.Material): (boolean, Color3)
	return pcall(function()
		return workspace.Terrain:GetMaterialColor(material)
	end)
end

local function AttemptSetMaterialColor(material: Enum.Material, color: Color3): boolean
	return pcall(function()
		workspace.Terrain:SetMaterialColor(material, color)
	end)
end

function TerrainSaveLoad.Clear()
	workspace.Terrain:Clear()
end

function TerrainSaveLoad.Save(): TerrainRegion
	local terrainRegion = workspace.Terrain:CopyRegion(workspace.Terrain.MaxExtents)
	terrainRegion.Name = "SavedTerrain"

	-- Save water properties:
	local waterProps = Instance.new("Folder")
	waterProps.Name = "WaterProperties"
	SaveTerrainProperty("WaterColor", "Color3Value", waterProps)
	SaveTerrainProperty("WaterReflectance", "NumberValue", waterProps)
	SaveTerrainProperty("WaterTransparency", "NumberValue", waterProps)
	SaveTerrainProperty("WaterWaveSize", "NumberValue", waterProps)
	SaveTerrainProperty("WaterWaveSpeed", "NumberValue", waterProps)
	waterProps.Parent = terrainRegion

	-- Save material colors:
	local materialColors = Instance.new("Folder")
	materialColors.Name = "MaterialColors"
	for _,material in Enum.Material:GetEnumItems() do
		local success, color = AttemptGetMaterialColor(material)
		if not success then continue end
		local colorValue = Instance.new("Color3Value")
		colorValue.Name = material.Name
		colorValue.Value = color
		colorValue.Parent = materialColors
	end
	materialColors.Parent = terrainRegion

	return terrainRegion
end

function TerrainSaveLoad.TrimToRegion(min: Vector3, max: Vector3, params: {scale: number, tolerance: number})
	local midPoint = (min + max) / 2
	local xScale, yScale, zScale = math.abs(min.X - max.X), math.abs(min.Y - max.Y), math.abs(min.Z - max.Z)

	local directionMaxClear = if params and params.scale then params.scale else 400
	local boundaryTolerance = if params and params.tolerance then params.tolerance else 10

	local regionSpaceVectors = {
		Vector3.new(0, -xScale/2 - directionMaxClear/2 - boundaryTolerance, 0),
		Vector3.new(0, xScale/2 + directionMaxClear/2 + boundaryTolerance, 0),
		Vector3.new(0, 0, -yScale/2 - directionMaxClear/2 - boundaryTolerance),
		Vector3.new(0, 0, yScale/2 + directionMaxClear/2 + boundaryTolerance),
		Vector3.new(-zScale/2 - directionMaxClear/2 - boundaryTolerance, 0, 0),
		Vector3.new(zScale/2 + directionMaxClear/2 + boundaryTolerance, 0, 0),
	}

	for _,vector in regionSpaceVectors do
		local offsetRegion = CFrame.new(midPoint) * CFrame.new(vector)
		local minRegion, maxRegion = offsetRegion.Position - Vector3.one * (directionMaxClear/2), offsetRegion.Position + Vector3.one * (directionMaxClear/2)
		--require(game.ReplicatedFirst.Ramka).Debug.Region3(minRegion, maxRegion)
		game.Workspace.Terrain:FillRegion(Region3.new(minRegion, maxRegion):ExpandToGrid(4), 4, Enum.Material.Air)
	end
end

function TerrainSaveLoad.Load(terrainRegion: TerrainRegion)
	if typeof(terrainRegion) ~= "Instance" or not terrainRegion:IsA("TerrainRegion") then
		error("Expected TerrainRegion object as argument to Load", 2)
	end

	local position = Vector3int16.new(
		-math.floor(terrainRegion.SizeInCells.X / 2),
		-math.floor(terrainRegion.SizeInCells.Y / 2),
		-math.floor(terrainRegion.SizeInCells.Z / 2)
	)

	workspace.Terrain:PasteRegion(terrainRegion, position, true)

	-- Load water properties:
	local waterProps = terrainRegion:FindFirstChild("WaterProperties")
	if waterProps then
		LoadTerrainProperty(terrainRegion, "WaterColor")
		LoadTerrainProperty(terrainRegion, "WaterReflectance")
		LoadTerrainProperty(terrainRegion, "WaterTransparency")
		LoadTerrainProperty(terrainRegion, "WaterWaveSize")
		LoadTerrainProperty(terrainRegion, "WaterWaveSpeed")
	end

	-- Load material colors:
	local materialColors = terrainRegion:FindFirstChild("MaterialColors")
	if materialColors then
		for _,material in Enum.Material:GetEnumItems() do
			local colorVal = materialColors:FindFirstChild(material.Name)
			if colorVal then
				AttemptSetMaterialColor(material, colorVal.Value)
			end
		end
	end
end

return TerrainSaveLoad