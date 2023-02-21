#!/bin/bash
#
# find all HermesMQTT installations by looking for 
# the filename HermesMQTT/config.ini
#
find / -name config.ini 2>/dev/null
exit 0