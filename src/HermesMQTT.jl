module HermesMQTT

using JSON
using StatsBase
using Dates
using Distributed
using Random
using UUIDs
using HTTP

include("utils.jl")
include("hermes-config.jl")
include("mqtt.jl")
include("hermes.jl")
include("intents.jl")
include("config.jl")
include("dates.jl")
include("db.jl")
include("gpio.jl")
include("shelly.jl")
include("weather.jl")
include("languages.jl")
include("callback.jl")
include("install.jl")

const HERMES_MQTT = "HermesMQTT"
PREFIX = nothing    # prefix for config.ini lines

# keep track of current actions:
# 
CURRENT = Dict(
    :language => "en",      # language code
    :prefix => nothing,     # prefix for parameter names
    :siteID => "default",
    :sessionID => "1",
    :devel_name => "unknown",
    :module => Main,
    :intent => "none",
    :app_dir => "",
    :app_name => "HermesMQTT")


# constants and
# default language and texts to en
#
const MODULE_NAME = @__MODULE__
const MODULE_DIR = @__DIR__
const APP_DIR = dirname(MODULE_DIR)
const APP_NAME = basename(APP_DIR)
const PACKAGE_BASE_DIR = dirname(dirname(pathof(@__MODULE__)))
const SKILLS_DIR = get_skills_dir()

const MQTT_TIMEOUT = 5    # cancel mqtt_subscribe after 5 seconds
const SUSI_ON_OFF_INTENT = "Susi:on_off"
const SUSI_YES_NO_INTENT = "Susi:yes_no"
const DEFAULT_LANG = "en"

const HERMES_ON_OFF_INTENT = "HermesMQTT:OnOff"   # <en>
LANGUAGE_TEXTS = Dict{Any, Any}()   # one entry for every language
                                    # with a Tuple as key (e.g. ("en", :ok) ...
FALSE_DETECTION = Dict{Any, Any}()  # one entry for each language 
                                    #   key is (language code, intent)
                                    #   val is (type, [vals])
                                    

# init config. Read of config.ini moved to starter script, because
# the Package is located anywhere...:
#
CONFIG_INI = Dict{Tuple{Symbol, Symbol}, Any}()
skills_dir = get_skills_dir()   # nothing if not yet configured/installed
if !isnothing(skills_dir)
    hermes_dir = joinpath(get_skills_dir(), "HermesMQTT.jl")
    load_hermes_config(hermes_dir)
end


# save home status database location in CONFIG_INI:
# dirname, filename and path (full path to database) 
#
action_channel = Channel(64)
delete_channel = Channel(64)






export subscribe_MQTT, read_one_MQTT, publish_MQTT, publish_MQTT_file,
       subscribe_to_intents, subscribe_to_topics, listen_to_intents_one_time,
       publish_end_session, publish_continue_session,
       publish_start_session_action, publish_start_session_notification,
       publish_hotword_on, publish_hotword_off,
       publish_nlu_query, publish_intent, publish_schedule_command,
       configure_intent,
       register_intent_action_module, 
       # get_intent_actions, set_intent_actions,
       ask_yes_no_unknown, ask_yes_or_no,
       publish_say,
       add_text, lang_text,
       set_siteID, get_siteID,
       set_sessionID, get_sessionID,
       set_developer_name, get_developer_name, set_module, get_module,
       set_appdir, get_appdir, set_appname, get_appname,
       set_topic, get_topic, set_intent, get_intent,
       read_config, match_config_skill, get_config_skill, is_in_config_skill, get_all_config,
       is_config_valid, is_valid_or_end, set_config_prefix, reset_config_prefix,
       get_config_path, read_language_sentences,
       tryrun, try_read_textfile, ping,
       try_parse_JSON_file, try_parse_JSON, try_make_JSON,
       extract_slot_value, extract_multislot_values, is_in_slot, 
       is_on_off_matched, 
       read_time_from_slot, readable_date_time, readable_date,
       set_GPIO, print_debug_skill, print_log_skill,
       switch_shelly_1, switch_shelly_25_relay, move_shelly_25_roller,
       all_occuresin, one_occursin, all_occursin_order,
       is_false_detection,
       db_write_entry, db_write_value, db_read_entry, db_read_value, 
       db_has_entry,
       get_weather,
       get_language, set_language, set_config, 
       load_hermes_config, load_skill_config, load_two_configs,
       install, generate_skill, install_skill, update_skill,
       upload_intents

end # module
