# functions for the QnD scheduler
#
#


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

    TRIGGER_NAME = "HermesMQTTScheduler"
    action = scheduler_make_action(executeTime, topic, trigger,
                            origin = origin)

    scheduleTrigger = Dict(
        :origin => origin,
        :topic => "HermesMQTT/trigger/$TRIGGER_NAME",
        :siteId => siteID,
        :sessionId => sessionID,
        :mode => "add schedules",
        :time => "$(Dates.now())",
        :actions => [action]
        )
    publish_system_trigger($TRIGGER_NAME, scheduleTrigger)
end


"""
    scheduler_add_actions(actions; ...)

Add all actions in the list of action objects to the database of
scheduled actions for execution.
The elements of `actions` can be created by `schedulerMakeAction()` and must
include executeTime, topic and the trigger to be published.

- `actions`: List of actions to be published. Format of the
           trigger is defined by the target skill.
"""
function scheduler_add_actions(actions;
                            sessionID=get_sessionID(),
                            origin=get_appname(),
                            siteID=get_siteID())

    scheduleTrigger = Dict(
        :origin => origin,
        :topic => "qnd/trigger/andreasdominik:HermesMQTTScheduler",
        :siteId => siteID,
        :sessionId => sessionID,
        :mode => "add schedules",
        :time => "$(Dates.now())",
        :actions => actions
        )

    publishSystemTrigger("HermesMQTTScheduler", scheduleTrigger)
end




"""
    scheduler_make_action(executeTime, topic, trigger;
                            origin=get_appname())

Return a `Dict` in the format for the QnD scheduler.
A list of these object can be used to schedule many
actions at once via `schedulerAddActions()`.
(see documentation of `schedulerAddAction()` for details.)
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
    scheduler_delete_all()

Delete all scheduled action triggers.
"""
function scheduler_delete_all()

    trigger = Dict(
        :mode => "delete all",
        :sessionId => get_sessionID(),
        :siteId => get_siteID(),
        :topic => "dummy",
        :origin => "dummy",
        :time => "$(Dates.now())"
        )
    publishSystemTrigger("HermesMQTTScheduler", trigger)
end


"""
    scheduler_delete_topic(topic)

Delete all scheduled action triggers with the given topic.
"""
function scheduler_delete_topic(topic)

    topic = expandTopic(topic)
    trigger = Dict(
        :mode => "delete by topic",
        :sessionId => get_sessionID(),
        :siteId => get_siteID(),
        :topic => topic,
        :origin => "dummy",
        :time => "$(Dates.now())"
        )
    publishSystemTrigger("ADoSnipsScheduler", trigger)
end


"""
    scheduler_delete_by_origin(origin)

Delete all scheduled action triggers with the given origin
(i.e. name of the app which cerated the scheduled action).
"""
function scheduler_delete_by_origin(origin)

    trigger = Dict(
        :mode => "delete by origin",
        :sessionId => get_sessionID(),
        :siteId => get_siteID(),
        :topic => "dummy",
        :origin => origin,
        :time => "$(Dates.now())"
        )
    publishSystemTrigger("HermesMQTTScheduler", trigger)
end
