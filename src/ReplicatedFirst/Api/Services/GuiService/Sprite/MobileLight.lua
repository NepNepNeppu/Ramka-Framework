local Spritesheet = require(script.Parent.Spritesheet)

local MobileLight = setmetatable({}, Spritesheet)
MobileLight.ClassName = "MobileLight"
MobileLight.__index = MobileLight

function MobileLight.new()
    local self = setmetatable(Spritesheet.new("rbxassetid://10455328094"), MobileLight)

    self:AddSprite(Enum.UserInputType.Touch, Vector2.new(0, 0), Vector2.new(100, 100))

    return self
end

return MobileLight