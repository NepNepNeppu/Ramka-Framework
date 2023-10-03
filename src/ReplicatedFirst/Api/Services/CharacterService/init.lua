local CharacterService = {}
CharacterService.__index = CharacterService

    function CharacterService.new(Player)
        local Character = require(script.Character).new(Player)
        local Transparency = require(script.Transparency)
        Character:Observe()

        local self = setmetatable({
            CharacterAdded = Character.added,
            CharacterRemoving = Character.removed,

            _characterData = {
                character = Character,
                transparency = Transparency
            },

            _services = {
                Animate = script.Animate,
                Snap = script.Snap,
                Character = script.Character,
                Transparency = script.Transparency,
            }
        },CharacterService)

        return self
    end

    function CharacterService:GetServices()
        return self._services
    end

    function CharacterService:Get()
        return self._characterData.character:Get()
    end

    function CharacterService:GetHumanoid()
        return self._characterData.character:GetHumanoid()
    end

    function CharacterService:GetHumanoidRootPart()
        return self._characterData.character:GetHumanoidRootPart()
    end

    function CharacterService:SetCharacterTransparency(Transparency: number)
        self._characterData.transparency.setCharacterLocalTransparency(self:Get(), Transparency)
    end

    function CharacterService:Destroy()
        self._characterData.character:Destroy()
        self:SetCharacterTransparency(0)
        self.CharacterAdded = nil
        self.CharacterRemoving = nil
        self._characterData = nil
        self._services = nil
    end

return CharacterService