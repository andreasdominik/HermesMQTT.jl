# DO NOT CHANGE THE FOLLOWING 3 LINES UNLESS YOU KNOW
# WHAT YOU ARE DOING!
# set CONTINUE_WO_HOTWORD to true to be able to chain
# commands without need of a hotword in between:
#
const CONTINUE_WO_HOTWORD = false

# set a local const LANG:
#
const LANG = Susi.get_language()



# Slots:
# Name of slots to be extracted from intents:
#
SLOT_NAMES

# name of entries in config.ini:
#

#
# link between actions and intents:
# intent is linked to action{Funktion}
# the action is only matched, if
#   * intentname matches and
#   * if the siteId matches, if site is  defined in config.ini
#     (such as: "switch TV in room abc").
#
# Susi.register_intent_action("TEMPLATE_SKILL", TEMPLATE_INTENT_action)
# Susi.register_on_off_action(TEMPLATE_INTENT_action)
