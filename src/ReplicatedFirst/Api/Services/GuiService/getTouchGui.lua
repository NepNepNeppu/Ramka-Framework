local TouchGui do
    local activeTouchGuis = {}

    local function watchTouchGui(Gui)
        local TouchControlFrame = Gui:WaitForChild("TouchControlFrame")
        local DynamicThumbstickFrame = TouchControlFrame:WaitForChild("DynamicThumbstickFrame")
        local ThumbstickEnd = DynamicThumbstickFrame:WaitForChild("ThumbstickEnd")

        if TouchGui == nil then
            TouchGui = {
                TouchGui = TouchGui,
                TouchControlFrame = TouchControlFrame,
                DynamicThumbstickFrame = DynamicThumbstickFrame,
                ThumbstickEnd = ThumbstickEnd,
            }

            TouchGui.ThumbstickEnd.ImageTransparency = 1
        end

        activeTouchGuis[Gui] = ThumbstickEnd:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
            for i,v in activeTouchGuis do
                if i ~= Gui then
                    v:Disconnect()
                    activeTouchGuis[i] = nil
                    i:Destroy()
                end
            end

            TouchGui = {
                TouchGui = TouchGui,
                TouchControlFrame = TouchControlFrame,
                DynamicThumbstickFrame = DynamicThumbstickFrame,
                ThumbstickEnd = ThumbstickEnd,
            }

            TouchGui.ThumbstickEnd.ImageTransparency = 1
        end)
    end

    for i,v in game.Players.LocalPlayer.PlayerGui:GetChildren() do
        if v.Name == "TouchGui" then
            task.spawn(watchTouchGui,v)
        end
    end

    game.Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(v)
        if v.Name == "TouchGui" then
            task.spawn(watchTouchGui,v)
        end
    end)
end

return {
    Get = function()
        return TouchGui.TouchGui
    end,

    GetDescendants = function()
        return TouchGui
    end
}