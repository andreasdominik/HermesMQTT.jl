#!/bin/bash
#
# try to find a running Rhasspy instance and copy the profile
# settings to config.ini.
#
#  A. Dominik, Feb. 2023
#
DIR=$1    # Dir of HermesMQTT config.ini

while [[ -z $OK ]]; do
    
    echo "Please enter host and port of the running Rhasspy instance:"
    read -e -p "host: " -i "localhost" RHASSPY_HOST
    read -e -p "port: " -i "12101" RHASSPY_PORT
    
    RHASSPY_URL="http://$RHASSPY_HOST:$RHASSPY_PORT/api"
    echo "Trying to get profile from $RHASSPY_URL ..."

    # test if Rhasspy is running on url:
    #
    curl -s $RHASSPY_URL/profile  > /dev/null
    RESULT=$?
    if [[ $RESULT == 0 ]]; then
        echo " "
        echo "Rhasspy is running on $RHASSPY_URL"
        OK=yes
    else
        echo " "
        echo "Rhasspy is not running on $RHASSPY_URL"
        echo "Please try again."
    fi
done

LANGUAGE="$(curl -s $RHASSPY_URL/profile | jq -r '.language')"
MQTT_HOST="$(curl -s $RHASSPY_URL/profile | jq -r '.mqtt.host')"
MQTT_PORT="$(curl -s $RHASSPY_URL/profile | jq -r '.mqtt.port')"
MQTT_USERNAME="$(curl -s $RHASSPY_URL/profile | jq -r '.mqtt.username')"
MQTT_PASSWORD="$(curl -s $RHASSPY_URL/profile | jq -r '.mqtt.password')"


echo "Got the following settings from Rhasspy:"
echo "HTTP-API: $RHASSPY_URL/"
echo "Language: $LANGUAGE"
echo "MQTT host: $MQTT_HOST"
echo "MQTT port: $MQTT_PORT"
echo "MQTT username: $MQTT_USERNAME"
echo "MQTT password: $MQTT_PASSWORD"


# copy template config.ini:
#
cat $DIR/config.ini.template | \
    sed "s+<insert languagecode here before running HermesMQTT>+$LANGUAGE+g" | \
    sed "s+<insert MQTT hostname/IP here before running HermesMQTT>+$MQTT_HOST+g" | \
    sed "s+<insert MQTT port here before running HermesMQTT>+$MQTT_PORT+g" | \
    sed "s+<insert MQTT user here before running HermesMQTT>+$MQTT_USERNAME+g" | \
    sed "s+<insert MQTT password here before running HermesMQTT>+$MQTT_PASSWORD+g" | \
    sed "s+<insert HTTP-API URL here before running HermesMQTT>+$RHASSPY_URL+g" | \
    > $DIR/config.ini
