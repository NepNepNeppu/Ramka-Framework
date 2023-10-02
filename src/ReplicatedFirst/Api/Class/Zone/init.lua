local Zones = require(script.Zone)

local Storage = {}
local Zone = {}

    function Zone.GetZones()
        return table.clone(Storage)
    end

    function Zone.GetZone(name)
        return Storage[name]
    end

    function Zone.CreateLocalStorage(name)
        local self = Zones()
        Storage[name] = self
        return self.new(name or "Unnamed")
    end

return Zone 