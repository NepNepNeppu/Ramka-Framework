local Ramka = require(game.ReplicatedFirst.Ramka)

Ramka.AddTasks(script.Tasks,"Handler$")

Ramka.Start():andThen(function()
    print("Ramka Server Started!")
end):catch(warn)