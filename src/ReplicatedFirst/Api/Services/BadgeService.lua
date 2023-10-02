--[[
    Awarding Badges: 
        server: badgeService.SendRequest(player,2143034576) -> success, badgeInfo
            fires (award guaranteed): localQueue.event.Event -> client & server -> player, alreadyAwared, badgeInfo

        client: badgeService.SendRequest(2143034576) -> success, badgeInfo
            fires (award guaranteed): badgeService.localQueue.event.Event -> client & server -> player, alreadyAwared, badgeInfo

    Misc:
        > Badges can be tracked by observing "badgeService.localQueue.requests"
            client:
                {
                    [1] = BadgeInfo,
                    [2] = BadgeInfo,
                }
            server:
                {
                    [player] = {
                        [1] = BadgeInfo,
                        [2] = BadgeInfo,
                    }
                }
]] 
local Spec = require(game.ReplicatedFirst.Spec)
local RemoteService = Spec:GetService("RemoteService")

local BadgeService = game:GetService("BadgeService")
local Bindable = RemoteService.Get("BadgeService")

local badgeService = {}

badgeService.localQueue = {requests = {}, event = Instance.new("BindableEvent")}

local function UpdateToQueue(success, badgeInfo, alreadyAwared, player)
    local success, result = pcall(function()
        if success ~= true then return end
        badgeInfo.alreadyObtained = alreadyAwared
    
        if game:GetService("RunService"):IsClient() then
            table.insert(badgeService.localQueue.requests, badgeInfo)
        else
            if badgeService.localQueue.requests[player] == nil then
                badgeService.localQueue.requests[player] = {}
            end
            table.insert(badgeService.localQueue.requests[player], badgeInfo)
        end
    
        badgeService.localQueue.event:Fire(player or game.Players.LocalPlayer, alreadyAwared, badgeInfo)
    end)
    
    if not success then
        warn(badgeInfo,result)
    end
end

local function _givePlayerBadge(player, badgeId)
    local preawarded = badgeService.PlayerHasBadge(player, badgeId)
    local success, badgeInfo = badgeService.GetBadgeInfo(badgeId)
    if preawarded then return true, badgeInfo, true end

    if success and badgeInfo.IsEnabled then
        local success, _ = pcall(function()
            return BadgeService:AwardBadge(player.UserId, badgeId)
        end)
        return success, badgeInfo, false
    end

    return false, {}, false
end

local function _sendRequest(...)
    local success, badgeInfo, alreadyAwarded

    if game:GetService("RunService"):IsClient() then
        success, badgeInfo, alreadyAwarded = Bindable:InvokeServer(...)
        UpdateToQueue(success, badgeInfo, alreadyAwarded)
    else
        local data = {...}
        success, badgeInfo, alreadyAwarded = _givePlayerBadge(...)
        pcall(function()
            Bindable:InvokeClient(data[1], success, badgeInfo, alreadyAwarded, data[1])
        end)
        UpdateToQueue(success, badgeInfo, alreadyAwarded, data[1])
    end

    return success, badgeInfo, alreadyAwarded
end

-------------#SYSTEMS#-------------

function badgeService.GetBadgeInfo(badgeId)
    local success, result = pcall(function()
        return BadgeService:GetBadgeInfoAsync(badgeId)
    end)

    return success, result
end

function badgeService.PlayerHasBadge(player, badgeId)
    local _, hasBadge = pcall(function()
        return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
    end)

    return hasBadge
end

-- function badgeService.Get()
    
-- end

if game:GetService("RunService"):IsServer() then
    Bindable.OnServerInvoke = function(player, ...)
        local success, badgeInfo, alreadyAwared = _givePlayerBadge(player, ...)
        UpdateToQueue(success, badgeInfo, alreadyAwared, player)
        return success, badgeInfo, alreadyAwared
    end

    function badgeService.SendRequest(Player: Player,BadgeId: number) -- Yielding Function; [success, badgeInfo]
        _sendRequest(Player, BadgeId)
    end
elseif game:GetService("RunService"):IsClient() then
    Bindable.OnClientInvoke = function(success, badgeInfo, alreadyAwared)
        UpdateToQueue(success, badgeInfo, alreadyAwared)
        return true
    end

    function badgeService.SendRequest(BadgeId: number)
        _sendRequest(BadgeId) -- Yielding Function; [success, badgeInfo]
    end
end

return badgeService
