#
# helper function for switching of a shelly device
#
#


"""
    switch_shelly_1(ip, action; 
            port=nothing, user=nothing, password=nothing)

Switch a shelly1 device with IP `ip` on or off, depending
on the value given as action and
return `true`, if successful.

## Arguments:
- `ip`: IP address or DNS name of Shelly1 device
- `action`: demanded action as symbol; one of `:on`, `:off`, `:push` or `:timer`.
            action `:push` will switch on for 200ms to simulate a push.
            action `:timer` will switch off after timer secs.
- `port`, `user`, `password`: if given, the device is accessed via
           http://user:password@ip:port

For the API-doc of the Shelly devices see:
`<https://shelly-api-docs.shelly.cloud>`.
"""
function switch_shelly_1(ip, action; 
            port=nothing, user=nothing, password=nothing)

    success = switch_shelly_25_relay(ip, 0, action; 
                port=port, user=user, password=password)
    if !success
        print_log("ERROR in switch_shelly_1 with ip $ip and action $action")
        publish_say("Try to switch a Shelly-one was not successful!")
    end

    return(success)
end



"""
    switch_shelly_25_relay(ip, relay, action; 
            port=nothing, user=nothing, password=nothing)

Switch the relay `relay` of a shelly2.5 device with IP `ip` on or off, depending
on the value given as action and return `true`, if successful.

## Arguments:
- `ip`: IP address or DNS name of Shelly2.5 device
- `relay`: Number of relay to be switched (0 or 1)
- `action`: demanded action as symbol; one of `:on`, `:off`, `push` or `:timer`.
            action `:push` will switch on for 200ms to simulate a push.

For the API-doc of the Shelly devices see:
`<https://shelly-api-docs.shelly.cloud>`.
"""
function switch_shelly_25_relay(ip, relay, action; 
            port=nothing, user=nothing, password=nothing)

    print_log("Switching Shelly1/2.5 $ip with action: $action")

    if !isnothing(port)
        ip = "$ip:$port"
    end
    if !isnothing(user) && !isnothing(password)
        ip = "$user:$password@$ip"
    end
    url = "http://$ip/relay/$relay"

    success = true
    if action == "on"
        cmd = "turn=on"
    elseif action == :timer
        cmd = "turn=on&timer=$timer"
    elseif action == "off"
        cmd = "turn=off"
    elseif action == "push"
        cmd = "turn=on"
    else
        print_log("ERROR in switch_shelly_25: action $action is not supported")
        publish_say("Try to switch a Shelly-two point five with an unsupported command!")
        success = false
    end
    try
        HTTP.get("$url?$cmd")
        if action == :push
            sleep(0.2)
            HTTP.get("$url?turn=off")
        end
    catch
        print_log("ERROR in switch_shelly_25: HTTP GET not successful!")
        publish_say("Try to switch a Shelly-two point five was not successful!")
        success = false
    end
        
    return success
end



"""
    move_shelly_25_roller(ip, action; pos=100, 
            port=nothing, user=nothing, password=nothing)

Move a roller with a shelly2.5 device with IP `ip`
and return `true`, if successful.

## Arguments:
- `ip`: IP address or DNS name of Shelly2.5 device
- `action`: demanded action as symbol; one of `:open`, `:close`, `:stop`
            or `:to_pos`.
- `pos`: desired position in percent.

For the API-doc of the Shelly devices see:
`<https://shelly-api-docs.shelly.cloud>`.
"""
function move_shelly_25_roller(ip, action; pos=100,
            port=nothing, user=nothing, password=nothing)

    # remove http:// from ip:
    #
    ip = replace(ip, "http://"=>"")

    if !isnothing(port)
        ip = "$ip:$port"
    end
    if !isnothing(user) && !isnothing(password)
        ip = "$user:$password@$ip"
    end
    url = "http://$ip/roller/0"

    success = true
    if action == :open
        cmd = "go=open"
    elseif action == :close
        cmd = "go=close"
    elseif action == :stop
        cmd = "go=stop"
    elseif action == :to_pos
        cmd = "go=to_pos&roller_pos=$pos"
    else
        print_log("ERROR in switch_shelly_25_roller: action $action is not supported")
        publish_say("Try to switch a Shelly-two point five with an unsupported command!")
        success = false
    end
    println("$url?$cmd")
    try
        HTTP.get("$url?$cmd")
    catch
        print_log("ERROR in switch_shelly_25: HTTP GET not successful!")
        publish_say("Try to switch a Shelly-two point five was not successful!")
        success = false
    end

    return success
end
