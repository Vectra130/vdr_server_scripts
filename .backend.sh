#!/bin/bash
# v1.0 vdrserver

#VDR-Backend

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

while true; do

#VDR starten
. $SCRIPTDIR/.startvdr

sleep 1
done
