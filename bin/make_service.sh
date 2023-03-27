#!/bin/bash 
#
# install HermesMQTT.jl as a service
#
# (a)dominik, Feb. 2023
#
H_MQTT_PATH="$1"
USER=$2
JULIA_EXEC=$3

SERVICE_NAME="hermesmqtt"
FILE_NAME="/etc/systemd/system/$SERVICE_NAME.service"
ACTION="$H_MQTT_PATH/HermesMQTT.jl/bin/action-hermesMQTT.jl"



echo "[Unit]" > $FILE_NAME
echo "Description=HermesMQTT service" >> $FILE_NAME
echo "After=network.target" >> $FILE_NAME
echo " " >> $FILE_NAME

echo "[Service]" >> $FILE_NAME
echo "Type=simple" >> $FILE_NAME
echo "Restart=always" >> $FILE_NAME
echo "RestartSec=1" >> $FILE_NAME
echo "StartLimitBurst=5" >> $FILE_NAME
echo "StartLimitIntervalSec=10" >> $FILE_NAME

echo "User=$USER" >> $FILE_NAME
echo "WorkingDirectory=$H_MQTT_PATH" >> $FILE_NAME
echo "ExecStart=$JULIA_EXEC $ACTION" >> $FILE_NAME
echo " " >> $FILE_NAME

echo "[Install]" >> $FILE_NAME
echo "WantedBy=multi-user.target" >> $FILE_NAME

