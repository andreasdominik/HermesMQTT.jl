"""
    register_intent_action(intent, developer, inModule, action)
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
- inModule: current module (can be accessed with `@__MODULE__`)
- action: the function to be linked with the intent
"""
function register_intent_action(intent, developer, inModule, action)

    global SKILL_INTENT_ACTIONS
    topic = "hermes/intent/$developer:$intent"
    push!(SKILL_INTENT_ACTIONS, (intent, developer, topic, inModule, action))
end


function register_intent_action(intent, action)

    register_intent_action(intent, get_developer_name(), 
                get_module(), action)
end




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
    topic = "qnd/trigger/$developer:$intent"
    push!(SKILL_INTENT_ACTIONS, (intent, developer, topic, inModule, action))
end

function register_trigger_action(intent, action)

    registerTriggerAction(intent, get_developer_name(), 
                get_module(), action)
end





"""
    get_intent_actions()

Return the list of all intent-function mappings for this app.
The function is exported to deliver the mappings
to the Main context.
"""
function get_intent_actions()

    global SKILL_INTENT_ACTIONS
    return SKILL_INTENT_ACTIONS
end




"""
    setIntentActions(intent_actions)

Overwrite the complete list of all intent-function mappings for this app.
The function is exported to get the mappings
from the Main context.

## Arguments:
* intent_actions: Array of intent-action mappings as Tuple of
                 (intent::AbstractString, developer::AbstractString,
                  inModule::Module, action::Function)
"""
function set_intent_actions(intent_actions)

    global SKILL_INTENT_ACTIONS
    SKILL_INTENT_ACTIONS = intent_actions
end


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

    if !occursin(r":", topic)
        topic = "$develName:$topic"
    end
    if !occursin(r"^qnd/trigger/", topic)
        topic = "qnd/trigger/$topic"
    end
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
