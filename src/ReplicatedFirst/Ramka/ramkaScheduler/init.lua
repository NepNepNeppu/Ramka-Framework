--[[---------------------------------------------------------------------
Scheduler:  A system that runs events planned by the Server or Client

        //Benefits\\
            Allows for a Plan to run at its own FPS [Locked from 1-60]
            Custom methods to allow for more diverse Control [SetFps, ReplaceTask, SetFpsByDistance, etc]
            Easy central control for all Plans
            Allows Plans to be scheduled with special ordering and run propertoes

        //Notes & Caveats\\
            Renderstepped cannot be scheduled by the server because the server runs by TPS not FPS, therefore you cant know when a frame updates or "renders"

Calender:   Stores 4 types tasks Async, Sync, Float
            Automatically initialized by a Scheduler

Plan:       A task scheduled by a Scheduler
            Created by calling the 'Arrange' method on a Scheduler
            Stored with a special Id, It can be defined or automatically generated

Tasks:    

        //Main\\
    Async:  Plans will run out of order (Default Behavior)
    Sync:   Runs before Async and runs Plans in order
            Determined by a number for order in a the sequence
    Float:  Plans that are inactive and uninitilaized or "floating"

    
API Summary:
1.
    Schedule.new(
        boolean: useClientSync
        identifier: string?
    )

    Returns 
        Schedule: {metatable}

    Creates a new Scheduler to run Plans
2.
    Schedule:Arrange(
        function: task,
        string <"Heartbeat","RenderStepped","Stepped">: frameStep,
        string: identifier
    )

    Returns
        metadata: {metatable}
        identifier: string

    Creates a new Plan to be ran by a Scheduler
3.
    Schedule:Settle(
        string: taskName,
        orderInSequence: number?,
    )

    Creates a new Plan to be ran by a Scheduler

    Note:
        orderInSequence is used only for 'Sync'

API for Plans:
1.
    Schedule:Cancel()

    Permanantly removes a new Plan from a Scheduler
2.
    Schedule:SetFps(
        number: fps,
    )

    Sets the Plan to a certain FPS
3.
    Schedule:SetFpsByDistance(
        Vector3: Origin,
        Vector3: Object,
        {[number]: number}: fpsTable,
        {[number]: number}: distanceTable,
    )

    Sets fps based on distance from an object given a set of parameters for range
]]-----------------------------------------------------------------------

--[[
    local new = scheduler.new(true)
    new:Init()

    new:Arrange("Heartbeat",function(time, deltaTime, plan, ...)
        plan:SetFps(60)
        print(...)
    end,...):SetFps(1)
]]

local _methods = require(script._methods)
__assert = _methods.__assert

local isClient = game:GetService("RunService"):IsClient()

local Schedulers = {}

local Scheduler = {}
Scheduler.__index = Scheduler

    function Scheduler.new(useClientSync: boolean?, identifier: string?, ignoreWarns: boolean?)
        local self = setmetatable({
            Calender = {
                Async = {}, 
                Sync = {}, 
                Float = {}, 
            },

            benchmark = {},
            benchmarkUpdated = Instance.new("BindableEvent"),

            identifier = identifier or (isClient and "Client" or "Server").." Scheduler",
            ignoreWarns = ignoreWarns or false,
            useClientSync = useClientSync or false,
        },Scheduler)

        local frameLoops = {"RenderStepped","Stepped","Heartbeat"}

        for calenderName,_ in self.Calender do
            for _,frameLoopName in frameLoops do
                self.Calender[calenderName][frameLoopName] = {}
            end
        end

        return self
    end

    function Scheduler.Get(identifier)
        return Schedulers[identifier]
    end

    function Scheduler:Init()
        __assert(Schedulers[self.identifier] == nil,string.format("Unable to initialize %s because it has already been scheduled",tostring(self.identifier)))
        Schedulers[self.identifier] = self

        local frameLoops = {"RenderStepped","Stepped","Heartbeat"}
        if not isClient then
            table.remove(frameLoops,1)
        end

        for _,index in {"Sync","Async"} do
            for _,nameLoop in frameLoops do
                Schedulers[self.identifier][index.."_"..nameLoop] = game:GetService("RunService")[nameLoop]:Connect(function(timeA,timeB)
                    local start,success,tasks = os.clock(),true,0
                    local usingSync = if self.useClientSync then game.Workspace:GetServerTimeNow() else (game.Workspace.DistributedGameTime)
                    local elaspedTime = if self.useClientSync then usingSync elseif nameLoop == "Stepped" then timeA else timeB
                    local deltaTime = if nameLoop == "Stepped" then timeB else timeA

                    for planIndex,plan in self.Calender[index][nameLoop] do
                        task.spawn(function()
                            tasks += 1
                            plan.storage.delta += deltaTime
                            plan.storage.storeFPS += 1
                            if plan.fps == 60 or plan.storage.storeFPS/60 >= 1/plan.fps then
                                local success, result = pcall(function()
                                    plan.task(elaspedTime,plan.storage.delta,plan,table.unpack(plan._data))
                                end)

                                if not success then
                                    if game:GetService("RunService"):IsStudio() then
                                        error(debug.traceback(result, 2))
                                    else
                                        warn(debug.traceback(result, 2))
                                    end
                                    success = false
                                    warn(plan.identifier .." removed from ".. self.identifier .. ".")
                                    self.Calender[index][nameLoop][planIndex] = nil
                                else
                                    plan.storage.delta = 0
                                    plan.storage.storeFPS = 0
                                end
                            end
                        end)
                    end

                    --benchmarking
                    if index == "Sync" then
                        self.benchmark[nameLoop:lower().."_running"] = {
                            ms = os.clock() - start,
                            status = success,
                            tasks = tasks,
                        }
                    else
                        local syncMark = self.benchmark[nameLoop:lower().."_running"]
                        self.benchmark[nameLoop:lower()] = {
                            ms = (syncMark and syncMark.ms or 0) + (os.clock() - start),
                            status = (syncMark and syncMark.status or true) and success,
                            tasks = (syncMark and syncMark.tasks or 0) + tasks,
                        }
                        self.benchmark[nameLoop:lower().."_running"] = nil
                        self.benchmarkUpdated:Fire(nameLoop:lower(),self.benchmark[nameLoop:lower()])
                    end
                end)
            end
        end
    end

    function Scheduler:IgnoreWarns(boolean: boolean?)
        self.ignoreWarns = boolean or true
    end

    function Scheduler:Arrange(frameStep, task, name, ...)
        local localSelf, identifier = _methods.new(self, task, frameStep, name, self.ignoreWarns, ...)
        self.Calender.Async[localSelf.frameStep][identifier] = localSelf
        return localSelf
    end

    function Scheduler:GetPlan(identifier)
        return _methods._getall()[identifier]
    end

return table.freeze(Scheduler)