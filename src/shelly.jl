#
# helper function for switching of a shelly device
#
#


"""
    switch_shelly_1(ip, action; timer = 10)

Switch a shelly1 device with IP `ip` on or off, depending
on the value given as action and
return `true`, if successful.

## Arguments:
- `ip`: IP address or DNS name of Shelly1 device
- `action`: demanded action as symbol; one of `:on`, `:off`, `push` or `:timer`.
            action `:push` will switch on for 200ms to simulate a push.
            action `:timer` will switch off after timer secs.
- `timer`: if action == `timer`, the device is switched on and
           off again after `timer` secs (default 10s).

For the API-doc of the Shelly devices see:
`<https://shelly-api-docs.shelly.cloud>`.
"""
function switch_shelly_1(ip, action; timer = 10)

    success = switch_shelly_25_relay(ip, 0, action; timer = timer)
    if !success
        print_log("ERROR in switchShelly1 with ip $ip and action $action")
        publish_say("Try to switch a Shelly-one was not successful!")
    end

    return(success)
end



"""
    switch_shelly_25_relay(ip, relay, action; timer = 10)

Switch the relay `relay` of a shelly2.5 device with IP `ip` on or off, depending
on the value given as action and return `true`, if successful.

## Arguments:
- `ip`: IP address or DNS name of Shelly2.5 device
- `relay`: Number of relay to be switched (0 or 1)
- `action`: demanded action as symbol; one of `:on`, `:off`, `push` or `:timer`.
            action `:push` will switch on for 200ms to simulate a push.
            action `:timer` will switch off after timer secs.
- `timer`: if action == `timer`, the device is switched on and
           off again after `timer` secs (default 10s).

For the API-doc of the Shelly devices see:
`<https://shelly-api-docs.shelly.cloud>`.
"""
function switch_shelly_25_relay(ip, relay, action; timer = 10)

    print_log("Switching Shelly1/2.5 $ip with action: $action")
    success = false
    timeout = 10
    if action == :on
        cmd = `curl -v -m $timeout "http://$ip/relay/$relay?turn=on"`
        success = tryrun(cmd)
    elseif action == :timer
        cmd = `curl -v -m $timeout "http://$ip/relay/$relay?turn=on&timer=$timer"`
        success = tryrun(cmd)
    elseif action == :off
        cmd = `curl -v -m $timeout "http://$ip/relay/$relay?turn=off"`
        success = tryrun(cmd)
    elseif action == :push
        cmd = `curl -v -m $timeout "http://$ip/relay/$relay?turn=on"`
        success = tryrun(cmd)
        sleep(1)
        cmd = `curl -v -m $timeout "http://$ip/relay/$relay?turn=off"`
        success = tryrun(cmd)
    else
        print_log("ERROR in switch_shelly_25: action $action is not supported")
        publish_say("Try to switch a Shelly-two point five with an unsupported command!")
    end

    return(success)
end



"""
    move_shelly_25_roller(ip, action; pos = 100, duration = 1)

Move a roller with a shelly2.5 device with IP `ip`
and return `true`, if successful.

## Arguments:
- `ip`: IP address or DNS name of Shelly2.5 device
- `action`: demanded action as symbol; one of `:open`, `:close`, `:stop`
            or `:to_pos`.
- `pos`: desired position in percent
- 'duration': is not yet implemented.

For the API-doc of the Shelly devices see:
`<https://shelly-api-docs.shelly.cloud>`.
"""
function move_shelly_25_roller(ip, action; pos = 100, duration = 1)

    timeout = 10
    if action == :open
        cmd = `curl -v -m $timeout "http://$ip/roller/0?go=open"`
    elseif action == :close
        cmd = `curl -v -m $timeout "http://$ip/roller/0?go=close"`
    elseif action == :stop
        cmd = `curl -v -m $timeout "http://$ip/roller/0?go=stop"`
    elseif action == :to_pos
        cmd = `curl -v -m $timeout "http://$ip/roller/0?go=to_pos&roller_pos=$pos"`
    else
        print_log("ERROR in switchShelly25: action $action is not supported")
        publish_say("Try to move a Shelly-two point five with an unsupported command!")
    end

    return(tryrun(cmd))
end
