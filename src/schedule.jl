# functions for the HermesMQTT scheduler
# to publish scheduler triggers:
#
#

const SCHEDULE_TRIGGER_NAME = "HermesMQTTScheduler"
const SCHEDULE_TRIGGER_PREFIX = "HermesMQTT/trigger"


"""
    publish_schedule_trigger(executeTime, topic, trigger;
            sessionID=get_sessionID(),
            origin=get_appname(),
            siteId =get_siteID())

Add the `trigger` to the database of scheduled actions for
execution at `executeTime`.

## Arguments:
- `executeTime`: DateTime object
- `topic`: topic to which the system trigger will be published.
           topic has the format: `"HermesMQTT/trigger/Susi:LightsSilent"`.
           The prefix `"HermesMQTT/trigger/"` is added if
           missing in the arguments.
- `trigger`: The system trigger to be published as Dict(). Format of the
           trigger is defined by the target skill.

`sessionID`, `origin` and `siteID` defaults to the current
values, if not given. SessionId and origin can be used to select
scheduled actions for deletion.
"""
function publish_schedule_trigger(executeTime, topic, trigger;
                            sessionID=get_sessionID(),
                            origin=get_appname(),
                            siteID=get_siteID())

    action = scheduler_make_action(executeTime, topic, trigger,
                            origin = origin)

    scheduleTrigger = Dict(
        :origin => origin,
        :topic => "$SCHEDULE_TRIGGER_PREFIX/$SCHEDULE_TRIGGER_NAME",
        :siteId => siteID,
        :sessionId => sessionID,
        :mode => "add schedules",
        :time => "$(Dates.now())",
        :actions => [action]
        )
    publish_system_trigger(SCHEDULE_TRIGGER_NAME, scheduleTrigger)
end


"""
    publish_schedule_actions(actions; ...)
    publish_schedule_action(action; ...)

Add all actions in the list of action objects to the database of
scheduled actions for execution.
The elements of `actions` can be created by `schedulerMakeAction()` and must
include executeTime, topic and the trigger to be published.

The singular form can be used to schedule a single action.

- `actions`: List of actions to be published. Format of the
           trigger is defined by the target skill.
"""
function publish_schedule_actions(actions;
                            sessionID=get_sessionID(),
                            origin=get_appname(),
                            siteID=get_siteID())

    scheduleTrigger = Dict(
        :origin => origin,
        :topic => "$SCHEDULE_TRIGGER_PREFIX/$SCHEDULE_TRIGGER_NAME",
        :siteId => siteID,
        :sessionId => sessionID,
        :mode => "add schedules",
        :time => "$(Dates.now())",
        :actions => actions
        )

    publish_system_trigger(SCHEDULE_TRIGGER_NAME, scheduleTrigger)
end

function publish_schedule_action(action;
                            sessionID=get_sessionID(),
                            origin=get_appname(),
                            siteID=get_siteID())

    publish_schedule_actions([action];
                            sessionID=sessionID,
                            origin=origin,
                            siteID=siteID)
end




"""
    scheduler_make_action(executeTime, topic, trigger;
                            origin=get_appname())

Return a `Dict` in the format for the HermesMQTT scheduler.
A list of these object can be used to schedule many
actions at once via `publish_schedule_actions()`.
"""
function scheduler_make_action(executeTime, topic, trigger;
                            origin=get_appname())

    topic = expandTopic(topic)
    action = Dict(
        :topic => topic,
        :origin => origin,
        :execute_time => "$executeTime",
        :trigger => trigger
        )

    return action
end



"""
    publish_delete_all_schedules()

Delete all scheduled action triggers.
"""
function publish_delete_all_schedules()

    trigger = Dict(
        :mode => "delete all",
        :sessionId => get_sessionID(),
        :siteId => get_siteID(),
        :topic => "dummy",
        :origin => "dummy",
        :time => "$(Dates.now())"
        )
    publish_system_trigger(SCHEDULE_TRIGGER_NAME, trigger)
end


"""
    publish_delete_scheduled_topic(topic)

Delete all scheduled action triggers with the given topic.
"""
function scheduler_delete_scheduled_topic(topic)

    topic = expandTopic(topic)
    trigger = Dict(
        :mode => "delete by topic",
        :sessionId => get_sessionID(),
        :siteId => get_siteID(),
        :topic => topic,
        :origin => "dummy",
        :time => "$(Dates.now())"
        )
    publish_system_trigger(SCHEDULE_TRIGGER_NAME, trigger)
end


"""
    publish_delete_schedule_by_origin(origin)

Delete all scheduled action triggers with the given origin
(i.e. name of the app which cerated the scheduled action).
"""
function  publish_delete_schedule_by_origin(origin)

    trigger = Dict(
        :mode => "delete by origin",
        :sessionId => get_sessionID(),
        :siteId => get_siteID(),
        :topic => "dummy",
        :origin => origin,
        :time => "$(Dates.now())"
        )
    publishSystemTrigger(SCHEDULE_TRIGGER_NAME, trigger)
end



# action for the scheduler to be executed if the trigger
# is received:
#
const SCHEDULE_TRIGGER_NAME = "HermesMQTTScheduler"
const SCHEDULE_TRIGGER_PREFIX = "HermesMQTT/trigger"

"""
    scheduler_action(topic, payload)

Trigger action for the scheduler. Each scheduler trigger must
contain a trigger and an execution time for the trigger.

## Trigger: add new schedule

A scheduler trigger addresses the scheduler (as target) and must
include a list of complete trigger objects as payload (i.e. trigger):
```
{
  "origin": "Susi:Automation",
  "topic": "HermesMQTT/trigger/HermesMQTTScheduler",
  "siteId": "default",
  "sessionId": "7dab7a26-84fb-4855-8ad0-acd955408072",
  "trigger": {
    "mode": "add schedules",
    "sessionId": "7dab7a26-84fb-4855-8ad0-acd955408072",
    "siteId": "default",
    "time": "2019-08-26T14:07:55.623",
    "origin": "Susi:Automation",
    "actions": [
      {
        "topic": "HermesMQTT/trigger/Susi:Lights",
        "origin": "Susi:Automation",
        "execute_time": "2019-08-28T10:00:20.534",
        "trigger": {
          "settings": "undefined",
          "device": "floor_light",
          "onOrOff": "OFF",
          "room": "default"
        }
      },
      {
        "topic": "HermesMQTT/trigger/Susi:Lights",
        "origin": "Susi:Automation",
        "execute_time": "2019-08-28T10:00:20.534",
        "trigger": {
          "settings": "undefined",
          "device": "floor_light",
          "onOrOff": "OFF",
          "room": "default"
        }
      }
    ]
  }
}
```

## Trigger: delete schedules

The trigger can delete **all** schedules or all schedules
for a specific trigger. The field `topic` is ignored for `mode == all`:
```
{
  "origin": "Susi:Automation",
  "topic": "HermesMQTT/trigger/HermesMQTTScheduler",
  "siteId": "default",
  "sessionId": "7dab7a26-84fb-4855-8ad0-acd955408072",
  "trigger": {
    "mode": "delete all",
    "sessionId": "7dab7a26-84fb-4855-8ad0-acd955408072",
    "siteId": "default",
    "topic": "dummy",
    "origin": "dummy",
    "time": "2019-08-26T14:07:55.623"
  }
}
```
"""
function scheduler_action(topic, payload)

    global action_channel

    print_log("trigger action scheduler_action() started.")


    if !haskey(payload, :trigger)
        print_log("ERROR: Trigger has no payload trigger!")
        return false
    end
    trigger = payload[:trigger]
    if !haskey(trigger, :origin)
        trigger[:origin] = payload[:origin]
    end

    if !haskey(trigger, :mode)
        print_log("ERROR: Trigger has no mode!")
        return false
    end

    # if mode == add new schedules:
    #
    if trigger[:mode] == "add schedules"
        if !haskey(trigger, :actions) || !(trigger[:actions] isa AbstractArray)
            print_log("ERROR: Trigger has no actions!")
            return false
        end

        for action in trigger[:actions]
            if !haskey(action, :topic) ||
               !haskey(action, :execute_time) ||
               !haskey(action, :trigger)
                print_log("ERROR: Trigger is incomplete!")
                return false
            end
            if !haskey(action, :origin)
                action[:origin] = trigger[:origin]
            end

            print_debug("new action found. $action")
            put!(action_channel, action)
        end

    # else delete ...
    #
    elseif trigger[:mode] == "delete by topic"
        if !haskey(trigger, :topic)
            print_log("ERROR: scheduler delete by topic but no topic in trigger!")
            return false
        end
        print_log("New delete schedule by topic trigger found: $trigger)")
        put!(delete_channel, trigger)

    elseif trigger[:mode] == "delete by origin"
        if !haskey(trigger, :origin)
            print_log("ERROR: scheduler delete by origin but no origin in trigger!")
            return false
        end
        print_log("New delete schedule by origin trigger found: $trigger)")
        put!(delete_channel, trigger)

    elseif trigger[:mode] == "delete all"
        print_log("New delete all schedules: $trigger)")
        put!(delete_channel, trigger)

    else
        print_log("Trigger has no valid mode: $trigger)")
    end
    return false
end



# run the scheduler in a separate task:
#
function start_scheduler()

    if ! check_all_config()
        print_log("Error reading config -> scheduler not started!")
        return
    end

    db = read_schedule_db()

    # loop forever
    # and execute one trigger per loop every 1 sec, if one is due
    # wait 60 secs if no more triggers are due.
    #
    interval = 60  # sec
    while true

        global action_channel
        global delete_channel
    
        db = read_schedule_db()

        # add actions to db:
        # read from channel, until empty:
        #
        while isready(action_channel)
            action = take!(action_channel)
            print_debug("action from channel: $action")
            add_action!(db, action)
        end
        # listen to delete signals:
        # read from _channel, until empty:
        #
        while isready(delete_channel)
            deletion = take!(delete_channel)
            # printDebug("deletion from _channel: $deletion")
            rm_actions!(db, deletion)
        end
        # printDebug("length: $(length(db))")
        # printDebug("length: $(length(db)), scheduler db: $db")

        # exec oldest action since last iteration
        #
        if length(db) > 0 && isDue(db[1])
            next_action = deepcopy(db[1])
            run_action(next_action)
            rm_1st_action!(db)
            interval = 1
        else
            interval = 60
        end

        sleep(interval)
    end
end



# modify the schedule db:
#
function read_schedule_db()

    if !db_has_entry(:scheduler)
        return Dict[]
    end

    db = db_read_value(:scheduler, :db)
    if isnothing(db)
        return Dict[]
    else
        return db
    end
end

function add_action!(db, action)

    action[:create_time] = Dates.now()
    if !haskey(action, :origin)
        action[:origin] = "unknown"
    end

    if !haskey(action, :topic)
        print_log("ERROR: action has no topic -> ignored!")
    else
        push!(db, action)
        sort!(db, by = x->x[:execute_time])
        db_write_value(:scheduler, :db, db)  # db is the schedule field of complete db
    end
    return db
end


function rm_1st_action!(db)

    if length(db) > 0
        deleteat!(db, 1)
    end
    Snips.db_write_value(:scheduler, :db, db)
    return db
end


function rm_actions!(db, deletion)

    if deletion[:mode] == "delete all"
        mask = [true for x in db]

    elseif deletion[:mode] == "delete by topic"
        mask = [x[:topic] == deletion[:topic] for x in db]

    elseif deletion[:mode] == "delete by origin"
        mask = [x[:origin] == deletion[:origin] for x in db]

    else
        mask = [false for x in db]
    end

    deleteat!(db, mask)
    db_write_value(:scheduler, :db, db)
    return db
end

"""
    function isDue(action)

Check, if the scheduled execution stime of action is in the past
and return `true` or `false` if not.
"""
function is_due(action)

    if haskey(action, :execute_time)
        return Dates.DateTime(action[:execute_time]) < Dates.now()
    else
        return false
    end
end


function run_action(action)

    Snips.print_log("SystemTrigger $(action[:topic]) published by scheduler.")
    Snips.publish_system_trigger(action[:topic], action[:trigger][:trigger])
end
