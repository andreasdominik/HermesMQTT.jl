#
# helpers to work with config.ini


"""
    load_two_configs(app_dir, hermes_dir=nothing, skill=get_appname())

Load config setting for a skill in dir `app_dir` **and**
config of the HermesMQTT` framework from 
`app_dir/../HermesMQTT/config.ini` or the specified dir.

### Arguments:
+ `hermes_dir`: path to the HermesMQTT-config.ini
               `.../Skills/HermesMQTT.jl`
"""
function load_two_configs(app_dir, hermes_dir=nothing; skill=get_appname())

    # construct HermesMQTT dir if not given:
    #
    if isnothing(hermes_dir)
        hermes_dir = joinpath(dirname(app_dir), "HermesMQTT.jl")
    end

    load_hermes_config(hermes_dir)
    load_skill_config(app_dir, skill=skill)
end


"""
    load_skill_config(app_dir; skill=get_appname()

Load config setting for a skill.

### Arguments:
+ `app_dir`: path to the config.ini
               `.../Skills/Skill  (/config.ini)`
"""
function load_skill_config(app_dir; skill=get_appname())

    global CONFIG_INI
    config_ini = read_config(app_dir, skill=skill)
    merge!(CONFIG_INI, config_ini)
end
    

"""
    load_hermes_config(hermes_dir)

Load config setting for the `HermesMQTT` framework.

### Arguments:
+ `hermes_dir`: path to the HermesMQTT-config.ini
               `.../Skills/HermesMQTT.jl`
"""
function load_hermes_config(hermes_dir)

    skills_dir = dirname(hermes_dir)  # set base dir one higher
    config_ini = read_config(hermes_dir; skill=HERMES_MQTT)

    global CONFIG_INI
    merge!(CONFIG_INI, config_ini)

    # fix some potential issues:
    #
    if isnothing(get_config(:language, skill=HERMES_MQTT))
        set_config(:language, DEFAULT_LANG, skill=HERMES_MQTT)
    end

    database_dir = joinpath(hermes_dir, "application_data", "database")
    if isnothing(get_config(:database_file, skill=HERMES_MQTT))
        database_file = "home.json"
    else
        database_file = get_config(:database_file, skill=HERMES_MQTT)
    end
    database_path = joinpath(database_dir, database_file)
    
    set_config(:database_dir, database_dir, skill=HERMES_MQTT) 
    set_config(:database_file, database_file, skill=HERMES_MQTT)
    set_config(:database_path, database_path, skill=HERMES_MQTT)
end


"""
    read_config(app_dir; skill=get_appname())

Read the lines of the App's config file and
return a Dict with config values.

## Arguments:
* `appDir`: Directory of the currently running app.
"""
function read_config(app_dir; skill=get_appname())

    skill = Symbol(skill)
    config_ini = Dict{Tuple{Symbol,Symbol}, Any}()
    file_name = joinpath(app_dir, "config.ini")

    config_lines = []
    try
        config_lines = readlines(file_name)

        # read lines as "param_name=value"
        # or "param_name=value1,value2,value3"
        #
        rgx = r"^ *(?<name>[^[:space:]]+) *= *(?<val>.+)$"
        read_section = false
        for line in config_lines
            # skip comments.
            #
            if !occursin(r"^#", line)
                
                if is_section_head_global(line)
                    read_section = true
                elseif is_section_head_lang(line)
                    read_section = false
                end

                if read_section
                    m = match(rgx, line)
                    if !isnothing(m)
                        name = strip(m[:name]) |> Symbol
                        rawVals = split(chomp(m[:val]), r",")
                        vals = [strip(rv) for rv in rawVals if length(strip(rv)) > 0]

                        if length(vals) == 1
                            config_ini[(skill,name)] = vals[1]
                        elseif length(vals) > 1
                            config_ini[(skill,name)] = vals
                        end
                    end
                end
            end
        end
    catch
        print_log("Warning: no config file found!")
    end
    return config_ini
end


# check, if a config.ini line is a section header
# and return true or false
#
function is_section_head(line)

    rgx = r"^\[.+\]$"
    return occursin(rgx, strip(line))
end



# check, if a config.ini line is a section header
# and return nothing, :global, language code
#
function get_section_head(line)
    line = replace(line, " "=>"")

    if line == "[global]"
        return :global
    end

    m = match(r"^\[(?<lang>[a-z][a-z])\]", line)
    if !isnothing m
        return m[:lang]
    end

    return nothing
end

function is_section_head_global(line)

    return strip(line) == "[global]"
end

function is_section_head_lang(line)

    return occursin(r"^\[(?<lang>[a-z][a-z])\]", strip(line))
end

function get_section_head_lang(line)

    m = match(r"^\[(?<lang>[a-z][a-z])\]", strip(line))
    if isnothing(m)
        return nothing
    else
        return m[:lang]
    end
end


        



"""
    match_config(name::Symbol, val::String; skill=get_appname())

Return true if the parameter with name `name` of the config.ini has the value
val or one element of the list as the value val.

## Arguments:
* `name`: name of the config parameter as Symbol or String
* `val`: desired value
"""
function match_config(name, val::String; skill=get_appname())

    skill = Symbol(skill)
    name = Symbol(add_prefix(name))

    global CONFIG_INI

    if haskey(CONFIG_INI, (skill,name))
        if CONFIG_INI[(skill, name)] isa AbstractString
            return val == CONFIG_INI[(skill,name)]

        elseif CONFIG_INI[(skill,name)] isa AbstractArray
            return val in CONFIG_INI[(skill,name)]
        end
    end
    return false
end



"""
    get_config(name; multiple = false, one_prefix = nothing)
    get_config_skill(name; multiple = false, one_prefix = nothing,
                    skill=get_appname())

Return the parameter value of the config.ini with
name or nothing if the param does not exist.
Return value is of type `AbstractString`, if it is a single value
or of type `AbstractArray{AbstractString}` if the a list of
values is read.

## Arguments:
* `name`: name of the config parameter as Symbol or String
* `multiple`: if `true` an array of values is returned, even if
              only a single value have been read.
* `one_prefix`: if defined, the prefix will be used only for this
              single call instead of the stored prefix.

## Details:
If name is of type `Symbol`, it is treated as key in the
Dirctionary of parameter values.
If name is an `AbstractString`, the prefix is added if a
prefix is defined (as `<prefix>:<name>`).
'get_config()' returns ''nothing if something is wrong.

`config.ini` entries are stored with the corresponding skill name 
(appname), The function calles get_config_skill() with the current
appname used as skill.
If a config-entry for a specific skill is wanted, the function 
`get_config_skill(...; skill="skillname")` can be used.
"""
function get_config_skill(name; multiple=false, one_prefix=nothing, 
                    skill=get_appname())

    global CONFIG_INI

    skill = Symbol(skill)
    if isnothing(one_prefix)
        name = add_prefix(name)
    else
        name = Symbol("$one_prefix:$name")
    end
println("**** get_config($name) for skill $skill")

    if haskey(CONFIG_INI, (skill,name))
        if multiple && (CONFIG_INI[(skill,name)] isa AbstractString)
            return [CONFIG_INI[(skill,name)]]
        else
            return CONFIG_INI[(skill,name)]
        end
    else
        return nothing
    end
end

function get_config(name; multiple=false, one_prefix=nothing) 
    return get_config_skill(name; multiple=multiple, one_prefix=one_prefix, 
                            skill="HermesMQTT")
end
                 
"""
    get_config_path(name, default_path; one_prefix = nothing,
                    skill=get_appname())

Read the config value 'name' as filename and generate a full
(absolute) path:
* if fName starts with '/', it is returned as is.
* otherwise a full path is created with 'defaultPath' as prefix.

## Arguments:
* `name`: name of the config parameter as Symbol or String
* `default_path`: path to be used if name is not already a path
* `one_prefix`: if defined, the prefix will be used only for this
              single call instead of the stored prefix.
"""
function get_config_path(name, default_path; one_prefix = nothing,
                         skill=get_appname())

    fName = get_config(name, one_prefix=one_prefix, skill=skill)
    if isnothing(fName) || (length(fName) < 1)
        return nothing
    elseif fName[1] == '/'
        return fName
    else
        return joinpath(default_path, fName)
    end
end


"""
    get_all_config()

Return a Dict with the complete `config.ini`.
"""
function get_all_config()

    return CONFIG_INI
end


"""
    is_in_config(name; skill=get_appname())

Return true if a parameter with name exists.

## Arguments:
* `name`: name of the config parameter as Symbol or String
"""
function is_in_config(name; skill=get_appname())

    conf = get_config(name, skill=skill)
    return !isnothing(conf)
end


"""
    add_false_detection(lang, check_type, vals))

Add a false detectuion rule for the language lang and intent intent
and init the list if necessary.
"""
function add_false_detection_rule(lang, intent, check_type, vals)
    
    global FALSE_DETECTION
    if !haskey(FALSE_DETECTION, (lang, intent))
        FALSE_DETECTION[(lang, intent)] = []
    end

    push!(FALSE_DETECTION[(lang, intent)], (check_type, vals))
end


function get_false_detection_rules(lang, intent)

    if haskey(FALSE_DETECTION, (lang, intent))
        return FALSE_DETECTION[(lang, intent)]
    else
        return []
    end
end

function get_false_detection_rules()

    return FALSE_DETECTION
end

"""
    is_config_valid(name; regex = r".", elem = 1, errorMsg = ERRORS_EN[:error_config],, 
                    skill=get_appname())

Return `true`, if the parameter `name` have been read correctly from the
`config.ini` file and `false` otherwise. By default "correct" means: it is a String with
length > 0. For a moore specific test, a regex can be provided.

## Arguments:
* name: name of parameter as AbstractString or Symbol
* regex: optional regex for the test
* elem: element to be tested, if the parameter returns an array
* errorMsg: alternative error message.
"""
function is_config_valid(name; regex = r".", elem = 1, 
                        error_msg = ERRORS_EN[:error_config],
                        skill=get_appname())

    name = add_prefix(name)
    if !is_in_config(name, skill=skill)
        return false
    end

    if isnothing(get_config(name,skill=skill))
        param = ""
    elseif get_config(name, skill=skill) isa AbstractString
        param = get_config(name, skill=skill)
    elseif get_config(name, skill=skill) isa AbstractArray
        param = get_config(name, skill=skill)[elem]
    else
        param = ""
    end

    if occursin(regex, param)
        return true
    else
        publish_say("$errorMsg : $name")
        print_log("[$CURRENT_APP_NAME]: $error_msg : $name")
        print_log("    Regex: $regex, parameter: $param")
        return false
    end
end


function add_prefix(name)

    global PREFIX

    # do nothing if name is a Symbol:
    #
    if name isa Symbol
        return name
    elseif isnothing(PREFIX)
        return Symbol(name)
    else
        return Symbol("$PREFIX:$name")
    end
end


"""
    set_config_prefix(new_prefix)

Set the prefix for all following calls to a parameter from
`config.ini`. All parameter names, gives as `Strings` will be
modified as `<prefix>:<name>`.

### Details:
Do not forget to reset the prefix (`reset_config_prefix()`) as 
possible, to avoid side effects as the prefix is applied globally!
"""
function set_config_prefix(new_prefix)

    global PREFIX = new_prefix
end


"""
    reset_config_prefix()

Remove the prefix for all following calls to a parameter from
`config.ini`.
"""
function reset_config_prefix()

    global PREFIX = nothing
end

"""
    set_config(name, value; skill=get_appname())

Set a config key-value pair to the global CONFIG_INI.
"""
function set_config(name, value; skill=get_appname())

    global CONFIG_INI
    skill = Symbol(skill)
    name = Symbol(name)
    CONFIG_INI[(skill,name)] = value
end


function read_language_sentences(app_dir; skill=get_appname())  

    file_name = joinpath(app_dir, "config.ini")

    config_lines = []
    lang = get_language()
    
    try
        config_lines = readlines(file_name)

        # read lines as "name = sentence"
        # or ":name = sentence"
        #
        rgx_sentence = r"^ *(?<name>[^[:space:]]+) *= *(?<val>.+)$"
        rgx_ensure =   r"^ *(?<intent>[^[:space:]]+):(?<must>(must_include|must_chain|must_span)) *= *(?<val>.+)$"
        read_section = false
        for line in config_lines
            # skip comments.
            #
            if !occursin(r"^#", line)
                
                if is_section_head_global(line)
                    read_section = false
                elseif is_section_head_lang(line)
                    read_section = true
                    lang = get_section_head_lang(line)
                end

                if read_section
                    m_ensure = match(rgx_ensure, line)
                    m_sentence = match(rgx_sentence, line)

                    if !isnothing(m_ensure)
                        intent = m_ensure[:intent]
                        check_type = m_ensure[:must]
                        rawVals = split(chomp(m_ensure[:val]), r",")
                        vals = [strip(rv) for rv in rawVals if length(strip(rv)) > 0]

                        add_false_detection_rule(lang, intent, check_type, vals)
                    
                    elseif !isnothing(m_sentence)    
                        name = m_sentence[:name]
                        sentence = m_sentence[:val]
                        add_text(lang, name, sentence)
                    end
                end
            end
        end
    catch
        print_log("Warning: no config file found!")
    end
end