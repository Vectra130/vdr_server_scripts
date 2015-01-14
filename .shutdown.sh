#!/bin/bash
# v1.0 vdrserver

#Script prueft vor dem Shutdown ob ein Aufnahmetimer lauft oder in den naechsten 5min startet

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

ACTION=$0
ACTION=$(basename $ACTION)
ACTION2="$@"
powerdown(){
logger -t POWEROFF "$ACTION wird eingeleitet"
#Avahi Infos loeschen
rm /etc/avahi/services/*

#DVB Treiber entladen
logger -t INFO "Entlade DVB Treiber"
[ "$DDHD" == 1 ] && rmmod ddbridge
[ "$SDFF" == 1 ] && rmmod dvb-ttpci
[ "$STHD" == 1 ] && /opt/bin/mediaclient --shutdown

# PCI Ports resetten
pciPort=$(lspci | grep Multimedia | awk -F":" '{ print $1 }' | sort | uniq | tr "\n" " ")
if [ "x$pciPort" != "x" ]; then
        logger -t INFO "PCI Portreset wird durchgefuehrt (Ports: $(lspci | grep Multimedia | awk -F":" '{ print $1 }' | sort | uniq | tr '\n' ' '))"
        for getPort in $pciPort; do
                echo 1 > /sys/bus/pci/devices/0000:${pciPort}:00.0/rescan
                echo 1 > /sys/bus/pci/devices/0000:${pciPort}:00.0/reset
                echo 1 > /sys/bus/pci/rescan
        done
fi

case "$ACTION" in
poweroff)
echo POWEROFF!!!
	/sbin/shutdown.exec -h -P now
	;;
reboot)
echo REBOOT!!!
	/sbin/shutdown.exec -r now
	;;
shutdown)
echo SHUTDOWN!!!
	/sbin/shutdown.exec $ACTION2
	;;
esac
}

if [ "$1" == "force" ]; then
	echo "FORCE"
	powerdown
	exit 0
fi

. $SCRIPTDIR/.check_next_timer

if [ "X$?" != X2 ]; then
	powerdown
else
	logger -t POWEROFF "$ACTION abgebrochen"
	echo "Aufnahme steht an. $ACTION abgebrochen!!!"
	vdr-dbus-send.sh /Timers timer.List | grep -v array | grep -v "]" | sed -e 's/string \"//' -e 's/\"//'
	CLIENTINFO="Aktiver Timer! $ACTION abgebrochen"
	. $SCRIPTDIR/.vdr_clientinfo
fi
exit 0
