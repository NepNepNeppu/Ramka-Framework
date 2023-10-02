---
-- @classmod Sprite

local Sprite = {}
Sprite.ClassName = "Sprite"
Sprite.__index = Sprite

function Sprite.new(data)
	assert(data.Texture)
	assert(data.Size)
	assert(data.Position)
	assert(data.Name)

	local self = setmetatable(data, Sprite)

	return self
end

return Sprite