
type func = typeof(function(input, processed) end)

local Buttons = {}
Buttons.__index = Buttons

    local function continueIfSuccess(input, keyCodes)
        for i,v in keyCodes do
            if input.KeyCode == v then
                return v
            elseif input.UserInputType == v then
                return v
            end
        end

        return false
    end

    local function useButtonActivated(button, keycodes, func, inputType)
        keycodes = if keycodes == nil then Buttons.defaultKeycode() else keycodes

        local self = setmetatable({
            enabled = true,
        },Buttons)

        self.connection = button[inputType]:Connect(function(input)
            if continueIfSuccess(input, keycodes) ~= false and self.enabled == true then
                func(input)
            end
        end)

        return self
    end

    function Buttons.defaultKeycode()
        return {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonA,Enum.UserInputType.Touch}
    end

    function Buttons.Pressed(button: ImageButton | TextButton | GuiButton, keyCodes: {[number]: Enum.KeyCode | Enum.UserInputType}, func: func)
        return useButtonActivated(button, keyCodes, func, "InputBegan")
    end

    function Buttons.Released(button: ImageButton | TextButton | GuiButton, keyCodes: {[number]: Enum.KeyCode | Enum.UserInputType}, func: func)
        return useButtonActivated(button, keyCodes, func, "InputEnded")
    end

    function Buttons:Destroy()
        self.connection:Disconnect()
        self.enabled = nil
    end

return Buttons