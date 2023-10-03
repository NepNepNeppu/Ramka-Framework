local Ramka = require(game.ReplicatedFirst.Ramka)

local CharacterService = require(Ramka.GetServices().CharacterService).new(game.Players.LocalPlayer)
Ramka.CreateCite(script.Components)
Ramka.CreateCite(CharacterService,"CharacterService")

Ramka.AddTasks(script.Tasks,"Handler$")

Ramka.Start():andThen(function()
    print("Ramka Client Started!")
end):catch(warn)