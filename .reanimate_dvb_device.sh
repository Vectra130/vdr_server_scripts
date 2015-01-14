#!/bin/bash
# v1.0 vdrserver

#Vom dynamite-Plugin detachte Devices wieder reanimieren

adapter="$1"
sleep 5
vdr-dbus-send.sh /Plugins/dynamite plugin.SVDRPCommand string:'ATTD $adapter' string:'command'

logger -t ATTACH_DVB "Device: $adapter attached"
exit 0
