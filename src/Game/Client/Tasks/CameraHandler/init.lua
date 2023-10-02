local Ramka = require(game.ReplicatedFirst.Ramka)

local CameraHandler = Ramka.CreateTask {
    Name = "CameraHandler",
    _running = true,
}

local SmoothCamera = require(script.SmoothCamera)

function CameraHandler:RamkaStart()
    Ramka.Construct {
        Name = "CameraHandler",
        Step = "Heartbeat",
        Update = function(elapsed, delta, plan)
            if self._running then
                SmoothCamera._update(delta)
            end
        end
    }
end

function CameraHandler:RamkaInit()
    local Character = Ramka.GetComponent("Character")
    local CharacterTransparency = require(Ramka.GetService("CharacterService").Transparency)
    local playerCharacter = Character:Get()
    CharacterTransparency.setCharacterLocalTransparency(playerCharacter,1)
end

return CameraHandler
