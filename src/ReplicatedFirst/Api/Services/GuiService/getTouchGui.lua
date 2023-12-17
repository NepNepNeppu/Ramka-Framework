local Ramka = require(game.ReplicatedFirst.Ramka)

local InstanceService = require(Ramka.Services.InstanceService)

return {
    Get = function()
        InstanceService.Child(game.Players.LocalPlayer.PlayerGui, "TouchGui"):await()
        InstanceService.Child(game.Players.LocalPlayer.PlayerGui.TouchGui,
                              InstanceService "TouchControlFrame"):await()
        InstanceService.Child(game.Players.LocalPlayer.PlayerGui.TouchGui
                                  .TouchControlFrame, "DynamicThumbstickFrame"):await()
        InstanceService.Child(game.Players.LocalPlayer.PlayerGui.TouchGui
                                  .TouchControlFrame.DynamicThumbstickFrame,
                              "ThumbstickEnd"):await()

        return {
            TouchGui = game.Players.LocalPlayer.PlayerGui.TouchGui,
            TouchControlFrame = game.Players.LocalPlayer.PlayerGui.TouchGui
                .TouchControlFrame,
            DynamicThumbstickFrame = game.Players.LocalPlayer.PlayerGui.TouchGui
                .TouchControlFrame.DynamicThumbstickFrame,
            ThumbstickEnd = game.Players.LocalPlayer.PlayerGui.TouchGui
                .TouchControlFrame.DynamicThumbstickFrame.ThumbstickEnd
        }
    end
}
