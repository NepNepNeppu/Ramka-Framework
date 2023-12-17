local Ramka = require(game.ReplicatedFirst.Ramka)
-- local Signal = require(Ramka.GetClasses().Signal)

local windowChanged = Instance.new("BindableEvent")
local cameraChanged = Instance.new("BindableEvent")

local function getWindowSize()
    local viewportSize = game.Workspace.CurrentCamera.ViewportSize
    return viewportSize.X, viewportSize.Y
end

local function getCameraTransform()
    local pos = game.Workspace.CurrentCamera.CFrame.Position
    local x, y, z = game.Workspace.CurrentCamera.CFrame:ToOrientation()

    return pos, Vector3.new(math.deg(x), math.deg(y), math.deg(z))
end

game.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    windowChanged:Fire(getWindowSize())
end)

game.Workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(function()
    cameraChanged:Fire(getCameraTransform())
end)

return {
    Window = game.Workspace.CurrentCamera,
    GetWindowSize = function()
        return game.Workspace.CurrentCamera.ViewportSize.X, game.Workspace.CurrentCamera.ViewportSize.Y
    end,

    OnWindowChanged = windowChanged.Event,
    OnCameraChanged = cameraChanged.Event,

    -- Position: Vector3, Orientation: Vector3
    ObserveCamera = function(func)
        func(getCameraTransform())

        return cameraChanged.Event:Connect(func)
    end,

    -- X: number, Y: number
    ObserveWindow = function(func)
        func(getWindowSize())

        return windowChanged.Event:Connect(func)
    end,
}