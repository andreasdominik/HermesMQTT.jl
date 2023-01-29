#
# helpers to work with config.ini


"""
    readConfig(appDir)

Read the lines of the App's config file and
return a Dict with config values.

## Arguments:
* `appDir`: Directory of the currently running app.
"""
function readConfig(appDir)

    global CONFIG_INI
    fileName = "$appDir/config.ini"

    configLines = []
    try
        configLines = readlines(fileName)

        # read lines as "param_name=value"
        # or "param_name=value1,value2,value3"
        #
        rgx = r"^(?<name>[^[:space:]]+)=(?<val>.+)$"
        for line in configLines
            # skip comments.
            #
            if !occursin(r"^#", line)
                
                line = replace(line, " "=>"")   # strip spaces
                m = match(rgx, line)
                if m != nothing
                    name = Symbol(m[:name])
                    rawVals = split(chomp(m[:val]), r",")
                    vals = [strip(rv) for rv in rawVals if length(strip(rv)) > 0]

                    if length(vals) == 1
                        CONFIG_INI[name] = vals[1]
                    elseif length(vals) > 1
                        CONFIG_INI[name] = vals
                    end
                end
            end
        end
    catch
        printLog("Warning: no config file found!")
    end

end


"""
    matchConfig(name::Symbol, val::String)

Return true if the parameter with name `name` of the config.ini has the value
val or one element of the list as the value val.

## Arguments:
* `name`: name of the config parameter as Symbol or String
* `val`: desired value
"""
function matchConfig(name, val::String)

    name = addPrefix(name)
    # if !(name isa Symbol)
    #     name = Symbol(name)
    # end

    global CONFIG_INI

    if haskey(CONFIG_INI, name)
        if CONFIG_INI[name] isa AbstractString
            return val == CONFIG_INI[name]

        elseif CONFIG_INI[name] isa AbstractArray
            return val in CONFIG_INI[name]
        end
    end
    return false
end



"""
    getConfig(name; multiple = false, onePrefix = nothing)

Return the parameter value of the config.ini with
name or nothing if the param does not exist.
Return value is of type `AbstractString`, if it is a single value
or of type `AbstractArray{AbstractString}` if the a list of
values is read.

## Arguments:
* `name`: name of the config parameter as Symbol or String
* `multiple`: if `true` an array of values is returned, even if
              only a single value have been read.
* `onePrefix`: if defined, the prefix will be used only for this
              single call instead of the stored prefix.

## Details:
If name is of type `Symbol`, it is treated as key in the
Dirctionary of parameter values.
If name is an `AbstractString`, the prefix is added if a
prefix is defined (as `<prefix>:<name>`).
'getConfig()' returns ''nothing if something is wrong.
"""
function getConfig(name; multiple = false, onePrefix = nothing)

    global CONFIG_INI

    if onePrefix == nothing
        name = addPrefix(name)
    else
        name = Symbol("$onePrefix:$name")
    end

    if haskey(CONFIG_INI, name)
        if multiple && (CONFIG_INI[name] isa AbstractString)
            return [CONFIG_INI[name]]
        else
            return CONFIG_INI[name]
        end
    else
        return nothing
    end
end

"""
    function getConfigPath(name, defaultPath; onePrefix = nothing)

Read the config value 'name' as filename and generate a full
(absolute) path:
* if fName starts with '/', it is returned as is.
* otherwise a full path is created with 'defaultPath' as prefix.

## Arguments:
* `name`: name of the config parameter as Symbol or String
* `defaultPath`: path to be used if name is not already a path
* `onePrefix`: if defined, the prefix will be used only for this
              single call instead of the stored prefix.
"""
function getConfigPath(name, defaultPath; onePrefix = nothing)

    fName = getConfig(name, onePrefix = onePrefix)
    if (fName == nothing) || (length(fName) < 1)
        return nothing
    elseif fName[1] == '/'
        return fName
    else
        return joinpath(defaultPath, fName)
    end
end


"""
    getAllConfig()

Return a Dict with the complete `config.ini`.
"""
function getAllConfig()

    return CONFIG_INI
end


"""
    isInConfig(name)

Return true if a parameter with name exists.

## Arguments:
* `name`: name of the config parameter as Symbol or String
"""
function isInConfig(name)

    name = addPrefix(name)
    # if !(name isa Symbol)
    #     name = Symbol(name)
    # end

    global CONFIG_INI
    return haskey(CONFIG_INI, name)
end


"""
    isConfigValid(name; regex = r".", elem = 1, errorMsg = ERRORS_EN[:error_config])

Return `true`, if the parameter `name` have been read correctly from the
`config.ini` file and `false` otherwise. By default "correct" means: it is aString with
length > 0. For a moore specific test, a regex can be provided.

## Arguments:
* name: name of parameter as AbstractString or Symbol
* regex: optional regex for the test
* elem: element to be tested, if the parameter returns an array
* errorMsg: alternative error message.
"""
function isConfigValid(name; regex = r".", elem = 1, errorMsg = ERRORS_EN[:error_config])

    name = addPrefix(name)
    if !isInConfig(name)
        return false
    end

    if getConfig(name) == nothing
        param = ""
    elseif getConfig(name) isa AbstractString
        param = getConfig(name)
    elseif getConfig(name) isa AbstractArray
        param = getConfig(name)[elem]
    else
        param = ""
    end

    if occursin(regex, param)
        return true
    else
        publishSay("$errorMsg : $name")
        printLog("[$CURRENT_APP_NAME]: $errorMsg : $name")
        printLog("    Regex: $regex, parameter: $param")
        return false
    end
end


function addPrefix(name)

    global prefix

    # do nothing if name is a Symbol:
    #
    if name isa Symbol
        return name
    elseif prefix == nothing
        return Symbol(name)
    else
        return Symbol("$prefix:$name")
    end
end


"""
    setConfigPrefix(newPrefix)

Set the prefix for all following calls to a parameter from
`config.ini`. All parameter names, gives as `Strings` will be
modified as `<prefix>:<name>`.
"""
function setConfigPrefix(newPrefix)

    global prefix = newPrefix
end


"""
    resetConfigPrefix()

Remove the prefix for all following calls to a parameter from
`config.ini`.
"""
function resetConfigPrefix()

    global prefix = nothing
end
