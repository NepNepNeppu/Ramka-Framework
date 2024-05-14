type ConstructorParam = {
    pipeline: string?,
    framerate: number?,
    name: string
}

type KeyframeLoop = {
    reverse: boolean?,
    looped: boolean?
}

type func = typeof(function() end)

local function lerp(a, b ,t: number)
    if typeof(a) == "Color3" then
        local r,g,b = a.R + (b.R - a.R) * t,a.G + (b.G - a.G) * t,a.B + (b.B - a.B) * t
        return Color3.new(r,g,b)
    elseif type(a) == "number" then
        return a + (b - a) * t
    elseif typeof(a) == "UDim" then
        return UDim.new(lerp(a.Scale, b.Scale, t), lerp(a.Offset, b.Offset, t))
    end
    return a:Lerp(b,t)
end

local Animate = {}
local activeInterpolants = {}
local activeOverrideInterpolants = {}

function Interpolate(RamkaScheduler, instance, properties, lifetime: number?, easeFunction: func?, constructorParam: ConstructorParam?)
    local activeRamka
    local elasped = 0
    local lifetime = lifetime or 1
    local link
    link = {
        onComplete = function() end,
        onBreak = function() end,
        Cancel = function()
            if activeRamka then
                if not (elasped/lifetime >= 1) then                    
                    if type(link.onBreak) == "function" then
                        task.spawn(link.onBreak)
                    end
                end

                if type(link._onBreak) == "function" then
                    task.spawn(link._onBreak)
                end

                activeRamka.Cancel()
            end
        end
    }

    local activeInterpolant = instance

    local defaultProperties = {} do -- confirm validity of properties
        for propName, propTarget in properties do
            if instance:IsA("Model") and typeof(propTarget) == "CFrame" then
                defaultProperties[propName] = instance:GetPivot()
            else
                local propValue = (instance :: any)[propName]

                if typeof(propTarget) ~= typeof(propValue) then
                    error(
                        ("bad property %s to Ramka.Interpolate (%s expected, got %s)"):format(
                        propName,
                        typeof(propValue),
                        typeof(propTarget)
                        ),
                        2
                    )
                else
                    if typeof(propValue) == "CFrame" then
                        defaultProperties[propName] = instance:GetPivot()
                    else
                        defaultProperties[propName] = propValue
                    end
                end
            end
        end     
    end
    
    activeOverrideInterpolants[activeInterpolant] = nil

    local indexNum do --automatically remove and change values if there is duplicate interpolater        
        if activeInterpolants[activeInterpolant] == nil then
            activeInterpolants[activeInterpolant] = {}
        end

        for i,independantProperties in activeInterpolants[activeInterpolant] do
            for propName, _ in independantProperties do
                if properties[propName] then
                    activeInterpolants[activeInterpolant][i][propName] = nil
                end
            end
        end
    
        table.insert(activeInterpolants[activeInterpolant], properties)
        indexNum = #activeInterpolants[activeInterpolant]
    end

    local function endFunction(executor)
        executor.Cancel()

        if activeInterpolants[activeInterpolant] ~= nil then
            activeInterpolants[activeInterpolant][indexNum] = nil

            if #activeInterpolants[activeInterpolant] == 0 then
                activeInterpolants[activeInterpolant] = nil
            end
        end
    end

    activeRamka = RamkaScheduler:Construct(constructorParam):Heartbeat(function(delta, _, executor)
        elasped += delta

        if instance == nil or activeInterpolant == nil or activeInterpolants[activeInterpolant] == nil or activeInterpolants[activeInterpolant][indexNum] == nil or indexNum ~= #activeInterpolants[activeInterpolant] then
            if type(link.onBreak) == "function" then
                task.spawn(link.onBreak)
            end

            --internal use, mainly for InterpolateModelPivot
            if type(link._onBreak) == "function" then
                task.spawn(link._onBreak)
            end

            endFunction(executor)
            return
        end
        
        local interpolant do
            interpolant = math.clamp(elasped/lifetime,0,1)
            if easeFunction then
                interpolant = easeFunction(interpolant)
            end
        end

        for propName, propTarget in properties do
            if instance:IsA("Model") and typeof(propTarget) == "CFrame" then
                instance:PivotTo(lerp(defaultProperties[propName], propTarget, interpolant))
            else          
                local propValue = (instance :: any)[propName]

                if typeof(propTarget) == typeof(propValue) and defaultProperties[propName] ~= nil then
                    if typeof(propValue) == "CFrame" then
                        instance:PivotTo(lerp(defaultProperties[propName], propTarget, interpolant))
                    else
                        instance[propName] = lerp(defaultProperties[propName], propTarget, interpolant)
                    end
                end
            end
        end

        if elasped/lifetime >= 1 then
            if type(link.onComplete) == "function" then
                task.spawn(link.onComplete)
            end

            if type(link._onComplete) == "function" then
                task.spawn(link._onComplete)
            end

            endFunction(executor)
        end
    end)

    return link
end

function InterpolateOverride(RamkaScheduler, instance, properties, lifetime: number?, easeFunction: func?, constructorParam: ConstructorParam?)
    local elasped = 0
    local lifetime = lifetime or 1
    local link
    local activeInterpolant = instance

    link = {
        onComplete = function() end,
        onBreak = function() end,
        Cancel = function()
            if activeOverrideInterpolants[activeInterpolant].activeRamka then
                if not (elasped/lifetime >= 1) then                    
                    if type(link.onBreak) == "function" then
                        task.spawn(link.onBreak)
                    end
                end

                if type(link._onBreak) == "function" then
                    task.spawn(link._onBreak)
                end

                activeOverrideInterpolants[activeInterpolant].activeRamka.Cancel()
            end
        end
    }

    local defaultProperties = {} do -- confirm validity of properties
        for propName, propTarget in properties do
            if instance:IsA("Model") and typeof(propTarget) == "CFrame" then
                defaultProperties[propName] = instance:GetPivot()
            else
                local propValue = (instance :: any)[propName]

                if typeof(propTarget) ~= typeof(propValue) then
                    error(
                        ("bad property %s to Ramka.Interpolate (%s expected, got %s)"):format(
                        propName,
                        typeof(propValue),
                        typeof(propTarget)
                        ),
                        2
                    )
                else
                    if typeof(propValue) == "CFrame" then
                        defaultProperties[propName] = instance:GetPivot()
                    else
                        defaultProperties[propName] = propValue
                    end
                end
            end
        end     
    end
    
    activeInterpolants[activeInterpolant]  = nil
    if activeOverrideInterpolants[activeInterpolant] then
        activeOverrideInterpolants[activeInterpolant].activeRamka.Cancel()
    end

    activeOverrideInterpolants[activeInterpolant] = {}

    local function endFunction(executor)
        executor.Cancel()
        activeOverrideInterpolants[activeInterpolant] = nil
    end

    activeOverrideInterpolants[activeInterpolant].activeRamka = RamkaScheduler:Construct(constructorParam):Heartbeat(function(delta, _, executor)
        elasped += delta

        if instance == nil or activeInterpolant == nil or activeOverrideInterpolants[activeInterpolant] == nil then
            if type(link.onBreak) == "function" then
                task.spawn(link.onBreak)
            end

            --internal use, mainly for InterpolateModelPivot
            if type(link._onBreak) == "function" then
                task.spawn(link._onBreak)
            end

            endFunction(executor)
            return
        end
        
        local interpolant do
            interpolant = math.clamp(elasped/lifetime,0,1)
            if easeFunction then
                interpolant = easeFunction(interpolant)
            end
        end

        for propName, propTarget in properties do
            if instance:IsA("Model") and typeof(propTarget) == "CFrame" then
                instance:PivotTo(lerp(defaultProperties[propName], propTarget, interpolant))
            else          
                local propValue = (instance :: any)[propName]

                if typeof(propTarget) == typeof(propValue) and defaultProperties[propName] ~= nil then
                    if typeof(propValue) == "CFrame" then
                        instance:PivotTo(lerp(defaultProperties[propName], propTarget, interpolant))
                    else
                        instance[propName] = lerp(defaultProperties[propName], propTarget, interpolant)
                    end
                end
            end
        end

        if elasped/lifetime >= 1 then
            if type(link.onComplete) == "function" then
                task.spawn(link.onComplete)
            end

            if type(link._onComplete) == "function" then
                task.spawn(link._onComplete)
            end

            endFunction(executor)
        end
    end)

    return link
end



function Keyframe(RamkaScheduler, loopTime: number, keyframes: {[number]: func}, keyframeParams: KeyframeLoop?, constructorParam: KeyframeLoop?)
    local activeRamka
    local isRunning = true

    local Params, min, max = {} do
        if type(keyframeParams) == "table" then
            Params = keyframeParams
        end

        Params.reverse = keyframeParams and keyframeParams.reverse or false
        Params.looped = keyframeParams and keyframeParams.looped or false

        for i,_ in keyframes do
            if min == nil or i < min then
                min = i
            end

            if max == nil or i > max then
                max = i
            end
        end
    end

    local pos, neg do            
        pos = function()
            local elasped = 0
            local lastIndex = nil
            local Bind = Instance.new("BindableEvent")

            if isRunning == false then return end

            if activeRamka then
                activeRamka.Cancel()
            end

            activeRamka = RamkaScheduler:Construct(constructorParam):Heartbeat(function(delta, _, executor)
                elasped += delta
                local normalizedTime = math.clamp(elasped/loopTime,0,1)
                local index = math.floor(min + (max - min) * normalizedTime)

                if lastIndex ~= index and keyframes[index] then
                    keyframes[index]()
                    lastIndex = index
                end

                if normalizedTime == 1 then
                    Bind:Fire()
                end
            end)
            
            Bind.Event:Wait()
            Bind:Destroy()
        end

        neg = function()
            local elasped = loopTime
            local lastIndex = max
            local Bind = Instance.new("BindableEvent")

            if isRunning == false then return end

            if activeRamka then
                activeRamka.Cancel()
            end

            activeRamka = RamkaScheduler:Construct(constructorParam):Heartbeat(function(delta, _, executor)
                elasped -= delta
                local normalizedTime = math.clamp(elasped/loopTime,0,1)
                local index = math.ceil(min + (max - min) * normalizedTime)

                if lastIndex ~= index and keyframes[index] and index ~= min then
                    keyframes[index]()
                    lastIndex = index
                end

                if normalizedTime == 0 then
                    Bind:Fire()
                end
            end)

            Bind.Event:Wait()
            Bind:Destroy()
        end
    end

    task.spawn(function()
        if Params.looped then
            if Params.reverse then
                local function loopFunc()
                    pos()
                    neg()
                    loopFunc()
                end

                loopFunc()
            else
                local function loopFunc()
                    pos()
                    loopFunc()
                end

                loopFunc()
            end
        else
            if Params.reverse then
                pos()
                neg()
            else
                pos()
            end
        end
    end)

    return {
        Cancel = function()
            isRunning = false
            if activeRamka then                    
                activeRamka.Cancel()
            end
        end
    }
end

function Animate.Get(RamkaScheduler)
    return {
        --[[
            Iterpolates properties of instance given a time (speed) and option easeFunction

            *Optional easeFunction expects an input (x: number) and an output (x: number)
            * Input value will range from 0 - 1, output will not clamped by the same range
        ]]
        Interpolate = function(instance, properties, lifetime: number?, easeFunction: func?, constructorParam: ConstructorParam?)
            return Interpolate(RamkaScheduler, instance, properties, lifetime, easeFunction, constructorParam)
        end,

        --Same as Interpolate, however if there is interpolate already running it will override it
        InterpolateWithPriority = function(instance, properties, lifetime: number?, easeFunction: func?, constructorParam: ConstructorParam?)
            return InterpolateOverride(RamkaScheduler, instance, properties, lifetime, easeFunction, constructorParam)
        end,

        InterpolateModelPivot = function(model, endPivot, lifetime: number?, easeFunction: func?, constructorParam: ConstructorParam?)
            -- local CFrameValue = Instance.new("CFrameValue")
            -- CFrameValue.Value = startPivot

            -- local InterpolateData = InterpolateOverride(RamkaScheduler, CFrameValue, {Value = endPivot}, lifetime, easeFunction, constructorParam)
            -- local finalCFrame = CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
            --     model:PivotTo(CFrameValue.Value)
            -- end)

            -- local function Break()
            --     finalCFrame:Disconnect()
            --     CFrameValue:Destroy()
            -- end
            
            -- InterpolateData._onBreak = Break
            -- InterpolateData._onComplete = Break

            return InterpolateOverride(RamkaScheduler, model, {CFrame = endPivot}, lifetime, easeFunction, constructorParam)
        end,

        --[[
            Keyframe indecies are represented as whole numbers from any range

            Edge case: If looped is only setting enabled there will be no delay transitioning between 
            the last back to the first keyframe, in this case you may need to add an extra blank keyframe
        ]]
        Keyframe = function(loopTime: number, keyframes: {[number]: func}, keyframeParams: KeyframeLoop?, constructorParam: KeyframeLoop?)
            return Keyframe(RamkaScheduler, loopTime, keyframes, keyframeParams, constructorParam)
        end
    }
end

return Animate