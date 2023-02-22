# API documentation

## Hermes functions

These functions publish and subscribe to Hermes MQTT-topics.

```@docs
subscribe_to_intents
subscribe_to_topics
publish_start_session_action
publish_start_session_notification
publish_end_session
publish_hotword_on
publish_hotword_off
```


## Dialogue manager functions

In addition to functions to work with the dialogue manager,
advanced direct dialogues are provided that can be included
in the control flow of the program.

```@docs
publish_continue_session
listen_intents_one_time
configure_intent
ask_yes_or_no_or_unknown
ask_yes_or_no
publish_say
publish_nlu_query
publish_intent
```

## Interaction with assistant Rhasspy/Susi/Snips

```@docs
get_language
```

## Functions to handle intents

```@docs
register_intent_action
get_intent_actions
set_intent_actions
is_false_detection
```



## config.ini functions

Helper functions for read values from the file `config.ini`.

`config.ini` files follow the normal rules as for all Snips apps, with
some extensions:

- spaces are allowed around the `=`
- the parameter value may not contain whitespace; i.e.
  `light=my light` is better `light=my_light`
- if the value of the parameter (right side) includes commas,
  the value can be interpreted as a comma-separated list of values.
  In this case, the reader-function will return an array of Strings
  with the values (which an be accessed by their index).
- parameter names may have a prefix (set by the function 
  `set_config_prefix()`).
  If set, all config-functions will try to find parameter names with prefix.
  Example: If the config.ini includes the lines:
  ```
  main_light:ip=192.168.0.15
  wall_light:ip=192.168.0.16
  ```
  the following code returns `192.168.0.15` in the first call
  and `192.168.0.16` in the second. This makes it easy to delegate config-reads
  to sub-functions:

  ```
  set_config_prefix("main_light")
  main_ip = get_config("ip")

  set_config_prefix("wall_light")
  wall_ip = get_config("ip")
  ```

  Obviously is possible to access the parameters directly via
  `get_config("main_light:ip")` or
  `get_config(Symbol("main_light:ip"))`
  without setting the prefix (the second form will work even if another
  prefix is set; see doc of the functions for details).



```@docs
get_config
set_config_prefix
reset_config_prefix
get_all_config
read_config
match_config
is_in_config
is_config_valid
get_config_path
load_hermes_config
load_skill_config
load_two_configs
```


## Slot access functions

Functions to read values from slots of recognised intents.

```@docs
extract_slot_value
extract_multislot_values
is_in_slot
is_on_off_matched
is_valid_or_end
read_time_from_slot
```


## MQTT functions

Low-level API to MQTT messages (publish and subscribe).
In the QuickAndDirty framework, these functions are calling
Eclipse `mosquitto_pub` and `mosquitto_sub`. However
this first (and preliminary) implementation is surpriningly
robust and easy to maintain - there might be no need to change.

```@docs
subscribe_MQTT
read_one_MQTT
publish_MQTT
publish_MQTT_file
```



## Handle background information of recognised intent
```@docs
set_siteID
get_siteID
set_sessionID
get_sessionID
set_module
get_module
set_appdir
get_appdir
set_appname
get_appname
set_topic
get_topic
set_intent
get_intent
```

## Multi-language utilities
```@docs
set_language
add_text
lang_text
```

## Hardware control

Some devices can be directly controlled by the framework.
In order to stay in the style of Snips, it is possible to
run Shelly WiFi-switches without any cloud accounts and
services.
The Shelly-devices come with an own WiFi network. After installing the
device just connect to Shelly's access point (somthing like `shelly1-35FA58`)
and configure the switch for DHCP in your network with  teh selft-explaining
the web-interface of the device. At no point it's necessary to create an account
or use a cloud service (although the Shelly1 documentation recommends).

```@docs
set_GPIO
switch_shelly_1
switch_shelly_25_relay
move_shelly_25_roller
```

## Status database

The framework handles a database to save status about
house and devices, controlled by the assistant.
The database is stored on disk in order to persist in case
of a system crash or restart.

Every skill can store and read Dicts() as entries with a unique key
or values as field-value-pairs as part of an entry.

The db looks somehow like:
```
{
    "irrigation" :
    {
        "time" : "2019-08-26T10:12:13.177"
        "writer" : "Susi:Irrigation",
        "payload" :
        {
            "status" : "on",
            "next_status" : "off"
        }
    }
}
```


Location of the database file is
`<application_data_dir>/HermesMQTT/<database_file>`
where `application_data_dir` and `database_file>` are parameters in the
`config.ini` of the framework.

```@docs
db_write_payload
db_write_value
db_has_entry
db_read_entry
db_read_value
```

## Scheduler

The framework provides a scheduler which allows to execute
intents or commands at a specified time in the future.

*TBD*


## Utility functions

Little helpers to provide functionality which is commonly needed
when developing a skill.

```@docs
readable_date_time
get_weather
tryrun
ping
try_read_textfile
try_parse_JSON_file
try_parse_JSON
try_mk_JSON
print_log
print_debug
```

## Index

```@index
```
