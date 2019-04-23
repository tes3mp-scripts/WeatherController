Gives full control over weather to the server, defined by configurable Markov chains per month (allowing seasons).

Requires [DataManager](https://github.com/tes3mp-scripts/DataManager)!

You can find the configuration file in `server/data/custom/__config_WeatherController.json`.  
A default configuration will be generated, with the same weather mechanics as vanilla
* `minDuration` the minimal amount of game hours a weather condition should last
* `maxDuration` the maximal amount of game hours a weather condition should last
* `seasonData`
  * `<season>` name of the season
    * `months` list of months included in the season, as numbers from `1` to `12`
    * `regions` table with lower case region names as keys and markov chain matrices as values
      * for each row `i` column `j` defines the probability of `j` being the next weather.  
      Each row should add up to 1.
        ```Lua
        ["ascadian isles region"] = {
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0},
            {0.45, 0.45, 0, 0, 5, 5, 0, 0, 0, 0}
        },
        ```

List of all weathers in Morrowind + Tribunal + Bloodmoon:
1. Clear
2. Clody
3. Fog
4. Overcast
5. Rain
6. Thunder
7. Ash
8. Blight
9. Snow
10. Blizzard

The following events are provided for other scripts to use:
* `Weather_OnSeasonInit(currentSeason)` called once on startup, gives the name of the current season as the only argument
* `Weather_OnSeasonChange(previousSeason, currentSeason)` called whenever the season changes
* `Weather_OnWeatherChange(region, previousWeather, currentWeather)` called whenever the weather in `region` changes