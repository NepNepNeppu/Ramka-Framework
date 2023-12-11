local Players = game:GetService("Players")
local Ramka = require(game.ReplicatedFirst.Ramka)
Ramka.CreateCite(script.Components)
Ramka.AddTasks(script.Tasks,"Handler$")

Ramka.Start():andThen(function()
    print("Ramka Server Started!")
end):catch(warn)