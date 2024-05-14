type func = typeof(function() end)

local frameLoops = {"RenderStepped","Stepped","Heartbeat"}

local Constructor = require(script.Constructor)

local HttpService = game:GetService("HttpService")

if game:GetService("RunService"):IsServer() then
    table.remove(frameLoops,1)
end

type scheduler = {
    clientSync: boolean,
    preservePipeline: boolean
}

type line = {
    pipeline: string?,
    framerate: number?,
    name: string
}

local Scheduler = {}
Scheduler.__index = Scheduler

     --[=[
        @return Scheduler
        Creates a new Scheduler. (Called once via Ramka on the Server and Client)
        
        Scheduler.new({
            clientSync: boolean, 
            preservePipeline: boolean
        })

        clientSync: Roughly keeps players in sync
        preservePipeline: Pipeline freezes time and will resume at the same
    ]=]
    function Scheduler.new(params: scheduler)
        local self = setmetatable({
            pipelines = {},
            timeManagement = {
                
            },

            clientSync = params.clientSync or false,
            preservePipeline = params.preservePipeline or false
        },Scheduler)

        return self
    end

    function Scheduler:assert(value, errormessage)
        if not value then
            error(errormessage)
        end
        return value
    end

    function Scheduler:Init()
        self:_createPipeline("_default")
        debug.setmemorycategory("Ramka Scheduler ".. (game:GetService("RunService"):IsClient() and "Client" or "Server"))

        for i,v in frameLoops do
            game:GetService("RunService")[v]:Connect(function(time, deltaTime)
                local usingSync = if self.clientSync then game.Workspace:GetServerTimeNow() else game.Workspace.DistributedGameTime
                local elaspedTime = if self.clientSync then usingSync elseif v == "Stepped" then time else deltaTime
                local deltaTime = if v == "Stepped" then deltaTime else time
                
                for pipelineName, pipelineData in self.pipelines do
                    if pipelineData.isActive then
                        do -- If a timeline is frozen, preserve elapsed at the time it was frozen       
                            if pipelineData.preservePipeline then
                                if pipelineData.timeCapsule.store[v] == nil then
                                    pipelineData.timeCapsule.store[v] = {
                                        elapsed = 0,
                                        delta = 0,
                                    }
                                end

                                pipelineData.timeCapsule.store[v].delta = (deltaTime * pipelineData.timeCapsule.scalar)
                                pipelineData.timeCapsule.store[v].elapsed += (deltaTime * pipelineData.timeCapsule.scalar)
                            else
                                pipelineData.timeCapsule.store = {}
                            end
                        end

                        -- each function already has their own elaspedTime stored
                        -- local elaspedTime = if pipelineData.preservePipeline then pipelineData.timeCapsule.store[v].elapsed else elaspedTime
                        local deltaTime = if pipelineData.preservePipeline then pipelineData.timeCapsule.store[v].delta else deltaTime

                        for name, details in pipelineData.executors do -- Added Functions
                            if details.framestep == v and details.isActive then -- Make sure function is running in the right framestep
                                details.frameManager.elapsed += deltaTime
                                details.frameManager.frames += deltaTime

                                if details.framerate == 60 then
                                    details.executor(details.frameManager.elapsed, details.frameManager.frames, details)
                                    details.frameManager.elapsed = 0
                                else -- precise framerate management
                                    local difference = details.frameManager.elapsed - (1/details.framerate)
                                    if difference >= -1/100 then
                                        details.executor(details.frameManager.elapsed, details.frameManager.frames, details)
                                        details.frameManager.elapsed = 0
                                    end
                                end
                            end
                        end                        
                    end
                end
            end)
        end
    end

-- Scheduling
    function Scheduler:Construct(params: line)
        if type(params) ~= "table" then
            params = {}
        end

        return Constructor.new(self, {
            framerate = params.framerate or 60,
            pipeline = params.pipeline or "_default",
            name = params.name or HttpService:GenerateGUID(false)
        })
    end

-- Pipeline management
    function Scheduler:_isPipeline(pipelineName: string)
        self:assert(type(pipelineName) == "string","pipelineName must be a string")
        if self.pipelines[pipelineName] then
            return self.pipelines[pipelineName]
        end
    end

    function Scheduler:_createPipeline(pipelineName: string, preservePipeline: boolean?)
        self:assert(self:_isPipeline(pipelineName) == nil,pipelineName.." is already a pre-existing pipeline")

        self.pipelines[pipelineName] = {
            isActive = true,
            preservePipeline = if preservePipeline then preservePipeline else self.preservePipeline,
            timeCapsule = {
                store = {},
                scalar = 1,
            },
            executors = {}
        }
    end

    function Scheduler:_insertIntoPipeline(system, pipelineName: string)
        if self:_isPipeline(pipelineName) == nil then
            self:_createPipeline(pipelineName)
        end

        if system.name then
            if self.pipelines[pipelineName][system.name] == nil then
                self.pipelines[pipelineName].executors[system.name] = system
            else
                error(system.name .. " in pipeline " .. pipelineName .. " already exists")
            end
        else
            table.insert(self.pipelines[pipelineName],system)
        end

        return self.pipelines[pipelineName].executors[system.name]
    end

    function Scheduler:DestroyPipeline(pipelineName: string)
        self:assert(self:_isPipeline(pipelineName),pipelineName.." does not exist")
        self:assert(pipelineName == "_default","pipelineName cannot be named _default")

        self.pipelines[pipelineName] = nil
    end

    function Scheduler:FreezePipeline(pipelineName: string)
        self:assert(self:_isPipeline(pipelineName),pipelineName.." does not exist")

        self.pipelines[pipelineName].isActive = false
    end
    
    function Scheduler:UnfreezePipeline(pipelineName: string)
        self:assert(self:_isPipeline(pipelineName),pipelineName.." does not exist")
        
        self.pipelines[pipelineName].isActive = true
    end
    
    function Scheduler:SetPipelineSpeed(pipelineName: string, number: number)
        self:assert(self:_isPipeline(pipelineName),pipelineName.." does not exist")
        self:assert(typeof(number) == "number",("bad argument 2 (number expected, got %s)"):format(typeof(number)))

        self.pipelines[pipelineName].timeCapsule.scalar = number
    end

return Scheduler