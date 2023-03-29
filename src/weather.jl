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

    weatherService = get_config_skill(INI_WEATHER_SERVICE, skill="HermesMQTT")

    if weatherService == "openweather"
        return get_open_weather()

    elseif weatherService == "weatherapi"
        return get_weather_api()

    else
        print_log("Try to get weather information form invalid service $weatherService")
        return nothing
    end
end


"""
    getOpenWeather()

Return a Dict with weather information from openweather.org.
"""
function get_open_weather()

# openwather JSON:
#
#  {
#    "coord":
#    {
#      "lon":8.7686,"lat":50.6981
#    },
#    "weather":
#    [
#      {"id":804,
#       "main":"Clouds",
#       "description":"overcast clouds",
#       "icon":"04d"
#      }
#    ],
#    "base":"stations",
#    "main":
#    {
#      "temp":278.7,
#      "feels_like":276.96,
#      "temp_min":277.25,
#      "temp_max":279.37,
#      "pressure":1019,
#      "humidity":83,
#      "sea_level":1019,
#      "grnd_level":985
#    },
#    "visibility":10000,
#    "wind":
#    {
#      "speed":2.21,
#      "deg":193,
#      "gust":4.79
#    },
#    "clouds":
#    {
#      "all":100
#    },
#    "dt":1680074949,
#    "sys":
#    {
#      "type":2,
#      "id":2009022,
#      "country":"DE",
#      "sunrise":1680066511,
#      "sunset":1680112252,
#      },
#    "timezone":7200,
#    "id":3220941,
#    "name":"Regierungsbezirk Gießen",
#    "cod":200
#  }


    weather = Dict()
    try
        api = get_config_skill(INI_WEATHER_API, one_prefix="openweather",
                               skill="HermesMQTT")
        city = get_config_skill(INI_WEATHER_ID, one_prefix="openweather",
                          skill="HermesMQTT")

        url = "$OPEN_WEATHER_URL?id=$city&APPID=$api"
        print_debug("openweather URL = $url")

        response = HTTP.get(url)
        data = String(response.body)

        print_log("Weather from OpenWeatherMap: $data")
        openWeather = try_parse_JSON(data)

        if !(openWeather isa Dict)
            return nothing
        end

        weather[:service] = "OpenWeatherMap"
        weather[:temperature] = get_from_keys(openWeather, :main, :temp)
        weather[:windspeed] = get_from_keys( openWeather, :wind, :speed)
        weather[:winddir] = get_from_keys( openWeather, :wind, :deg)
        weather[:clouds] = get_from_keys( openWeather, :clouds, :all)
        weather[:rain1h] = get_from_keys( openWeather, :rain, Symbol("1h"))
        if isnothing(weather[:rain1h])
            weather[:rain1h] = 0.0
        end
        weather[:rain3h] = get_from_keys( openWeather, :rain, Symbol("3h"))
        if isnothing(weather[:rain3h])
            weather[:rain3h] = 0.0
        end
        weather[:rain] = 0.0

        timeEpoch = get_from_keys(openWeather, :sys, :sunrise)
        if !isnothing(timeEpoch)
            weather[:sunrise] = Dates.unix2datetime(timeEpoch)

            if (weather[:sunrise] isa DateTime) && haskey(openWeather, :timezone)
                weather[:sunrise] += Dates.Second(openWeather[:timezone])
            end
        end

        timeEpoch = get_from_keys(openWeather, :sys, :sunset)
        if !isnothing(timeEpoch)
            weather[:sunset] = Dates.unix2datetime(timeEpoch)

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
function get_weather_api()

    weather = Dict()
    try
        api = get_config_skill(INI_WEATHER_API, one_prefix="weatherapi",
                               skill="HermesMQTT")
        print_debug("api = $api")
        location = get_config_skill(INI_WEATHER_LOCATION,
                             multiple=true, one_prefix="weatherapi",
                             skill="HermesMQTT")
        if length(location) != 2
            print_log("Wrong location in config.ini for weatherAPI: lon,lat expected!")
            return nothing
        end
        lat = location[1]
        lon = location[2]
        #print_debug("location = $lat, $lon")

        url = "$WEATHER_API_URL?key=$api&q=$lat,$lon"
        #print_debug("url = $url")

        response = HTTP.get(url)
        data = String(response.body)
        weatherApi = try_parse_JSON(data)

        if !(weatherApi isa Dict)
            return nothing
        end

        weather[:service] = "WeatherApi"
        weather[:temperature] = weatherApi[:current][:temp_c]
        weather[:windspeed] = weatherApi[:current][:wind_kph]
        weather[:winddir] = weatherApi[:current][:wind_degree]
        weather[:clouds] = weatherApi[:current][:cloud]
        weather[:rain1h] = weatherApi[:current][:precip_mm]
        if isnothing(weather[:rain1h])
            weather[:rain1h] = 0.0
        end
        weather[:rain3h] = weather[:rain1h]


        url = "$WEATHER_AST_URL?key=$api&q=$lat,$lon"

        response = HTTP.get(url)
        data = String(response.body)
        print_log("Astronomy from WeatherApi: $response")
        weatherApi = try_parse_JSON(data)

        if !(weatherApi isa Dict)
            return nothing
        end

        timestr = weatherApi[:astronomy][:astro][:sunrise]
        sunriseTime = Dates.Time(timestr, "HH:MM pp")
        weather[:sunrise] = DateTime(today(), sunriseTime)

        timestr = weatherApi[:astronomy][:astro][:sunset]
        sunsetTime = Dates.Time(timestr, "HH:MM pp")
        weather[:sunset] = DateTime(today(), sunsetTime)
    
        weather[:time] = "$(Dates.now())"
    catch
        weather = nothing
    end

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
