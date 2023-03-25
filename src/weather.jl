# get weather info from openweater.org
#

const INI_WEATHER_SERVICE = "weather_service"
const INI_WEATHER_API = "api_key"
const INI_WEATHER_ID = "city_id"
const INI_WEATHER_LOCATION = "location"
const OPEN_WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
const WEATHER_API_URL = "http://api.weatherapi.com/v1/current.json"
const WEATHER_AST_URL = "http://api.weatherapi.com/v1/astronomy.json"

"""
    get_weather()

Return a Dict with weather information from openweather.org
or weatherapi.com.
The `config.ini`
of the framework must include the lines to define which
service to be used and api key and location for the service used
(available from openweather.org or weatherapi.com).

```
# weather_service=openweather
weather_service=weatherapi
openweather:api_key=insert_valid_API-key_here
openweather:city_id=6350865

weatherapi:api_key=insert_valid_API-key_here
weatherapi:location=52.52,13.40
```


## Value:
The return value has the elements:
- `:service`: name of the weather service
- `:pressure`: pressure in hPa
- `:temperature`: temperature in degrees Celsius
- `:windspeed`: wind speed in meter/sec
- `:winddir`: wind direction in degrees
- `:clouds`: cloudiness in percent
- `:rain`: rain forecast for today
- `:rain1h`
- `:rain3h`: rain in mm in the last 1 or 3 hours
- `:sunrise`
- `:sunset`: local time of sunrise/sunset as DateTime object

If something went wrong with the API-service, `nothing` is returned.
"""
function get_weather()

    weatherService = getConfig(INI_WEATHER_SERVICE)

    if weatherService == "openweather"
        return getOpenWeather()

    elseif weatherService == "weatherapi"
        return getWeatherApi()

    else
        print_log("Try to get weather information form invalid service $weatherService")
        return nothing
    end
end


"""
    getOpenWeather()

Return a Dict with weather information from openweather.org.
"""
function getOpenWeather()

    weather = Dict()
    try
        api = get_config(INI_WEATHER_API, one_prefix="openweather" )
        city = get_config(INI_WEATHER_ID, one_prefix="openweather")

        url = "$OPEN_WEATHER_URL?id=$city&APPID=$api"
        print_debug("openweather URL = $url")
        response = read(`curl $url`, String)

        print_log("Weather from OpenWeatherMap: $response")
        openWeather = try_parse_JSON(response)

        if !(openWeather isa Dict)
            return nothing
        end

        weather[:service] = "OpenWeatherMap"
        weather[:temperature] = get_from_keys(openWeather, :main, :temp)
        weather[:windspeed] = get_from_keys( openWeather, :wind, :speed)
        weather[:winddir] = get_from_keys( openWeather, :wind, :deg)
        weather[:clouds] = get_from_keys( openWeather, :clouds, :all)
        weather[:rain1h] = get_from_keys( openWeather, :rain, Symbol("1h"))
        if weather[:rain1h] == nothing
            weather[:rain1h] = 0.0
        end
        weather[:rain3h] = get_from_keys( openWeather, :rain, Symbol("3h"))
        if weather[:rain3h] == nothing
            weather[:rain3h] = 0.0
        end
        weather[:rain] = 0.0

        timeEpoch = get_from_keys(openWeather, :sys, :sunrise)
        if timeEpoch != nothing
            weather[:sunrise] = unix2datetime(timeEpoch)

            if (weather[:sunrise] isa DateTime) && haskey(openWeather, :timezone)
                weather[:sunrise] += Dates.Second(openWeather[:timezone])
            end
        end

        timeEpoch = get_from_keys(openWeather, :sys, :sunset)
        if timeEpoch != nothing
            weather[:sunset] = unix2datetime(timeEpoch)

            if (weather[:sunset] isa DateTime) && haskey(openWeather, :timezone)
                weather[:sunset] += Dates.Second(openWeather[:timezone])
            end
        end

        weather[:time] = "$(Dates.now())"
    catch
        weather = nothing
    end

    return weather
end



"""
    getWeatherApi()

Return a Dict with weather information from weatherapi.com.
"""
function getWeatherApi()

    weather = Dict()
    try
        api = get_config(INI_WEATHER_API, one_prefix="weatherapi")
        print_debug("api = $api")
        location = get_config(INI_WEATHER_LOCATION,
                             multiple=true, one_prefix="weatherapi")
        if length(location) != 2
            print_log("Wrong location in config.ini for weatherAPI: lon,lat expected!")
            return nothing
        end
        lat = location[1]
        lon = location[2]
        print_debug("location = $lat, $lon")

        url = "$WEATHER_API_URL?key=$api&q=$lat,$lon"
        print_debug("url = $url")

        cmd = `curl $url`
        print_debug("cmd = $cmd")
        response = read(cmd, String)
        print_log("Weather from WeatherApi: $response")
        weatherApi = try_parse_JSON(response)

        if !(weatherApi isa Dict)
            return nothing
        end

        weather[:service] = "WeatherApi"
        weather[:temperature] = weatherApi[:current][:temp_c]
        weather[:windspeed] = weatherApi[:current][:wind_kph]
        weather[:winddir] = weatherApi[:current][:wind_degree]
        weather[:clouds] = weatherApi[:current][:cloud]
        weather[:rain] = weatherApi[:current][:precip_mm]
        weather[:rain1h] = 0.0
        weather[:rain3h] = 0.0

        url = "$WEATHER_AST_URL?key=$api&q=$lat,$lon"
        print:debug("url = $url")

        cmd = `curl $url`
        print_debug("cmd: $cmd")
        response = read(cmd, String)
        print_log("Astronomy from WeatherApi: $response")
        weatherApi = tryParseJSON(response)

        if !(weatherApi isa Dict)
            return nothing
        end

        timestr = weatherApi[:astronomy][:astro][:sunrise]
        sunriseTime = Time(timestr, "HH:MM pp")
        weather[:sunrise] = DateTime(today(), sunriseTime)

        timestr = weatherApi[:astronomy][:astro][:sunset]
        sunsetTime = Time(timestr, "HH:MM pp")
        weather[:sunset] = DateTime(today(), sunsetTime)
    catch
        weather = nothing
    end

    weather[:time] = "$(Dates.now())"
    print_debug("weatherapi complete: $weather")
    return weather
end


function get_from_keys(hierDict, key1, key2)

    if haskey(hierDict, key1) && haskey(hierDict[key1], key2)
        val = hierDict[key1][key2]
        return val
    else
        return nothing
    end
end
function get_from_keys(hierDict, key1, key2, key3)

    if haskey(hierDict, key1) && haskey(hierDict[key1], key2) &&
       haskey(hierDict[key1][key2], key3)
        val = hierDict[key1][key2][key3]
        return val
    else
        return nothing
    end
end
