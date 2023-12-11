return {
    -- return benchmark time in seconds
    benchmarkRT = function(predicate: string, func)
        local startClock = os.clock()
        local returnstatement = func()
        print(string.format("[%.3f sec] %s", (os.clock() - startClock), predicate))
        return returnstatement
    end,

    -- return benchmark time in ms
    benchmark = function(predicate: string, func)
        local startClock = os.clock()
        local returnstatement = func()
        print(string.format("[%.3f ms] %s", (os.clock() - startClock) * 1000, predicate))
        return returnstatement
    end,
}