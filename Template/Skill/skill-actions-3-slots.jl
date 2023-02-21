
        slot_value = extract_slot_value(SLOT_NAME, default=:no_slot)
        publish_say(:slot_echo_1, SLOT_NAME, :slot_echo_2, slot_value)
