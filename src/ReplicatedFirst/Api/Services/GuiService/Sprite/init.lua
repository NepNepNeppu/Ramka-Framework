local Spritesheet = setmetatable({table.unpack(Enum:GetEnums())},{})

    local function _destring(str)
        local str = string.split(str,".")
        return str[3],str[2]
    end

    Spritesheet.Sprites = {
        Dark = {
            Keyboard = require(script.KeyboardDark).new(),
            Xbox = require(script.XboxDark).new(),
            Mobile = require(script.MobileDark).new(),
        },
        Light = {
            Keyboard = require(script.KeyboardLight).new(),
            Xbox = require(script.XboxLight).new(),
            Mobile = require(script.MobileLight).new(),
        }
    }
    function Spritesheet._applyDetails(sheet,spritesheet,enum)
        local success,result = pcall(function()
            return sheet.Image
        end)
        if success then
            sheet.Image = spritesheet
            sheet.ImageRectSize = enum.Size
            sheet.ImageRectOffset = enum.Position
            -- sheet.Name = enum.Name--:match('[^.]*$')
        else
            warn("Failed to apply properties to SpriteSheet.")
            warn(result)
        end
    end

    function Spritesheet.Replace(instance,enum,color)
        if Spritesheet.Get(enum,color) then
            Spritesheet._applyDetails(instance,Spritesheet.Get(enum,color))
        end
        return instance
    end

    --[[
        rbxassetid://1244652930  ▼  {
                    ["Name"] = "Enum.UserInputType.MouseButton1",
                    ["Position"] = 800, 0,
                    ["Size"] = 100, 100,
                    ["Texture"] = "rbxassetid://1244652930"
                 }
    ]]
    function Spritesheet.Get(enum,color : "Dark" | "Light") --Dark is auto
        local color = color == nil and "Dark" or color
        local Sprites = Spritesheet.Sprites
        if Sprites[color].Keyboard:HasSprite(enum) then
            return Sprites[color].Keyboard._texture,Sprites[color].Keyboard:GetSprite(enum)
        elseif Sprites[color].Xbox:HasSprite(enum) then
            return Sprites[color].Xbox._texture,Sprites[color].Xbox:GetSprite(enum)
        elseif Sprites[color].Mobile:HasSprite(enum) then
            return Sprites[color].Mobile._texture,Sprites[color].Mobile:GetSprite(enum)
        end
    end

    function Spritesheet.GuessEnum(Icon)
        local sheet = Icon.Image
        local imageDataSheet = nil

        for _,SheetColor in Spritesheet.Sprites do
            for SheetName,SheetData in SheetColor do
                if SheetData._texture == sheet then
                    imageDataSheet = SheetData
                end
            end
        end

        for i,v in imageDataSheet._sprites do
            if v.Size == Icon.ImageRectSize and v.Position == Icon.ImageRectOffset then
                return v
            end
        end
    end

    function Spritesheet.getFlippedData(Icon,customTheme)
        local function getTypeAndName(Icon)
            local usesAttribute = Icon:GetAttribute("Enum")
            if usesAttribute then 
                local data = string.split(usesAttribute,",")
                return data[1],data[2]
            else
                return _destring(Spritesheet.GuessEnum(Icon).Name)
            end
        end

        local Name,Type = getTypeAndName(Icon)
        if Name and Type then
            local texture,sprite = Spritesheet.Get(Enum[Type][Name],customTheme or "Light")
            return texture,sprite
        else
            warn("Unable to retrieve flipped color for Icon.")
        end
    end

    function Spritesheet.FlipColor(Icon)
        local texture,sprite = Spritesheet.getFlippedData(Icon)
        if texture and sprite then
            Icon.Image = texture
            Icon.ImageRectOffset = sprite.Position
            Icon.ImageRectSize = sprite.Size
        end
    end

    function Spritesheet.new(enum : EnumItem)
        if Spritesheet.Get(enum) then
            local sheet = Instance.new("ImageLabel")
            Spritesheet._applyDetails(sheet,Spritesheet.Get(enum))
            return sheet
        end
    end

return Spritesheet
