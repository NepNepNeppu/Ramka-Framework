local Ramka = require(game.ReplicatedFirst.Ramka)

local Character = require(Ramka.GetService("CharacterService").Character)
local RamkaCharacter = Character.new(game.Players.LocalPlayer)
RamkaCharacter:Observe()

Ramka.SetComponent(script.Components)
Ramka.SetComponent(RamkaCharacter,"Character")

Ramka.AddTasks(script.Tasks,"Handler$")

Ramka.Start():andThen(function()
    print("Ramka Client Started!")
end):catch(warn)