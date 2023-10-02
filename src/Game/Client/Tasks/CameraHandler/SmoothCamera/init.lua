local Ramka = require(game.ReplicatedFirst.Ramka)

local Mouse = require(Ramka.GetService("DeviceService").Mouse)
local PreferredInput = require(Ramka.GetService("DeviceService").PreferredInput)
local TouchGui = require(Ramka.GetService("GuiService").getTouchGui)
local Character = Ramka.GetComponent("Character")
local Math = require(Ramka.GetService("MathService").math)

local Popper = require(script.Popper)

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local gamepad = {
    ButtonX = 0,
    ButtonY = 0,
    DPadDown = 0,
    DPadUp = 0,
    ButtonL2 = 0,
    ButtonR2 = 0,
    Thumbstick1 = Vector2.new(),
    Thumbstick2 = Vector2.new(),
}

local mouse = {
    lastDelta = Vector2.new(),
    delta = Vector2.new(),
    mouseDown = true,
}

local PAN_TOUCH_SPEED    = Vector2.new(1, 1)*(pi/16)
local PAN_MOUSE_SPEED    = Vector2.new(.6,.45)*(pi/64)
local PAN_GAMEPAD_SPEED  = Vector2.new(1, .5)*(pi/2)
local PAN_GAIN = Vector2.new(1, .5)*8

local Camera = game.Workspace.CurrentCamera

local min = game.StarterPlayer.CameraMinZoomDistance
local max = game.StarterPlayer.CameraMaxZoomDistance

local smoothCamera = {}
smoothCamera.loop = nil
smoothCamera.connections = nil

smoothCamera.zoomDistance = 0
smoothCamera.currentZoom = 0
smoothCamera.poppedZoom = 0

smoothCamera.heldKeyZoomFactor = 0
smoothCamera.touchIsPinching = false

smoothCamera.goalGamepadDelta = Vector2.new()
smoothCamera.goalMouseDelta = Vector2.new()

    function mobileIsUsingThumbstick()
        local descendants = TouchGui.GetDescendants()
        if descendants.ThumbstickEnd then
            return not (descendants.ThumbstickEnd and descendants.ThumbstickEnd.ImageTransparency == 1)
        end
        return true
    end

    function _pan(delta)         
        local function pan(vector)
            local kMouse = (Mouse:GetDelta())*vector*2
            smoothCamera.goalMouseDelta -= (kMouse * PAN_GAIN)
            Mouse:Lock()
        end

        if Mouse:IsRightDown() or smoothCamera.poppedZoom <= .5 + 1e-1 then
            pan(PAN_MOUSE_SPEED)
        elseif PreferredInput.Current == "Touch" and smoothCamera.touchIsPinching == false and not mobileIsUsingThumbstick() then
            pan(PAN_TOUCH_SPEED)
        else
            Mouse:Unlock()
        end

        mouse.delta = mouse.delta:Lerp(smoothCamera.goalMouseDelta,delta * 15)            
        smoothCamera.goalMouseDelta -= smoothCamera.goalGamepadDelta * PAN_GAMEPAD_SPEED * PAN_GAIN
        smoothCamera.goalMouseDelta = Vector2.new(smoothCamera.goalMouseDelta.X, math.clamp(smoothCamera.goalMouseDelta.Y,-80,80))
    end

    function smoothCamera._update(delta)
        if Character:Get() and Character:GetHumanoid() and Character:GetHumanoidRootPart() then 
            Camera.CameraType = Enum.CameraType.Scriptable

            _pan(delta)
            
            local headPos = Character:GetHumanoidRootPart().Position + (Vector3.yAxis * (Character:GetHumanoid().HipHeight - .5))
            local rotation = CFrame.Angles(0,math.rad(mouse.delta.X/4),0) * CFrame.Angles(math.rad(mouse.delta.Y),0,0)
            local focus = CFrame.new(headPos) * rotation
            local keyHeldZoomFactor = smoothCamera.heldKeyZoomFactor * delta * math.clamp((smoothCamera.zoomDistance/8),2,20) * 6
    
            smoothCamera.zoomDistance = math.clamp(smoothCamera.zoomDistance + keyHeldZoomFactor,min,max)
            smoothCamera.currentZoom = math.clamp(Math.compute.smoothStep(smoothCamera.currentZoom,smoothCamera.zoomDistance,delta * 13),min,max)
    
            local poppedCameraDistance = Popper(focus,smoothCamera.currentZoom)        
            local target = CFrame.new(headPos) * rotation * CFrame.new(0,0,poppedCameraDistance)
            local nX,nY,_ = target:ToOrientation()
            local newCameraCFrame = CFrame.new(headPos) * CFrame.fromOrientation(nX,nY,0) * CFrame.new(0,0,poppedCameraDistance)
            
            smoothCamera.poppedZoom = poppedCameraDistance
            Camera.CFrame = newCameraCFrame
    
            if Character:GetHumanoid().Sit == false then
                local x,_,z = Character:GetHumanoidRootPart().CFrame:ToOrientation()
                Character:GetHumanoidRootPart().CFrame = CFrame.new(Character:GetHumanoidRootPart().Position) * CFrame.fromOrientation(x,nY,z)
            end
            Mouse:LockCenter()
        end
    end

return smoothCamera