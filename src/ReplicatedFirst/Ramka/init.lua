local Promise = require(game.ReplicatedFirst.Api.Class.Promise)
local BasePartService = require(game.ReplicatedFirst.Api.Services.BasePartService)

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

local tasks = {}
local components = {}
local hooks = {}

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
    Step: "Heartbeat" | "Stepped" | "RenderStepped",
    Update: func
}

type Schedule = {
    Name: string,
    Step: "Heartbeat" | "Stepped" | "RenderStepped",
    Update: func
}

local function DoesTaskExist(taskName: string): boolean
	local task: Task? = tasks[taskName]
	return task ~= nil
end

local function GetHook(Name: string, expectedType: string)
    local RemoteSignals = game.ReplicatedStorage.RemoteSignals

    if RemoteSignals:FindFirstChild(Name) == nil then
        error(Name.. " Hook does not exists.")
        return false, nil
    end

    if RemoteSignals:FindFirstChild(Name).ClassName ~= expectedType then
        error(string.format("%s is a %s not a %s",Name,RemoteSignals:FindFirstChild(Name).ClassName,expectedType))
        return false, nil
    end

    return true, RemoteSignals:FindFirstChild(Name)
end

local Ramka = {}
RamkaScheduler = require(script.ramkaScheduler).new(true)

    --[=[
        Match is a rule that the Module(s) can follow
        ex: Handler$ means the Module will end with Handler

        Requires all the modules that are children of the given parent.
    ]=]
    function Ramka.AddTasks(Files: Folder,Match: string?)
        local addedTasks = {}
        for _, v in Files:GetChildren() do
            if not v:IsA("ModuleScript") and (Match == nil or v.Name:match(Match)) then
                continue
            end
            table.insert(addedTasks, require(v))
        end
        return addedTasks
    end

    --[=[
        Match is a rule that the Module(s) can follow
        ex: Handler$ means the Module will end with Handler

        Requires all the modules that are descendants of the given parent.
    ]=]
    function Ramka.AddTasksDeep(Files: Folder,Match: string?)
        local addedTasks = {}
        for _, v in Files:GetDescendants() do
            if not v:IsA("ModuleScript") and (Match == nil or v.Name:match(Match)) then
                continue
            end
            table.insert(addedTasks, require(v))
        end
        return addedTasks
    end

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
        return task
    end

    --[=[
        Gets the task by name. Throws an error if the task
        is not found.
    ]=]
    function Ramka.GetTask(taskName: string): Task
        local task = tasks[taskName]
        if task then
            return task
        end
        assert(started, "Cannot call GetTask until Ramka has been started")
        assert(type(taskName) == "string", `TaskName must be a string; got {type(taskName)}`)
        error(`Could not find task "{taskName}". Check to verify a task with this name exists.`, 2)
    end

    --[=[
        Creates a new Schedule that will begin running as early as RamkaStart.
        ```lua
        -- Create a schedule
        local MySchedule = Ramka.Construct {
            Name = "MyTask",
            Step = "Heartbeat",
            Update = function(elapsed, delta, plan)
                print("Update")
            end)
        }
        ```
    ]=]
    function Ramka.Construct(scheduleDef: ScheduleDef): Schedule
        return RamkaScheduler:Arrange(scheduleDef.Step,scheduleDef.Update,scheduleDef.Name)
    end

    function Ramka.GetApi()
        return {
            Class = game.ReplicatedFirst.Api.Class,
            Service = game.ReplicatedFirst.Api.Services,
        }
    end

    function Ramka.GetService(name: string)
        return Ramka.GetApi().Service[name]
    end

    function Ramka.GetClass(name: string)
        return Ramka.GetApi().Class[name]
    end

    function Ramka.HookClient(Name: string,Player: Player,...)
        local verifiedHook, Hook: RemoteEvent = GetHook(Name)
        if verifiedHook then
            Hook:FireClient(Player,...)
        end
    end

    function Ramka.HookAllClients(Name: string,...)
        local verifiedHook, Hook: RemoteEvent = GetHook(Name, "RemoteEvent")
        if verifiedHook then
            Hook:FireAllClients(...)
        end
    end

    function Ramka.HookServer(Name: string,...)
        local verifiedHook, Hook: RemoteEvent = GetHook(Name, "RemoteEvent")
        if verifiedHook then
            Hook:FireServer(...)
        end
    end

    function Ramka.HookInvokeClient(Name: string,Player: Player,...)
        local verifiedHook, Hook: RemoteFunction = GetHook(Name, "RemoteFunction")
        if verifiedHook then
            return Hook:InvokeClient(Player,...)
        end
    end

    function Ramka.HookInvokeServer(Name: string,...)
        local verifiedHook, Hook: RemoteFunction = GetHook(Name, "RemoteFunction")
        if verifiedHook then
            return Hook:InvokeServer(...)
        end
    end

    --[=[
    Creates a new Hook.

    :::caution
    Hook must be created on the server.
    :::
    ]=]
    function Ramka.CreateHook(Name: string,type: "RemoteEvent" | "RemoteFunction"?)
        if game:GetService("RunService"):IsClient() then
            error("Unable to create hook '"..Name.."'. 'CreateHook' must be called on the server.")
            return
        end

        if hooks[Name] then
            error(Name.. " Hook already exists.")
            return
        else
            local RemoteSignals = game.ReplicatedStorage.RemoteSignals
            hooks[Name] = BasePartService.Create(type or "RemoteFunction",Name,RemoteSignals)
            return hooks[Name]
        end
    end

    function Ramka.SetComponent(key,name: string?)
        components[name or key.Name] = key
    end

    function Ramka.GetComponent(name: string?)
        return components[name]
    end

    function Ramka.GetComponents()
        return components
    end

    -- Read only
    function Ramka.GetTasks()
        return table.freeze(table.clone(tasks))
    end

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

        if game:GetService("RunService"):IsServer() then
            BasePartService.Create("Folder","RemoteSignals",game.ReplicatedStorage)
        end
    
        return Promise.new(function(resolve)
            -- Init:
            local promisesStartTasks = {}
    
            for _, ramkatask in tasks do
                if type(ramkatask.RamkaInit) == "function" then
                    table.insert(
                        promisesStartTasks,
                        Promise.new(function(r)
                            debug.setmemorycategory(ramkatask.Name)
                            ramkatask:RamkaInit()
                            r()
                        end)
                    )
                end
            end
    
            resolve(Promise.all(promisesStartTasks))
        end):andThen(function()
            -- Start:

            for _, ramkatask in tasks do
                if type(ramkatask.RamkaStart) == "function" then
                    task.spawn(function()
                        debug.setmemorycategory(ramkatask.Name)
                        ramkatask:RamkaStart()
                    end)
                end
            end
    
            startedComplete = true
            onStartedComplete:Fire()
            RamkaScheduler:Init()
    
            task.defer(function()
                onStartedComplete:Destroy()
            end)
        end)
    end

    --[=[
	@return Promise
	Returns a promise that is resolved once Ramka has started. This is useful
	for any code that needs to tie into Ramka tasks but is not the script
	that called `Start`.
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

return Ramka