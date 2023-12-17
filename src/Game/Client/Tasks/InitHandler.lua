local Ramka = require(game.ReplicatedFirst.Ramka)

local Systems = Ramka.CreateTask {Name = "Systems"}

function Systems:RamkaStart()
    local n = Ramka.Construct {
        name = "key",
        pipeline = "Systems",
        framerate = 2,
    }
    
    n:Heartbeat(function(delta, elapsed, executor)
        print(delta)
    end)

    -- local PlayerData = Ramka.Networking.GetReturn("Datastore")
    -- print(PlayerData:InvokeServerCallback({Key = "NonValue"}))
end

return Systems
