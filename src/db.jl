#
# functions to read and write status db
#
# The db looks like:
# {
#     "irrigation" :
#     {
#         "time" : <modification time>,
#         "writer" : "ADoSnipsIrrigation",
#         "payload" :
#         {
#             "status" : "on",
#             "next_status" : "off"
#         }
#     }
# }
#

"""
    db_write_payload(key, payload)

Write a complete payload to a database entry.
The payload is overwitten if the entry already exists,
or created otherwise.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
- `payload`: payload of the entry with key `key`
         to be written.
- `value`: value to be stored in the field.
"""
function db_write_payload(key, payload)

    if ! (key isa Symbol)
        key = Symbol(key)
    end

    if !db_lock()
        return false
    end

    db = db_read()

    if haskey(db, key)
        entry = db[key]
    else
        entry = Dict()
        db[key] = entry
    end

    entry[:time] = Dates.now()
    entry[:writer] = get_appname()
    entry[:payload] = payload

    db_write(db)
    db_unlock()
end

"""
    db_write_value(key, field, value)

Write a field=>value pair to the payload of a database entry.
The field is overwitten if the entry already exists,
or created elsewise.
The database is written to the JSON-file after the write.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
- `field`: database field of the payload of the entry with key `key`
         to be written (`AbstractString` or `Symbol`).
- `value`: value to be stored in the field.
"""
function db_write_value(key, field, value)

    if ! (key isa Symbol)
        key = Symbol(key)
    end
    if ! (field isa Symbol)
        field = Symbol(field)
    end

    if !db_lock()
        return false
    end

    db = db_read()
    if haskey(db, key)
        entry = db[key]
    else
        entry = Dict()
    end

    if !haskey(entry, :payload)
        entry[:payload] = Dict()
    end

    entry[:payload][field] = value
    entry[:time] = Dates.now()
    entry[:writer] = get_appname()

    db[key] = entry
    db_write(db)
    db_unlock()
end


"""
    db_has_entry(key)

Check if the database has an entry with the key `key`
and return `true` or `false` otherwise.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
"""
function db_has_entry(key)

    if ! (key isa Symbol)
        key = Symbol(key)
    end

    db = db_read()
    return haskey(db, key)
end



"""
    db_read_entry(key)

Read the complete entry with the key `key` from the
status database
and return the entry as `Dict()` or nothing if not in the database.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
"""
function db_read_entry(key)

    if ! (key isa Symbol)
        key = Symbol(key)
    end

    db = db_read()
    if haskey(db, key)
        return db[key]
    else
        print_log("Try to read entry for unknown key $key from status database.")
        return nothing
    end
end


"""
    db_read_value(key, field)

Read the field `field` of the  entry with the key `key` from the
status database
and return the value or nothing if not in the database.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
- `field`: database field of the payload of the entry with key `key`
         (`AbstractString` or `Symbol`).
"""
function db_read_value(key, field)

    if ! (key isa Symbol)
        key = Symbol(key)
    end
    if ! (field isa Symbol)
        field = Symbol(field)
    end

    db = db_read()
    if haskey(db, key) &&
       haskey(db[key],:payload) &&
       haskey(db[key][:payload],field)
        return db[key][:payload][field]
    else
        print_log("Try to read value for unknown key $key from status database.")
        return nothing
    end
end






"""
    db_read()

Read the status db from file.
Path is constructed from `config.ini` values
`<HermesMQTT dir>/database/<database_file>`.
"""
function db_read()

    db = try_parse_JSON_file(get_db_name(), quiet=true)
    if length(db) == 0
        print_log("Empty status DB read: $(get_db_name()).")
        db = Dict()
    end
    return db
end


"""
    db_write()

Write the status db to a file.
"""
function db_write(db)

    if !ispath( get_config(:database_dir))
        mkpath( get_config(:database_dir))
    end

    fname = get_db_name()
    open(fname, "w") do f
        JSON.print(f, db, 2)
    end
end




function db_lock()

    lockName = get_db_name() * ".lock"

    # wait until unlocked:
    #
    waitSecs = 10
    while isfile(lockName) && waitSecs > 0
        waitSecs -= 1
        sleep(1)
    end

    if waitSecs == 0
        print_log("ERROR: unable to lock home database file: $(dbName())")
        return false
    else
        open(lockName, "w") do f
            print_debug(f, "database is locked")
        end
        return true
    end
end

function db_unlock()

    lockName = get_db_name() * ".lock"
    rm(lockName, force = true)
end



function get_db_name()

    return get_config(:database_path)
end
