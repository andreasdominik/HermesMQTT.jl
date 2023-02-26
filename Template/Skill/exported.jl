# exported functions:
#
# DO NOT CHANGE THIS FILE UNLESS YOU KNOW
# WHAT YOU ARE DOING!
#
# deliver actions and intents to the Main context:
#
function get_intent_actions()

   return SKILL_INTENT_ACTIONS
end

function register_intent_action(intent, action)

    global SKILL_INTENT_ACTIONS
    topic = "hermes/intent/$intent"
    push!(SKILL_INTENT_ACTIONS, (intent, topic, MODULE_NAME, action))
end

function register_on_off_action(action)

    lang = get_language()
    intent = "$(HermesMQTT.HERMES_ON_OFF_INTENT)<$lang>"

    register_intent_action(intent, action)
end


# This function is executed to run a
# skill action in the module.
#
function callback_run(fun, topic, payload)

        Susi.set_topic(topic)

        Susi.set_siteID(payload[:siteId])
        Susi.set_sessionID(payload[:sessionId])
        Susi.set_intent(payload)

        Susi.set_module(MODULE_NAME)
        Susi.set_appdir(APP_DIR)
        Susi.set_appname(APP_NAME)

    if Susi.is_false_detection(payload)
        Susi.publish_end_session("")
        return false
    end

    result = fun(topic, payload)

    # fix, if the action does not return true or false:
    #
    if !(result isa Bool)
        result = false
    end

    if CONTINUE_WO_HOTWORD && result
        Susi.publish_start_session_action("")
    end
end
