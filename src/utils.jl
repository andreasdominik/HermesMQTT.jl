"""
    add_strings_to_array!( a, more_elements)

Add more_elements to a. If a is not an existing
Array of String, a new Array is created.

## Arguments:
* `a`: Array of String.
* `more_elements`: elements to be added.
"""
function add_strings_to_array!( a, more_elements)

    if a isa AbstractString
        a = [a]
    elseif !(a isa AbstractArray{String})
        a = String[]
    end

    if more_elements isa AbstractString
        push!(a, more_elements)
    elseif more_elements isa AbstractArray
        for t in more_elements
            push!(a, t)
        end
    end
    return a
end



"""
    extract_slot_value(slot_name, payload; default=nothing, as=String)

Return the value of a slot.

Nothing is returned, if
* no slots in payload,
* no slots with name slot_name in payload,
* no value in slot slot_name,
* or the value cannot be casted into the type, specified ba the `as=` argument.

### Arguments:
+ `slot_name`: name of the slot as defined in the intent
+ `payload`: JSON payload
+ `default`: default value; returned if the slot is not present in the payload
+ `as`: type of the returned value (default: String)
"""
function extract_slot_value(slot_name, payload; default=nothing, as=String)

    slot_name = "$slot_name"
    value = default
    if !haskey(payload, :slots)
        return default
    end

    for slot in payload[:slots]
        if slot[:slotName] == slot_name
            value = slot[:value][:value]
        end
    end

# println("extract_slot_value: name = $slot_name, value = $value, $(typeof(value))")

    if isnothing(value)
        return default
    end

    if as == String
        return "$value"
    elseif value isa AbstractString 
        return tryparse(as, value)
    end
    return value
end

"""
    extract_multislot_values(slot_names,payload)

Return a list with all values of a list of slots.

Nothing is returned, if
* no slots in payload,
* no slots with name in slotNames in payload,
* no values in slot slotNames.
"""
function extract_multislot_values(slot_names::AbstractArray, payload)

    values = []

    for slot in slot_names
        value = extract_slot_value(slot, payload, multiple=true)
        if !isnothing(value)
            append!(values, value)
        end
    end

    if length(values) < 1
        return nothing
    else
        return values
    end
end



"""
    is_in_slot(slot_name, value, payload)

Return `true`, if the value is present in the slot slotName
of the JSON payload (i.e. one of the slot values must match).
Return `false` if something is wrong (value not in payload or no
slots slotName.)
"""
function is_in_slot(slot_name, value, payload)

print_log("is_in_slot($slot_name, $value, $payload)")
    values = extract_slot_value(slot_name, payload)
print_log("is_in_slot: values = $values")
    return !isnothing(values) && (value in values)
end


"""
    read_time_from_slot(slot_name, payload)

Return a DateTime from a slot with a time string of the format
`"2019-09-03 18:00:00 +00:00"` or `nothing` if it is
not possible to parse the slot.
"""
function read_time_from_slot(slot_name, payload)

    dateTime = nothing

    # date format delivered from Snips:
    #
    # dateFormat = Dates.DateFormat("yyyy-mm-dd HH:MM:SS")
    timeStr = extract_slot_value(slot_name, payload, multiple = false)
    if isnothing(timeStr)
        return nothing
    end

    # fix timezone in slot:
    #
    print_debug("Raw timeStr in readTimeFromSlot(): $timeStr")
    timeStr = replace(timeStr, r" \+\d\d:\d\d$"=>"")
    print_debug("Corrected timeStr in readTimeFromSlot(): $timeStr")

    try
        # dateTime = Dates.DateTime(timeStr, dateFormat)
        dateTime = Dates.DateTime(timeStr)
    catch
        dateTime = nothing
    end
    return dateTime
end



"""
    tryrun(cmd; wait = true, error_msg = ERRORS_EN[:error_script], silent = false)

Try to run an external command and returns true if successful
or false if not.

## Arguments:
* cmd: command to be executed on the shell
* wait: if `true`, wait until the command has finished
* error_msg: AbstractString or key to multi-language dict with the
            error message.
* silent: if `true`, no error is published, if something went wrong.
"""
function tryrun(cmd; wait = true, error_msg = ERRORS_EN[:error_script], silent = false)

    error_msg = lang_text(error_msg)
    result = true
    try
        run(cmd; wait = wait)
    catch
        result = false
        silent || publish_say(error_msg)
        print_log("Error running script $cmd")
    end

    return result
end

function find_all_files(base, name, verbose=false)

    i = 0
    finds = []
    for (root, dirs, files) in walkdir(base, onerror=x->nothing)
        i += 1
        if verbose
            if i % 800 == 0
            println(".")
            elseif i % 100 == 0
                print(".")
            end
        end
        for file in files
            if file == name
                push!(finds, joinpath(root, file))
            end
        end
    end
    return finds
end


"""
    ping(ip; c = 1, W = 1)

Return true, if a ping to the ip-address (or name) is
successful.

## Arguments:
* c: number of pings to send (default: 1)
* W: timeout (default 1 sec)
"""
function ping(ip; c = 1, W = 1)

    try
        run(`ping -c $c -W $W $ip`)
        return true
    catch
        return false
    end
end




"""
    try_read_textfile(fname, error_msg = TEXTS[:error_read])

Try to read a text file from file system and
return the text as `String` or an `String` of length 0, if
something went wrong.
"""
function try_read_textfile(fname, error_msg = :error_read)

    error_msg = lang_text(error_msg)
    text = ""
    try
        text = open(fname) do file
                  read(file, String)
               end
    catch
        publish_say(err_msg, lang = LANG)
        print_log("Error opening text file $fname")
        text = ""
    end

    return text
end


"""
    add_text(lang::AbstractString, key, text)

Add the text to the dictionary of text sniplets for the language
`lang` and the key `key`.

## Arguments:
* lang: String with language code (`"en", "de", ...`)
* key: Symbol or string with unique key for the text
* text: String or array of String with the text(s) to be uttered.

## Details:
If text is an Array, all texts will be saved and the function `J4H.lang_text()`
will return a randomly selected text from the list.

If the key already exists, the new text will be added to the the
Array of texts for a key.
"""
function add_text(lang::AbstractString, key, text)

    if text isa AbstractString
        text = [text]
    end
    key = strip("$key", ':') |> Symbol

    if !haskey(LANGUAGE_TEXTS, (lang, key))
        LANGUAGE_TEXTS[(lang, key)] = text
    else
        append!(LANGUAGE_TEXTS[(lang, key)], text)
    end
end


"""
    function lang_text(texts..., lang=get_language())

Join the elements of texts into a single string and
replace each string by the sentence of the language.

### Arguments:
`texts`: iterable collection of elements that can be converted
         into strings. `Symbols` will be replaced by the
         languange snipplets.
"""
function lang_text(texts...; lang=get_language())

    texts = [lang_text_one(t, lang) for t in texts]
    return join(texts, " ")
end

"""
    lang_text_one(key::Symbol, lang)
    lang_text_one(key::Nothing)
    lang_text_one(key::AbstractString)

Return the text in the languages dictionary for the key and the
configured language.

If the key does not exists, the text in the default language is returned;
if this also does not exist, an error message is returned.

The variants make sure that nothing or the key itself are returned
if key is nothing or an AbstractString, respectively.
"""
function lang_text_one(key::Symbol, lang)

    if haskey(LANGUAGE_TEXTS, (lang, key))
        t = LANGUAGE_TEXTS[(lang, key)]
        ts = StatsBase.sample(t)
        return ts
    else
        return "I don't know what to say! I got $key"
    end
end

function lang_text_one(key::Nothing, lang)

    return ""
end


function lang_text_one(key::Any, lang)

    return "$key"
end




"""
    set_appdir(app_dir)

Store the directory `appdir` as CURRENT[:app_dir] in the
current session
"""
function set_appdir(app_dir)

    global CURRENT
    CURRENT[:app_dir] = app_dir
end

"""
    get_appdir()

Return the directory of the currently running app
"""
function get_appdir()
    return CURRENT[:app_dir]
end




"""
    set_appname(app_name)

Store the name of the current app/module in CURRENT.
"""
function set_appname(app_name)

    global CURRENT
    CURRENT[:app_name] = app_name
end

"""
    get_appname()

Return the name of the currently running app.
"""
function get_appname()
    return CURRENT[:app_name]
end


"""
    print_log(s)

Print the message
The current App-name is printed as prefix.
"""
function print_log(s)

    if isnothing(s)
        s = "log-message is nothing"
    end
    logtime = Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")
    prefix = get_appname()
    println("***> $logtime [$prefix]: $s")
    flush(stdout)
end


"""
    print_debug(s)

Print the message only, if debug-mode is on.
Debug-modes include
* `none`: no debugging
* `logging`: print_debug() will print
* `no_parallel`: logging is on and skill actions will
                 will not be spawned (as a result, the listener is
                 off-line while a skill-action is running).
Current App-name is printed as prefix.
"""
function print_debug(s)

    if isnothing(s)
        s = "log-message is nothing"
    end
    if !match_config(:debug, "none", skill=HERMES_MQTT)
        print_log("<<< DEBUG >>> $s")
    end
end


"""
    all_occursin(needles, haystack)

Return true if all words in the list needles occures in haystack.
`needles` can be an AbstractStrings or regular expression.
"""
function all_occursin(needles, haystack)

    if needles isa AbstractString
        needles = [needles]
    end

    match = true
    for needle in needles
        if ! occursin(Regex(needle, "i"), haystack)
            match = false
        end
    end
    return match
end


"""
    one_occursin(needles, haystack)

Return true if one of the words in the list needles occures in haystack.
`needles` can be an AbstractStrings or regular expression.
"""
function one_occursin(needles, haystack)

    if needles isa AbstractString
        needles = [needles]
    end

    match = false
    for needle in needles
        if occursin(Regex(needle, "i"), haystack)
            match = true
        end
    end
    return match
end

"""
    all_occursin_order(needles, haystack; complete = true)

Return true if all words in the list needles occures in haystack
in the given order.
`needles` can be an AbstractStrings or regular expressions.
The match is case insensitive.

## Arguments:
`needles`: AbstractString or list of Strings to be matched
`haystack`: target string
`complete`: if `true`, the target string must start with the first
            word and end with the last word of the list.
"""
function all_occursin_order(needles, haystack; complete=true)

    if needles isa AbstractString
        needles = [needles]
    end

    # create an regex to match all in one:
    #
    if complete
        rg = Regex("^$(join(needles, ".*"))\$", "i")
    else
        rg = Regex("$(join(needles, ".*"))", "i")
    end
    #print_debug("RegEx: >$rg<, command: >$haystack<")
    return occursin(rg, haystack)
end



"""
    is_false_detection(payload)

Return true, if the current intent is **not** correct for the uttered
command (i.e. false positive).

## Arguments:
- `payload`: Dictionary with the payload of a recognised intent.

## Details:
All lines of the `config.ini` are analysed, witch match expressions:
- `<intentname>:must_include:<description>=<list of words>

An example would be:
- `switchOnOff:must_include = on, light`
- `switchOnOff:must_chain = light,on`
- `switchOnOff:must_span = switch,light,on`
- `switchOnOff:must_span = switch,on`

The command must include all words in the correct order
of at least one parameter lines and the words must span the complete line
(i.e. the command starts with first word and ends with the last word
of the list).

Several lines are possible; the last part of the parameter name
is used as description and to make the parameter names unique.
"""
function is_false_detection(payload)

    INCLUDE = "must_include"
    CHAIN = "must_chain"
    SPAN = "must_span"

    # run only on recognised intents from rhasspy:
    #
    if !haskey(payload, :input)
        return false
    end

    command = strip(payload[:input])
    intent = get_intent(payload)
    lang = get_language()

    # make list of all config.ini keys which hold lists
    # of must-words:
    #

    rules = get_false_detection_rules(lang, intent)
    print_log("$lang - $intent")
    print_log("Config false detection lines: $rules")

    if length(rules) == 0
        falseActivation = false
    else
        # let true, if none of the word lists is matched:
        #
        falseActivation = true
        for (type, words) in rules
            print_debug("""type = $type; words = "$words".""")

            if type == INCLUDE && all_occursin(words, command)
                print_debug("match INCLUDE: $command, $words")
                falseActivation = false
            elseif type == CHAIN && all_occursin_order(words, command, complete=false)
                print_debug("match CHAIN: $command, $words")
                falseActivation = false
            elseif type == SPAN && all_occursin_order(words, command, complete=true)
                print_debug("match SPAN: $command, $words")
                falseActivation = false
            end
        end
    end
    if falseActivation
        print_log(  """[$intent]: Intent "$intent" aborted. False detection recognised for command: "$command".""")
    end

    return falseActivation
end



# copy a directory with subdirectories:
#
function copydir(src, dst)
    run(`cp -r $src $dst`)
end