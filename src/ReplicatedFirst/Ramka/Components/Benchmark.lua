local function getSec(func)
    local startClock = os.clock()
    local returnstatement = func()
    return tonumber(string.format("%.3f", (os.clock() - startClock))), returnstatement
end

local function getMs(func)
    local startClock = os.clock()
    local returnstatement = func()
    return tonumber(string.format("%.3f", (os.clock() - startClock)  * 1000)), returnstatement
end

return {
    -- returns benchmark time in seconds
    SEC = function(predicate: string, func)
        local sec, returnstatement = getSec(func)
        print(string.format("[%s sec] %s", tostring(sec), predicate))
        return returnstatement
    end,

    -- return benchmark time in ms
    MS = function(predicate: string, func)
        local ms, returnstatement = getMs(func)
        print(string.format("[%s ms] %s", tostring(ms), predicate))
        return returnstatement
    end,

    GETSEC = function()
        
    end
}