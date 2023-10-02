local Tasks = {}

local function __assert(value, errorMessage: string?)
    if (value ~= true) then
        error(errorMessage)
    end
end

local function __assertWarn(value, errorMessage: string?,ignoreWarns: boolean?)
    if (value ~= true) and ignoreWarns ~= true then
        warn(errorMessage)
        return true
    end
end

local function getIdentifier(identifier: string?,ignoreWarns)
    local found = table.find(Tasks,identifier)
    if found then
        __assertWarn(found ~= nil,string.format("[%s] has already exists and was renamed to [%s].",identifier,identifier),ignoreWarns)
        return identifier
    elseif identifier == nil then
        -- local newName = string.format("Plan_Number|%d|",World.getRandomID())
        -- return newName
        warn("Unknown schedule identifier")
    end
    return identifier
end


local Plan = {}
Plan.__index = Plan

    Plan.__assert = __assert
    Plan.__assertWarn = __assertWarn

    function Plan._getall()
        return Tasks
    end

    function Plan.new(Scheduler, task, frameStep, name, ignoreWarns: boolean?, ...)
        __assert(type(task) == "function", "Task needs to be a function")
        __assert(frameStep == "Heartbeat" or frameStep == "RenderStepped" or frameStep == "Stepped","frameStep needs to be a RunService event [Heartbeat, Stepped, RenderStepped]")
        __assert(name ~= nil,"Plan name cannot be nil")
        __assert(Tasks[name] == nil ,name.." is already a pre-existing Plan")

        local self = setmetatable({
            task = task,
            frameStep = frameStep,
            identifier = name,
            fps = 60,

            Scheduler = Scheduler,
            taskName = "Async",
            taskId = nil,
            _data = {...},
            ignoreWarns = ignoreWarns,

            storage = {
                delta = 0,
                storeFPS = 0,
            }
        },Plan)

        Tasks[self.identifier] = self
        return self, self.identifier
    end

    function Plan:Get()
        return self
    end

    function Plan:SetTask(taskName,taskId: number?)
        __assert(taskName == "Async" or taskName == "Sync" or taskName == "Float",taskName.." is not an accepted task.")
        if __assertWarn(taskName == self.taskName,taskName.." has already been set.",self.ignoreWarns) then return end

        if taskName == "Sync" then
            __assert(type(taskId) == "number" and math.floor(taskId) == taskId and math.ceil(taskId) == taskId,"taskId must be an integer")
            __assert(self.Scheduler.Calender.Sync[taskId] == nil,string.format("%s is unable to replace Calender Sync index %d.",self.identifier,taskId))
            self.Scheduler.Calender[self.taskName][self.frameStep][self.identifier] = nil
            self.Scheduler.Calender.Sync[self.frameStep][taskId] = self
            self.taskId = taskId
        else
            if self.taskName == "Sync" then
                self.Scheduler.Calender.Sync[self.frameStep][self.taskId] = nil
            else
                self.Scheduler.Calender[self.taskName][self.frameStep][self.identifier] = nil
            end

            self.Scheduler.Calender[taskName][self.frameStep][self.identifier] = self
            self.taskId = nil
        end

        self.taskName = taskName
        return self
    end

    function Plan:SetTag(identifier: string)
        __assert(type(identifier) == "string","identifier must be a string")
        identifier = getIdentifier(nil,self.Scheduler.ignoreWarns)
        Tasks[self.identifier] = nil
        Tasks[identifier] = self
        self.Scheduler.Calender[self.taskName][self.frameStep][self.taskName == "Sync" and self.taskId or self.identifier] = nil
        self.Scheduler.Calender[self.taskName][self.frameStep][self.taskName == "Sync" and self.taskId or identifier] = self
        self.identifier = identifier
        return self
    end

    function Plan:Cancel()
        Tasks[self.identifier] = nil
        self.Scheduler.Calender[self.taskName][self.frameStep][self.taskName == "Sync" and self.taskId or self.identifier] = nil
    end

    function Plan:SetFps(fps: number)
        __assert(type(fps) == "number","fps must be a number")
        __assert(fps > 0 and fps <= 60 and math.floor(fps) + math.ceil(fps) == fps * 2,"fps must be an integer from 1-60")
        Tasks[self.identifier].fps = fps
        return self
    end

    function Plan:SetFpsByDistance(Origin: Vector3, Object: Vector3, fpsTable: {}, distanceTable: {})
        __assert(typeof(Origin) == "Vector3","Origin must be a Vector3.")
        __assert(typeof(Object) == "Vector3","Object must be a Vector3.")
        __assert(typeof(fpsTable) == "table" and #fpsTable == 2,"fpsTable must be a table with a length of 2.")
        __assert(type(fpsTable[1]) == "number" and fpsTable[1] > 0 and fpsTable[1] <= 60 and math.floor(fpsTable[1]) + math.ceil(fpsTable[1]) == fpsTable[1] * 2,"fpsTable index 1 must be a integer from 1-60.")
        __assert(type(fpsTable[2]) == "number" and fpsTable[2] > 0 and fpsTable[2] <= 60 and math.floor(fpsTable[2]) + math.ceil(fpsTable[2]) == fpsTable[2] * 2,"fpsTable index 2 must be a integer from 1-60.")
        __assert(typeof(distanceTable) == "table" and #distanceTable == 2,"distanceTable must be a table with a length of 2.")
        __assert(type(distanceTable[1]) == "number","distanceTable index 1 must be a number.")
        __assert(type(distanceTable[2]) == "number","distanceTable index 2 must be a number.")

        local distanceFromOrigin = (Origin - Object).Magnitude - distanceTable[1]
        local m = (fpsTable[2]-fpsTable[1])/(distanceTable[2]-distanceTable[1])
        local int = fpsTable[1] - (m * distanceTable[1])
        local invert = -((m*distanceFromOrigin) + int) + (fpsTable[2]-fpsTable[1])
        local fps = math.round(math.clamp(invert,fpsTable[1],fpsTable[2]))
        self:SetFps(fps)
        return self
    end

    function Plan:IgnoreWarns(boolean: boolean?)
        self.ignoreWarns = boolean or true
        return self
    end


return table.freeze(Plan)