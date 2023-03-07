# topics:
#
#
#
# Helper function for JSON:
#
#
"""
    try_parse_JSON(text)

parses a JSON and returns a hierarchy of Dicts{Symbol, Any} and Arrays with
the content or a string (text), if text is not a valid JSON, the raw string is
returned.
"""
function try_parse_JSON(text)

    jsonDict = Dict()
    try
        jsonDict = JSON.parse(text)
        jsonDict = key2symbol(jsonDict)
    catch
        jsonDict = text
    end

    return jsonDict
end





"""
    key2symbol(arr::Array)

Wrapper for key2symbol, if 1st hierarchy is an Array
"""
function key2symbol(arr::Array)

    return [key2symbol(elem) for elem in arr]
end


"""
    key2symbol(dict::Dict)

Return a new Dict() with all keys replaced by Symbols.
d is scanned hierarchically.
"""
function key2symbol(dict::Dict)

    mkSymbol(s) = Symbol(replace(s, r"[^a-zA-Z0-9]"=>"_"))

    d = Dict{Symbol}{Any}()
    for (k,v) in dict

        if v isa Dict
            d[mkSymbol(k)] = key2symbol(v)
        elseif v isa Array
            d[mkSymbol(k)] = [(elem isa Dict) ? key2symbol(elem) : elem for elem in v]
        else
            d[mkSymbol(k)] = v
        end
    end
    return d
end

"""
    try_make_JSON(payload)

Create a JSON representation of the input (nested Dict or Array)
or return an empty string if not possible.
"""
function try_make_JSON(payload)

    json = Dict()
    try
        json = JSON.json(payload)
    catch
        json = ""
    end

    return json
end


"""
    try_parse_JSON_file(fname; quiet = false)

Parse a JSON file and return a hierarchy of Dicts with
the content.
* keys are changed to Symbol
* on error, an empty Dict() is returned

## Arguments:
- fname: filename
- quiet: if false Snips utters an error message
"""
function try_parse_JSON_file(fname; quiet = false)

    json = Dict()
    try
        json = JSON.parsefile( fname)
        json = key2symbol(json)
    catch
        msg = ERRORS_EN[:error_json]
        if ! quiet
            publish_say(msg)
        end
        json = Dict()
    end
    return json
end


"""
    set_siteID(siteID)

Set the siteID in the Module HermesMQTT
(necessary to direct the say() output to the current room)
"""
function set_siteID(siteID)

    global CURRENT[:siteID] = siteID
end

"""
    get_siteID()

Return the siteID in the Module HermesMQTT
(necessary to direct the say() output to the current room)
"""
function get_siteID()

    return CURRENT[:siteID]
end



"""
    set_sessionID(sessionID)

Set the sessionId in the Module SnipsHermesQnD.
The sessionId will be used to publish Hermes messages
inside a runing session. The framework handles this in the background.

## Arguments:
* sessionId: as String from a Hermes payload.
"""
function set_sessionID(sessionID)

    global CURRENT[:sessionID] = sessionID
end

"""
    get_sessionID()

Return the sessionId of the currently running session.
"""
function get_sessionID()

    return CURRENT[:sessionID]
end



"""
    set_developer_name(name)

Set the developer name of the currently running app in the Module SnipsHermesQnD.
The framework adds the name to MQTT messages in the background.

## Arguments:
* name: Name of the developer of the current app
        i.e. the part before the colon of an intent name.
"""
function set_developer_name(name)

    global CURRENT[:devel_name] = name
end

"""
    get_developer_name()

Return the name of the develpper of the currently running app.
"""
function get_developer_name()

    return CURRENT[:devel_name]
end



"""
    set_module(currentModule)

Set the module of the currently running app in SnipsHermesQnD.
The framework uses this in the background.

## Arguments:
* currentModule: The module in which the current skill is running.
                 (acessible via marco `@__MODULE__`)
"""
function set_module(currentModule)

    global CURRENT[:module] = currentModule
end

"""
    get_module()

Return the module of the currently running app.
"""
function get_module()

    return CURRENT[:module]
end





"""
    set_topic(topic)

Set the topic for which the currently running app is working.
The framework uses this in the background.

## Arguments:
* topic: name of current topic
"""
function set_topic(topic)

    global CURRENT[:topic] = topic
end

"""
    get_topic()

Return the topic of the currently running app.
"""
function get_topic()

    return CURRENT[:topic]
end


"""
    set_intent(payload)

Set the intent for which the currently running app is working.
The framework uses this in the background.

## Arguments:
* topic: name of current topic
"""
function set_intent(payload)

    if haskey(payload, :intent) && 
            payload[:intent] isa Dict && 
            haskey(payload[:intent], :intentName)
        global CURRENT[:intent] = payload[:intent][:intentName]
    else
        global CURRENT[:intent] = "unkown_intent"
    end
end

"""
    get_intent()
    get_intent(payload)

Return the intent name of the currently running app.
"""
function get_intent()

    return CURRENT[:intent]
end

function get_intent(payload)

    if haskey(payload, :intent) && haskey(payload[:intent], :intentName)
        return payload[:intent][:intentName]
    else
        return "unkown_intent"
    end
end




"""
    set_language(lang)

Set the language in the Module HermesMQTT
"""
function set_language(lang)

    set_config(:language, lang, skill=HERMES_MQTT)
end

"""
    get_language()

Return the language in the Module HermesMQTT
"""
function get_language()

    return get_config(:language)
end
