#!/bin/bash
# v1.0 vdrserver

#VDR-Backend

#nur einmal ausfuehren!
#echo $0
#echo $(basename $0)
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0
echo $(pidof -x $(basename $0) | wc -w)
echo $(pidof -x $(basename $0))
pidof -x $(basename $0) | wc -w
pidof -x $0
pidof -x test.sh | wc -w
pidof -x test.sh
echo OK

. /etc/vectra130/configs/sysconfig/.sysconfig

sleep 10
exit 0
while true; do

#VDR starten
. $SCRIPTDIR/.startvdr

sleep 1
done
