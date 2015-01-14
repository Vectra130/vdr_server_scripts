#!/bin/bash
# v1.1 vdrserver

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

set_avahi() {
#avahi service eintrag
cat > /etc/avahi/services/video_hdd_mount_${1}.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
<name replace-wildcards="yes">/vdrvideo0$1|$2|nfstype=$3|/$4</name>
<service>
       <type>_VDR-Streaming-Mount._tcp</type>
</service>
</service-group>
EOF
}
set_avahi_mount() {
#neue struktur
cat > /etc/avahi/services/video_hdd_mount.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
<name replace-wildcards="yes">VDR-Streaming-Mount @ %h</name>
<service>
        <type>_VDR-Streaming-Mount._tcp</type>
        <port>694</port>
$(echo -e $MOUNT)
 </service>
</service-group>
EOF
}

#videodir mounts loesen
stop autofs
MOUNT=""
for i in 0 1 2 3 4 5 6 7 8; do
	umount -l /vdrvideo0$i
#	[ -e /etc/avahi/services/video_hdd_mount_$i.service ] && rm /etc/avahi/services/video_hdd_mount_$i.service
#	[ -e /etc/avahi/services/video_nas_mount_$i.service ] && rm /etc/avahi/services/video_nas_mount_$i.service
	[ -e /etc/avahi/services/video_nas_mount.service ] && rm /etc/avahi/services/video_nas_mount.service
done

#erst alle videoverzeichnisse und mount eintraege loeschen
[ $(ls / | grep vdrvideo0 | wc -l) -gt 0 ] && rmdir /vdrvideo0*
sed -i -e '/vdrvideo0/d' /etc/fstab

#alte hdds aus /etc/exports entfernen
sed -i -e '/^\/vdrvideo0[0-9]/d' /etc/exports

#pruefen ob alle Verzeichnisse geloescht sind
if [ $(ls / | grep vdrvideo0[1-9] | wc -l) -gt 0 ]; then
	if [ ! -e /tmp/.set_videodir ]; then
		logger -t VIDEOMOUNT "Irgendwas lief schief! Nicht alle Videoverzeichnisse konnten gelöscht werden. Versuche es noch einmal!!!"
		[ ! -e /tmp/.set_videodir ] && touch /tmp/.set_videodir
		/etc/vectra130/scripts/.set_videodir_hdds.sh &
		exit 0
	fi
	logger -t VIDEOMOUNT "Irgendwas lief schief! Nicht alle Videoverzeichnisse konnten gelöscht werden!!!"
	exit 0
fi

echo "OK" > /tmp/.set_videodir

#pruefen ob HDDs verfuegbar sind
. $SCRIPTDIR/.set_local_hdds
. $SCRIPTDIR/.set_nas_hdds
[ "x$hddCount" == "x" ] && exit 0

#autofs wieder starten
start autofs

#video verzeichnisse anlegen
#echo "hddCount=$hddCount"
if [ "$hddCount" == 1 ]; then
	mkdir /vdrvideo00
	echo -e "/vdrvideo01 /vdrvideo00\tnone\tbind,noauto\t0\t0" >> /etc/fstab
fi
if [ "$hddCount" -gt 1 ]; then
	mkdir /vdrvideo00
	DIRS=$(find /vdrvideo0[1-8] -maxdepth 0 | tr '\n' ',')
	echo "mhddfs: $DIRS"
	echo -e "mhddfs#${DIRS%%,}\t/vdrvideo00\tfuse\tnoauto,rw,defaults,allow_other,mlimit=1024M" >> /etc/fstab
fi
set_avahi_mount
mount /vdrvideo00
exportfs -ra
[ -e /tmp/.set_videodir ] && rm /tmp/.set_videodir
exit 0


