local Spritesheet = require(script.Parent.Spritesheet)

local MobileDark = setmetatable({}, Spritesheet)
MobileDark.ClassName = "MobileDark"
MobileDark.__index = MobileDark

function MobileDark.new()
    local self = setmetatable(Spritesheet.new("rbxassetid://10445408900"), MobileDark)

    self:AddSprite(Enum.UserInputType.Touch, Vector2.new(0, 0), Vector2.new(100, 100))

    return self
end

return MobileDark