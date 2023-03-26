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
    db_write_entry(key, entry)

Write a complete entry to a database entry.
The entry is overwitten if it already exists,
or created otherwise.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
- `entry`: entry with key `key`
         to be written.
"""
function db_write_entry(key, entry)

    if ! (key isa Symbol)
        key = Symbol(key)
    end

    if !db_lock()
        return false
    end

    db = db_read()
    db[key] = entry
    db_write(db)
    db_unlock()
end

"""
    db_write_value(key, field, value)

Write a field=>value pair to the entry of a database entry.
The field is overwitten if the entry already exists,
or created elsewise.
The database is written to the JSON-file after the write.

## Arguments
- `key`: unique key of the database entry of
         type `AbstractString` or `Symbol`
- `field`: database field of the entry with key `key`
         to be written (`AbstractString` or `Symbol`).
- `value`: value to be stored in the field, typically
         a Dict() will be stored as JSON.
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
    if !haskey(db, key)
        db[key] = Dict()
    end

    db[key][field] = value

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

    if !(key isa Symbol)
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

    entry = db_read_entry(key)

    if isnothing(entry)
        print_log("Try to read value for unknown key $key from status database.")
        return nothing

    else
        if ! (field isa Symbol)
            field = Symbol(field)
        end

        if haskey(entry, field)
            return entry[field]
        else
            print_log("Try to read value for key $key and unknown field $field from status database.")
            return nothing
        end
    end
end






"""
    db_read()

Read the status db from file.
Path is constructed from `config.ini` values
`<HermesMQTT dir>/database/<database_file>`.
"""
function db_read()

    db_path_name = get_db_name()
    db = try_parse_JSON_file(db_path_name, quiet=true)

    if length(db) == 0
        print_log_skill("Empty status DB read: $db_path_name", skill=HERMES_MQTT)
        db = Dict()
    end
    return db
end


"""
    db_write()

Write the status db to a file.
"""
function db_write(db)

    db_name = get_db_name()
    db_path = dirname(db_name)
    isdir(db_path) || mkpath(db_path, mode=0o755)

    fname = get_db_name()
    open(fname, "w") do f
        JSON.print(f, db, 2)
    end
end




function db_lock()

    db_name = get_db_name()
    db_path = dirname(db_name)
    isdir(db_path) || mkpath(db_path, mode=0o755)
    lock_name = "$db_name.lock"

    # wait until unlocked:
    #
    wait_secs = 5
    while isfile(lock_name) && wait_secs > 0
        wait_secs -= 1
        sleep(1)
    end

    if wait_secs == 0
        print_log("ERROR: unable to lock home database file: $db_name")
        return false
    else
        open(lock_name, "w") do f
            print(f, "database is locked")
        end
        return true
    end
end

function db_unlock()

    lock_name = "$(get_db_name()).lock"
    println("unlocking database $lock_name")
    rm(lock_name, force = true)
end



function get_db_name()

    return get_config(:database_path)
end
