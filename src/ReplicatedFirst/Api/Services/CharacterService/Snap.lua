local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Core = require(ReplicatedStorage.Core)

local function coreAddon(func,object)  
	local function initItems(newObject)
		func(object)
		if newObject:IsA("Model") or newObject:IsA("Folder") then
			for _,item in pairs(newObject:GetDescendants()) do
				func(item)
			end
			newObject.DescendantAdded:Connect(function(item)
				func(item)
			end)
		end
	end

	if type(object) == "table" then
		for _,item in pairs(object) do
			initItems(item)
		end
	else
		initItems(object)
	end
end

local Snap = {}
Snap.__index = Snap

    function Snap.new(object : BasePart,customName : string,cameraSnap : boolean)
        local self = setmetatable({
            ["Name"] = customName,
            ["cameraSnap"] = cameraSnap,
            conditionals = {},
            _details = {
                ["LastCFrame"] = nil,
                ["Runner"] = nil,
                ["Manual"] = true,
                ["Items"] = {},

                lastInstance = nil,
            },
            SnapDistance = 15,
            DisconnectOnFall = true,
            Enabled = true,
        },Snap)

        if object then
            self:AddItems(object)
        end

        return self
    end

    function Snap:SetGroupSnap(objects : {[number] : BasePart | Model | Folder})
        for _,object in pairs(objects) do
            table.insert(self._details.Items,object)
        end
    end

    function Snap:RemoveGroupSnap(objects : {[number] : BasePart | Model | Folder})
        for _,object in pairs(objects) do
            if table.find(self._details.Items,object) then
                table.remove(self._details.Items,table.find(self._details.Items,object))
            end
        end
    end

    function Snap:AddCondition(func)
        table.insert(self.conditionals,func)
    end

    function Snap:ConditionsMet()
        local conditionsMet = true
        for _,condit in pairs(self.conditionals) do
            local doCon = condit()
            if doCon == false then
                conditionsMet = false
            end
        end
        return conditionsMet
    end

    function Snap:ResetSnap()
        self._details.usingReset = true
    end

    function Snap:Update(Character)
        local canCheckForPlatform = Character~=nil

		if canCheckForPlatform then
			local humanoid = Character:FindFirstChildOfClass("Humanoid")
			canCheckForPlatform = if humanoid then humanoid:GetState()~=Enum.HumanoidStateType.Freefall or self.DisconnectOnFall == false else canCheckForPlatform
		end

		if not canCheckForPlatform then
			self._details["LastCFrame"] = nil
			return
		end

		local characterPivotCFrame = Character:GetPivot()

		local platformRaycastParams = RaycastParams.new()
		platformRaycastParams.FilterType = Enum.RaycastFilterType.Include
		platformRaycastParams.FilterDescendantsInstances = self._details.Items or {}

		local raycastResult = workspace:Raycast(characterPivotCFrame.Position, -Vector3.yAxis*self.SnapDistance, platformRaycastParams)
		if raycastResult then
			local platformCFrame = raycastResult.Instance.CFrame
			if self._details["LastCFrame"] == nil or self._details.lastInstance ~= raycastResult.Instance then
				self._details["LastCFrame"] = platformCFrame
			end
            self._details.lastInstance = raycastResult.Instance

			local platformRelativeCFrame = platformCFrame * self._details["LastCFrame"]:inverse()
			self._details["LastCFrame"] = platformCFrame

            if self._details.usingReset == nil and self:ConditionsMet() == true and self.Enabled == true then
                Character:PivotTo(platformRelativeCFrame * characterPivotCFrame)
                if self.cameraSnap then
                    local _,Y,_ = platformRelativeCFrame:ToOrientation()
                    game.Workspace.CurrentCamera.CFrame *= CFrame.Angles(0,Y,0)
                end
            else
                self._details.usingReset = nil
            end
		else
			self._details["LastCFrame"] = nil
		end
        self._details.Manual = false
    end

    function Snap:AddItems(object : BasePart)
        local function AddTo(item)
            if item:IsA("BasePart") and not table.find(self._details.Items,item) then
                table.insert(self._details.Items,item)
            end
        end   

        coreAddon(AddTo,object)
    end

    function Snap:RemoveItems(object : BasePart)
         local function RemoveFrom(item)
            if item:IsA("BasePart") and table.find(self._details.Items,item) then
                table.remove(self._details.Items,table.find(self._details.Items,item))
            end
        end   

        coreAddon(RemoveFrom,object)
    end

return Snap
