#!/bin/bash
#Update Script

#Vorbereitungen
#configvars setzen
. /etc/vectra130/configs/sysconfig/.sysconfig

#Multimedia beenden
. $SCRIPTDIR/.stopallmultimedia

#weitere Dienste beenden
for daemon in "lighttpd samba camd3run irexec lircd"; do
	[ -e /etc/init.d/$daemon ] && /etc/init.d/$daemon stop
done

#Update Grafik einblenden
$SCRIPTDIR/.showstartimage.sh update



#Ende der Vorbereitungen

#Update durchfuehren

#Dienste installieren/deinstallieren
apt-get update
aptitude install 
aptitude purge 

#Dateien kopieren/loeschen



#Update Ende
#Neustart
#/sbin/reboot

exit 0
