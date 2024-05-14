local AudioService = {}

local function createSound(sound,name: string?)
    if type(sound) == "number" then
        local sfx = Instance.new("Sound")
        sfx.SoundId = sound
        sfx.Name = name
        return sfx
    else
        local sfx = sound:Clone()
        return sfx
    end
end

AudioService.specialSound = function(Sound: Sound | number,SoundGroup)
    local metadata = {}
    metadata.__index = metadata

    local self = setmetatable({
        instance = createSound(Sound),
        customName = "Sound"
    },metadata)

    function metadata:_play(isLooped,isPlaying)
        self.instance.TimePosition = 0
        self.instance.Playing = isPlaying or true
        self.instance.Looped = isLooped or false
    end

    function metadata:PlayOnce() --//Plays once, cant be played again
        self.instance.Ended:Once(function()
            self.instance:Destroy()
        end)
        self:_play(false,true)
    end

    function metadata:PlayTillEnd() --//Plays once, can still be played again
        self:_play(false,true)
    end

    function metadata:PlayTillStop()
        self:_play(true,true)
    end

    function metadata:Stop()
        self:_play(false,false)
    end

    function metadata:Destroy()
        self:Stop()
        self.instance:Destroy()
    end

    self.instance.Parent = SoundGroup or game.SoundService
    if SoundGroup then
        self.instance.SoundGroup = SoundGroup
    end
    -- self.instance.Name = self.instance.Name

    return self
end

AudioService.playSound = function(sound: Instance,parent : Instance?)
    AudioService.specialSound(sound,parent):PlayOnce()
end

AudioService.createSound = createSound

return AudioService