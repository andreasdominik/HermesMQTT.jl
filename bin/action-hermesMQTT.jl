#!/usr/local/bin/julia
#
# main executable script of ADos's SniosHermesQnD framework.
# It loads all skills into one Julia environment.
#
# Normally, it is NOT necessary to change anything in this file,
# unless you know what you are doing!
#
# A. Dominik, April 2019, © GPL3
#

using HermesMQTT

# set config entries for dirs:
# get dir of framework installation and
# skill installations (tis file is assumed to be located at:
# <Skills-dir>/HermesMQTT/startup
#
# <Skills-dir>/HermesMQTT/ApplicationData/home.json   # database
# <Skills-dir>/Skill1.jl
# <Skills-dir>/Skill2.jl
# ...
# <Skills-dir>/HermesMQTT/config.ini
# <Skills-dir>/HermesMQTT/action-hermesMQTT.jl
# <Skills-dir>/HermesMQTTIntents/loader-hermes-intents.jl
#
#
const HERMES_MQTT_DIR = dirname(@__DIR__)
const SKILLS_DIR = dirname(HERMES_MQTT_DIR)

# println("HERMES_MQTT_DIR = $HERMES_MQTT_DIR")
# println("SKILLS_DIR = $SKILLS_DIR")

load_hermes_config(HERMES_MQTT_DIR)     # load config.ini of HermesMQTT

#
# disable yes/no, because it is too general!
# (activate only when needed!):
#
configure_intent(HermesMQTT.SUSI_YES_NO_INTENT, false)

# list of intents and related actions:
# (name of intent, name of developer, module, function to be executed)
#
INTENT_ACTIONS = Tuple{AbstractString, AbstractString, AbstractString,
                       Module, Function}[]


# search all dir-tree for files like loader-<name>.jl
#
loaders = AbstractString[]
for (root, dirs, files) in walkdir(SKILLS_DIR)

    files = filter(f->occursin(r"^loader-.*\.jl", f), files)
    paths = root .* "/" .* files
    append!(loaders, paths)
end

print_log("[HermesMQTT loader]: $(length(loaders)) skills found to load.")

for loader in loaders
    global INTENT_ACTIONS
    println("[HermesMQTT skill loader]: loading Julia app $loader.")
    include(loader)
end

# register HermesMQTT intents and triggers:
#
registster_trigger_action(HermesMQTT.SCHEDULE_TRIGGER_NAME,
                          "andreasdominik", HermesMQTT,
                          scheduler_action)

# run scheduler in background (listen to channels):
#
action_channel = Channel(64)
delete_channel = Channel(64)
@async HermesMQTT.start_scheduler()


# start listening to MQTT with main callback
#
const topics = [i[3] for i in INTENT_ACTIONS]
subscribe_to_topics(topics, HermesMQTT.main_callback)
