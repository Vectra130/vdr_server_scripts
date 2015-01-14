#!/bin/bash


# Little Script for getting ID's for EPG from TVM and epgdate.com
# by 3PO


EPGD_CONF="/etc/epgd/epgd.conf"



[ -f $EPGD_CONF ] && PIN="$(grep epgdata.pin $EPGD_CONF |awk '{print $3 }')" 
PIN_LENGTH="$(echo "$PIN" |wc -c)"

URL="http://wwwa.tvmovie.de/static/tvghost/html/onlinedata/cftv520/datainfo.txt"

download_epgdata ()
{
if [ ! "$(ping -c 1 www.epgdata.com 1>/dev/null)" ] ; then
  if [ $PIN ] ; then
     cd $HOME
     [ ! -d .epgidcheck ] && mkdir .epgidcheck
     cd .epgidcheck
     CHECK_AGE=$(find . \( -name '*.zip' \) -ctime -1 -exec ls {} \; |wc -l)
     if [ $CHECK_AGE -eq 0 ] ; then
       rm -f *.xml *.zip
       echo -e "\n loading list from \"www.epgdata.com\" ...\n"
       curl -s "http://www.epgdata.com/index.php?action=sendInclude&iOEM=vdr&pin=$PIN&dataType=xml" -o data.zip
       if [ "$(grep "Wrong value in an parameter" data.zip)" ] ; then
         echo -e "\nWrong or expired Pin detected\n"
         echo -e "\nScript terminated\n"
         exit
       fi
       unzip data.zip
       echo -e "\n\n"
     fi
  fi
else
  echo -e "\nServer www.epgdata.com not available"
  echo -e "\nScript terminated\n"
fi

}

case $1 in

   -a-tvm|a-tvm)
   if [ ! "$(ping -c 1 wwwa.tvmovie.de 1>/dev/null)" ] ; then
     lynx --dump $URL | tail -n +4 |while read i ; do
     if [ "$str" == "" ] ; then
     str="$i"
     else
       printf "%-28s %s\n" "${str}" "${i}"
       str=""
     fi
     done |sort -f
   else
     echo -e "\nServer wwwa.tvmovie.de not available"
     echo -e "\nScript terminated\n"
   fi
   ;;

   -i-tvm|i-tvm)
   if [ ! "$(ping -c 1 wwwa.tvmovie.de 1>/dev/null)" ] ; then
     lynx --dump $URL | tail -n +4 | while read i ; do
     if [ "$str" == "" ] ; then
       str="$i"
     else
       printf "%-10s %s\n" "${i}" "${str}"
       str=""
     fi
     done |sort -n
   else
     echo -e "\nServer wwwa.tvmovie.de not available"
     echo -e "\nScript terminated\n"
   fi

   ;;

   -a-edc|a-edc)
   if [ $PIN_LENGTH != 41 ] ; then
     echo -e "\nNo, or incorrect Pin for epgdata.com found!"
     echo -e "\nScript terminated\n"
   else
     download_epgdata
     egrep "<ch0>|<ch4>" channel_y.xml |cut -d ">" -f2 |cut -d "<" -f1 |while read i ; do
     if [ "$str" == "" ] ; then
       str="$i"
     else
       printf "%-40s %s\n" "${str}" "${i}"
       str=""
     fi
     done |sort -f
   fi 
   ;; 

   -i-edc|i-edc)
   if [ $PIN_LENGTH != 41 ] ; then
     echo -e "\nNo, or incorrect Pin for epgdata.com found!"
     echo -e "\nScript terminated\n"
   else
     download_epgdata
     egrep "<ch0>|<ch4>" channel_y.xml |cut -d ">" -f2 |cut -d "<" -f1 |while read i ; do
     if [ "$str" == "" ] ; then
       str="$i"
     else
       printf "%-7s %s\n" "${i}" "${str}"
       str=""
     fi
     done |sort -n
   fi
   ;;

   -pin|pin)
   if [ $PIN_LENGTH != 41 ] ; then
     echo -e "\nNo, or incorrect Pin for epgdata.com found!"
   else
     echo -e "\n$PIN\n"
   fi
   ;;


   *)
   echo -e "\n   Little Script for getting ID's for EPG from TVM and epgdata.com"
   echo -e "\n   by 3PO\n"
   echo -e "\n   usage: [-a-tvm] [-i-tvm] [-a-edc] [-i-edc] [-pin]\n"
   echo -e "	-a-tvm  TVM IDs, sort by channelname in alphabetical order" 
   echo -e "	-i-tvm  TVM IDs, sort by ID in numeric order"
   echo -e "	-a-edc  epgdata.com IDs, sort by channelname in alphabetical order" 
   echo -e "	-i-edc  epgdata.com IDs, sort by ID in numeric order"
   echo -e "	-pin    Show Pin for epgdata.com\n" 
   ;;

esac
