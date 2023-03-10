# Simple quick-and-dirty wrapper around mosquitto
# to publish and subscribe to messages.
#
# A. Dominik, 2019
#


"""
    subscribe_MQTT(topics, callback)

Listen to one or more topics.

## Arguments
* `topics`: AbstractString or List of AbtsractString to define
          topics to subscribe
* `callback`: Function to be executed for a incoming message.

## Details:
The callback function has the signature f(topic, payload), where
topic is a String and payload a Dict{Symbol, Any} with the content
of the payload (assuming, that the payload is in JSON-format) or
a String, if the payload is not a valid JSON.

The callback function is spawned.
"""
function subscribe_MQTT(topics, callback)

    cmd = construct_MQTT_cmd(topics)

    intents = Channel(32)
    @async while true
        retrieved = run_one_MQTT(cmd)
        put!(intents, retrieved)
    end


    # process intents from channel:
    #
    while true
        retrieved = take!(intents)
        (topic, payload) = parse_MQTT(retrieved)

        if !isnothing(topic) && !isnothing(payload)
            if match_config(:debug, "no_parallel")
                callback(topic, payload)
            else
                @async callback(topic, payload)
            end
        end
    end
end



"""
    read_one_MQTT(topics; timeout=TIMEOUT)

Listen to one or more topics until one message is
retrieved and return topic as string and payload as Dict
or as String if JSON parsing is not possible).

## Arguments
* `topics`: AbstractString or List of AbstractString to define
          topics to subscribe
"""
function read_one_MQTT(topics, timeout=MQTT_TIMEOUT)

    cmd = construct_MQTT_cmd(topics; timeout=timeout)

    retrieved = run_one_MQTT(cmd)
    topic, payload = parse_MQTT(retrieved)

    return topic, payload
end



#
#
# low-level mosquito-commands:
#
#

"""
    construct_MQTT_cmd(topics; hostname = nothing, port = nothing
                               user=nothing, password=nothing,
                               timeout=nothing)

Build the shell cmd to retrieve one MQTT massege with mosquito_sub.
Timeout is in sec.
"""
function construct_MQTT_cmd(topics; hostname=nothing, port=nothing,
                            user=nothing, password=nothing,
                            timeout=nothing)

    params = make_mosquitto_params(hostname=hostname, port=port, 
                                   user=user, password=password,
                                   timeout=timeout)

    cmd = `mosquitto_sub --qos 2 -v -C 1 $params`

    if topics isa AbstractString
        topics = [topics]
    end
    unique!(topics)
    for topic in topics
        cmd = `$cmd -t $topic`
    end

    cmd = Cmd(cmd, ignorestatus = true)
    return cmd
end

function make_mosquitto_params(;hostname=nothing, port=nothing,
                               user=nothing, password=nothing,
                               timeout=nothing)

    isnothing(hostname) && (hostname = get_config(:mqtt_host))
    isnothing(port) && (port = get_config(:mqtt_port))
    isnothing(user) && (user = get_config(:mqtt_user))
    isnothing(password) && (password = get_config(:mqtt_password))

    params = ``
    if !isnothing(hostname)
        params = `$params -h $hostname`
    end

    if !isnothing(port)
        params = `$params -p $port`
    end

    if !isnothing(user)
        params = `$params -u $user`
    end

    if !isnothing(password)
        params = `$params -P $password`
    end

    if !isnothing(timeout)
        params = `$params -W $timeout`
    end

    return params
end

"""
    run_one_MQTT(cmd)

Run the cmd return mosquito_sub output.
"""
function run_one_MQTT(cmd)

    print_log("MQTT-command: $cmd")
    return read(cmd, String)
end


"""
    parse_MQTT(message)

Parse the output of mosquito_sub -v and return topic as string
and payload as Dict (or String if JSON parsing is not possible)
"""
function parse_MQTT(message)

    # extract topic and JSON payload:
    #
    rgx = r"(?<topic>[^[:space:]]+) (?<payload>.*)"s
    m = match(rgx, message)
    if !isnothing(m)
        topic = strip(m[:topic])
        payload = try_parse_JSON(strip(m[:payload]))
    else
        print_log("Unable to parse MQTT message/timeout")
        topic = nothing
        payload = Dict()
    end

    return topic, payload
end





"""
    publish_MQTT(topic, payload; file=false)

Publish a MQTT message.

## Arguments
+ `topics`: String with the topic
+ `payload`: Dict() with message
+ `file`: if `true`, the file will be sent (via `-f payload`, otherwise
          the payload will be sent as JSON string via `-m`)
"""
function publish_MQTT(topic, payload; file=false)

    # build cmd as a list of strings:
    #
    params = make_mosquitto_params()
    cmd = `mosquitto_pub --qos 2 $params -t $topic`

    if file
        cmd = `$cmd -f $payload`
    else
        json = try_make_JSON(payload)
        if json isa AbstractString && length(json) > 0
            cmd = `$cmd -m $json`
        else
            print_log("ERROR: Unable to create JSON from payload!")
        end
    end

    cmd = Cmd(cmd, ignorestatus = true)

    print_log(cmd)
    run(cmd, wait=true)  # false maybe possible?
end


"""
    publish_MQTT_file(topic, fname)

Publish a MQTT message with a file as payload.

## Arguments
* `topics`: String with the topic
* `fname`: full path and name of file to be published
"""
function publish_MQTT_file(topic, fname)

    publish_MQTT(topic, fname, file=true)
end
