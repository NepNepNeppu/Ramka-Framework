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

        for i,v in frameLoops do
            game:GetService("RunService")[v]:Connect(function(time, deltaTime)
                local usingSync = if self.clientSync then game.Workspace:GetServerTimeNow() else game.Workspace.DistributedGameTime
                local elaspedTime = if self.clientSync then usingSync elseif v == "Stepped" then time else deltaTime
                local deltaTime = if v == "Stepped" then deltaTime else time
                
                for pipelineName, pipelineData in self.pipelines do
                    if pipelineData.working then
                        if pipelineData.timeAccumulator[v] == nil and pipelineData.preservePipeline then                            
                            pipelineData.timeAccumulator[v] = 0
                        end
                        
                        if pipelineData.preservePipeline then
                            pipelineData.timeAccumulator[v] += deltaTime
                        end

                        local timeline = if pipelineData.preservePipeline then pipelineData.timeAccumulator[v] else elaspedTime

                        for name, details in pipelineData.executors do
                            if details.framestep == v then                     
                                details.executor(deltaTime * pipelineData.timeDisplacement, timeline * pipelineData.timeDisplacement, details)
                            end
                        end                        
                    end
                end
            end)
        end
    end

-- Scheduling
    function Scheduler:Construct(params: line)
        -- self:assert(params.name == nil or type(params.name) == "string","name cannot be nil and must be a string")
        local params do
            if type(params) ~= "table" then
                params = {}
            end
        end

        params.framerate = params.framerate or 60
        params.pipeline = params.pipeline or "_default"
        params.name = params.name or HttpService:GenerateGUID(false)

        return Constructor.new(self, params)
    end

-- Pipeline management
    function Scheduler:_isPipeline(pipelineName: string)
        self:assert(type(pipelineName) == "string","pipelineName must be a string")
        if self.pipelines[pipelineName] then
            return self.pipelines[pipelineName]
        end
    end

    function Scheduler:_createPipeline(pipelineName: string, isAsync: boolean?, preservePipeline: boolean?)
        self:assert(self:_isPipeline(pipelineName) == nil,pipelineName.." is already a pre-existing pipeline")

        self.pipelines[pipelineName] = {
            working = true,
            isAsync = isAsync or false,
            preservePipeline = if preservePipeline then preservePipeline else self.preservePipeline,
            timeAccumulator = {},

            timeDisplacement = 1,
            timeElapsed = 0,

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

        self.pipelines[pipelineName].working = false
    end
    
    function Scheduler:UnfreezePipeline(pipelineName: string)
        self:assert(self:_isPipeline(pipelineName),pipelineName.." does not exist")
        
        self.pipelines[pipelineName].working = true
    end
    
    function Scheduler:SetPipelineSpeed(pipelineName: string, number: number)
        self:assert(self:_isPipeline(pipelineName),pipelineName.." does not exist")
        self:assert(type(number) == "number","number must be a number") -- how else do I describe this

        self.pipelines[pipelineName].timeDisplacement = true
    end

return Scheduler