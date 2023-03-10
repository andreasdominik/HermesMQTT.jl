"""
    register_intent_action_module(intent, in_module, action)
    register_intent_action(intent, action)

Add an intent to the list of intents to subscribe to.
Each function that shall be executed if Snips recognises
an intent must be registered with this function.
The framework will collect all these links, subscribe to all
needed intents and execute the respective functions.
The links need not to be unique (in both directions):
It is possible to assign several functions to one intent
(all of them will be executed), or to assign one function to
more then one intent.

The variant with only `(intent, action)` as arguments
applies the current DEVEL_NAME and MODULE as
stored in the framework.
The variants registerIntent... create topics with prefix
`hermes/intent/developer:intent`.

## Arguments:
- intent: Name of the intend (without developer name)
- developer: Name of skill developer
- in_module: current module (can be accessed with `@__MODULE__`)
- action: the function to be linked with the intent
"""
function register_intent_action_module(intent, in_module, action)

    global SKILL_INTENT_ACTIONS
    topic = "hermes/intent/$intent"
    push!(SKILL_INTENT_ACTIONS, (intent, topic, in_module, action))
end


# this version is defined in each skill locally:

# function register_intent_action(intent, action)
# 
#     global SKILL_INTENT_ACTIONS
#     topic = "hermes/intent/$intent"
#     push!(SKILL_INTENT_ACTIONS, (intent, topic, MODULE_NAME, action))
#     register_intent_action(intent, get_module(), action)
# end



"""
    register_on_off_action_module(action, module_name)
    register_on_off_action(action)

Register the action function with the generic HermesMQTT on/off-intent.
The register function will register to the intent 
`HermesMQTT:on_off<xy>` where `xy` is the languagecode of the currently 
running app.    
Make sure, that the intent for your language exists and create one 
if necessary.
"""
function register_on_off_action_module(action, module_name)

    lang = get_language()
    intent = "$HERMES_ON_OFF_INTENT<$lang>"

    global SKILL_INTENT_ACTIONS
    topic = "hermes/intent/$intent"
    push!(SKILL_INTENT_ACTIONS, (intent, topic, module_name, action))
end
#
# register_intent_action is defined in each skill locally
#





"""
    register_trigger_action(intent, developer, inModule, action)
    register_trigger_action(intent, action)

Add an intent to the list of intents to subscribe to.
Each function that shall be executed if Snips recognises
The variants registerTrigger... create topics with prefix
`QnD/trigger/developer:intent`.

See `register_intent_action()` for details.
"""
function register_trigger_action(intent, developer, inModule, action)

    global SKILL_INTENT_ACTIONS
    topic = "qnd/trigger/$intent"
    push!(SKILL_INTENT_ACTIONS, (intent, developer, topic, inModule, action))
end

function register_trigger_action(intent, action)

    registerTriggerAction(intent, get_developer_name(), 
                get_module(), action)
end





# """
#     get_intent_actions()
# 
# Return the list of all intent-function mappings for this app.
# The function is exported to deliver the mappings
# to the Main context.
# """
# function get_intent_actions()
# 
#     global SKILL_INTENT_ACTIONS
#     return SKILL_INTENT_ACTIONS
# end
# 
# must be defined locally in each skill



# unused!
#
# """
#     setIntentActions(intent_actions)
# 
# Overwrite the complete list of all intent-function mappings for this app.
# The function is exported to get the mappings
# from the Main context.
# 
# ## Arguments:
# * intent_actions: Array of intent-action mappings as Tuple of
#                  (intent::AbstractString, developer::AbstractString,
#                   inModule::Module, action::Function)
# """
# function set_intent_actions(intent_actions)
# 
#     global SKILL_INTENT_ACTIONS
#     SKILL_INTENT_ACTIONS = intent_actions
# end


"""
    publish_system_trigger(topic, trigger; develName = get_developer_name())

Publish a system trigger with topic and payload.

## Arguments:
* topic: MQTT topic, with or w/o the developername. If no
         developername is included, CURRENT_DEVEL_NAME will be added.
         If the topic does not start with `qnd/trigger/`, this
         will be added.
* trigger: specific payload for the trigger.
"""
function publish_system_trigger(topic, trigger; develName=get_developer_name())

    (topic, payload) = make_system_trigger(topic, trigger, develName=develName)

    print_debug("PUBLISH payload: $payload")
    publish_MQTT(topic, payload)
end



"""
    make_system_trigger(topic, trigger; develName=get_developer_name())

Return (topic, payload) where topic is the fully quallified topic and
payload a Dict() that include a system trigger topic and payload.

## Arguments:
* topic: MQTT topic, with or w/o the developername. If no
         developername is included, CURRENT_DEVEL_NAME will be added.
         If the topic does not start with `qnd/trigger/`, this
         will be added.
* trigger: specific payload for the trigger.
"""
function make_system_trigger(topic, trigger; develName=get_developer_name())

    print_debug("TRIGGER: $trigger")
    topic = expand_topic(topic, develName)

    payload = Dict( :topic => topic,
                    :origin => "$(get_module())",
                    :time => "$(now())",
                    :sessionId => get_sessionID(),
                    :siteId => get_siteID(),
                    :trigger => trigger
                  )

    print_debug("PAYLOAD: $payload")
    return topic, payload
end

function expand_topic(topic, develName=get_developer_name())

    # do NOT include developer name in intent!
    #
    # if !occursin(r":", topic)
    #     topic = "$develName:$topic"
    # end
    # if !occursin(r"^qnd/trigger/", topic)
    #     topic = "qnd/trigger/$topic"
    # end
    return topic
end




"""
    publish_listen_trigger(mode)

Publish a stop-listen or start-listen trigger to make
the assistant stop listening to voice commands.

## Arguments:
`mode`: one of `:stop` or `:start`

## Details:
The Skill `HermesDoNotListen` must be installed in order to respond to the
trigger,otherwise the trigger will be ignored.

The trigger can be used to avoid false activation while watching TV or
listening to the radio. Just publish the trigger as part of the
"watch-TV-command".
The trigger will disable all intents, listed in the `config.ini` and
enable the `listen-again` intent only. The `listen-again` intent is
double-checking any voice activation, so that only exact matches of commands
(like "hör wieder zu" in German or "listen again" in English)
will activate the intent.

The trigger must have the following JSON format:
    {
      "target" : "qnd/trigger/andreasdominik:HermesDoNotListen",
      "origin" : "HermesScheduler",
      "sessionId": "1234567890abcdef",
      "siteId" : "default",
      "time" : "timeString",
      "trigger" : {
          "command" : "stop"   // or "start"
          }
    }
"""
function publish_listen_trigger(mode)

    if mode in [:start, :stop]
        trigger = Dict( :command => mode)
        publish_system_trigger("HermesDoNotListen", trigger)
    end
end



"""
    publish_schedule_command(command, exec_time, origin; 
                    siteID=get_site_id(), sessionID=mk_session_id())

Publish a command to be executed at a specific time.
"""
function publish_schedule_command(command, exec_time, origin; 
                    siteID=get_siteID(), sessionID=mk_sessionID())
    
    payload = Dict(:intent => "Scheduler:AddAction",
                   :action => "add action",
                   :sessionId => sessionID,
                   :siteId => siteID,
                   :type => "command", 
                   :exec_time => exec_time,
                   :origin => origin,
                   :customData => command)
    publish_intent(payload, "susi/intent/Scheduler:AddAction")
end



"""
    match_device_room(skill, payload; slot_device="device", slot_room="room")

Find the device in a room by matching the slots of an intent (payload)
with the config.ini of a skill.

## Arguments:

* `skill`: skill name
* `payload`: intent payload
* `slot_device`: name of the slot for the device
* `slot_room`: name of the slot for the room

## Details

Devices are configured in the `config.ini` of a skill. The 
combination of `device` and `room` is used to match the slots
of an intent and must be unique within the skill.

A joker device may be defined to match any device, but it still needs to be 
unique - so this is only possible if there is a single device in a room
(e.g. `joker = light` makes it possible to call *turn on the light* in 
every room as long as there is only one light in the room **or** 
one of the lights is defined explicitly as type `light`).

Example:
```
joker = light

living_room:light = shelly1, lrmain.home.me
living_room:floor_lamp = shelly1, lrfloor.home.me

kitchen:ceiling_lamp = shelly1, kimain.home.me

stairs:ceiling_lamp = shelly1, stmain.home.me
stairs:wall_lamp = shelly1, stwall.home.me
```

In the exampe house, it is possible to call:
+ *turn on the light in the living room*: will turn on the *light*
+ *turn on the light in the kitchen*: will turn on the *ceiling_lamp*, beacuse it is 
  the only one.
+ *turn on the wall lamp in the stairs*: will turn on the *wall*
but it is not possible to call:
+ *turn on the light in the stairs*: because there is more than one light in the 
  stairs and no light is defined as type `light`. 

If no room is found in the slots of the intent, the site-ID of the intent
(i.e. the room in which the command is recorded) is used as room.
"""
function match_device_room(skill, payload; slot_device="device", slot_room="room")

    # get room:
    #
    room = extract_slot_value(slot_room, payload)
    if isnothing(room)
        room = get_siteID(payload)
    end

    if isnothing(room)
        publish_say(:no_room)
        print_log("No room found in intent payload or siteID")
        return nothing
    end

    # get device:
    #
    slot_device = extract_slot_value(slot_device, payload)
    if isnothing(slot_device)
        publish_say(:no_device)
        print_log("No device found in intent payload")
        return nothing
    end

    # match:
    #
    device = nothing
    if is_in_config_skill("$room:$slot_device", skill=skill)
        device = "$room:$slot_device"
    
    elseif is_in_config_skill("joker", skill=skill) &&
           get_config_skill("joker", skill=skill) == slot_device

        devices = get_all_devices_in_room(skill, room)
        if length(devices) == 1
            device = "$room:$(devices[1])"
        elseif length(devices) > 1
            publish_say(:device_not_unique)
            print_log("Device $slot_device in room $room is not unique")
        end
    end

    if isnothing(device)
        publish_say(:device_not_found)
        print_log("No device $room_device in room $room")
    end
    return device
end

function get_all_devices_in_room(skill, room)
    
    devices = []
    for ((sk,param), value) in get_all_config()
        if "$sk" == skill && occursin(Regex("^$(room):"), "$param")
            push!(devices, "$param")
        end
    end

    devices = replace.(devices, Regex("^$(room):") => "")
    return devices
end