#
# The main file for the App.
#
# DO NOT CHANGE THIS FILE UNLESS YOU KNOW
# WHAT YOU ARE DOING!
#
module TEMPLATE_SKILL

import Dates

const MODULE_NAME = @__MODULE__
const MODULE_DIR = @__DIR__
const APP_DIR = dirname(MODULE_DIR)
const SKILLS_DIR = dirname(APP_DIR)
const APP_NAME = basename(APP_DIR)

# List of intents to listen to:
# (intent, topic, module, skill-action)
#
SKILL_INTENT_ACTIONS = Tuple{AbstractString, AbstractString, 
                             Module, Function}[]

using HermesMQTT
Susi = HermesMQTT

Susi.load_skill_config(APP_DIR, skill=APP_NAME)

Susi.set_module(MODULE_NAME)
Susi.set_appdir(APP_DIR)
Susi.set_appname(APP_NAME)

include("api.jl")
include("skill-actions.jl")
include("exported.jl")
include("config.jl")
read_language_sentences(APP_DIR)

# mask the following functions:
#
get_config(name; o...) = HermesMQTT.get_config_skill(name; skill=APP_NAME, o...)
is_in_config(name; one_prefix=nothing) = 
    HermesMQTT.is_in_config_skill(name; skill=APP_NAME, one_prefix=one_prefix)           
match_config(name, val::AbstractString; one_prefix=nothing) = 
    HermesMQTT.match_config_skill(name, val; skill=APP_NAME, one_prefix=one_prefix)
print_log(s) = HermesMQTT.print_log_skill(s; skill=APP_NAME)
print_debug(s) = HermesMQTT.print_debug_skill(s; skill=APP_NAME)


export 
get_intent_actions, register_intent_action, register_on_off_action,
callback_run

end

