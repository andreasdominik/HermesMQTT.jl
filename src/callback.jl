CONTINUE_WO_HOTWORD = false

#
# main callback function:
#
# Normally, it is NOT necessary to change anything in this file,
# unless you know what you are doing!
#

function main_callback(topic, payload)

    # println("""*********************************************
    #         $payload
    #         ************************************************""")

    if !(payload isa Dict) ||
       !(haskey(payload, :siteId)) ||
       !(haskey(payload, :sessionId))


        print_log("Corrupted payload detected for topic $topic")
        # print_log("payload: $(JSON.print(payload))")
        print_log("intent aborted!")
        return
    end

    # find the intents that match the current
    # message:
    matchedTopics = filter(Main.INTENT_ACTIONS) do i
                        i[3] == topic
                    end

    for t in matchedTopics

        topic = t[3]
        fun = t[5]   # action function
        skill = t[4]   # module

        if occursin(r"hermes/intent/", topic)
            print_log("Hermes intent $topic recognised; execute $fun in $skill.")
        end
        skill.callback_run(fun, topic, payload)
    end

    #println("*********** mainCallback() ended! ****************")
end



# This function is executed to run a
# skill action in the module.
#
function callback_run(fun, topic, payload)

    set_topic(topic)

    if occursin(r"^hermes/intent/", topic)
        set_siteID(payload[:siteId])
        set_sessionID(payload[:sessionId])
        set_intent(payload)

        if is_false_detection(payload)
            publish_end_session("")
            return false
        end
    end

    result = fun(topic, payload)

    # fix, if the action does not return true or false:
    #
    if !(result isa Bool)
        result = false
    end

    if CONTINUE_WO_HOTWORD && result
        publish_start_session_action("")
    end
end
