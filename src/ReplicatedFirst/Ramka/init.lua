local Promise = require(game.ReplicatedFirst.Api.Class.Promise)

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")
local tasks = {}

type func = typeof(function() end)
type TaskDef = {
	Name: string,
	[any]: any,
}

type Task = {
	Name: string,
	[any]: any,
}

type ScheduleDef = {
	Name: string,
    Pipeline: string?,
    Step: "Heartbeat" | "Stepped" | "RenderStepped",
    Update: func
}

type Schedule = {
    Name: string,
    Pipeline: string?,
    Step: "Heartbeat" | "Stepped" | "RenderStepped",
    Update: func
}

type ConstructorParam = {
    pipeline: string?,
    framerate: number?,
    name: string
}

type KeyframeLoop = {
    reverse: boolean?,
    looped: boolean?
}

local function formatArg(argNum: number, fnName: string, expectedType: string, value: any, canBeNil: boolean?)
    if canBeNil and value == nil then return end
    if not expectedType:find(typeof(value)) then
        return ("bad argument #%d to %s (%s expected, got %s)"):format(argNum, fnName, expectedType, typeof(value))
    end
end

local function formatSpecArg(argNum: number, fnName: string, expectedType: string, value: any)
    if not value or value.ClassName ~= expectedType then
        return ("bad argument #%d to %s (%s expected, got %s)"):format(argNum, fnName, expectedType, if not value then "nil" else value.ClassName)
    end
end

local function DoesTaskExist(taskName: string): boolean
	local task: Task? = tasks[taskName]
	return task ~= nil
end

local function addModule(addedTasks, v)
    local success, result = pcall(function()
        return require(v)
    end)

    if success then
        table.insert(addedTasks, result)
    else
        warn(("%s ran into an error while being added to Ramka. (%s)"):format(v.Name, result))
    end
end

local RamkaScheduler = require(script.Scheduler).new({preservePipeline = true})

local Ramka = {}

--Creating/Getting Systems
    --[=[
        Creates a new Tasks.

        :::caution
        Tasks must be created _before_ calling `Ramka.Start()`.
        :::
        ```lua
        -- Create a task
        local MyTask = Ramka.CreateTask {
            Name = "MyTask",
        }

        function MyTask:RamkaStart()
            print("MyTask started")
        end

        function MyTask:RamkaInit()
            print("MyTask initialized")
        end
        ```
    ]=]
    function Ramka.CreateTask(taskDef: TaskDef): Task
        assert(type(taskDef) == "table", `Task must be a table; got {type(taskDef)}`)
        assert(type(taskDef.Name) == "string", `Task.Name must be a string; got {type(taskDef.Name)}`)
        assert(#taskDef.Name > 0, "Task.Name must be a non-empty string")
        assert(not DoesTaskExist(taskDef.Name), `Task {taskDef.Name} already exists`)
        local task = taskDef :: Task
        tasks[task.Name] = task
        return taskDef
    end

    --[=[
        Gets the task by name. Throws an error if the task
        is not found.

        :::caution
        GetTask must be called in RamkaStart or after RamkaInit
        :::
    ]=]
    function Ramka.GetTask(taskName: string): Task
        local currentTask = tasks[taskName]
        if currentTask then
            return currentTask
        end
        assert(started, "Cannot call GetTask until Ramka has been started")
        assert(type(taskName) == "string", `TaskName must be a string; got {type(taskName)}`)
        error(`Could not find task "{taskName}". Check to verify a task with this name exists.`, 2)
    end

--Loading the Systems into Ramka
    --[=[
        Match is a rule that the Module(s) can follow
        ex: Handler$ means the Module will end with Handler
        ex: Component means the Module name will have 'Component' in its nane

        Requires a specified module.
    ]=]
    function Ramka.AddTask(File: ModuleScript, Match: string?)
        local WrongFileType = formatSpecArg(1, "Ramka.AddTask", "ModuleScript", File) do
            if WrongFileType then warn(WrongFileType) return end
        end

        local WrongMatchType = formatArg(2, "Ramka.AddTask", "string", Match, true) do
            if WrongMatchType then warn(WrongMatchType) return end
        end
        
        if not File:IsA("ModuleScript") or (Match ~= nil and File.Name:match(Match) == nil) then

        else
            local addedTasks = {}
            addModule(addedTasks, File)
            return addedTasks[1]
        end
    end

    --[=[
        Match is a rule that the Module(s) can follow
        ex: Handler$ means the Module will end with Handler
        ex: Component means the Module name will have 'Component' in its nane

        Requires all the modules that are children of the given parent.
    ]=]
    function Ramka.AddTasks(Files: Folder, Match: string?)
        local WrongFileType = formatArg(1, "Ramka.AddTask", "Instance", Files) do
            if WrongFileType then warn(WrongFileType) return end
        end

        local WrongMatchType = formatArg(2, "Ramka.AddTask", "string", Match, true) do
            if WrongMatchType then warn(WrongMatchType) return end
        end

        local addedTasks = {}
        for _, v in Files:GetChildren() do
            if not v:IsA("ModuleScript") or (Match ~= nil and v.Name:match(Match) == nil) then
                continue
            end          
                         
            addModule(addedTasks, v)
        end
        return addedTasks
    end

    --[=[
        Match is a rule that the Module(s) can follow
        ex: Handler$ means the Module name will end with 'Handler'
        ex: Component means the Module name will have 'Component' in its nane

        Requires all the modules that are descendants of the given parent.
    ]=]
    function Ramka.AddTasksDeep(Files: Folder, Match: string?)
        local WrongFileType = formatArg(1, "Ramka.AddTask", "Instance", Files) do
            if WrongFileType then warn(WrongFileType) return end
        end

        local WrongMatchType = formatArg(2, "Ramka.AddTask", "string", Match, true) do
            if WrongMatchType then warn(WrongMatchType) return end
        end

        local addedTasks = {}
        for _, v in Files:GetDescendants() do
            if not v:IsA("ModuleScript") or (Match ~= nil and v.Name:match(Match) == nil) then
                continue
            end  

            addModule(addedTasks, v)
        end
        return addedTasks
    end

--Core
    --[=[
        @return Promise
        Starts Ramka. Should only be called once per client.
        ```lua
        Ramka.Start():andThen(function()
            print("Ramka started!")
        end):catch(warn)
        ```
    ]=]
    function Ramka.Start()
        if started then
            return Promise.reject("Ramka already started")
        end
    
        started = true

        debug.setmemorycategory("RAMKA ".. (game:GetService("RunService"):IsClient() and "CLIENT" or "SERVER"))

        return Promise.new(function(resolve)
            -- Init:
            local promisesStartTasks = {}
    
            for _, ramkatask in tasks do
                if ramkatask.RamkaInit and type(ramkatask.RamkaInit) == "function" then
                    table.insert(
                        promisesStartTasks,
                        Promise.new(function(r)
                            debug.setmemorycategory("[Ramka Init] - "..ramkatask.Name)
                            ramkatask:RamkaInit()
                            r()
                        end)
                    )
                end
            end

            RamkaScheduler:Init()
    
            resolve(Promise.all(promisesStartTasks))
        end):andThen(function()
            -- Start:

            for _, ramkatask in tasks do
                if ramkatask.RamkaStart and type(ramkatask.RamkaStart) == "function" then
                    task.spawn(function()
                        debug.setmemorycategory("[Ramka Start] - "..ramkatask.Name)
                        ramkatask:RamkaStart()
                    end)
                end
            end
    
            startedComplete = true
            onStartedComplete:Fire()
    
            task.defer(function()
                onStartedComplete:Destroy()
            end)
        end)
    end

    --[=[
        @return Promise
        Returns a promise that is resolved once Ramka has started. This is useful
        for any code that needs to tie into Ramka tasks but is not the scripts
        that are called using `Start`.
	```lua
	Ramka.OnStart():andThen(function()
		local MyTask = Ramka.GetTask("MyTask")
		MyTask:DoSomething()
	end):catch(warn)
	```
    ]=]
    function Ramka.OnStart()
        if startedComplete then
            return Promise.resolve()
        else
            return Promise.fromEvent(onStartedComplete.Event)
        end
    end

--[=[
    Creates a new Schedule that will begin running as early as RamkaStart.
    ```lua
    -- Create a schedule
    local Pipeline_Name = Ramka.Construct {
        name = "MyTask",
        pipeline = "Pipeline_Name",
        framerate = 30,
    }
    Pipeline_Name:Stepped(function(delta, elapsed, executor)
        
    end)
    ```
]=]
function Ramka.Construct(constructorParam: ConstructorParam)
    return RamkaScheduler:Construct(constructorParam)
end

--Access to Scheduler functionality
Ramka.Scheduler = RamkaScheduler

--Access to internal OOP Classes
Ramka.Class = game.ReplicatedFirst.Api.Class

--Access to Services
Ramka.Services = game.ReplicatedFirst.Api.Services

--Access to custom Modules
Ramka.Embeded = game.ReplicatedFirst:FindFirstChild("Embeded")

--Built in benchmarking functions
Ramka.Benchmark = require(script.Components.Benchmark)

--Built in Networking, no different than using Remotes but has much quicker access to remotes and their methods
Ramka.Networking = require(script.Components.Networking)

--Built in animating functions using the scheduler
Ramka.Animate = require(script.Components.Animate).Get(RamkaScheduler)

--Built in Debug functions to help visualize development
Ramka.Debug = require(script.Components.Debug)

return Ramka