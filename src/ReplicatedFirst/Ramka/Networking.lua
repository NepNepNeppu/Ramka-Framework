local Networking = {}

local RemoteEvents = {}
local RemoteFunctions = {}

local _Channels = {
    remotefunction = {},
    remoteevent = {}
}

local function addinstance(instance: string, name: string, parent: Instance)
    local Item = Instance.new(instance)
    Item.Name = name
    Item.Parent = parent
    return Item
end

local function Create(name: string, type: string, keyName: string)
    local RemoteSignals = game.ReplicatedStorage.RemoteSignals

    if game:GetService("RunService"):IsClient() then
        error(string.format("Unable to create Channel %s. %s must be called on the server.", name, keyName))
    end

    if _Channels[string.lower(type)][name] then
        error(name.. " Channel already exists.")
    else
        return addinstance(type, name, RemoteSignals)
    end
end

local function getChildrenWithClass(class, parent)
    local tbl = {}
    
    for i,v in parent:GetChildren() do
        if v.ClassName == class then
            tbl[v.Name] = v
        end
    end

    return tbl
end

RemoteEvents.__index = RemoteEvents
RemoteFunctions.__index = RemoteFunctions

    function Networking.Nudge(nudgeName: string)
        local self = setmetatable({
            remoteEvent = Create(nudgeName, "RemoteEvent", "newEvent")
        }, RemoteEvents)

        _Channels.remoteevent[nudgeName] = self
        return _Channels.remoteevent[nudgeName]
    end

    function Networking.Return(returnerName: string)
        local self = setmetatable({
            remoteFunction = Create(returnerName, "RemoteFunction", "newEvent"),
        }, RemoteFunctions)

        _Channels.remotefunction[returnerName] = self
        return _Channels.remotefunction[returnerName]
    end

    function Networking.GetNudge(nudgeName: string)
        local RemoteSignals = game.ReplicatedStorage.RemoteSignals
        local Tbl = getChildrenWithClass("RemoteEvent", RemoteSignals)

        if _Channels.remoteevent[nudgeName] then
            return _Channels.remoteevent[nudgeName]
        elseif Tbl[nudgeName] then
            _Channels.remoteevent[nudgeName] = setmetatable({
                remoteEvent = Tbl[nudgeName]
            }, RemoteEvents)

            return _Channels.remoteevent[nudgeName]
        else            
            error("Nudge " ..nudgeName.. " does not exists.")
        end
    end

    function Networking.GetReturn(returnerName: string)
        local RemoteSignals = game.ReplicatedStorage.RemoteSignals
        local Tbl = getChildrenWithClass("RemoteFunction", RemoteSignals)

        if _Channels.remotefunction[returnerName] then
            return _Channels.remotefunction[returnerName]
        elseif Tbl[returnerName] then
            _Channels.remotefunction[returnerName] = setmetatable({
                remoteFunction = Tbl[returnerName]
            }, RemoteFunctions)

            return _Channels.remotefunction[returnerName]
        else            
            error("Nudge " ..returnerName.. " does not exists.")
        end
    end

--//RemoteEvents

    -- :FireClient
    function RemoteEvents:PushToClient(client: Player, ...)
        self.remoteEvent:FireClient(client,...)
    end

    -- :FireAllClients
    function RemoteEvents:PushToClients(...)
        self.remoteEvent:FireAllClients(...)
    end

    -- :FireServer
    function RemoteEvents:PushToServer(...)
        self.remoteEvent:FireServer(...)
    end

--//RemoteFunctions

    --[[ 
        :InvokeClient
        Server > Client > Server
    ]]
    function RemoteFunctions:InvokeClientCallback(client: Player, ...)
        return self.remoteFunction:InvokeClient(client,...)
    end

        --[[ 
        :InvokeClient
        Client > Server > Client
    ]]
    function RemoteFunctions:InvokeServerCallback(...)
        return self.remoteFunction:InvokeServer(...)
    end

return Networking