local function hoursToSeconds(hours)
    return hours * 3600
end

return {
    NextMinute = function()
        return hoursToSeconds(1/60) + os.time()
    end,

    NextTwelveHours = function()
        return hoursToSeconds(12) + os.time()
    end,
    
    NextDay = function(scaler)
        return hoursToSeconds(24 * scaler) + os.time()
    end,

    NextInHours = function(hours)
        return hoursToSeconds(hours) + os.time()
    end,

    NextYear = function()
        return hoursToSeconds(8760) + os.time()
    end,
}