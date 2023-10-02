local Ramka = require(game.ReplicatedFirst.Ramka)

local Systems = Ramka.CreateTask {Name = "Systems"}

function Systems:RamkaStart()
    Ramka.Construct {
        Name = "Ramka Client Systems",
        Step = "Heartbeat",
        Update = function(elapsed, delta, plan)
            print("System Update")
        end
    }

    local PlayerData = Ramka.HookInvokeServer("Datastore",{
        Key = "GetData"
    })

    print(PlayerData)
end

function Systems:RamkaInit()
    
end

return Systems
