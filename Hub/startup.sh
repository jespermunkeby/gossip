#!/bin/bash
#
# To add this, first make sure this file is executable by running
# $ chmod +x ~/Hub/startup.sh
#
# then type the following command
# $ crontab -e
#
# and add this line
# @reboot ~/Hub/startup.sh
#

sleep 5

sudo systemctl start hostapd

sleep 5

# Uncomment this line to actually make the program run
#python3 ~/Hub/main.py &&

# Uncomment this to power off the machine after exiting program
#sleep 2 &&

#sudo poweroff
