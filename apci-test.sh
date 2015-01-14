#!/bin/bash
# Startet dem Rechner nach 3 Minuten ueber ACPI neu.

DEV=/sys/class/rtc/rtc0/wakealarm
#DEV=/proc/acpi/alarm              # Fuer Kernel < 2.6.22

nextboot=`date --date "now +180 seconds" "+%s"`
echo 0 > $DEV
echo $nextboot > $DEV  # Einige Mainboards sind etwas begriffsstutzig,
#echo $nextboot > $DEV  # sie kapieren erst nach zwei Aufrufen, was Sache ist.


echo "Aktuelle Zeit:         "`date "+%Y-%m-%d %H:%M:%S"`
echo
cat /proc/driver/rtc
echo
echo "Fahre Rechner runter."

#busybox poweroff
#/usr/bin/poweroff.pl
poweroff
