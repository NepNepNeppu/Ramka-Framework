local Ramka = require(game.ReplicatedFirst.Ramka)

local Datastore = Ramka.CreateTask {Name = "Datastore"}

function Datastore:RamkaInit()
    local DatastoreHook = Ramka.Networking.Return("Datastore")
    DatastoreHook.remoteFunction.OnServerInvoke = function(Player, Command)
        return {
            Key = Command.Key,
            UserId = Player.UserId,
            Currency = math.random(1,10),
        }
    end
end

return Datastore
