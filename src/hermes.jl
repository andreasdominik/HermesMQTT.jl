# Hermes wrapper
#
#
# A. Dominik, 2019
#



"""
    subscribe_to_intents(intents, callback; moreTopics = nothing)

Subscribe to one or a list of intents and listen forever and run the callback
if a matching intent is recieved.

## Arguments:
* `intents`: Abstract String or List of Abstract Strings to define
           intents to subscribe. The intents will be expanded
           to topics (i.e. "hermes/intent/SwitchOnLight")
* `callback`: Function to be executed for a incoming message
* `moreTopics`: keyword arg to provide additional topics to subscribe
            (complete names of of topics).

## Details:
The callback function has the signature f(topic, intentMessage), where
topic is a String and intentMessage a Dict{Symbol, Any} with the content
of the payload (assuming, that the payload is in JSON-format) or
a String, if the payload is not valid JSON.
The callback function is spawned and the function is listening
to the MQTT server while the callback is executed.
"""
function subscribe_to_intents(intents, callback; moreTopics = nothing)

    topics = "hermes/intent/" .* intents
    topics = add_strings_to_array!(topics, moreTopics)
    subscribe_to_topics(topics, callback)
end


"""
    subscribe_to_topics(topics, callback)

Subscribe to one or a list of topics and listen forever and run the callback
if a matching intent is recieved.

## Arguments:
* `topics`: Abstract String or List of Abstract Strings to define
           topics to subscribe.
* `callback`: Function to be executed for a incoming message

See `subscribe2Intents()` for details.
"""
function subscribe_to_topics(topics, callback)

    subscribe_MQTT(topics, callback)
end


"""
    listen_to_intents_one_time(intents; moreTopics = nothing)

Subscribe to one or a list of Intents, but listen only until one
matching intent is recognised.

## Arguments
* `intents`: AbstractString or List of AbstractString to define
           intents to subscribe or nothing
* `moreTopics`: keyword arg to provide additional topics to subscribe to.

## Value:
Return values are topic (as String) and payload (as Dict or as
String if JSON parsing is not possible).
If the topic is an intent, only the intent id is returned
(i.e.: devname:intentname without the leading hermes/intent/)
"""
function listen_to_intents_one_time(intents; moreTopics = nothing)

    if isnothing(intents)
        topics = String[]
    else
        topics = "hermes/intent/" .* intents
    end
    topics = add_strings_to_array!(topics, moreTopics)

    topic, payload = read_one_MQTT(topics)
    intent = topic
    if intent isa AbstractString
        intent = replace(topic, "hermes/intent/"=>"")
    end

    return intent, payload
end



"""
    ask_yes_no_unknown(question)

Ask the question and listen to the intent "ADoSnipsYesNoDE"
and return :yes if "Yes" is answered or :no if "No" or
:unknown otherwise.

## Arguments:
* `question`: String with the question to be uttered by Snips
"""
function ask_yes_no_unknown(question)

    intentListen = "andreasdominik:ADoSnipsYesNoDE"
    topicsListen = ["hermes/nlu/intentNotRecognized", "hermes/error/nlu",
                    "hermes/dialogueManager/intentNotRecognized"]
    slotName = "yes_or_no"

    listen = true
    intent = ""
    payload = Dict()

    configureIntent(intentListen, true)
    publish_MQTT(TOPIC_NOTIFICATION_OFF, Dict(:siteId => get_siteID()))

    question = langText(question)
    publish_continue_session(question, sessionID=get_sessionID,
              intentFilter=intentListen,
              customData=nothing, sendIntentNotRecognized=true)

    topic, payload = listen_to_intents_one_time(intentListen,
                            moreTopics = topicsListen)

    configure_intent(intentListen, false)

    if !isnothing(get_config(:notifications)) && get_config(:notifications) == "on"
        publish_MQTT(TOPIC_NOTIFICATION_ON, Dict(:siteId => get_siteID()))
    end

    if is_in_slot(payload, slotName, "YES")
        return :yes
    elseif isInSlot(payload, slotName, "NO")
        return :no
    else
        return :unknown
    end
end


"""
    ask_yes_or_no(question)

Ask the question and listen to the intent "ADoSnipsYesNoDE"
and return :true if "Yes" or "No" otherwise.

## Arguments:
* `question`: String with the question to uttered
"""
function ask_yes_or_no(question)

    answer = ask_yes_no_unknown(question)
    return answer == :yes
end



"""
    publish_end_session(text; sessionID=get_sessionID)

MQTT publish end session.

## Arguments:
* `sessionId`: ID of the session to be terminated as String.
             If omitted, sessionId of the current will be inserted.
* `text`: text to be said via TTS
"""
function publish_end_session(text=nothing, sessionID=get_sessionID())

    text = lang_text(text)
    payload = Dict(:sessionId => sessionID)
    if !isnothing(text)
        payload[:text] = text
    end
    publish_MQTT("hermes/dialogueManager/endSession", payload)

    # wait for end session:
    #
    (topic, payload) = read_one_MQTT("hermes/dialogueManager/sessionEnded")
end




"""
    publish_continue_session(text; sessionID=get_sessionID(),
         intentFilter = nothing,
         customData = nothing, sendIntentNotRecognized = false)

MQTT publish continue session.

## Arguments:
* `sessionID`: ID of the current session as String
* `text`: text to be said via TTS
* `intentFilter`: Optional Array of String - a list of intents names to
                restrict the NLU resolution on the answer of this query.
* `customData`: Optional String - an update to the session's custom data.
* `sendIntentNotRecognized`: Optional Boolean -  Indicates whether the
                dialogue manager should handle non recognized intents
                by itself or sent them as an Intent Not Recognized for
                the client to handle.
"""
function publish_continue_session(text; sessionID=get_sessionID(),
         intentFilter=nothing,
         customData=nothing, sendIntentNotRecognized=false)

    text = lang_text(text)
    payload = Dict{Symbol, Any}(:sessionId => sessionID, :text => text)

    if !isnothing(intentFilter)
        if intentFilter isa AbstractString
            intentFilter = [intentFilter]
        end
        payload[:intentFilter] = intentFilter
    end
    if !isnothing(customData)
        payload[:customData] = customData
    end
    if !isnothing(sendIntentNotRecognized)
        payload[:sendIntentNotRecognized] = sendIntentNotRecognized
    end

    publish_MQTT("hermes/dialogueManager/continueSession", payload)
end


"""
    publish_start_session_action(text; siteID=get_siteID(),
         intentFilter=nothing, sendIntentNotRecognized=false,
         customData=nothing)

MQTT publish start session with init action

## Arguments:
* `siteID`: ID of the site in which the session is started
* `text`: text to be said via TTS
* `intentFilter`: Optional Array of String - a list of intent names to
                restrict the NLU resolution of the answer of this query.
* `sendIntentNotRecognized`: Optional Boolean -  Indicates whether the
                dialogue manager should handle non recognized intents
                by itself or sent them as an Intent Not Recognized for
                the client to handle.
* `customData`: data to be sent to the service.
"""
function publish_start_session_action(text; siteID=get_siteID(),
                intentFilter=nothing, sendIntentNotRecognized=false,
                customData=nothing)

    text = lang_text(text)

    if !isnothing(intentFilter)
        if intentFilter isa AbstractString
            intentFilter = [intentFilter]
        end
    end

    init = Dict(:type => "action",
                :text => text,
                :canBeEnqueued => true,
                :sendIntentNotRecognized => sendIntentNotRecognized)

    if !isnothing(intentFilter)
        init[:intentFilter] = intentFilter
    end

    publish_start_session(siteID, init, 
                customData=customData, wait=true)
end


"""
    publish_start_session_notification(text; siteID=get_siteID(),
                                    customData=nothing)

MQTT publish start session with init notification

## Arguments:
* `siteID`: siteID
* `text`: text to be said via TTS
* `customData`: data to be sent to the service.
"""
function publish_start_session_notification(text; siteID=get_siteID(),
                customData = nothing)

    text = lang_text(text)
    init = Dict(:type => "notification",
                :text => text)

    publish_start_session(siteID, init, 
                customData=customData, wait=true)
end



"""
    publish_start_session(siteID, init; customData=nothing,
                        wait=true)

Worker function for publish start session; called for
start session topics of type action or notification.
"""
function publish_start_session(siteID, init; customData=nothing,
                             wait=true)

    payload = Dict{Symbol, Any}(
                :siteId => siteID,
                :init => init)

    if !isnothing(customData)
        payload[:customData] = customData
    end

    publishMQTT("hermes/dialogueManager/startSession", payload)
end





"""
    publish_say(text; sessionID=get_sessionID(), siteID=nothing,
                    lang=LANG, id=nothing, wait=true)

Let the TTS say something.

The variant with a Symbol as first argument looks up the phrase in the
dictionary of phrases for the selected language by calling
`getText()`.

## Arguments:
* `text`: text to be said via TTS
* `lang`: optional language code to use when saying the text.
        If not specified, default language will be used
* `sessionId`: optional ID of the session if there is one
* `id`: optional request identifier. If provided, it will be passed back
      in the response on hermes/tts/sayFinished.
* `wait`: wait until the massege is spoken (i.i. wait for the
        MQTT-topic)
"""
function publish_say(text; sessionID=get_sessionID(),
                    siteID=get_siteID(), lang=get_language(),
                    id=nothing, wait=true)

    text = lang_text(text)
    text = replace(text, r"\n|\r"=>" ")
    payload = Dict(:text => text, :siteId => siteID)
    payload[:lang] = lang
    payload[:sessionId] = sessionID

    # make unique ID:
    #
    if isnothing(id)
        id = randstring(25)
    end
    payload[:id] = id

    publish_MQTT("hermes/tts/say", payload)

    # wait until finished:
    #
    while wait
        topic, payload = read_one_MQTT("hermes/tts/sayFinished")
        if !haskey(payload, :id)
            print_log("ERROR: sayFinished retrieved without id!")
            wait = false
            sleep(3)
        elseif payload[:id] == id
            wait = false
        end
    end
end


"""
    is_on_off_matched(payload, device_name; siteID=get_siteID())

Action to be combined with the ADoSnipsOnOFF intent.
Depending on the payload the function returns:
* :on if "on"
* :off if "off"
* :matched, if the device is matched but no on or off
* :unmatched, if one of
    * wrong siteId
    * wrong device
## Arguments:
* `payload`: payload of intent
* `siteId`: siteId of the device to be matched with the payload of intent
            if `siteId == "any"`, the device will be matched w/o caring
            about siteId or room.
* `device_name` : name of device to be matched with the payload of intent
"""
function is_on_off_matched(payload, device_name; siteID=get_siteID())

    result = :unmatched

    if siteID == "any"
        commandSiteID = siteID
    else
        commandSiteID = extract_slot_value(payload, "room")
        if isnothing(commandSiteID)
            commandSiteID = payload[:siteId]
        end
    end

    printDebug("siteID: $siteID")
    printDebug("payload[:siteId]: $(payload[:siteId])")
    printDebug("commandSiteID: $commandSiteID")
    printDebug("device_name: $device_name")

    if commandSiteID == siteID

        # test device name from payload
        #
        if is_in_slot(payload, "device", device_name)
            if is_in_slot(payload, "on_or_off", "ON")
                result = :on
            elseif is_in_slot(payload, "on_or_off", "OFF")
                result = :off
            else
                result = :matched
            end
        end
    end
    return result
end




"""
    configure_intent(intent, on)

Enable or disable an intent.


* `intent`: one intent to be configured
* `on`: boolean value; if `true`, the intent is enabled; if `false`
  it is disabled.
 """
function configure_intent(intent, on)

    topic = "hermes/dialogueManager/configure"

    payload = Dict(:siteId=>get_siteID,
                   :intents=>[Dict(:intentId=>intent, :enable=>on)])

    publish_MQTT(topic, payload)
end



"""
    is_valid_or_end(param; error_msg = "mandatory parameter is nothing")

End the session, with the message, if the param is `nothing`
and returns false or true otherwise.

Function is a shortcut:
```Julia
if isnothing(param)
    publishEndSession(:error)
    return true
end
```
is:
```Julia
is_valid_or_end(param, :error) || return true
```

## Arguments:
* param: any value (from slot or config.ini) that may be `nothing`
* errorMsg: Error as string or key of a text in the
  languages Dict (::Symbol).
"""
function is_valid_or_end(param; error_msg)

    if isnothing(param) || length(param) < 1
        publish_end_session(error_msg)
        return false
    else
        return true
    end
end


"""
    function publish_hotword_on(siteID)

Publish a hotword-on topic for the siteID.

## Arguments:
* siteID: mandatory argument siteID must be given as String (no default)
"""
function publish_hotword_on(siteID)

    publish_hotword_on_off(:on, siteID)
end



"""
    function publish_hotword_off(siteID)

Publish a hotword-off topic for the siteId.

## Arguments:
* siteID: mandatory argument siteId must be given as String (no default)
"""
function publish_hotword_off(siteID)

    publish_hotword_on_off(:off, siteID)
end




function publish_hotword_on_off(onoff, siteID)

    if onoff == :off
        topic = "hermes/hotword/toggleOff"
    else
        topic = "hermes/hotword/toggleOn"
    end

    payload = Dict(:siteId=>siteID,
                   :sessionId=>"no_session")

    publish_MQTT(topic, payload)
end
