local Constructor = {}
Constructor.__index = Constructor

type elapsed = number
type deltaTime = number
type render = typeof(function(deltaTime: number, elapsed: number, executer) 
    
end)

    function Constructor.new(scheduler, params)
        local self = setmetatable({
            scheduler = scheduler,
            params = params,
        },Constructor)

        if scheduler:_isPipeline(params.pipeline) == nil then
            scheduler:_createPipeline(params.pipeline)
        end

        return self
    end

    function Constructor:assert(value, errormessage)
        if not value then
            error(errormessage)
        end
        return value
    end

    function Constructor:_construct(params, executor, framestep)
        local execution = table.clone(params)

        function execution.Cancel()
            self.scheduler.pipelines[params.pipeline].executors[params.name] = nil
        end

        function execution.Pause()
            execution.isActive = false
        end

        function execution.Begin()
            execution.isActive = true
        end
        
        execution.executor = executor
        execution.framestep = framestep -- not goal framerate, runservice string function
        execution.isActive = true 
        execution.frameManager = {elapsed = 0, frames = 0}
        return execution
    end

    function Constructor:Stepped(executor: render): deltaTime | elapsed
        return self.scheduler:_insertIntoPipeline(self:_construct(self.params, executor, "Stepped"), self.params.pipeline or "_default")
    end

    function Constructor:RenderStepped(executor: render): deltaTime | elapsed
        self:assert(game:GetService("RunService"):IsClient(),"RenderStepped can only be called by on the Client")

        return self.scheduler:_insertIntoPipeline(self:_construct(self.params, executor, "RenderStepped"), self.params.pipeline or "_default")
    end

    function Constructor:Heartbeat(executor: render): deltaTime | elapsed
        return self.scheduler:_insertIntoPipeline(self:_construct(self.params, executor, "Heartbeat"), self.params.pipeline or "_default")
    end

return Constructor