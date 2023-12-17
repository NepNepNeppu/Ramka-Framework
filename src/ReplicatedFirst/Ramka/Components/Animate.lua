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
    end
    return a:Lerp(b,t)
end

local Animate = {}
local activeInterpolants = {}

function Interpolate(RamkaScheduler, instance, properties, lifetime: number?, easeFunction: func?, constructorParam: ConstructorParam?)
    local elasped = 0
    local lifetime = lifetime or 1
    local link = {
        onComplete = function() end,
        onBreak = function() end
    }

    local defaultProperties = {} do -- confirm validity of properties
        for propName, propTarget in properties do
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
                defaultProperties[propName] = propValue
            end
        end     
    end

    local indexNum do --automatically remove and change values if there is duplicate interpolater        
        if activeInterpolants[instance] == nil then
            activeInterpolants[instance] = {}
        end

        for i,independantProperties in activeInterpolants[instance] do
            for propName, _ in independantProperties do
                if properties[propName] then
                    activeInterpolants[instance][i][propName] = nil
                end
            end
        end
    
        table.insert(activeInterpolants[instance], properties)
        indexNum = #activeInterpolants[instance]
    end

    local function endFunction(executor)
        executor.Cancel()

        if activeInterpolants[instance] ~= nil then
            activeInterpolants[instance][indexNum] = nil

            if #activeInterpolants[instance] == 0 then
                activeInterpolants[instance] = nil
            end
        end
    end

    RamkaScheduler:Construct(constructorParam):Heartbeat(function(delta, _, executor)
        elasped += delta

        if instance == nil or instance.Parent == nil or activeInterpolants[instance] == nil or activeInterpolants[instance][indexNum] == nil then
            if type(link.onBreak) == "function" then
                task.spawn(link.onBreak)
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

        for propName, propTarget in activeInterpolants[instance][indexNum] do
            local propValue = (instance :: any)[propName]

            if typeof(propTarget) == typeof(propValue) then
                instance[propName] = lerp(defaultProperties[propName], propTarget, interpolant)
            end
        end

        if elasped/lifetime >= 1 then
            if type(link.onComplete) == "function" then
                task.spawn(link.onComplete)
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