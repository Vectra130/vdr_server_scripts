#!/bin/bash
# v1.0 vdrserver

#Script zum Anzeigen der Netzwerk-Aktivitaeten

[ "x$1" == "x" ] && echo "Port mit angeben!!!"
[ "x$1" == "x" ] && exit 2
. /etc/vectra130/configs/sysconfig/.sysconfig

NETEVENTFILE=$SCRIPTDIR/.scan_clients.conf

ACT=""
[ -e $SYSCONFDIR/.clients_online_$1 ] && rm $SYSCONFDIR/.clients_online_$1
touch $SYSCONFDIR/.clients_online_$1

#echo "Aktive Netzwerk-Clients:"
#echo "Client:		Port:	Protokoll:"

netstat>/tmp/netstat.tmp

while read LINE; do

 ACTEVENT=""

 if [ "$LINE" -a "`echo $LINE|cut -c 1`" != "#" ]; then 
  EVENT="`echo "$LINE"|cut -d " " -f 1`"
  EVENTNAME="`echo "$LINE"|cut -d " " -f 2-99`"
  if [ -z "$EVENTNAME" ]; then EVENTNAME="$EVENT"
  fi
  ACTEVENT="`cat /tmp/netstat.tmp|grep "$IP$EVENT"`"
 fi

 if [ "$ACTEVENT" ]; then

  OCLIENT=""
  OPORT=""

  while read PART; do
   CLIENT="`echo "$PART"|awk {'print $5'}|cut -d ":" -f 1`"
   if [ "`echo $EVENT|cut -c 1`" = ":" ]; then
    PORT="`echo "$EVENT"|cut -c 2-99`"
   else
    PORT="$EVENT"
   fi
   PROTO="$EVENTNAME"
   if [ "x$CLIENT" != "x$OCLIENT" -o "x$PORT" != "x$OPORT" ]; then
    echo "$CLIENT	$PORT 	$PROTO"
    [ "x$PORT" == "x$1" ] && echo "$CLIENT" >> $SYSCONFDIR/.clients_online_$1
    OCLIENT="$CLIENT"
    OPORT="$PORT"
   fi

  done< <(echo "$ACTEVENT")

 fi

done< <(cat $NETEVENTFILE)

rm /tmp/netstat.tmp
