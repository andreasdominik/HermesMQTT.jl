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
    extract_slot_value(payload, slot_name; multiple = false)

Return the value of a slot.

Nothing is returned, if
* no slots in payload,
* no slots with name slot_name in payload,
* no values in slot slot_name.

If multiple == `true`, a list of all slot values will be
returned. If false, only the 1st one as String.
"""
function extract_slot_value(payload, slot_name; multiple = false)

    if !haskey(payload, :slots)
        return nothing
    end

    values = []
    for sl in payload[:slots]
        if sl[:slot_name] == slot_name
            if haskey(sl, :value) && haskey(sl[:value], :value)
                push!(values,sl[:value][:value])
            end
        end
    end

    if length(values) < 1
        return nothing
    elseif !multiple
        return values[1]
    else
        return values
    end
end

"""
    extract_multislot_values(payload, slot_names)

Return a list with all values of a list of slots.

Nothing is returned, if
* no slots in payload,
* no slots with name in slotNames in payload,
* no values in slot slotNames.
"""
function extract_multislot_values(payload, slot_names::AbstractArray)

    values = []

    for slot in slot_names
        value = extract_slot_value(payload, slot, multiple=true)
        if value != nothing
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
    is_in_slot(payload, slot_name, value)

Return `true`, if the value is present in the slot slotName
of the JSON payload (i.e. one of the slot values must match).
Return `false` if something is wrong (value not in payload or no
slots slotName.)
"""
function is_in_Slot(payload, slot_name, value)

    values = extract_slot_value(payload, slot_name; multiple = true)
    return (values != nothing) && (value in values)
end


"""
    read_time_from_slot(payload, slot_name)

Return a DateTime from a slot with a time string of the format
`"2019-09-03 18:00:00 +00:00"` or `nothing` if it is
not possible to parse the slot.
"""
function read_time_from_slot(payload, slot_name)

    dateTime = nothing

    # date format delivered from Snips:
    #
    # dateFormat = Dates.DateFormat("yyyy-mm-dd HH:MM:SS")
    timeStr = extract_slot_value(payload, slot_name, multiple = false)
    if timeStr == nothing
        return nothing
    end

    # fix timezone in slot:
    #
    printDebug("Raw timeStr in readTimeFromSlot(): $timeStr")
    timeStr = replace(timeStr, r" \+\d\d:\d\d$"=>"")
    printDebug("Corrected timeStr in readTimeFromSlot(): $timeStr")

    try
        # dateTime = Dates.DateTime(timeStr, dateFormat)
        dateTime = Dates.DateTime(timeStr)
    catch
        dateTime = nothing
    end
    return dateTime
end



"""
    tryrun(cmd; wait = true, error_msg = ERRORS_EN[:error_script], silent = flase)

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

    error_msg = langText(error_msg)
    result = true
    try
        run(cmd; wait = wait)
    catch
        result = false
        silent || publish_say(error_msg)
        printLog("Error running script $cmd")
    end

    return result
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

    error_msg = langText(error_msg)
    text = ""
    try
        text = open(fname) do file
                  read(file, String)
               end
    catch
        publish_say(err_msg, lang = LANG)
        printLog("Error opening text file $fname")
        text = ""
    end

    return text
end


"""
    set_language(lang)

Set the default language for HermesMQTT
Currently supported laguages are "en" and "de".

This will affect publishSay() and all system messages.
Log-messages will always be in English.

## Arguments
* lang: one of `"en"` or `"de"` or any other.
"""
function set_language(lang)

    if lang != nothing
        global LANG = lang
    else
        global LANG = DEFAULT_LANG
    end
end

"""
    add_text(lang::AbstractString, key::Symbol, text)

Add the text to the dictionary of text sniplets for the language
`lang` and the key `key`.

## Arguments:
* lang: String with language code (`"en", "de", ...`)
* key: Symbol with unique key for the text
* text: String or array of String with the text(s) to be uttered.

## Details:
If text is an Array, all texts will be saved and the function `J4H.langText()`
will return a randomly selected text from the list.

If the key already exists, the new text will be added to the the
Array of texts for a key.
"""
function add_text(lang::AbstractString, key::Symbol, text)

    if text isa AbstractString
        text = [text]
    end

    if !haskey(LANGUAGE_TEXTS, (lang, key))
        LANGUAGE_TEXTS[(lang, key)] = text
    else
        append!(LANGUAGE_TEXTS[(lang, key)], text)
    end
end


"""
    lang_text(key::Symbol)
    lang_text(key::Nothing)
    lang_text(key::AbstractString)

Return the text in the languages dictionary for the key and the
language set with `setLanguage()`.

If the key does not exists, the text in the default language is returned;
if this also does not exist, an error message is returned.

The variants make sure that nothing or the key itself are returned
if key is nothing or an AbstractString, respectively.
"""
function lang_text(key::Symbol)

    if haskey(LANGUAGE_TEXTS, (LANG, key))
        return StatsBase.sample(LANGUAGE_TEXTS[(LANG, key)])
    elseif haskey(LANGUAGE_TEXTS, (DEFAULT_LANG, key))
        return StatsBase.sample(LANGUAGE_TEXTS[(DEFAULT_LANG, key)])
    else
        return "I don't know what to say! I got $key"
    end
end

function lang_text(key::Nothing)

    return nothing
end


function lang_text(key::AbstractString)

    return key
end




"""
    set_appdir(appdir)

Store the directory `appdir` as CURRENT_APP_DIR in the
current session
"""
function set_appdir(appdir)

    global CURRENT_APP_DIR = appdir
end

"""
    get_appdir()

Return the directory of the currently running app
(i.e. the variable CURRENT_APP_DIR)
"""
function get_appdir()
    return CURRENT_APP_DIR
end




"""
    set_appname(appname)

Store the name of the current app/module as CURRENT_APP_NAME in the
current session
"""
function set_appname(appname)

    global CURRENT_APP_NAME = appname
end

"""
    get_appname()

Return the name of the currently running app
(i.e. the variable CURRENT_APP_NAME)
"""
function get_appname()
    return CURRENT_APP_NAME
end


"""
    print_log(s)

Print the message
The current App-name is printed as prefix.
"""
function print_log(s)

    if s == nothing
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
* `logging`: only printDebug() will print
* `no_parallel`: logging is on and skill actions will
                 will not be spawned (as a result, the listener is
                 off-line while a skill-action is running).
Current App-name is printed as prefix.
"""
function print_debug(s)

    if s == nothing
        s = "log-message is nothing"
    end
    if !match_config(:debug, "none")
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
The match ic case insensitive.

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
    print_debug("RegEx: >$rg<, command: >$haystack<")
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
- `switchOnOff:must_include:just_words1=on,light`
- `switchOnOff:must_chain:in_order=light,on`
- `switchOnOff:must_span:start_to_end=switch,light,on`
- `switchOnOff:must_span:start_to_end=switch,on`

The command must include all words in the correct order
of at least one parameter lines and the words must span the complete line
(i.e. the command starts with first word and ends with the last word
of the list).

Several lines are possible; the last part of the parameter name
is used as description and to make the parameter names unique.
"""
function is_false_detection(payload)

    INCLUDE = ":must_include:"
    CHAIN = ":must_chain:"
    SPAN = ":must_span:"

    command = strip(payload[:input])
    intent = get_intent()

    # make list of all config.ini keys which hold lists
    # of must-words:
    #
    rgx = Regex("^$intent$INCLUDE|^$intent$CHAIN|^$intent$SPAN")
    config = filter(p->occursin(rgx, String(p.first)), get_all_config())
    print_debug("Config false detection lines: $config")

    if length(config) == 0
        falseActivation = false
    else
        # let true, if none of the word lists is matched:
        #
        falseActivation = true
        for (name,needle) in config
            print_debug("""name = $name; needle = "$needle".""")

            if occursin(INCLUDE, "$name") && all_occursin(needle, command)
                # printDebug("match INCLUDE: $command, $needle")
                falseActivation = false
            elseif occursin(CHAIN, "$name") && all_occursin_order(needle, command, complete=false)
                # printDebug("match CHAIN: $command, $needle")
                falseActivation = false
            elseif occursin(SPAN, "$name") && all_occursin_order(needle, command, complete=true)
                # printDebug("match SPAN: $command, $needle")
                falseActivation = false
            end
        end
    end
    if falseActivation
        print_log(  """[$intent]: Intent "$intent" aborted. False detection recognised for command: "$command".""")
    end

    return falseActivation
end
