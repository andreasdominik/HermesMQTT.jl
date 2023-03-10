#
# helper function for GPIO switching
# on the local server (main)
#
#
# the GPIO number is read form a config entry: Light-GPIO=24
#


"""
    set_GPIO(ip, gpio, action; user=nothing, password=nothing)

Switch a GPIO on or off with pigs.

## Arguments:
* `ip`: IP address or DNS name of rasberry pi or "localhost"
* `gpio`: ID of GPIO (not pinID)
* `action`: one of "on" or "off"
* `user`: user for ssh connection
* `password`: password for ssh connection

## Details:
* if `ip` is "localhost", the GPIO is switched on the local server (main)
  uising pigs; pigs must be installed.
* if `ip` is not "localhost", the GPIO is switched on the remote server
  using ssh or sshpass and pigs on the remote machine
* if only `user` is given, ssh is used for a pasword-free login
* if user and password are given, sshpass is used for a password login
* as always, it is recommended to use ssh keys for password-free login.
"""
function set_GPIO(ip, gpio, action; user=nothing, password=nothing)

    if action == "on"
        value = 1
    else
        value = 0
    end

    if ip == "localhost"
        shell = `pigs w $gpio $value`

    elseif !isnothing(user) && !isnothing(password)
        shell = `sshpass -p $password ssh $user@$ip pigs w $gpio $value`

    elseif !isnothing(user) && isnothing(password)
        shell = `ssh $user@$ip pigs w $gpio $value`

    else
        print_log("ERROR: no user and password given for remote GPIO switching at host $ip")
        return false
    end
    return tryrun(shell, error_msg=ERRORS_EN[:error_gpio])
end
