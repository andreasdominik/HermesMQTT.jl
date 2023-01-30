module HermesMQTT

using JSON
using statsBase
using Dates
using Distributed

include("utils.jl")
include("snips.jl")
include("mqtt.jl")
include("hermes.jl")
include("intents.jl")
include("config.jl")
include("dates.jl")
include("db.jl")
include("schedule.jl")
include("gpio.jl")
include("shelly.jl")
include("weather.jl")
include("languages.jl")
include("callback.jl")
include("susi.jl")

# keep track of current actions:
# 
PREFIX = nothing    # prefix for parameter names
CURRENT_SITE_ID = "default"
CURRENT_SESSION_ID = "1"
CURRENT_DEVEL_NAME = "unknown"
CURRENT_MODULE = Main
CURRENT_INTENT = "none"
CURRENT_APP_DIR = ""
CURRENT_APP_NAME = "HermesMQTT framework"


# set default language and texts to en
#
const DEFAULT_LANG = "en"
LANGUAGE_TEXTS = Dict{Any, Any}()   # one entry for every language
                                    # with a Tuple as key (e.g. ("en", :ok) ...
INI_MATCH = "must_include"

# read config susi.config entries moved to HermesMQTT config:
#
const HERMES_DIR = @__DIR__
const ACTIONS_DIR = diretory(HERMES_DIR)
const CONFIG_INI = read_config(HERMES_DIR)
const LANG = set_language(get_config(:language))

# List of intents to listen to:
# (intent, developer, complete topic, module, skill-action)
#
SKILL_INTENT_ACTIONS = Tuple{AbstractString, AbstractString, AbstractString,
                             Module, Function}[]

export subscribe_MQTT, read_one_MQTT, publish_MQTT, publish_MQTT_file,
       subscribe2Intents, subscribe2Topics, listenIntentsOneTime,
       publishEndSession, publishContinueSession,
       publishStartSessionAction, publishStartSessionNotification,
       publishSystemTrigger,publishListenTrigger, makeSystemTrigger,
       publishHotwordOn, publishHotwordOff,
       configureIntent,
       registerIntentAction, registerTriggerAction,
       getIntentActions, setIntentActions,
       askYesOrNoOrUnknown, askYesOrNo,
       publishSay,
       add_text, lang_text,
       setSiteId, getSiteId,
       setSessionId, getSessionId,
       setDeveloperName, getDeveloperName, setModule, getModule,
       set_appdir, get_appdir, set_appname, get_appname,
       setTopic, getTopic, setIntent, getIntent,
       read_config, match_config, get_config, is_in_config, get_all_config,
       is_config_valid, is_valid_or_end, set_config_prefix, reset_config_prefix,
       get_config_path,
       tryrun, try_read_textfile, ping,
       tryParseJSONfile, tryParseJSON, tryMkJSON,
       extract_slot_value, extract_multislot_values, is_in_slot, isOnOffMatched, 
       read_time_from_slot, readableDateTime,
       setGPIO, print_debug, print_log,
       switchShelly1, switchShelly25relay, moveShelly25roller,
       all_occuresin, one_occursin, all_occursin_order,
       is_false_detection,
       dbWritePayload, dbWriteValue, dbReadEntry, dbReadValue, dbHasEntry,
       schedulerAddAction, schedulerAddActions, schedulerMakeAction,
       schedulerDeleteAll, schedulerDeleteTopic, schedulerDeleteOrigin,
       getWeather,
       get_language, set_language

end # module
