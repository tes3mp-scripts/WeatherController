local Weather = {}

Weather.scriptName = "WeatherController"

Weather.defaultConfig = require("custom.WeatherController.defaultConfig")
Weather.config = DataManager.loadConfiguration(Weather.scriptName, Weather.defaultConfig)

Weather.defaultData = require("custom.WeatherController.defaultData")
Weather.data = DataManager.loadData(Weather.scriptName, Weather.defaultData)


function Weather.LogMessage(message)
    tes3mp.LogMessage(enumerations.log.INFO, "[WeatherController]"..message)
end

function Weather.getRandom()
    return math.random()
end

function Weather.getCurrentSeason()
    return Weather.config.seasonData[Weather.currentSeason]
end


function Weather.generateNextWeather(region)
    local options = Weather.getCurrentSeason().regions[region][Weather.data.currentWeather[region] + 1]
    local roll = Weather.getRandom()
    local base = 0
    for i, chance in ipairs(options) do
        if base < roll and roll < base + chance then
            return i - 1
        end
        base = base + chance
    end
    return 0
end

function Weather.updateSeason()
    local month = WorldInstance.data.time.month
    local oldseason = Weather.currentSeason
    Weather.currentSeason = Weather.monthToSeason[month]
    if oldseason == nil then
        customEventHooks.triggerHandlers(
            "Weather_OnSeasonInit",
            customEventHooks.makeEventStatus(true, true),
            {Weather.currentSeason}
        )
    else
        if oldseason ~= Weather.currentSeason then
            customEventHooks.triggerHandlers(
                "Weather_OnSeasonChange",
                customEventHooks.makeEventStatus(true, true),
                {oldseason, Weather.currentSeason}
            )
        end
    end
end

function Weather.applyWeather(region, previousWeather)
    if WorldInstance.storedRegions[region] == nil then
        WorldInstance.storedRegions[region] = { visitors = {}, forcedWeatherUpdatePids = {} }
    end

    local storedRegion = WorldInstance.storedRegions[region]

    storedRegion.currentWeather = previousWeather
    storedRegion.nextWeather = Weather.data.currentWeather[region]
    storedRegion.queuedWeather = Weather.data.nextWeather[region]
    storedRegion.transitionFactor = 0
    local pid = next(Players)
    if pid ~= nil then
        WorldInstance:LoadRegionWeather(region, pid, true, false)
    end
end

function Weather.updateWeather(region)
    if Weather.data.currentWeather[region] ~= Weather.data.nextWeather[region] then
        customEventHooks.triggerHandlers(
            "Weather_OnWeatherChange",
            customEventHooks.makeEventStatus(true, true),
            {region, Weather.data.currentWeather[region], Weather.data.nextWeather[region]}
        )
    end

    local oldWeather = Weather.data.currentWeather[region]
    Weather.data.currentWeather[region] = Weather.data.nextWeather[region]
    Weather.data.nextWeather[region] = Weather.generateNextWeather(region)

    Weather.LogMessage(string.format(
        "Changing weather in %s from %d to %d",
        region,
        oldWeather,
        Weather.data.currentWeather[region]
    ))

    Weather.applyWeather(region, oldWeather)
end


function Weather.getTimerDuration()
    local frametimeMultiplier = WorldInstance:GetCurrentTimeScale() / WorldInstance.defaultTimeScale

    local roll = Weather.getRandom()
    local hours = Weather.config.minDuration + (Weather.config.maxDuration - Weather.config.minDuration) * roll
    return hours * frametimeMultiplier * 60 * 1000
end

function WeatherControllerTimer(region)
    Weather.updateWeather(region)
    tes3mp.RestartTimer(Weather.timers[region], Weather.getTimerDuration())
end

function Weather.setupTimers()
    Weather.timers = {}
    for region, _ in pairs(Weather.getCurrentSeason().regions) do
        Weather.updateWeather(region)
        Weather.timers[region] = tes3mp.CreateTimerEx(
            "WeatherControllerTimer",
            Weather.getTimerDuration(),
            "s",
            region
        )
        tes3mp.StartTimer(Weather.timers[region])
    end
end


function Weather.mapSeasons()
    Weather.monthToSeason = {}
    for season, data in pairs(Weather.config.seasonData) do
        for i, month in pairs(data.months) do
            Weather.monthToSeason[month] = season
        end
    end
end

function Weather.OnServerPostInit(eventStatus)
    Weather.mapSeasons()
    Weather.updateSeason()
    Weather.setupTimers()
end

customEventHooks.registerHandler("OnServerPostInit", Weather.OnServerPostInit)


function Weather.OnPlayerCellChange(eventStatus, pid)
    if eventStatus.validCustomHandlers then
        local region = string.lower(tes3mp.GetRegion(pid))
        if region ~= "" then
            WorldInstance:LoadRegionWeather(region, pid, false, true)
        end
    end
end

customEventHooks.registerHandler("OnPlayerCellChange", Weather.OnPlayerCellChange)


function Weather.OnWorldWeather(eventStatus, pid)
    return customEventHooks.makeEventStatus(false, false)
end
customEventHooks.registerValidator("OnWorldWeather", Weather.OnWorldWeather)


function Weather.OnServerExit(eventStatus)
    DataManager.saveData(Weather.scriptName, Weather.data)
end
customEventHooks.registerHandler("OnServerExit", Weather.OnServerExit)


return Weather