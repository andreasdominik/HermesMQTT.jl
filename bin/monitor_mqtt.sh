#!/bin/bash
#
# output all MQTT traffic
#
# (c) A. Dominik, 2023
#
LAST=hermes
mosquitto_sub -v -h susi -p 12102 -u rhasspy -P 1701 -t '#' | \
    while read -r LINE ; do
        if [[ $LINE =~ (hermes|rhasspy|snips|Hermes) ]] ; then
            TOPIC="$(echo $LINE | awk '{print $1}')"

            if [[ $TOPIC =~ "audio" ]] ; then
                if [[ $LAST != audio ]] ; then
                    echo " "
                    echo  ">>> Topic: $TOPIC"
                    echo "Binary audio!"
                    LAST=audio
                fi
            else
                echo " "
                echo  ">>> Topic: $TOPIC"
                echo "$LINE" | sed 's/^[^ ]\+ //g' | jq
                LAST=hermes
            fi
        fi
    done