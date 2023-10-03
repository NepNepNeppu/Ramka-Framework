local Ramka = require(game.ReplicatedFirst.Ramka)
local Signal = require(Ramka.GetClasses().Signal)

local Character = {}
Character.__index = Character

    function Character.new(Player: Player)
        local self = setmetatable({
            Player = Player,
            Character = Player.Character,

            Updated = Signal.new()
        },Character)

        return self
    end

    function Character:Observe()
        self.added = Signal.Wrap(self.Player.CharacterAdded)
        self.added:Connect(function(character)
            self.Character = character
            self.Updated:Fire()
        end)

        self.removed = Signal.Wrap(self.Player.CharacterRemoving)
        self.removed:Connect(function()
            self.Character = nil
        end)
    end

    function Character:Is()
        return self.Character ~= nil
    end

    function Character:Wait()
        self.Updated:Wait()
    end

    function Character:Get()
        if not self:Is() then self:Wait() end
        return self.Character
    end

    function Character:GetHumanoid()
        if not self:Is() then self:Wait() end
        return self.Character.Humanoid
    end

    function Character:GetHumanoidRootPart()
        if not self:Is() then self:Wait() end
        return self.Character.HumanoidRootPart
    end

    function Character:Destroy()
        self.Signal:Destroy()
        self.added:Destroy()
        self.removed:Destroy()
        self.Updated:Destroy()
    end

return Character