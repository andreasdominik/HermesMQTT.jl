#
# The main file for the App.
#
# DO NOT CHANGE THIS FILE UNLESS YOU KNOW
# WHAT YOU ARE DOING!
#
module TEMPLATE_SKILL

import Dates

const MODULE_DIR = @__DIR__
const APP_DIR = dirname(MODULE_DIR)
const SKILLS_DIR = dirname(APP_DIR)
const APP_NAME = basename(APP_DIR)

using HermesMQTT
Susi = HermesMQTT

Susi.load_two_configs(APP_DIR)
Susi.set_appdir(APP_DIR)
Susi.set_appname(APP_NAME)

include("api.jl")
include("skill-actions.jl")
include("config.jl")
read_language_sentences(APP_DIR)
include("exported.jl")


export getIntentActions, callbackRun

end
