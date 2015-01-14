#!/bin/bash
# v1.0 vdrserver

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

nice -$_watchdog_sh_nice $SCRIPTDIR/.backend.sh &


