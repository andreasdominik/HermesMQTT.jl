module HermesMQTT

using JSON
using statsBase
using Dates
using Distributed
using Random

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
CURRENT = Dict(
    :prefix => nothing,    # prefix for parameter names
    :siteID => "default",
    :sessionID => "1",
    :devel_name => "unknown",
    :module => Main,
    :intent => "none",
    :app_dir => "",
    :app_name => "HermesMQTT framework")


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
if isnothing(get_config(:language))
    set_language(DEFAULT_LANG)
end

# save home status database location in CONFIG_INI:
# dirname, filename and path (full path to database) 
#
set_config(:database_dir, joinpath(ACTIONS_DIR, "ApplicationData", "database"))
if isnothing(get_config(:database_file))
    set_config(:database_file, "home.json")
end
set_config(:database_path), 
    joinpath(get_config(:database_dir), get_config(:database_file))


# List of intents to listen to:
# (intent, developer, complete topic, module, skill-action)
#
SKILL_INTENT_ACTIONS = Tuple{AbstractString, AbstractString, AbstractString,
                             Module, Function}[]

export subscribe_MQTT, read_one_MQTT, publish_MQTT, publish_MQTT_file,
       subscribe_to_intents, subscribe_to_topics, listen_to_intents_one_time,
       publish_end_session, publish_continue_session,
       publish_start_session_action, publish_start_session_notification,
       publish_system_trigger, publish_listen_trigger, make_system_trigger,
       publish_hotword_on, publish_hotword_off,
       configure_intent,
       register_intent_action, register_trigger_action,
       get_intent_actions, set_intent_actions,
       ask_yes_no_unknown, ask_yes_or_no,
       publish_say,
       add_text, lang_text,
       set_siteID, get_siteID,
       set_sessionID, get_sessionID,
       set_developer_name, get_developer_name, set_module, get_module,
       set_appdir, get_appdir, set_appname, get_appname,
       set_topic, get_topic, set_intent, get_intent,
       read_config, match_config, get_config, is_in_config, get_all_config,
       set_config,
       is_config_valid, is_valid_or_end, set_config_prefix, reset_config_prefix,
       get_config_path,
       tryrun, try_read_textfile, ping,
       try_parse_JSON_file, try_parse_JSON, try_make_JSON,
       extract_slot_value, extract_multislot_values, is_in_slot, 
       is_on_off_matched, 
       read_time_from_slot, readable_date_time, readable_date,
       set_GPIO, print_debug, print_log,
       switchShelly1, switchShelly25relay, moveShelly25roller,
       all_occuresin, one_occursin, all_occursin_order,
       is_false_detection,
       db_write_payload, db_write_value, db_read_entry, db_read_value, 
       db_has_entry,
       scheduler_add_trigger, scheduler_add_actions, scheduler_make_action,
       scheduler_delete_all, scheduler_delete_topic, scheduler_delete_by_origin,
       getWeather,
       get_language, set_language

end # module
