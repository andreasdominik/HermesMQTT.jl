#
# helper function for GPIO switching
# on the local server (main)
#
#
# the GPIO number is read form a config entry: Light-GPIO=24
#


"""
    set_GPIO(gpio, onoff::Symbol)

Switch a GPIO on or off with pigs.

## Arguments:
* gpio: ID of GPIO (not pinID)
* onoff: one of :on or :off
"""
function set_GPIO(gpio, onoff::Symbol)

    if onoff == :on
        value = 1
    else
        value = 0
    end

    shell = `pigs w $gpio $value`
    tryrun(shell, error_msg=ERRORS_EN[:error_gpio])
end
