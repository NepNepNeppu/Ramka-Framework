local Default = {"EmotesMenu","Health","PlayerList","ResetButtonCallback"} --//Topbar disables ability to click buttons at the top
local StarterGui = game:GetService("StarterGui")

function findWithName(name)
    for _,v in Enum.CoreGuiType:GetEnumItems() do
        if v.Name == name then
            return v
        end
    end
end

function coreCall(method, ...)
    local coreType = type(method) == "string" and findWithName(method) or method
    coreType = if type(coreType) ~= "string" then "SetCoreGuiEnabled" else "SetCore"

    local result = {}
    for retries = 1, 8 do
        local success, result = pcall(StarterGui[coreType],StarterGui,method,...)
        if success then
            break
        elseif retries == 8 then
            warn(string.format("%s",result))
        end
        game:GetService("RunService").Stepped:Wait()
    end
    return unpack(result)
end

--[[
    Use ":" as a string seperator for custom booleans
    EX:
        CoreGui(true,{"ResetButtonCallback","EmotesMenu:false"})
]]
return function(Bool : boolean?,Core : {[number] : string?}?)
	for _,v: string in (Core or Default) do
        local str = type(v) == "string" and v:split(":") or v
        if type(str) == "table" and #str == 2 then
            coreCall(str[1],(str[2] == "true" and true or false) == true)
        else
            coreCall(v,(Bool or false) == true)
        end
    end
end
