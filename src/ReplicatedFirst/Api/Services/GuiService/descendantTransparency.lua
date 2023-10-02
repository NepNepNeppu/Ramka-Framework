--//work around for canvasgroups
local Game = require(game.StarterPlayer.StarterPlayerScripts.Client.Components)
local SharedPackages = game:GetService('ReplicatedFirst').SharedPackages
local ClientPackages = game.StarterPlayer.StarterPlayerScripts.Client.Scheduler.Packages
local Schedule = Game.Scheduler.Get()

local Tasks = require(SharedPackages.Tasks)
ifThen = Tasks.ifThen
doTask = Tasks.doTask

local spr = require(SharedPackages.mathematics.spr)
local worldGeneric = require(SharedPackages.world.generic)

local descendantTransparency = {}
descendantTransparency.worldStep = false

local worldDescendants = {}
local numberValues: {} = {}
local instanceTypeProperties = {
    ignoreList = {},
    availableList = {}
}

local propertyTable = {"BackgroundTransparency","TextTransparency","TextStrokeTransparency","GroupTransparency","ImageTransparency","TextTransparency","ScrollBarImageTransparency"}
do -- internal use only
    instanceTypeProperties._get = function(instance) 
        if instanceTypeProperties.availableList[instance.ClassName] == nil and instanceTypeProperties.ignoreList[instance.ClassName] == nil then
            instanceTypeProperties.availableList[instance.ClassName] = {}
            local hasProperties = false

            for _,property in propertyTable do
                local hasProperty,_ = worldGeneric.hasProperty(instance,property)
                if hasProperty == true then
                    table.insert(instanceTypeProperties.availableList[instance.ClassName],property)
                    hasProperties = true
                end
            end

            if hasProperties == false then
                instanceTypeProperties.ignoreList[instance.ClassName] = true
                instanceTypeProperties.availableList[instance.ClassName] = nil
            end
        end

        return instanceTypeProperties.availableList[instance.ClassName],(instanceTypeProperties.ignoreList[instance.ClassName] == nil)
    end

    instanceTypeProperties.Get = function(instance,self)
        local properties,isGui = instanceTypeProperties._get(instance)
        local currentProperties = {
            info = {},
            wasUpdated = false, --if the modifiers have been applied yet
        }
        if isGui then
            for _,property in properties do
                currentProperties.info[property] = instance[property]
            end
        end
        return currentProperties,isGui       
    end
end

--[[ NOTE
    * when cloning an object, store it elsewhere so its not invisible when copied
]]

    function descendantTransparency._clearExpiredParents()
        for i,v in numberValues do
            if i == nil or i.Parent == nil then
                numberValues[i].value:Destroy()
                numberValues[i].isActive = false
                for i,v in numberValues[i].activeConnections do
                    v:Disconnect()
                end
                numberValues[i] = nil
            end
        end
    end

    function descendantTransparency._systemIsActive()
        for i,v in numberValues do
            if v.isActive then
                return true
            end
        end
        return false
    end

    function descendantTransparency._getDescendantTransparency(descendant)
        local isActiveDescendant = false
        local transparency = 1
        for i,v in numberValues do
            if descendant:IsDescendantOf(i) and (v.isActive or worldDescendants[descendant].wasUpdated == false) then
                worldDescendants[descendant].wasUpdated = true
                isActiveDescendant = true
            end
        end

        local softError = worldDescendants[descendant].numValues or false
        if softError == false then
            descendantTransparency.prepareInstanceValues(descendant)
            -- warn("Soft error detected for "..descendant.Name)
            -- warn("Repair Status: "..if (worldDescendants[descendant].numValues or false) == false then "failed" else "success")
        end

        for _,numberValue in (worldDescendants[descendant].numValues or {}) do --TODO:  THIS SILENT ERRORS, FIND THE SOURCE
            transparency *= (-numberValue.Value+1)
        end

        return -transparency+1,isActiveDescendant
    end

    function descendantTransparency._applyTransparencyToDescendant(descendant,ignoreActiveDescendant: boolean?)
        local transparency = 1
        local ActiveDescendant
        if descendant.Parent ~= nil and worldDescendants[descendant] then
            local trueTransparency,isActiveDescendant = descendantTransparency._getDescendantTransparency(descendant)
            ActiveDescendant = isActiveDescendant
            if (if ignoreActiveDescendant == true then true else isActiveDescendant) then
                for propertyName,propertyValue in worldDescendants[descendant].info do
                    if type(propertyValue) ~= "table" then  
                        transparency = propertyValue + (trueTransparency * (-propertyValue + 1))  
                        descendant[propertyName] = transparency
                    end
                end
            end
        end
        return transparency, ActiveDescendant
    end

    function descendantTransparency._applyDirectTransparencyModifier(tbl: {})
        for instance,_ in tbl do
            descendantTransparency._applyTransparencyToDescendant(instance,false)
        end
    end
    
    function descendantTransparency._getParentDescendants(parent: GuiObject)
        local tbl = {}
        for instance,properties in worldDescendants do
            if instance:IsDescendantOf(parent) then
                tbl[instance] = properties
            end
        end
        return tbl
    end
        
    -- Use only for debugging
    function descendantTransparency._getAncestorTransparencyList(instance: GuiObject)
        local list = {}
        local transparency = 1

        for i,v in numberValues do
            if instance:IsDescendantOf(i) then
                transparency *= (-numberValues[i].value.Value+1)
                list[i.Name] = numberValues[i].value.Value
            end
        end

        return list,-transparency+1
    end

    --[[
        all descendants of playergui are initialized with given properties
        this functions allows you to override those old properties to the current ones
    ]]
    function descendantTransparency.reloadInstanceBaseProperties(instance: GuiObject)
        if worldDescendants[instance] then
            local propertyTable,isGui = instanceTypeProperties.Get(instance) 
            if isGui then
                worldDescendants[instance] = propertyTable
                descendantTransparency._applyTransparencyToDescendant(instance,true)
            end
        else
            warn((instance and instance.Name or "nil").." is not a descendant of PlayerGui.")
        end
    end

    --[[
        VERY important function, keeps all descendants up-to-date with all recent changes in parents and allows transparency updates
    ]]
    function descendantTransparency.prepareInstanceValues(descendant,maxIterations: number?)
        if descendant and descendant.Parent then            
            local parent = descendant.Parent --dont want it to find itself
            local Iterations = 0

            if worldDescendants[descendant].numValues == nil then
                worldDescendants[descendant].numValues = {}
            end

            while true do
                Iterations += 1
                if Iterations >= (maxIterations or 30) or descendant.Parent == game.Players.LocalPlayer.PlayerGui then
                    warn("Max Iteration cap reached.")
                    break
                end

                if parent and parent.Parent and descendant:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) then
                    if numberValues[parent] then
                        if not table.find(worldDescendants[descendant].numValues,numberValues[parent].value) then                   
                            table.insert(worldDescendants[descendant].numValues,numberValues[parent].value)
                        end
                    end
                    parent = parent.Parent
                else
                    break
                end                
            end
        end
    end
    
    -- Remove instance and its values connected
    function descendantTransparency.clearAttributes(parent)
        if numberValues[parent] then            
            numberValues[parent].value:Destroy()
            for i,v in numberValues[parent].activeConnections do
                v:Disconnect()
            end
            for i,v in numberValues[parent] do
                numberValues[parent][i] = nil
            end
            numberValues[parent] = nil
        end
    end

    -- Special behavioral properties
    function descendantTransparency.setAttributes(parent: GuiObject,transparency: number?,autoVisibility: boolean?)
        local function setAttributes()  
            if autoVisibility ~= nil then
                numberValues[parent].autoVisibility = autoVisibility
            end
            
            if transparency ~= nil then
                numberValues[parent].value.Value = transparency
                numberValues[parent].transparency = transparency

                if descendantTransparency.worldStep == false then
                    descendantTransparency._applyDirectTransparencyModifier(descendantTransparency._getParentDescendants(parent))
                end
                
                if numberValues[parent].autoVisibility then
                    parent.Visible = (transparency ~= 1)
                end
            end
        end

        if numberValues[parent] then
            setAttributes()
            return numberValues[parent]
        elseif parent and parent.Parent then
            numberValues[parent] = {
                value = Instance.new("NumberValue"),
                isActive = false,
                activeConnections = {},
                autoVisibility = true,
                transparency = if parent.Visible == false then 1 else 0,
                tween = nil,
            }
            
            setAttributes()   
            
            for instance,_ in descendantTransparency._getParentDescendants(parent) do
                if worldDescendants[instance].numValues == nil then
                    worldDescendants[instance].numValues = {}
                end
                table.insert(worldDescendants[instance].numValues,numberValues[parent].value)
            end
            
            if numberValues[parent].activeConnections[1] == nil then
                table.insert(numberValues[parent].activeConnections,spr.link(numberValues[parent].value).Stopped:Connect(function()
                    if numberValues[parent] then
                        numberValues[parent].isActive = false
                        if numberValues[parent].value.Value == 1 and numberValues[parent].autoVisibility then
                            parent.Visible = false
                        end
                        descendantTransparency.worldStep = descendantTransparency._systemIsActive()
                    end
                end))
            end
            return numberValues[parent]
        end
    end

    -- Immediate set
    function descendantTransparency.settle(parent: GuiObject,transparency: number)
        if numberValues[parent] then
            if numberValues[parent].tween then
                numberValues[parent].tween:Pause()
            end
            
            if transparency ~= 1 and numberValues[parent].autoVisibility then
                parent.Visible = true
            end

            numberValues[parent].nextGoal = transparency
            numberValues[parent].value.Value = transparency
            numberValues[parent].isActive = true
            descendantTransparency._applyDirectTransparencyModifier(descendantTransparency._getParentDescendants(parent))
            numberValues[parent].isActive = false
        else
            descendantTransparency.setAttributes(parent,if parent.Visible == false then 1 else -transparency + 1)
            descendantTransparency.settle(parent,transparency)
        end
    end

    -- Spring motion
    function descendantTransparency.target(parent: GuiObject,transparency: number,dampingRatio: number?,frequency: number?)
        if numberValues[parent] and type(numberValues[parent].value) ~= "number" then
            if numberValues[parent].tween then
                numberValues[parent].tween:Pause()
            end
                    
            if numberValues[parent].isActive then
                spr.stop(numberValues[parent].value)
            end
            
            if transparency ~= 1 and numberValues[parent].autoVisibility then
                parent.Visible = true
            end
            
            if numberValues[parent].nextGoal == transparency then
                return
            end

            descendantTransparency.worldStep = true
            numberValues[parent].isActive = true
            numberValues[parent].nextGoal = transparency
            spr.target(numberValues[parent].value,dampingRatio or 1,frequency or 1,{Value = transparency})
        else
            descendantTransparency.setAttributes(parent,if parent.Visible == false then 1 else -transparency + 1)
            descendantTransparency.target(parent,transparency,dampingRatio,frequency)
        end
    end

    function descendantTransparency.getDescendantStatus(instance: GuiObject)
        return table.clone(worldDescendants[instance])
    end
    
    --[[
        Tweened motion
        returns tweenObject that must be played manually
    ]]
    function descendantTransparency.tween(parent: GuiObject,tweenInfo: TweenInfo,transparency: number) 
        descendantTransparency.setAttributes(parent,if parent.Visible == false then 1 else -transparency + 1)
        if numberValues[parent].tween then
            numberValues[parent].tween:Pause()
        end
        
        if numberValues[parent].isActive then
            spr.stop(numberValues[parent].value) --internally checks if Value == 1 and sets visibility accordingly, put before statement that sets to true
        end
        
        if transparency ~= 1 and numberValues[parent].autoVisibility then
            parent.Visible = true
        end

        descendantTransparency.worldStep = true
        numberValues[parent].isActive = true
        numberValues[parent].nextGoal = transparency
        numberValues[parent].tween = game:GetService("TweenService"):Create(numberValues[parent].value,tweenInfo,{Value = transparency})
        return numberValues[parent].tween
    end
    
--runner
    
    Schedule:Arrange("RenderStepped",function()
        descendantTransparency._clearExpiredParents()
        if descendantTransparency.worldStep then
            descendantTransparency._applyDirectTransparencyModifier(worldDescendants)
        end
    end):SetTag("descendantTransparency")

--preload all ui, this is to avoid any deep setting before parents have time to realize

    local function addDescendant(v)
        local propertyTable,isGui = instanceTypeProperties.Get(v) 
        if isGui and worldDescendants[v] == nil then
            worldDescendants[v] = propertyTable
        end
        return isGui
    end

    do       
        game.Players.LocalPlayer.PlayerGui.DescendantAdded:Connect(function(descendant)
            if addDescendant(descendant) then
                descendantTransparency.prepareInstanceValues(descendant)
                descendantTransparency._applyTransparencyToDescendant(descendantTransparency,true)
            end
        end)
        
        for i,v in game.Players.LocalPlayer.PlayerGui:GetDescendants() do
            addDescendant(v)
        end
        
        game.Players.LocalPlayer.PlayerGui.DescendantRemoving:Connect(function(v)
            worldDescendants[v] = nil
        end)
    end

    return descendantTransparency