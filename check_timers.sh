#!/bin/bash
# Script erstellt eine all_timers.conf mit neuen Timern

#vars
vdrConfDir=/root/.vdr
timersConfFile=$vdrConfDir/timers.conf
allTimersConfFile=$vdrConfDir/all_timers.conf
touch $allTimersConfFile



read_new_timers() {
newTimers=$(diff $timersConfFile $allTimersConfFile | grep ^"< 1" | sed -e 's/<\ //g')
echo -e "Neue Timer:\n$newTimers"
}

write_new_timers() {
echo -e "$newTimers" >> $allTimersConfFile
cleanFile=$(cat $allTimersConfFile | sed '/^ *$/d' | sort | uniq)
echo -e "$cleanFile" > $allTimersConfFile
}




#Ablauf
read_new_timers
write_new_timers

exit 0
