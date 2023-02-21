



"""
    TEMPLATE_SKILL_action(topic, payload)

Generated dummy action for the intent TEMPLATE_NAME_RAW.
This function will be executed when the intent is recognized.
"""
function TEMPLATE_SKILL_action(topic, payload)

    print_log("action TEMPLATE_SKILL_action() started.")
    publish_say(:skill_echo, get_intent(payload))

    if ask_yes_or_no(:ask_echo_slots)
