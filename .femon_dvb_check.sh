#!/bin/bash
# v1.0 vdrserver

#Signalinfos der DVB Empfaenger auslesen

#while read dvb; do
for dvb in $(ls /dev/dvb/); do

adapter=$(echo $dvb | sed 's/.*adapter//')
echo "Adapter $adapter"
femon=$(femon -a$adapter -c1 -H | grep -v Problem)
echo $femon | grep "FE:"
echo $femon | grep -v Problem | awk -F \| '{ print $1 "," $2 "," $3 ":" $10 "," $12":"$13","$15":"$16 }'

done
