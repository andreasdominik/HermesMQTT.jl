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
                        i[2] == topic
                    end

    for t in matchedTopics

                       # intent
        topic = t[2]   # topic
        skill = t[3]   # module
        fun =   t[4]   # action function

        if occursin(r"hermes/intent/", topic)
            print_log("Hermes intent $topic recognised; execute $fun in $skill.")
        end
        skill.callback_run(fun, topic, payload)

        set_module(MODULE_NAME)
        set_appdir(APP_DIR)
        set_appname(APP_NAME)
    end

    #println("*********** mainCallback() ended! ****************")
end

