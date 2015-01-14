#!/bin/bash
# v1.0 eeebox

#Infos fuer den SkinDesigner

DBUS="/usr/bin/vdr-dbus-send.sh /Plugins/skindesigner plugin.SVDRPCommand string:SCTK"

#cpu swap
CPUUSAGE=$(printf "%.2f\n" $(cat /proc/stat | grep "^cpu " | awk '{print ($2+$4)*100/($2+$4+$5)}' | tr "." ","))
#$DBUS string:"ctCpuUsage = $(echo $CPUUSAGE | tr ',' '.')"
logger -t INFO "CPUUSAGE "$CPUUSAGE

#mem usage
MEMUSAGE=$(printf "%.2f\n" $(free | grep "Mem:" | awk '{ print $3*100/$2 }' | tr "." ","))
#$DBUS string:"ctMemUsage = $(echo $MEMUSAGE | tr ',' '.')"
logger -t INFO "MEMUSAGE "$MEMUSAGE

#swap usage
SWAPUSAGE=$(printf "%.2f\n" $(free | grep "Swap:" | awk '{ print ($2-$4)*100/$2 }' | tr "." ","))
#$DBUS string:"ctSwapUsage = $(echo $SWAPUSAGE | tr ',' '.')"
logger -t INFO "SWAPUSAGE "$SWAPUSAGE
