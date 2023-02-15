#!/bin/bash
#
# output all MQTT traffic
#
# (c) A. Dominik, 2023
#
read -d '' PAYLOAD << EOF
{
"init":{
    "type": "notification", 
    "text": "Hello Susi"
    },
"siteId": "hugh"
}
EOF
PAYLOAD=$(echo "$PAYLOAD" | tr -d '\n')

echo "$PAYLOAD"
mosquitto_pub -h susi -p 12102 -u rhasspy -P 1701 \
    -t 'hermes/dialogueManager/startSession' \
    -m "$PAYLOAD"
