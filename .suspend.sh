#!/bin/bash
# v1.1 vdrserver

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

SHUTDOWN=1

activetimercheck(){
    CTACTIVE=0
    if [ -e /root/.vdr/timers.conf ]; then
        while read line
        do
            ACTIVE=`echo ${line} | awk -F : '{ print $1 }'`
            if [ X${ACTIVE} == X1 ]; then
		CTACTIVE=1
            fi
        done < <(cat /root/.vdr/timers.conf)
    fi

    #Pruefen ob aktiver Timer vorhanden ist
    if [[ X${CTACTIVE} == X0 || $1 == 0 ]]; then
        #Kein aktiver Timer
	logger -t SUSPEND "Kein aktiver Timer gefunden"
	ACTIVETIMER=0
    else
	#Aktiver Timer vorhanden
        logger -t SUSPEND "Aktiven Timer gefunden"
	ACTIVETIMER=1
    fi
}

activeclientcheck(){
	#Pruefen ob ein Client verbunden ist
	ACTIVECLIENT=0
	echo "" > $SYSCONFDIR/.clients_online
	. $SCRIPTDIR/.scan_avahi_clients
	. $SCRIPTDIR/.scan_clients

		CLIENT="$(cat $SYSCONFDIR/.clients_online | tr '\n' ' ')"
		if [ "X$(echo $CLIENT | sed -e 's/ //g')" != "X" ]; then
				ACTIVECLIENT=1
				logger -t SUSPEND "Es sind Streaming-Clients Online ( $CLIENT)"
		fi
	[ "$ACTIVECLIENT" == 0 ] && logger -t SUSPEND "Kein Client ist Online"
#	[ "$ACTIVECLIENT" == 1 ] && logger -t SUSPEND "Suspend wird abgebrochen"
#	[ "$ACTIVECLIENT" == 1 ] && suspend_frontend
	[ "$ACTIVECLIENT" == 1 ] && SHUTDOWN=0

}

activeusercheck(){
	USERONLINE=$(users)
	[ "X$USERONLINE" != "X" ] && logger -t SUSPEND "Es sind SSH-User angemeldet ( $(echo $USERONLINE | tr '\n' ' '))"
}

activeh264check() {
	if (  [ $(pidof -xs to_h264_server | wc -w) != 0 ] && [ $(/usr/local/bin/to_h264_sh_current -q | wc -l) -gt 1 ] ); then
		ACTIVEH264=1
		logger -t SUSPEND "Es stehen noch $(($(/usr/local/bin/to_h264_sh_current -q | wc -l)-1)) Videos zum konvertieren in der Warteschlange"
#		logger -t SUSPEND "Suspend wird abgebrochen"
		SHUTDOWN=0
	else
		ACTIVEH264=0
	fi
}

activemovecheck() {
	if [ $(pidof -xs .move_video.sh | wc -w) != 0 ]; then
		ACTIVEMOVE=1
		logger -t SUSPEND "Es werden gerade Videos verschoben"
#		logger -t SUSPEND "Suspend wird abgebrochen"
		SHUTDOWN=0
	else
		ACTIVEMOVE=0
	fi
}

shutdown(){
	touch /tmp/.startsuspend
	killall -q vdr &
        WAIT=0
        while true; do
	        [ $(pidof -xs vdr | wc -l) == "0" ] && break
                [ $WAIT == 30 ] && logger -t SUSPEND "sauberes beenden von vdr($VDRVERS) innerhalb von 30 Sekunden nicht moeglich, toete vdr($VDRVERS)" && killall -9 -q vdr && break
                WAIT=$[ WAIT+1 ]
                sleep 1
        done

	exit 0
}

#setchannel(){
#	if [ $(svdrpsend next rel | grep "-" | wc -l) != "0" ]; then
#		svdrpsend chan 7
#		logger -t SUSPEND "Keine Aufnahme aktiv, schalte auf Kanal 7"
#	fi
#}

suspend_frontend(){
#	vdr-dbus-send.sh /Remote remote.HitKeys array:string:'menu','5','blue','menu'
#	svdrpsend hitk menu 5 blue menu
	logger -t SUSPEND "Setze Frontend auf suspend"
}

#setchannel
activemovecheck
activeh264check
activeusercheck
activeclientcheck
#activetimercheck

	if [ "$1" != 0 ]; then
#		#ACPI Aufweckzeit wird konfiguriert
#		offset=$(($2 - 300 ))
#		# sync system clock to RTC
#		hwclock --systohc --utc
#		NextTimer=$(($1 - 300 ))  # Start 5 minutes earlier
#		#ACPI Device
#		DEV=/sys/class/rtc/rtc0/wakealarm
#		echo "0" > $DEV
#		echo $NextTimer > $DEV
#		STARTTIME=$(cat /proc/driver/rtc | grep alrm_time | awk -F':' '{ print $2":"$3":"$4 }')
#		STARTDATE=$(cat /proc/driver/rtc | grep alrm_date | awk -F':' '{ print $2 }' | awk -F'-' '{ print $3"-"$2"-"$1 }')
#		logger -t SUSPEND "ACPI konfiguriert. VDR startet wieder: $STARTTIME"
#		if [[ "$offset" -lt "60" || "$SHUTDOWN" == 0 ]] ; then
		. $SCRIPTDIR/.check_next_timer
		if [ "$?" == "2" ] ; then
#			logger -t SUSPEND "Aktiver Timer innerhalb der naechsten 5min gefunden. Shutdown abgebrochen"
			echo "Aufnahme steht an. Shutdown abgebrochen!!!"
			exit 0
		fi
	else
		logger -t SUSPEND "Kein Timer aktiv"
	fi
if [ "X$SHUTDOWN" == "X1" ]; then

logger -t SUSPEND "Suspend"
shutdown

fi

exit 0
