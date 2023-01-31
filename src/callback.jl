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
        print_log("intent or trigger aborted!")
        return
    end

    # find the intents or triggers that match the current
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
        else occursin(r"qnd/trigger/", topic)
            print_log("System trigger $topic recognised; execute $fun in $skill.")
        end
        skill.callback_run(fun, topic, payload)
    end

    #println("*********** mainCallback() ended! ****************")
end
