#!/bin/sh
#
# Copyright 2009 - 2013 Sundtek Ltd. <kontakt@sundtek.de>
#
# For use with Sundtek Devices only
#

export _LANG="EN DE"
_SIZE=49454
tmp=tmp
dialogbin=`which dialog >/dev/null 2>&1`
sttybin=`which stty >/dev/null 2>&1`
usedialog=0
softshutdown=0
NETINSTALL=1
KEEPALIVE=0
# using blacklist for opensource driver is recommended since the opensource
# driver is not stable and failed even our basic tests with a full system
# lockup
useblacklist=0

if [ -x $dialogbin ] && [ -x $sttybin ] && [ "$sttybin" != "" ] && [ "$dialogbin" != "" ]; then
  usedialog=1
  BACKTITLE="Welcome to the Sundtek Driver Installer"
  WIDTH=`stty -a | grep columns | awk 'BEGIN{FS=";"}{print $3}' | awk '{print $2}'`
  HEIGHT=`stty -a | grep rows | awk 'BEGIN{FS=";"}{print $2}' | awk '{print $2}'`
fi

busyboxfound=`ls -l /bin/ls 2>&1 | grep busybox -c`

if [ "$NETINSTALL" = "1" ]; then
	if [ -e /usr/bin/wget ]; then
		WGET="wget"
	else
	   wget > /dev/null 2>&1
	   rv=$?
	   if [ "$rv" = "0" ] || [ "$rv" = "1" ]; then
		WGET="wget"
   	   else
		curl > /dev/null 2>&1
		rv=$?
		if [ "$rv" = "0" ] || [ "$rv" = "1" ] || [ "$rv" = "2" ]; then
		    WGET="curl -s -O"	
		else
	            echo "This installer requires 'curl' or 'wget' please install one of both"
		    exit 1
		fi
	   fi
	fi
fi

if [ "$busyboxfound" = "1" ] && [ "$usedialog" = "0" ]; then
	echo "Busybox installation"
fi

showdialog() {
	dialog --backtitle "$BACKTITLE" --title "Information" --msgbox "This installer will set up the latest Linux driver for Sundtek based Products\n * Sundtek MediaTV Pro (DVB-T, DVB-C, AnalogTV, FM Radio, Composite, S-Video)\n * Sundtek MediaTV Digital Home (DVB-C, DVB-T)\n * Sundtek SkyTV Ultimate (DVB-S/S2)\n * Sundtek FM Transmitter/Receiver\n * Sundtek Virtual Analog TV driver (for testing purpose)" $((HEIGHT-6)) $((WIDTH-4))
}


#if [ "$usedialog" = "1" ]; then
#  showdialog
#fi

checkperm() {
	fail=0
	idstr=$(id -u 2> /dev/null)
	if [ "$?" != "0" ]; then
	   if [ "$USER" != "root" ]; then
		   fail=1
	   fi 
	elif [ "$idstr" != "0" ]; then
	   fail=1
	fi
	if [ "$fail" = "1" ]; then
		echo "In order to install this driver please run it as root"
		echo "eg. $ sudo $0"
                echo "If you are sure that you already have root/admin permissions"
                echo "you can also try $0 -admin"
		exit 0;
	fi
}

print_help() {
echo ""
echo "Sundtek linux driver setup"
echo "(C)opyright 2008-2013 Sundtek <kontakt@sundtek.de>"
echo ""
echo "Please note it's only allowed to use this driver package with devices from"
echo "authorized distributors or from Sundtek Germany"
echo "The Virtual analogTV Grabber (vivi) might be used freely for testing purpose"
echo ""
echo "-h ... print help"
echo "-u ... uninstall driver"
echo "-e ... extract driver"
echo "-easyvdr ... install without asking"
echo "-service ... only install driver, without preload modification"
echo "-nolirc ... do not install lirc scripts"
echo "-netinst ... download driver packages from sundtek.de"
echo "-system ... override system parameter"
echo "     possible system parameters"
echo "      armsysv        ... ARM SYSV4"
echo "      armoabi        ... ARM OABI"
echo "      32bit          ... x86 32bit (newer libc)"
echo "      32bit23        ... x86 32bit (older libc)"
echo "      64bit          ... x86 64bit"
echo "      android        ... android linux"
echo "      mips           ... MIPS MIPS-I (big endian)"
echo "      openwrtmipsr2  ... MIPS MIPS32 (big endian)"
echo "      mipsel         ... MIPS MIPS32 (little endian)"
echo "      dreambox       ... MIPS MIPS32 (little endian, includes startscripts)"
echo "      mipsel2        ... MIPS MIPS-I (little endian)"
echo "      ppc32          ... PowerPC 32bit (big endian)"
echo "      ppc64          ... PowerPC 64bit (big endian)"
echo ""
echo "default operation is to install the driver"
echo "if no argument is given"
echo ""
}

remove_driver() {
	echo -n "removing driver"
	rm -rf /$tmp/.sundtek
	rm -rf /$tmp/.sundtek_install
	for i in libmediaclient.so  libmedia.so  medialib.a; do
           rm -rf /opt/lib/$i;
        done
	echo -n "."
	rm -rf /etc/udev/rules.d/80-mediasrv.rules
	rm -rf /etc/udev/rules.d/80-mediasrv-eeti.rules
	rm -rf /etc/udev/rules.d/80-remote-eeti.rules
	rm -rf /lib/udev/rules.d/80-mediasrv.rules
	rm -rf /lib/udev/rules.d/80-mediasrv-eeti.rules
	rm -rf /lib/udev/rules.d/80-remote-eeti.rules
	# this file is not deployed anymore
	if [ -f /etc/init.d/mediasrv ]; then
	  rm -rf /etc/init.d/mediasrv
	  rm -rf /etc/rc2.d/S25mediasrv
	  rm -rf /etc/rc2.d/S45mediasrv
	  rm -rf /etc/rcS.d/S45mediasrv
	  if [ -f /etc/rc.local ]; then
	    sed -i '/.*mediasrv start*$/d' /etc/rc.local
	  fi
	fi
	echo -n "."
	for i in dmx.h frontend.h mediaclient.h mediacmds.h videodev2.h; do
           rm -rf /opt/include/$i;
        done
	echo -n "."
	rm -rf /etc/ld.so.conf.d/optlib.conf
	ldconfig > /dev/null 2>&1
	echo -n "."
        for i in dvb mediaclient mediasrv sundtekremote; do
	   rm -rf /opt/bin/$i;
        done
	echo "."
	rm -rf /opt/doc/README /opt/doc/mediaclient.c /opt/doc/override.c
	rm -rf /lib/udev/rules.d/80-mediasrv-eeti.rules
	rm -rf /opt/bin/audio/libalsa.so
	rm -rf /opt/bin/audio/liboss.so
	rm -rf /opt/bin/audio/libpulse.so
	rm -rf /opt/bin/extension/librtkfm.so
	rm -rf /opt/bin/extension/librtkfmc.so
	rm -rf /opt/bin/extension/sundtek32decoder
	rm -rf /opt/bin/plugins/libencoder_plugin.so
	rm -rf /opt/doc/libmedia.pc
	rm -rf /opt/doc/sundtek_vcr_remote.conf
	rm -rf /opt/include/mcsimple.h
	rm -rf /opt/lib/libmcsimple.so
	echo "driver removed..."
	echo ""
	echo "ENGLISH:"
	echo "You might contact Sundtek about your distribution, to receive a custom driver version"
	echo "In case you do not have sufficient space in /$tmp for the driver installation please"
	echo "use our netinstaller, the netinstaller only requires around 5mb temporary space"
	echo "while the full installer which contains drivers for all architectures requires around"
	echo "50mb free temporary space"
	echo "http://sundtek.de/media/sundtek_netinst.sh"
	echo ""
	echo "DEUTSCH:"
	echo "Um einen angepassten Treiber zu erhalten kontaktieren Sie bitte Sundtek"
	echo "Sollten Sie nicht ausreichend Speicher in /$tmp zur Verfügung haben, verwenden Sie"
	echo "bitte unseren Netinstaller, dieser laedt lediglich benoetigte Dateien nach"
	echo "Der sundtek_installer_development beinhaltet Treiber fuer alle Architekturen und"
	echo "benoetigt ca. 50 MB freien Speicher in /$tmp"
	echo "http://sundtek.de/media/sundtek_netinst.sh"
	echo ""
	echo "                                         Sundtek Team"
	echo "                                         kontakt@sundtek.de"
}

uninstall_driver() {
	echo ""
	echo "Sundtek linux driver setup"
	echo ""

	if [ "$busyboxfound" = "1" ]; then
	   pid=`ps | grep mediasrv | grep grep -v | while read a b; do echo $a; done`
	else
	   pid=`ps fax | grep mediasrv | grep grep -v | while read a b; do echo $a; done`
	fi

	if [ "$softshutdown" = "1" ]; then
		if [ -e /opt/bin/mediaclient ]; then
                	/opt/bin/mediaclient --shutdown
                fi
        elif [ "$pid" != "" ]; then
		echo "stopping sundtek driver stack..."
		kill $pid > /dev/null 2>&1;
		killall -q -9 sundtekremote >/dev/null 2>&1
	fi
	echo "removing driver "
	sed -i 's#/opt/lib/libmediaclient.so ##' /etc/ld.so.preload
	echo -n "."
	if [ -f /etc/redhat-release ]; then
	   if [ -f /usr/sbin/semanage ]; then
	      if [ "`/usr/sbin/semanage fcontext  -l 2>/dev/null | grep libmediaclient -c`" = "1" ]; then
                 /usr/sbin/semanage fcontext -d -t lib_t /opt/lib/libmediaclient.so >/dev/null 2>&1
	      fi
           fi
        fi
	for i in libmediaclient.so  libmedia.so  medialib.a; do
           rm -rf /opt/lib/$i;
        done
	echo -n "."
	rm -rf /etc/udev/rules.d/80-mediasrv.rules
	rm -rf /etc/udev/rules.d/80-mediasrv-eeti.rules
	rm -rf /etc/udev/rules.d/80-remote-eeti.rules
	if [ -f /etc/init.d/mediasrv ]; then
	  rm -rf /etc/init.d/mediasrv
	  rm -rf /etc/rc2.d/S25mediasrv
	  rm -rf /etc/rc2.d/S45mediasrv
	  rm -rf /etc/rcS.d/S45mediasrv
	  if [ -f /etc/rc.local ]; then
	    sed -i '/.*mediasrv start*$/d' /etc/rc.local
	  fi
        fi
	echo -n "."
	for i in dmx.h frontend.h mediaclient.h mediacmds.h videodev2.h; do
           rm -rf /opt/include/$i;
        done
	echo -n "."
	rm -rf /etc/ld.so.conf.d/optlib.conf
	ldconfig > /dev/null 2>&1
	echo -n "."
        for i in dvb mediaclient mediasrv; do
	   rm -rf /opt/bin/$i;
        done
	echo -n "."
	rm -rf /opt/doc/README /opt/doc/mediaclient.c /opt/doc/override.c
	rm -rf /opt/doc/hardware.conf /opt/doc/lirc_install.sh /opt/doc/lircd.conf /opt/doc/sundtek.conf /opt/doc/sundtek_vdr.conf /opt/bin/getinput.sh /opt/bin/lirc.sh /opt/bin/mediarecord /opt/lib/pm/10mediasrv /etc/hal/fdi/preprobe/sundtek.fdi /usr/lib/pm-utils/sleep.d/10mediasrv
	rm -rf /lib/udev/rules.d/80-mediasrv-eeti.rules
	rm -rf /opt/bin/audio/libalsa.so
	rm -rf /opt/bin/audio/liboss.so
	rm -rf /opt/bin/audio/libpulse.so
	rm -rf /opt/bin/extension/librtkfm.so
	rm -rf /opt/bin/extension/librtkfmc.so
	rm -rf /opt/bin/extension/sundtek32decoder
	rm -rf /opt/bin/plugins/libencoder_plugin.so
	rm -rf /opt/doc/libmedia.pc
	rm -rf /opt/doc/sundtek_vcr_remote.conf
	rm -rf /opt/include/mcsimple.h
	rm -rf /opt/lib/libmcsimple.so
	rm -rf /usr/lib/systemd/system/sundtek.service
	echo -n "."
	echo ""
	echo "driver successfully removed from system"
	echo ""
}

extract_driver() {
	echo "Extracting driver ..."
	app=$0
        dd if=${app} of=installer.tar.gz skip=1 bs=${_SIZE} 2> /dev/null

        if [ ! -f installer.tar.gz ]; then
           sed '1,1370d' ${app} > /tmp/.sundtek/installer.tar.gz
        fi

	if [ "$busyboxfound" = "1" ]; then
		tar xzf installer.tar.gz 2>/dev/null 1>/dev/null
		if [ "$?" = "1" ]; then
			gzip -d installer.tar.gz
			if [ "$?" != "0" ]; then
				echo "Extracting driver failed..."
				exit 1
			fi
			tar xf installer.tar
			if [ "$?" != "0" ]; then
				echo "Extracting driver failed..."
				exit 1
			fi
		fi
	else
		tar xzmf installer.tar.gz 2>/dev/null 1>/dev/null
		if [ "$?" != "0" ]; then
			echo "Extracting driver failed..."
			exit 1
		fi
	fi
	echo "done."
}

install_driver() {
	echo ""
	echo "Welcome to the Sundtek linux driver setup"
	echo "(C)opyright 2008-2013 Sundtek <kontakt@sundtek.de>"
	echo ""
	for lang in $_LANG; do
	  if [ "$lang" = "EN" ]; then
	    echo "Legal notice:"
	    echo "This software comes without any warranty, use it at your own risk"
	    echo ""
	    echo "Please note it's only allowed to use this driver package with devices from"
	    echo "authorized distributors or from Sundtek Germany"
	    echo "The Virtual analogTV Grabber (vivi) might be used freely for testing purpose"
	    echo ""
	    echo "Do you want to continue [Y/N]:"
  	  elif [ "$lang" = "DE" ]; then
	    echo "Nutzungsbedingungen:"
	    echo "Sundtek übernimmt keinerlei Haftung für Schäden welche eventuell durch"
	    echo "das System oder die angebotenen Dateien entstehen können."
	    echo ""
	    echo "Dieses Softwarepaket darf ausschließlich mit Geraeten von authorisierten"
	    echo "Distributoren oder Sundtek Deutschland verwendet werden"
	    echo "Der Virtuelle AnalogTV Treiber (vivi) kann für Testzwecke ohne jegliche"
	    echo "Restriktionen verwendet werden"
	    echo ""
  	    echo "Wollen Sie fortfahren [J/N]:"
	  fi
	done
        if [ "$AUTO_INST" = "1" ]; then
		echo "AUTO_INST is set"
		key="Y";
	else   
		read key
	fi
	if [ "$key" != "Y" ] && [ "$key" != "J" ] && [ "$key" != "j" ] && [ "$key" != "y" ]; then
	  for lang in $_LANG; do
	    if [ "$lang" = "EN" ]; then
		echo "Installation aborted..."
  	    elif [ "$lang" = "DE" ]; then
		echo "Installation abgebrochen..."
	    fi
  	    exit
	  done
	fi

	if [ -f /etc/environment ]; then
	  if [ "`grep -c /opt/bin /etc/environment`" = "0" ]; then
		echo "adding /opt/bin to environment paths"
		sed -i 's#\(PATH.*\)\"$#\1:/opt/bin\"#g' /etc/environment > /dev/null 2>&1
	  fi
	fi
	
	if [ -f /etc/ld.so.preload ]; then
	  sed -i 's#/opt/lib/libmediaclient.so ##g' /etc/ld.so.preload
	  sed -i 's#/opt/lib/libmediaclient.so##g' /etc/ld.so.preload
	  rm -rf /opt/lib/libmediaclient.so
        fi

	if [ -f /etc/group ]; then
	  if [ "`grep -c ^audio:x /etc/group`" = "1" ]; then
             if [ "`grep  ^audio:x /etc/group | grep root -c`" = "0" ]; then
		echo "adding administrator to audio group for playback..."
		sed -i 's#\(^audio:x\:[0-9]*\:\)#\1root,#g' /etc/group
	     fi; 
	  fi;
        fi;

	app=$0
	if [ "$KEEPALIVE" = "0" ]; then
	  if [ "$busyboxfound" = "1" ]; then
	     pid=`ps | grep mediasrv | grep grep -v | while read a b; do echo $a; done`
          else
	     pid=`ps fax | grep mediasrv | grep grep -v | while read a b; do echo $a; done`
          fi
 
	  if [ "$softshutdown" = "1" ]; then
		if [ -e /opt/bin/mediaclient ]; then
                	/opt/bin/mediaclient --shutdown
                fi
	  elif [ "$pid" != "" ]; then
		echo "stopping old driver instance..."
		kill $pid > /dev/null 2>&1;
		killall -q -9 sundtekremote >/dev/null  2>&1
	  fi
        else
          echo "not stopping driver"
        fi
	echo "unpacking..."

	# in order to satisfy linux magazine writers who need a few more lessions in secure bash
	# scripting, by far there have been other more important parts than an already existing
        # /$tmp/chk64/etc binary.
  

	if [ -d /$tmp/.sundtek ]; then
		rm -rf /$tmp/.sundtek
		if [ -e /$tmp/.sundtek ]; then
			echo "please remove /$tmp/.sundtek manually and retry the installation"
			exit 1;
		fi
	fi
 
	mkdir -p /$tmp/.sundtek

	dd if=${app} of=/$tmp/.sundtek/installer.tar.gz skip=1 bs=${_SIZE} 2> /dev/null
        if [ ! -f /$tmp/.sundtek/installer.tar.gz ]; then
           echo "extracting..."
           sed '1,1346d' ${app} > /$tmp/.sundtek/installer.tar.gz
        fi

	cd /$tmp/.sundtek
	if [ "$busyboxfound" = "1" ]; then
		tar xzf installer.tar.gz 2>/dev/null 1>/dev/null
		if [ "$?" = "1" ]; then
			gzip -d installer.tar.gz
			tar xf installer.tar
		fi
	else
		tar xzmf installer.tar.gz 2>/dev/null 1>/dev/null
	fi
	
	echo -n "checking system... "
	unamer=`uname -r`
        dm500hd=`echo $unamer | grep -c 'dm500hd$'`
        dm800=`echo $unamer | grep -c 'dm800$'`
        dm800se=`echo $unamer | grep -c 'dm800se$'`
	dm7020=`echo $unamer | grep -c 'dm7020hd$'`
        dm8000=`echo $unamer | grep -c 'dm8000$'`
	vusolo1=`uname -a | grep "vusolo 2.6.18-7.3 " -c`
	vusolo2=`grep Brcm4380 /proc/cpuinfo -c`
	azbox=0
	if [ -e /proc/stb/info/azmodel ]; then
		azbox=1
	fi
	tardereference=`tar --help 2>&1 | grep dereference -c`
	tvh64=0
	if [ "$tardereference" != "0" ]; then
		tarflag=" -h"
	else
		tarflag=""
	fi
	if [ "$vusolo1" = "1" ] && [ "$vusolo2" = "1" ]; then
	   vusolo=1
        else
           vusolo=0
        fi
	if [ -e /proc/stb/info/vumodel ]; then
           vusolo3=`cat /proc/stb/info/vumodel`;
	   if [ "$vusolo3" = "solo" ]; then
              vusolo=1
           fi
        fi
	if [ -e /proc/stb/info/boxtype ]; then
	   gigablue=`grep -c gigablue /proc/stb/info/boxtype`;
	else
	   gigablue=0
	fi


        ctversion=0
	if [ -e /proc/stb/info/version ]; then
		ctversion=`cat /proc/stb/info/version`;
        fi

        ctet9000=0

	if [ -e /proc/stb/lcd/scroll_delay ] && [ "$ctversion" = "2" ] && [ "`grep -c BCM97xxx /proc/cpuinfo`" = "1" ]; then
		ctet9000=1
	fi

	if [ -e /proc/stb/info/boxtype ] && [ "`grep -c et9000 /proc/stb/info/boxtype`" = "1" ]; then
		ctet9000=1
	fi
	ctet5000=0

	if [ -e /proc/stb/info/boxtype ] && [ "`grep -c et5000 /proc/stb/info/boxtype`" = "1" ]; then
        	ctet5000=1;
        fi
	
	ctet6000=0

	if [ -e /proc/stb/info/boxtype ] && [ "`grep -c et6000 /proc/stb/info/boxtype`" = "1" ]; then
        	ctet6000=1;
        fi

	ctet4x00=0
	if [ -e /proc/stb/info/boxtype ] && [ "`grep -c et4000 /proc/stb/info/boxtype`" = "1" ]; then
        	ctet4x00=1;
        fi
	         
        # should more be like openwrt installer on wndr3700
	wndr3700=`grep -c 'NETGEAR WNDR3700$' /proc/cpuinfo`
	tplink=`grep -c 'Atheros AR9132 rev 2' /proc/cpuinfo`
        ddwrt=`grep -c dd-wrt /proc/version`
        atheros=`grep -c "Atheros AR7161 rev 2" /proc/cpuinfo`
        dockstar=`grep -c "ARM926EJ-S" /proc/cpuinfo`
	synology=`grep -c "Synology" /proc/cpuinfo`
	if [ "$synology" = "0" ]; then
 	  synology=`uname -a | grep -i synology -c`
        fi
	if [ -e /etc/synoinfo.conf ]; then
	  synology=1
	fi
	sedver=`sed --version | grep "GNU sed version" -c 2>/dev/null >/dev/null`
	driverinstalled=`grep -c mediaclient /etc/rc.local 2>/dev/null >/dev/null`
	if [ "`grep -c 'VIA Samuel 2' /proc/cpuinfo`" = "1" ] && [ "`grep -c 'CentaurHauls' /proc/cpuinfo`" = "1" ]; then
		c3="1"
	else
		c3="0"
	fi
	   
        if [ "$dockstar" != "0" ]; then
	    if [ -e /usr/local/cloudengines/hbplug.conf ]; then
               touch /dev/.testfile >/dev/null 2>&1
               if [ ! -e /dev/.testfile ]; then
                    dockstar=1; # remains 1
               else
                    dockstar=0;
               fi
            else
               dockstar=0;
            fi
        fi
	if [ "$ddwrt" = "1" ] && [ "$atheros" = "1" ]; then
		ddwrtwndr3700=1;
        else
                ddwrtwndr3700=0;
        fi
	arm=`file /bin/ls 2>/dev/null | grep -c 'ARM'`

	# Dreambox dm800(0)
        # http://www.i-have-a-dreambox.com/wbb2/thread.php?threadid=135273
        #
	if [ "$SYSTEM" != "" ]; then
	        echo "overriding SYSTEM parameter with $SYSTEM"
	elif [ "$gigablue" = "1" ]; then
		echo "Gigablue detected"
		SYSTEM="mipsel2"
	elif [ "$azbox" = "1" ]; then
		echo "Azbox detected"
		SYSTEM="mipsel2"
	elif [ "$vusolo" = "1" ]; then
		echo "VU+ Solo detected"
		SYSTEM="mipsel2"
        elif [ "$ctet9000" = "1" ]; then
                echo "Clarke Tech ET9000 detected"
		SYSTEM="mipsel2"
	elif [ "$ctet4x00" = "1" ]; then
		echo "Clarke Tech ET4000 detected"
		SYSTEM="mipsel2"
	elif [ "$ctet5000" = "1" ]; then
		SYSTEM="mipsel2"
		echo "Clarke Tech ET5000 detected"
	elif [ "$ctet6000" = "1" ]; then
		SYSTEM="mipsel2"
		echo "Clarke Tech ET6000 detected"
        elif [ "$dm7020" = "1" ]; then
                echo "Dreambox 7020HD detected"
		SYSTEM="dreambox"
	elif [ "$dm8000" = "1" ]; then
		echo "Dreambox 8000 detected"
		kver=`uname -r`
		if [ "`echo $kver | grep -c 'dm'`" = "1" ]; then
		    echo "Kernel is supported"
                    SYSTEM="dreambox"
		else
		    echo "This is an unsupported dreambox version, please send an email to kontakt@sundtek.de"
		    echo "pointing out that your system kernel uses $kver"
		    remove_driver
		    exit 1;
		fi
        elif [ "$dockstar" = "1" ]; then
                echo "Dockstar like system detected"
		SYSTEM="armsysv"
	elif [ "$dm800" = "1" ] || [ "$dm800se" = "1" ] || [ "$dm7020" = "1" ]; then
		echo "Dreambox 800/800se detected"
		kver=`uname -r`
		if [ -e /usr/sundtek/usbkhelper-dm800.ko ]; then
			rm -rf /usr/sundtek/usbkhelper*;
		fi
		if [ -e /etc/image-version ] && [ "`grep -c 'version=1openpli' /etc/image-version`" = "1" ]; then
                    SYSTEM="mipsel2"
		elif [ "`echo $kver | grep -c 'dm'`" = "1" ]; then
		    echo "Kernel is supported"
                    SYSTEM="dreambox"
		else
		    echo "This is an unsupported dreambox version, please send an email to kontakt@sundtek.de"
		    echo "pointing out that your system kernel uses $kver"
		    remove_driver
		    exit 1;
		fi
        elif [ "$dm500hd" = "1" ]; then
                echo "Dreambox 500hd detected"
		#delete old modules
		if [ -e /usr/sundtek/usbkhelper-dm800.ko ]; then
			rm -rf /usr/sundtek/usbkhelper*;
		fi
                SYSTEM="dreambox"
        elif [ "$wndr3700" = "1" ]; then
		echo "Netgear WNDR3700 detected"
		SYSTEM="openwrtmipsr2"
		if [ -e /bin/opkg ] && [ "`opkg list libpthread | wc -l`" = "0" ]; then
			echo "running opkg update"
			opkg update
			echo "installing libpthread"
			opkg install libpthread
			opkg install librt
		fi	
        elif [ "$ddwrtwndr3700" = "1" ]; then
                echo "Netgear WNDR3700 (DD-WRT) detected"
                SYSTEM="openwrtmipsr2"
	elif [ "$c3" = "1" ]; then
		echo "Via C3 detected"
		SYSTEM="c3"
	else
           CHK64=-1
	   if [ "$arm" = "0" ]; then
	     /$tmp/.sundtek/chk64bit 1>/dev/null 2>&1
             CHK64=$?
#	     echo "CHECKED 64bit: $CHK64"
             if [ "$CHK64" = "0" ]; then
		if [ "$synology" = "1" ] && [ -e /usr/local/tvheadend/bin/tvheadend ]; then
			/$tmp/.sundtek/chk32bit23 -a
			if [ "$?" = "0" ]; then
				/$tmp/.sundtek/chk32bit23 -elfhdr /bin/ls
				basesys=$?
				/$tmp/.sundtek/chk32bit23 -elfhdr /usr/local/tvheadend/bin/tvheadend
				if [ "$?" = "1" ] && [ "$basesys" = "0" ]; then
					echo ""
					echo "Your base system is 32bit (busybox), but you installed 64bit tvheadend"
					echo ""
					tvh64=1
				fi
			fi
		fi
		/$tmp/.sundtek/chk64bit -b 1>/dev/null 2>&1
                if [ "$?" = "1" ] && [ "$tvh64" = "0" ]; then
                    CHK64=-1
                else
                    CHK64=0
                fi
             fi
	   fi
	   if [ "$CHK64" = "0" ] && [ "$arm" = "0" ]; then
		   if [ "$tvh64" = "0" ]; then
	           	/$tmp/.sundtek/chk64bit -a
  	  	   	if [ "$?" != "0" ]; then
				remove_driver
				exit 1;
		   	fi
	   	   fi
	 	   echo "64Bit System detected"
		   SYSTEM="64bit"
	   else
             if [ "$arm" = "0" ]; then
	       /$tmp/.sundtek/chk32bit 1>/dev/null 2>&1
	     fi
	     if [ "$?" = "0" ] && [ "$arm" = "0" ]; then
	        /$tmp/.sundtek/chk32bit -a
		if [ "$?" != "0" ]; then
			/$tmp/.sundtek/chk32bit23 1>/dev/null 
			if [ "$?" = "0" ]; then
                           echo -n "checking older libc version... "
                           /$tmp/.sundtek/chk32bit23 -a
                           if [ "$?" != "0" ]; then
			       remove_driver
			       exit 1;
			   else
			       echo "32Bit System detected (libc2.3)"
                               SYSTEM="32bit23"
                           fi
                        else
			   remove_driver
			   exit 1;
                        fi
	        else
	 	        echo "32Bit System detected"
		        SYSTEM="32bit"
		fi
	     else
		if [ "$arm" = "0" ]; then
		    /$tmp/.sundtek/chkppc32 1>/dev/null 2>&1
		fi
		if [ "$?" = "0" ] && [ "$arm" = "0" ]; then
		    /$tmp/.sundtek/chkppc32 -a
		    if [ "$?" != "0" ]; then
			remove_driver
			exit 1;
		    fi
		    echo "PPC32 System detected"
                    SYSTEM="ppc32"
                else
                  if [ -e /lib/ld-linux-armhf.so.3 ]; then
	            if [ ! -e /lib/ld-linux.so.3 ]; then
		        ln -s /lib/ld-linux-armhf.so.3 /lib/ld-linux.so.3
	            fi
                    /$tmp/.sundtek/chkarmsysvhf 1>/dev/null 2>&1
                    if [ "$?" = "0" ]; then
                        remove_driver
                        exit 1;
                    fi
                    echo "ARM SYSV HF System detected"
                    SYSTEM="armsysvhf"
		  else
                    /$tmp/.sundtek/chkarmsysv 1>/dev/null 2>&1
                    if [ "$?" = "0" ]; then
		       if [ ! -e /etc/WiAutoConfig.conf ]; then
                         
                          /$tmp/.sundtek/chkarmsysv -a
		       fi
		       if [ "$?" != "0" ]; then
			  remove_driver
			  exit 1;
		       fi
		       if [ "$synology" = "1" ]; then
		          echo "Synology NAS Detected"
		       else
                          echo "ARM SYSV System detected"
		       fi
                       SYSTEM="armsysv"
                    else
		       /$tmp/.sundtek/chkarmoabi 1>/dev/null 2>&1
		       if [ "$?" = "0" ]; then
		          /$tmp/.sundtek/chkarmoabi -a
		          if [ "$?" != "0" ]; then
			     remove_driver
			     exit 1;
		          fi
                          echo "ARM OABI System detected"
                          SYSTEM="armoabi"
                       else
		          /$tmp/.sundtek/chkmips 1>/dev/null 2>&1
			  if [ "$?" = "0" ]; then
		              /$tmp/.sundtek/chkmips -a
		              if [ "$?" != "0" ]; then
			        remove_driver
			        exit 1;
		              fi
			      echo "MIPS System detected"
                              SYSTEM="mips"
                          else
			     /$tmp/.sundtek/chkmipsel 1>/dev/null 2>&1
			     if [ "$?" = "0" ]; then
                                /$tmp/.sundtek/chkmipsel -a
                                if [ "$?" != "0" ]; then
                                    remove_driver
                                    exit 1;
                                fi
                                echo "MIPSel (little endian) detected"
                                SYSTEM="mipsel"
				if [ `grep -c Brcm /proc/cpuinfo` -gt 0 ]; then
					SYSTEM="mipsel2"
				fi
                             else
		                /$tmp/.sundtek/chkppc64 1>/dev/null 2>&1
 			        if [ "$?" = "0" ]; then
		                   /$tmp/.sundtek/chkppc64 -a
		                   if [ "$?" != "0" ]; then
	 	 	               remove_driver
			               exit 1;
		                   fi
		                   echo "PPC64 System detected"
                                   SYSTEM="ppc64"
                                else
                                   /$tmp/.sundtek/chkmipsel2 1>/dev/null 2>&1
                                   if [ "$?" = "0" ]; then
                                      /$tmp/.sundtek/chkmipsel2 -a
                                      if [ "$?" != "0" ]; then
                                         remove_driver
                                         exit 1;
                                      fi
                                      echo "MIPSel (old libc) System detected"
				      SYSTEM="mipsel2"
                                   else
                                      /$tmp/.sundtek/chkopenwrtmipsr2 0.9.33 1>/dev/null 2>&1
                                      if [ "$?" = "0" ]; then
                                         /$tmp/.sundtek/chkopenwrtmipsr2 -a
                                         if [ "$?" != "0" ]; then
					     remove_driver
					     exit 1;
					 fi
					 if [ -e /var/flash/ar7.cfg ]; then
                                             echo "Fritzbox detected"
                                         else
					     echo "OpenWRT MipsR3 (0.9.33) detected"
                                         fi
					 SYSTEM="openwrtmipsr3"
					 if [ -e /bin/opkg ]; then
		                           if [ "`opkg list librt | wc -l`" = "0" ] || [ "`opkg list libpthread | wc -l`" = "0" ]; then
					     echo "running opkg update"
					     opkg update
				           fi
		                           if [ "`opkg list libpthread | wc -l`" = "0" ]; then
					     echo "installing libpthread"
					     opkg install libpthread
					   fi	
		                           if [ "`opkg list librt | wc -l`" = "0" ]; then
					     echo "installing librt"
					     opkg install librt
					   fi	
				         fi
				      else
					 /$tmp/.sundtek/chkopenwrtmipsr2 1>/dev/null 2>&1
                                         if [ "$?" = "0" ]; then
                                           /$tmp/.sundtek/chkopenwrtmipsr2 -a
                                           if [ "$?" != "0" ]; then
					     remove_driver
					     exit 1;
				  	   fi
					   if [ -e /var/flash/ar7.cfg ]; then
                                             echo "Fritzbox detected"
                                           else
					     echo "OpenWRT MipsR2 detected"
                                           fi
					   SYSTEM="openwrtmipsr3"
					   if [ -e /bin/opkg ]; then
		                             if [ "`opkg list librt | wc -l`" = "0" ] || [ "`opkg list libpthread | wc -l`" = "0" ]; then
					       echo "running opkg update"
					       opkg update
				             fi
		                             if [ "`opkg list libpthread | wc -l`" = "0" ]; then
					       echo "installing libpthread"
					       opkg install libpthread
					     fi	
		                             if [ "`opkg list librt | wc -l`" = "0" ]; then
					       echo "installing librt"
					       opkg install librt
					     fi	
				           fi
					 else
					   /$tmp/.sundtek/chkmipselbcm 1>/dev/null 2>&1
					   if [ "$?" = "0" ]; then
                                              /$tmp/.sundtek/chkmipselbcm -a
                                              if [ "$?" != "0" ]; then
                                                remove_driver
                                                exit 1;
                                              fi
                                              echo  "MIPS BCM detected"
                                              SYSTEM="mipselbcm"
                                           else
				            /$tmp/.sundtek/chksh4 1>/dev/null 2>&1
					    if [ "$?" = "0" ]; then
						/$tmp/.sundtek/chksh4 -a
						if [ "$?" != "0" ]; then
						    remove_driver
						    exit 1;
						fi
						echo "SH4 detected"
						SYSTEM="sh4"
					    else
						/$tmp/.sundtek/chkopenwrtarm4 1>/dev/null 2>&1
						if [ "$?" = "0" ]; then
						   /$tmp/.sundtek/chkopenwrtarm4 -a
						   if [ "$?" != "0" ]; then
						        remove_driver
							exit 1;
						   fi
						   echo "ARM4 SYSV uClibc detected"
						   SYSTEM="openwrtarm4"
						else
		                                   echo "Your system is currently unsupported"
						   echo ""
						   echo "also check that this installer is not corrupted due a bad download"
						   echo "/$tmp must not be mounted with noexec flag, otherwise the installer"
						   echo "won't work"
						   echo ""
						   echo "In case you do not have enough free space on your system you might"
						   echo "use the network installer"
						   echo "http://sundtek.de/media/sundtek_netinst.sh"
						   echo ""
		                                   echo "in case your system is really unsupported please contact"
						   echo "our support via mail <kontakt@sundtek.de>"
		                                   echo ""
			                           remove_driver
		                                   exit 0
					        fi
				              fi
					    fi
                                         fi
                                      fi
                                   fi
                                fi
                             fi
                          fi
                       fi
                     fi
		  fi
                fi
             fi
	  fi
	fi
	if [ "$NETINSTALL" = "1" ]; then
	   echo "installing (netinstall mode) ..."
	   if [ "$SYSTEM" = "" ]; then
		   echo "unable to detect architecture.."
		   echo "please contact us via email kontakt@sundtek.de"
		   # report a failed installation.. this should never happen 
		   # if it happens report it back. 
		   $WGET http://sundtek.de/support/failed.phtml
		   exit 1
	   fi
		   
	   mkdir /$tmp/.sundtek/$SYSTEM
	   cd /$tmp/.sundtek/$SYSTEM
	   echo "Downloading architecture specific driver ... $SYSTEM"
	   $WGET http://www.sundtek.de/media/netinst/$SYSTEM/installer.tar.gz > /dev/null 2>&1
	   echo "Download finished, installing now ..."
	   if [ "$?" != "0" ]; then
		echo "unable to download $SYSTEM drivers"
		exit 1
	   fi
	else
	   echo "installing (local mode) ..."
	fi
	mkdir -p /opt/bin >/dev/null 2>&1
	if [ -d /opt/bin ]; then
		USE_TMP=0
		mkdir -p /opt/include > /dev/null 2>&1
		if [ -d /opt/include ]; then
			USE_TMP=0
		else
			echo "Trying to use /$tmp/opt/bin for driver installation"
			echo "please note this installation will only be temporary"
			echo "since we don't have write access to /opt/bin"
			USE_TMP=1
		fi
	else
		echo "Trying to use /$tmp/opt/bin for driver installation"
		echo "please note this installation will only be temporary"
		echo "since we don't have write access to /opt/bin"
		USE_TMP=1
	fi
	if [ "$vusolo" = "1" ] || [ "$ctet9000" = "1" ] || [ "$ctet5000" = "1" ] || [ "$ctet6000" = "1" ] || [ "$ctet4x00" = "1" ]; then
          cd /
          tar xzf /$tmp/.sundtek/mipsel2/installer.tar.gz
        elif [ "$dm8000" = "1" ] || [ "$dm800" = "1" ] || [ "$dm500hd" = "1" ] || [ "$dm800se" = "1" ] || [ "$dm7020" = "1" ] || [ `grep -c Brcm /proc/cpuinfo` -gt 0 ]; then
	  echo "Using /dev/misc/vtuner0 interface"
	  if [ ! -e /usr/sundtek/mediasrv ] && [ `df -P | grep root | awk '{print $4}'` -lt 5000 ]; then
	     if [ `df -P | grep '/usr$' -c` -eq 1 ] && [ `df -P | grep '/usr$' | awk '{print $4}'` -gt 5000 ]; then
	       echo "root / doesn't seem to have enough space,"
	       echo "although /usr has .. OK"
             else
	       echo "Not enough free space"
	       if [ `df -P | grep /media/hdd -c` -gt 0 ] && [ `df -P | grep /media/hdd | awk '{print $4}'` -gt 5000 ]; then
	 	 echo "using /media/hdd for driver installation"
		 if [ ! -e /usr/sundtek ]; then
		     mkdir /usr/sundtek
	         fi
		 if [ "`mount | grep sundtek -c`" = "0" ]; then
		   echo "mounting driver loopback"
		   mkdir -p /media/hdd/sundtek
		   mount -obind /media/hdd/sundtek /usr/sundtek
		 fi
	       else
		 echo "not enough space available for driver installation, you might contact kontakt@sundtek.de"
	       fi
	     fi
	  else
	      echo "Default installation"
	  fi
	  cd /
	  tar ${tarflag}xzf /$tmp/.sundtek/$SYSTEM/installer.tar.gz
	elif [ $USE_TMP -eq 1 ]; then
          cd /$tmp
	  tar xzf /$tmp/.sundtek/$SYSTEM/installer.tar.gz >/dev/null 2>&1
	  if [ "$?" = "1" ]; then
	     cd /$tmp/.sundtek/$SYSTEM/
	     gzip -d installer.tar.gz
	     cd /$tmp
	     tar ${tarflag}xf /$tmp/.sundtek/$SYSTEM/installer.tar
	  fi
        else
	  cd /
	  if [ "$busyboxfound" = "1" ]; then
		# can fail on some systems 
		tar ${tarflag}xzf /$tmp/.sundtek/$SYSTEM/installer.tar.gz >/dev/null 2>&1
		if [ "$?" = "1" ]; then
			cd /$tmp/.sundtek/$SYSTEM/
			gzip -d installer.tar.gz
			cd /
			tar ${tarflag}xf /$tmp/.sundtek/$SYSTEM/installer.tar
		fi
	  else
		tar ${tarflag}xzmf /$tmp/.sundtek/$SYSTEM/installer.tar.gz
	  fi 
	  if [ -f /sbin/udevadm ]; then
	     if [ `/sbin/udevadm version` -lt 086 ]; then
		rm -rf /etc/udev/rules.d/80-mediasrv-eeti.rules
	     else
		rm -rf /etc/udev/rules.d/80-mediasrv.rules
  	     fi
	  else
	    if [ -f /usr/bin/udevinfo ]; then
#        since --v is not supported with older versions...
	      if [ `/usr/bin/udevinfo -V | sed 's#[^0-9]##g'` -lt 086 ]; then
 		 rm -rf /etc/udev/rules.d/80-mediasrv-eeti.rules
	      else
		 rm -rf /etc/udev/rules.d/80-mediasrv.rules
  	      fi
	    else
#       stick with the newer rules which disable UAC audio
	     rm -rf /etc/udev/rules.d/80-mediasrv.rules
	    fi
          fi
	  if [ -d /usr/lib/pkgconfig ]; then
                # can fail on read only filesystems
                cp /opt/doc/libmedia.pc /usr/lib/pkgconfig > /dev/null 2>&1
          fi
	  if [ -d /lib/udev/rules.d ]; then
		if [ -f /etc/udev/rules.d/80-mediasrv-eeti.rules ]; then
		   cp /etc/udev/rules.d/80-mediasrv-eeti.rules /lib/udev/rules.d;
		fi
		if [ -f /etc/udev/rules.d/80-mediasrv.rules ]; then
		   cp /etc/udev/rules.d/80-mediasrv.rules /lib/udev/rules.d;
		fi
		if [ -f /etc/udev/rules.d/80-remote-eeti.rules ] && [ "$NOLIRC" = "0" ]; then
		   echo "installing remote control support"
		   cp /etc/udev/rules.d/80-remote-eeti.rules /lib/udev/rules.d;
                else
                   rm -rf /etc/udev/rules.d/80-remote-eeti.rules 
		   rm -rf /lib/udev/rules.d/80-remote-eeti.rules
		fi
	  fi
	  if [ ! -e /opt/bin/mediasrv ]; then
		  rm -rf /$tmp/.sundtek
		  echo "Seems like there's a problem installing the driver to /opt/bin"
		  echo "doing some tests..."
		  echo "mkdir -p /opt/bin"
		  mkdir -p /opt/bin >/dev/null 2>&1 
		  if [ -d /opt/bin ]; then
			  echo "succeeded"
	          else
			  echo "failed!"
		  fi
		  echo "mkdir -p /$tmp/opt/bin"
		  mkdir -p /$tmp/opt/bin > /dev/null 2>&1
		  if [ -d /$tmp/opt/bin ]; then
			  echo "succeeded"
		  else
			  echo "failed!"
		  fi
		  echo "Some more information"
		  echo "uname -a"
		  uname -a
		  echo "vendor_id"
		  cat /proc/cpuinfo | grep "vendor_id"
		  echo "Model Name"
		  cat /proc/cpuinfo  | grep "model name"
		  echo "disk space"
		  df
		  echo "memory"
		  free
		  echo ""
		  echo "please send these information to kontakt at sundtek de"
		  exit 1
          fi
	  chmod gou=sx /opt/bin/mediasrv
	  rm -rf /$tmp/.sundtek
	  echo -n "finalizing configuration... (can take a few seconds)  "
	  if [ -d /usr/lib/pm-utils/sleep.d ]; then
	     cp /opt/lib/pm/10mediasrv /usr/lib/pm-utils/sleep.d/
	  fi
	  if [ -f /etc/redhat-release ]; then
            /usr/bin/chcon -t lib_t /opt/lib/libmediaclient.so >/dev/null 2>&1
	    if [ -f /usr/sbin/semanage ]; then
	       if [ "`/usr/sbin/semanage fcontext  -l 2>/dev/null| grep libmediaclient -c`" = "0" ]; then
                 echo -n "."
                 /usr/sbin/semanage fcontext -a -t lib_t /opt/lib/libmediaclient.so >/dev/null 2>&1
               fi
	    fi
	    if [ -e /usr/bin/systemctl ]; then
		rm -rf /etc/udev/rules.d/80-mediasrv-eeti.rules
		rm -rf /lib/udev/rules.d/80-mediasrv-eeti.rules
	    fi 
          fi
	  echo ""
	# dreambox doesn't need preloading, the driver is directly using /dev/misc/vtuner0
	  if [ "$synology" = "1" ]; then
             echo ""
	     echo ""
	     echo "IMPORTANT: in order to use the device on your Synology NAS"
	     echo "           run \"export LD_PRELOAD=/opt/lib/libmediaclient.so\""
	     echo "           and afterwards start your TV Application"
	     echo ""
	     echo "           you can also place this in the start script of eg."
	     echo "           tvheadend in order to initialize it automatically"
	     echo ""
	     echo ""
	     if [ -e /var/packages/tvheadend/scripts/start-stop-status ]; then
		     echo "adding libmediaclient to tvheadend start script"
		     sed -i 's#^    ${TVHEADEND}#    LD_PRELOAD=/opt/lib/libmediaclient.so ${TVHEADEND}#g' /var/packages/tvheadend/scripts/start-stop-status
		     sed -i 's#su - ${RUNAS} -c "${TVHEADEND}#su - ${RUNAS} -c "LD_PRELOAD=/opt/lib/libmediaclient.so ${TVHEADEND}#g' /var/packages/tvheadend/scripts/start-stop-status
	     fi
	     if [ -e /var/packages/tvheadend ]; then
		     echo "setting up tvheadend autorestart in /etc/sundtek.conf"
		     echo "device_attach=/var/packages/tvheadend/scripts/start-stop-status restart" > /etc/sundtek.conf
             fi
	     initdpath=""
	     if [ -e /opt/etc/init.d ] && [ ! -e /opt/etc/init.d/S01sundtek ]; then
		     initdpath="/opt/etc/init.d";
	     elif [ -e /usr/syno/etc/rc.d ] && [ ! -e /usr/syno/etc/rc.d/S01sundtek ]; then
		     initdpath="/usr/syno/etc/rc.d"
	     fi

	     if [ "$initdpath" != "" ]; then
		     echo '#!/bin/sh
# Autostart Shell for sundtek mediasrv
case $1 in
     start)
         /opt/bin/mediaclient --start
         ;;
     stop)
         /opt/bin/mediaclient --shutdown
         ;;
     *)
         echo "Usage: $0 [start|stop]"
         ;;
esac' > ${initdpath}/S01sundtek
                     chmod 755 ${initdpath}/S01sundtek
             fi


	  elif [ `grep -c Brcm /proc/cpuinfo` -gt 0 ]; then
	     echo "Broadcom STB design detected"
	  elif [ ! -e /etc/WiAutoConfig.conf ] && [ "$NOPREL" != "1" ]; then
	    if [ -f "/etc/ld.so.preload" ] && [ `grep -c Brcm /proc/cpuinfo` -eq 0 ]; then
	      if [ "`grep -c libmediaclient.so /etc/ld.so.preload`" = "0" ]; then
	        echo "installing libmediaclient interception library"
	        sed -i "s#^#/opt/lib/libmediaclient.so #" /etc/ld.so.preload
	        if [ `grep -c libmediaclient.so /etc/ld.so.preload` -eq 0 ]; then
	           echo "/opt/lib/libmediaclient.so " >> /etc/ld.so.preload
                fi
	      fi
	    else
	      echo "/opt/lib/libmediaclient.so " >> /etc/ld.so.preload
	    fi 
	    chmod 644 /etc/ld.so.preload
	    if [ -f /sbin/ldconfig ]; then
	    /sbin/ldconfig >/dev/null 2>&1
	    fi
	    if [ -f /etc/sidux-version ]; then
	       if [ -f /etc/init.d/lirc ] && 
                  [ "`grep -c '#udevsettle' /etc/init.d/lirc`" = "0" ]; then
                  echo "  uncommenting udevsettle in /etc/init.d/lirc in order to avoid"
                  echo "  a deadlock when registering the lirc remote control"
	          /bin/sed -i 's#udevsettle ||#:\n\#udevsettle ||#g' /etc/init.d/lirc
               fi
	    fi
          fi
        fi
	rm -rf /$tmp/.sundtek_install
	rm -rf /$tmp/.sundtek
	if [ "$KEEPALIVE" = "0" ]; then
   	  echo "Starting driver..."
        fi
        if [ "$ctet5000" = "1" ] || [ "$ctet9000" = "1" ] || [ "$ctet6000" = "1" ] || [ "$vusolo" = "1" ]; then
           if [ "$KEEPALIVE" = "0" ]; then
              /opt/bin/mediasrv -d --no-nodes
              /opt/bin/mediaclient --loglevel=off
           fi
	   if [ ! -e /usr/bin/mediaclient ]; then
               ln -s /opt/bin/mediaclient /usr/bin/mediaclient
           fi
	   if [ -e /usr/lib/enigma2/python/Screens/ScanSetup.py ] && [ "`grep -c Sundtek /usr/lib/enigma2/python/Screens/ScanSetup.py`" = "0" ]; then
	       sed -i 's/^                if tunername == "CXD1981"\:/                if tunername\[0:7\] == "Sundtek":\
                        cmd = "mediaclient --blindscan %d" % \(nim_idx\)\
                elif tunername == "CXD1981"\:/' /usr/lib/enigma2/python/Screens/ScanSetup.py
           fi
	elif [ "$dm800" = "1" ] && [ "$SYSTEM" = "dreambox" ]; then
           cd /usr/sundtek
	   KVER=`uname -r`;
           VERMAGIC=`/opt/bin/mediaclient --strings /lib/modules/${KVER}/extra/lcd.ko | grep vermagic=`
           if [ "$dm800" = "1" ]; then
              VERMAGICOLD=`/opt/bin/mediaclient --strings usbkhelper-dm800.ko | grep vermagic=`
           fi
	   if [ "$VERMAGICOLD" != "$VERMAGIC" ]; then
               /usr/sundtek/kpatch usbkhelper-dm800.ko /usr/sundtek/usbkhelper-dm-local.ko "$VERMAGICOLD" "$VERMAGIC"
           else
              cp usbkhelper-dm800.ko /usr/sundtek/usbkhelper-dm-local.ko
	   fi
	   if [ "$KEEPALIVE" = "0" ]; then
             /opt/bin/mediasrv -d --no-nodes
             /opt/bin/mediaclient --loglevel=off
	   fi
	   mkdir -p /opt/bin/ > /dev/null 2>&1
	   mkdir -p /opt/lib > /dev/null 2>&1
	   if [ ! -e /opt/bin/mediaclient ]; then
	       ln -s /usr/sundtek/mediaclient /opt/bin/mediaclient -s > /dev/null 2>&1 
	   fi
	   if [ ! -e /usr/bin/mediaclient ]; then # this symlink is needed for the automatic search
               ln -s /opt/bin/mediaclient /usr/bin/mediaclient
           fi
	   if [ ! -e /opt/bin/mediasrv ]; then
	       ln -s /usr/sundtek/mediasrv /opt/bin/mediasrv > /dev/null 2>&1
	   fi
	   if [ ! -e /opt/lib/libmediaclient.so ]; then
	       ln -s /usr/sundtek/libmediaclient.so /opt/lib/libmediaclient.so > /dev/null 2>&1
           fi
	   if [ -e /usr/lib/enigma2/python/Screens/ScanSetup.py ] && [ "`grep -c Sundtek /usr/lib/enigma2/python/Screens/ScanSetup.py`" = "0" ]; then
	       sed -i 's/^                if tunername == "CXD1981"\:/                if tunername\[0:7\] == "Sundtek":\
                        cmd = "mediaclient --blindscan %d" % \(nim_idx\)\
                elif tunername == "CXD1981"\:/' /usr/lib/enigma2/python/Screens/ScanSetup.py
           fi
	elif [ "$SYSTEM" = "dreambox" ]; then
	   cd /usr/sundtek
	   if [ "$KEEPALIVE" = "0" ]; then
             /usr/sundtek/mediasrv -d --no-nodes
             /usr/sundtek/mediaclient --loglevel=off
           fi
	   mkdir -p /opt/bin/ > /dev/null 2>&1
	   mkdir -p /opt/lib > /dev/null 2>&1
	   if [ ! -e /opt/bin/mediaclient ]; then
	       ln -s /usr/sundtek/mediaclient /opt/bin/mediaclient -s > /dev/null 2>&1 
	   fi
	   if [ ! -e /usr/bin/mediaclient ]; then # this symlink is needed for the automatic search
               ln -s /opt/bin/mediaclient /usr/bin/mediaclient
           fi
	   if [ ! -e /opt/bin/mediasrv ]; then
	       ln -s /usr/sundtek/mediasrv /opt/bin/mediasrv -s > /dev/null 2>&1
	   fi
	   if [ ! -e /opt/lib/libmediaclient.so ]; then
	       ln -s /usr/sundtek/libmediaclient.so /opt/lib/libmediaclient.so > /dev/null 2>&1
           fi
	   if [ -e /usr/lib/enigma2/python/Screens/ScanSetup.py ] && [ "`grep -c Sundtek /usr/lib/enigma2/python/Screens/ScanSetup.py`" = "0" ]; then
	       sed -i 's/^                if tunername == "CXD1981"\:/                if tunername\[0:7\] == "Sundtek":\
                        cmd = "mediaclient --blindscan %d" % \(nim_idx\)\
                elif tunername == "CXD1981"\:/' /usr/lib/enigma2/python/Screens/ScanSetup.py
           fi
        elif [ "$dockstar" = "1" ]; then
           cd /$tmp/opt/bin
	   if [ "$KEEPALIVE" = "0" ]; then
              ./mediasrv -d
              ./mediaclient --loglevel=off
              ./mediaclient --enablenetwork=on
           fi
        elif [ "$ddwrtwndr3700" = "1" ]; then
           cd /$tmp/opt/bin
	   if [ "`grep usbkhelper /proc/modules -c`" = "0" ]; then
             KVER=`uname -r`;
             VERMAGIC=`strings /lib/modules/${KVER}/kernel/fs/ext2/ext2.ko | grep vermagic=`
	     VERMAGICOLD=`strings ../kmod/usbkhelper-ddwrt2.ko | grep vermagic=`
	     # doesn't really matter if it fails or not the router is fast enough to work without
             # acceleration module
	     if [ "$VERMAGIC" != "$VERMAGICOLD" ]; then
               ./kpatch ../kmod/usbkhelper-ddwrt2.ko ../kmod/usbkhelper-ddwrt-local.ko "$VERMAGICOLD" "$VERMAGIC"
             else
               cp ../kmod/usbkhelper-ddwrt2.ko ../kmod/usbkhelper-ddwrt-local.ko
             fi
	     insmod ../kmod/usbkhelper-ddwrt-local.ko
	     if [ "$?" != "0" ]; then
               echo "not using acceleration module"
	     fi
           fi
	   if [ "$KEEPALIVE" = "0" ]; then
             ./mediasrv -d
             ./mediaclient --loglevel=off
             ./mediaclient --enablenetwork=on
           fi
        elif [ "$wndr3700" = "1" ]; then
         if [ $USE_TMP -eq 1 ]; then
            cd /$tmp/opt/bin
         else
            cd /opt/bin
         fi
	 #if [ "`grep usbkhelper /proc/modules -c`" = "0" ]; then
         #  KVER=`uname -r`;
         #  VERMAGIC=`strings /lib/modules/${KVER}/ehci-hcd.ko | grep vermagic=`
	 #  VERMAGICOLD=`strings ../kmod/usbkhelper-openwrtmipsr2.ko | grep vermagic=`
	   # doesn't really matter if it fails or not the router is fast enough to work without
           # acceleration module
	 #  if [ "$VERMAGIC" != "$VERMAGICOLD" ]; then
         #     ./kpatch ../kmod/usbkhelper-openwrtmipsr2.ko ../kmod/usbkhelper-openwrt-local.ko "$VERMAGICOLD" "$VERMAGIC"
         #  else
         #     cp ../kmod/usbkhelper-openwrtmipsr2.ko ../kmod/usbkhelper-openwrt-local.ko
         #  fi
	 #  insmod ../kmod/usbkhelper-openwrt-local.ko
	 #  if [ "$?" != "0" ]; then
         #      echo "not using acceleration module"
	 #  fi
         #fi
          ./mediasrv -d
          ./mediaclient --loglevel=off
          ./mediaclient --enablenetwork=on
        elif [ $USE_TMP -eq 1 ]; then
          cd /$tmp/opt/bin
          ./mediasrv -d
          ./mediaclient --loglevel=off
          ./mediaclient --enablenetwork=on
        else
	  if [ "$synology" != "0" ]; then
	     if [ "`grep -c mediaclient /etc/rc`" = "0" ]; then
		     echo "Setting up autostart (/etc/rc)"
		     sed -i 's#exit 0#/opt/bin/mediaclient --start\nexit 0#g'  /etc/rc
             else
		     echo "Driver is already installed in /etc/rc"
	     fi
	  fi
	  if [ "$synology" != "0" ] && [ "$sedver" != "0" ] && [ "$driverinstalled" = "0" ]; then
	     echo "Setting up autostart (/etc/rc.local)"
	     cp /etc/rc.local /etc/rc.local.`date +%s`
	     sed -i '2 s/\(.*\)/\/opt\/bin\/mediaclient --start\n\1/' /etc/rc.local 2>/dev/null 1>/dev/null
	  else
	     if [ "$synology" != "0" ]; then
	       echo "Driver is already installed in /etc/rc.local"
	     fi
	  fi
	  /opt/bin/mediaclient --start
        fi
	if [ -f /usr/bin/enigma2.sh ]; then
	    sed -i 's/LIBS=\/usr\/lib\/libopen.so.0.0.0/LIBS="\/opt\/lib\/libmediaclient.so \/usr\/lib\/libopen.so.0.0.0"/g' /usr/bin/enigma2.sh
	    sed -i 's/LIBS="$LIBS \/usr\/lib\/libopen.so/LIBS="$LIBS \/opt\/lib\/libmediaclient.so \/usr\/lib\/libopen.so/g' /usr/bin/enigma2.sh
	fi
	sleep 3
	rm -rf /$tmp/.sundtek_install
	if [ -e /usr/bin/systemctl ] && [ -e /opt/doc/sundtek.service ] && [ "$USE_TMP" = "0" ]; then
		mkdir -p /usr/lib/systemd/system/
		cp /opt/doc/sundtek.service /usr/lib/systemd/system/
	fi
	echo "done."
}

export NOLIRC=0

CHECKPERM=0;

if [ $# -eq 0 ]; then
	CHECKPERM=1; INSTALLDRIVER=1;
fi

while [ $# -gt 0 ]; do
	case $1 in
	   -u) checkperm; uninstall_driver; exit 0;;
	   -h) print_help; exit 0;;
	   -e) extract_driver; exit 0;;
	   -nolirc) NOLIRC=1; INSTALLDRIVER=1;;
           -softshutdown) softshutdown=1;;
	   -easyvdr) AUTO_INST=1; CHECKPERM=1; INSTALLDRIVER=1;;
	   -service) NOPREL=1; INSTALLDRIVER=1;;
	   -system) SYSTEM=$2; INSTALLDRIVER=1;;
	   -keepalive) KEEPALIVE=1; INSTALLDRIVER=1;;
           -admin) CHECKPERM=2; INSTALLDRIVER=1;;
           -netinst) NETINSTALL=1; INSTALLDRIVER=1;;
	   -tmp) shift; if [ -d $1 ]; then echo "using $1 as temp directory"; tmp=$1; INSTALLDRIVER=1; else echo "invalid directory $1"; exit 0; fi;;
	   *) if [ "$CHECKPERM" = "0" ]; then CHECKPERM=1; fi; INSTALLDRIVER=1;;
	esac
	shift;
done

if [ "$CHECKPERM" = "1" ]; then
  checkperm
fi

if [ "$useblacklist" = "1" ]; then
	em28xxblk=`grep -c em28xx /etc/modprobe.d/blacklist.conf`
	if [ "$em28xxblk" = "0" ]; then
		echo "blacklist em28xx" >> /etc/modprobe.d/blacklist.conf
		if [ -x /sbin/rmmod ]; then
			/sbin/rmmod em28xx >/dev/null 2>&1 
		fi
	fi
fi
   
if [ "$INSTALLDRIVER" = "1" ]; then
  install_driver
fi

exit 0
� ޘDR �<kt[Ezs%?Ǳo�&q�5(�lc�I�@�#����y���+˒bdI�
�rB�ڈ��	x�T
�����4-��%��k�Z����i���^/� �iz��Є���UL]4���4��� �Lv�\ S9��
�6��
x���߂4�i^�)*ٻ�`�l{gq_�{��)'O�?����'�`8� �=����r�o0�?��@̳'� ��,�s�g;/�y��@�D��0��~�E�O�|Q��I���c�%"!J�R4�DȆx~
�tݽ�ckw��սmK���`�vW�gk��x6�������u�;;=;;6�hT"����&���%� {�����a�Zx���ށڍg{jM�ԓ��5*y�h-?Z�B�kGi&(͟���'G�8*߰fެffc�UZ&ӏ�g\NzF,dʬ�ck�.%uP&����fanzx�)!Ϯ��*Vk�{���У#ΡC#*���%�i����ݠ[��f�A�̙T��5�^��ԮIu�(���NyV�)��,�:�\�~j̄�Ǚ�i�aV[^B:�~.���h@���@Yc�[��(�l�T;��=��������i�v���JA�i��e�ڍ@�r[ˀNU���N�5�/4�����CL���[�V2~����Ѻ�#ffkg���ZWOH��Ff��#V��QH�|-�Ӿ�'�����#u�v��ˬ=�4�wr��p-� ��.'�%Bf-�%'�b�.ac�d�/y�h5�K�7I�&^_��Y��
�����5�Y
ܾ�`�?8���B�$����`�ZQb��n�l��ށ������~�3�1������l[��;@d�7Nlt�g�E����g�:b�%"1����>�`$������/�p�d�Ea����d���lm!�(�:����	�b1"np#aq�c1*'�� �k�7�i����I��*��@:���˼L�a����a,i�&O�48�wA:�=������[�3��8	��C�v |E���xp[�tb3���w�*�3��It8�T��.@$���]�Z?;�Htc@7V��!��&�c�p`)@w@�� ��]J�S�NU�}B��X�����v|[�Ø����?�өk�Qq]����Of7ʛ�8�����9�J(�=.�Ƥg��~!с�;n���T�v,��`!'
ȓc�����JY������<���Z�Sb�m2�>�̜
�k�3Zgfs8k
��6�٫�?pad��U�������0���꫉��W��b��J^ԫ���s��CC~�k8=�8��|�Ѿg0��Ã�Jɾq�}�`��gcxy�F����Ȁ���W?�6�:c-Ǘ*����z��3*a��Lr����I�0=��>�ޥ�c�N��D�ܤ�]�>&�UE3�)���}�>s�?&vr/����8��Yȷ}��}L���>��#EQ��ȏb�o)����}����:�xG���
�𣍂�5�@f������um����jÕ�����5w���e=ijnnni����E ��0��|��������O����I;���a����o�Dg'v]��{D.�2��ƕu��GMv]^��D.�ľYh����p.;"������\ߣ�ws;zLz>~��9��Ӌ�7L�}bO�8��8o��5������˄��Ö���uy�k3�}��ɵ��s;�W�/�.��~ZZ0,��I�6׵��P0��װ�}]ú6<�o���P��m�(����q��AZlo��C�hJI>>��q煻���V!W�3��H�Ύ��o+R�z��+�з)�+R�P���"嫊��)�Y��}�0[5�L\�XG��D\,Z��`8�G���r�/�������Ń�0_Eȋ���0:��.�6��7uzZl-6��Y*�w��Bwx��HrEpR=��U=4�q#�f���q��c�"��1U*�c5R�<�iRy�T^/���w�T.�ۥr�~�]*��ʝR�|��-���s��%cd��?�eXt�r"{���i$���z���G��)<\X�G���')����˦'(����1�@�`�ſ�8�lz��1��U�C�q4w:J�^��5�=�qtɴ���GWLۥ�z�{ݩ͙��s��{g�����v�<������'g"�pat}�L�>Y�����);I]1:t�R�Mv9S�LT���9<aq�J?��O���O�΃?I�}��]���N�r���e��L�^������0w�N�Ց}���(������#�o�]�<s3X�rd�3d_�y�o�>�fӃ�Wpg������<�i���Y�^���A$s�3�/<��d婃o��չQl��e疱g�s��4}�ր��盜��3���j*�r�23<8C�=��<��Jμ�]�)�� �����������y�1�:ӎ���%�/N��Ã�J�M���n�?d^�S���sm������6��JxɮV�43^�@8Ν�J;N��I
u��8�g���v��['���C�TK��v�s��@"�K�Zk�j��h4�y���U�
}M�vGG��ѥ��$�1�I���F���s��I��[s�n����4߆k>�����q,A����0��"�n�ބ��)��%�3�ol'�>U1W�[F���4��g���J}�Թ@�5�n#�߲�٘-P��W������z�ޕ\��{�S��! /^`�����ȝ#�G��Tه˟0.y\�Ǜ�9��9��9��9��9��9��9�������Y�8OgM�~?�$c�g*�>凗��g9.��n~�R�j�gy.�,�Q��vb��%��uD��
/Ӂq^���s��
G[Ǧ����5E�G�q�@F<1��)�EB�
���?j~~K,B�_Wଯ���x�*�-�+&�6��~�>&���÷*�j��%|F�)���X�9�×���@��p	���_<J�.�E£�?�ƒo�<|�(��羼5�c�8s����S�+g��o��O��E[Mq=bw�����Ǽ~���u��}�9���ǚ�����v��ptgΧv���<iw�`�vw�9��ݳ����>ќ��������7�
��æ�gO����~����_5��A���0��C�Lp<'�Զ���b$�����KQ�0��½o�ysЀ���a(�-����h/��b�wĮ1��F��K��L[��x�)��)�Wr����ȡ����n���4�Q�\��\��\,��1��[y�괃\��K�C����f5��6����P�#VsX�F5���m��#�)�#F4}��AQ���Xf�?����];���$>D��i��X��%|��c7�E�Ƞ�T��j��y�#��E���U��t��R��-�Sa��g��h:�tP�6%��
�L���SLf�N\˚�S0e �M���>Sf�`�V!��JSf�x�3��!i�!d���ה���-���O�����נ)3j�Ȕ�L1`��ڠ)�;<�̾�2�ѿ�`�/R�9W�/�����D�q��B���Z�H�GV��J^�:����<����|&np��|[�W��q<GJߗ����%���>~�m��A%���^��8�,����\~G�G�Y�2UCR}�O�iv9W��_��%S4�}�}K�
��R��;�=�dH�f�W��J���U�5�����J��4��#{����|D��������"�;)Q>?�/ r%����I!~��i!g�b���2^>���"E^�[��J�cxIޠ�oQ�[���� �Pԏ�# ���K<L~S�����`�N�T1cA���7�4k$~��Y�S4�n�R�ъ�u+"�NC}J��K��F�
�T��+V��Q�p%,�sJ*�U�RX���GcEۉ�R�'�xSiЄq�Mr1��fE}������n_m�W�i��$�F�J+*K��?���Wy�Y��ln�W�V�Us��sH�^���비���.* ������DP�/���=�����po��%��ᷯ� ����D����}2��-���;��ҥr�z������^�	��8�[~E����3�����ߨćv]91�zO���Z.���-\�<X��5\6k
b�����
p������Ǚ,Π,C�#YK��M6�,8�>�4!duM��C�j	����:��q`�5�5�-���g'=�Ƥ�۷�{��ۻ&����Z'(��p(z��Pk:�A��Bg���4�}<�bM���s�)+q�VX�G��<>O�[|m����4�'�,��XS<��I��.�(b�[�Wٗ,����V�+�R��B�z,�t��_s�Ǖ ���h~���_�M[��E���Up���b��.$��bk�w��]-�V��/�E��WQ�+�r4��<��R�������JoS�>��R��X$��>t�6��xWϕ��]�W���wqL��S=�ق��Ŵ��y5�i���iB�$�����NN�]�,O�ю�;�^A/6f.]r�\Oĺ^�I;��g�5^dH��]��~}H�}dㅜ��nAҋ�\���rà��ظڒl��*����Z�L���dh�p(���iX��'�0�57�Z�2s�3x�J���f��i6��A4�~�Rc����l�N�N�]��)n��scnl^��%EG��-���_5g[�9۲��-hg�Ķt�ۂ׎2�R�ٖ�.l�\�m���l���}q�p3Y��a��[a��
�.�w
I)����7����(�M��V�}��1:�[O��7-o��<JȀ#vbO8�a+�ѱ;{�s�ի�M�>'��/m�R<`��&�d��	��Ӹ|��1ٚL7���χ2`i�s�X���3`ip۝K�s^���:52K�sU^,
#S�02�
#�[ad�F&Oad�*��z���W�Sf7����V��a=iPad&������y�d6�2_.ngdSf3�QSf�L�)�;��Lf��ߔO?#c��9?���)r�"�(�En#�ZedR�+��odb�<2�l6��-&���g��17���o��?����'�����q�ҟ���'��L����\���HbR0~�>d�壊ܣ1�H0<���op�_��T��28?��;�l��y�1)Ȭ��E��\����-
���Õ�jN*6�49�dn�ӈL� ���M�l5����j*�Og#�?e�f��?U��*��?������F�]�X��ŷ�'Ÿ	��(u �7��
%]D�-������:H��-\QcDT;(��e�� ����G��j7���#����颼��g��%��^�3�3�C7M�E�meǇ?V|d�F �C�@����m���u,%��h�Hy�{P�Iz�V<�1]xyΓi
|xR�|I������|��H]$�X�cPsF�l���`߯̈�b�v�$�����YA���|$�A�b����,��]2c�����T�qL����F��h�r�q������o���`!q������[�Kg��Lϰ��d��(���������pL�>�11����6O���^�J���9*�W��h�q�j~�>��+!�֧�=,��u���"���c�zkj׽7���l�8���E���uؔ-�L���b�>|�h2��m7�u�n:�kg�̴7Y`o=r����v����#�vבS��Gs�}Gg���.���>|t��{t�}�h�=t��}y=�m?��){�6��6�~u�{��;��6ۇ���{�uۇ������ڽ�3�����w��o���wۧۻ�3�P���5��5�� �u �: r ��\@� �������A�n������A�n)�z�k=���- W��r��\- W��r��\� W+��
r��\� W+��:�ra�Eٰ^T��/�I�:�e̻�2q��shKe��G�3�
�6�LL�D���GL�����\���{T]�֖�ϫ��9|x-�JG����v)��)��ZɅ�_�?LF�0��y���e�a���λt��2��>'�%�Yf�b���
Cl3L1��sj��a�9A@���`:��1��9���c��Ӕt�'���<�@|'��y
���ɰ�	�=�����{��H��#t���}�Z5����>`N�^p����K�����*���5��t~f��s�A1o��?�� t��/�?:�O_���B:���=�Q�e/��b��y�5N�����[҅��4��!��4�4?���{��(~�-��N�c����>��ϻ]����S���5�t~柞ϵ�5�&B���|�Wy���g���H����{�6�K}��N�QI:���j9�!�kٰ�_��O}�e��'_��P���%�.�)0�K��y'�A�c�Ċ^�L�1	qT`S�3A�J�s�c	�ć%�X�
�Q�U2�]�8��$�_�X���6�� G��f��*�>��?�O��%���'@<�h���,1�,��&�^-���*9^����>I�[������~\��,�o?�|�
>�1]��?C������@y��@�� ܨ�|����}�����sI�V1Ƀ/yR:?3���0����I|�0�<[t��K �X�o~�/��2���PY~/��@��;*�O�v�ף�iv��E̽�o�.��0򫑸�O��j���!࿏�� c�1�C�Q�W(�O	���P
�t~�J��\�g	}⛴>B� �$��vۻ�ֻ�]BOA�ǵ~C?|Z��������p�n_�_��n��z��X'���]�����P�8�ۼWu���'�x��\��#���Kp���8!1���3:��:�E$��{�~r`���C�5>����	��%���t}�<
_�5��!�
B�U^�W���t�� �Q���uAR���J�>V�'|7�f=��<����>N���mO�!��~?Q�1>����>�۴�Ç!�1R��q����C�.�?|P�/2�ǵ�"8���=D@_�.]�����#_~�u��,\����-��4��<(�a�o��'�ޮ�'���,��u��w�k^���5/M�/����p���cD?0������B��p|����D�o���N������[_�+-\bqƏ�W��]䶧�.s�ӱ(���������#�6��ܧ�&8�
����P��|>�>��&���n���翗B�T��O��b��w_�ܒ���i8�γ+�7��N����Ȓ�\�g�����wg���k�t�3_���4�YVZ�����p"J����(*��V+y�<�J3P֮Lw+Җ%�z��)+�n���5
��hj�KS.$J4��]HH0��G��$�;�4/�*��n�D%#�!� ť�W�R�<�.հ��ST��;N�H>�4M֮����Cv�8� �[����-}�o�C5�j����%�I�쩎��Mr��+�kѨ��VQ�j�ir��h�t��u���T]Y��(W�SJv�(�uM���}��t���u)fU��.-�|i��-��h6.���C��i���b��$��ʭ��`ud���eJ�-6�F�*��"���̉��
_
R������t�^�͂�X��6u0hu�3;���	�����4U�&���U�8�'�7
�V@�!àK�D~]%o�a]�,�I��Tvy۠��p�����]家r1=�_��	�|I5���J;�Yxa��
�[��S�B~��	�ɩ\�_8-���ߟ�m�O�S~�|�M���Y�f�
�O��4�v��'iܛ$=�G�wd���5� �i<KY����$�%}�GV�o��N��P���S4OH��,;�{��G�I9�`�y�%E�o�����\/�K�^l��RdM��$�o����-�d!�!� �3�\�	��}��{V�C�c�����s=���q��p��Ä�)�
���6|
���70)?���g�n�O���>,�]Xl��:v�K_
�v���q�d<����`��.��,j��Ea���\^�zov������Bk;,|���"
�+�s��+6+,V��,\b�X�z_�`�z���׻�`a�w���$,G Ka�dT�`��}��Ͽ�w�,(�ѷx>�8�q�]�1^����p�<y�^���=m:=ƫ��v'�&�O5���1^ϩ.����W���{�_�t�P?菢�S�jOy���t�1=����t����8��$�M}���r���
�B���n�%�k���~w��M�7b~`#��Mn�%�5��nU�W��^�~pC��/F`2�o�:�
ƍ:a:n��Щ;������������{�V��4�h5����w�����۷����'�wIZ��F{�~�s�ǎ��i1����>��Q��u ݱ�ǩ�}g�����j��	�oA|_s5E�Ő��a+�v�����}j�������}+K��;@^�K�a�� yι�r�0	��Ρhn�΁n����VY����P�8wBpNs�0�Ǧ�IhM��I����д�6��Y�b����5� O�W�����D�X�(�Zl��~��'E:�ZW�
l��-R+�����[cX_�M�u�̫c	�rT`�Oc��0�?���#O_����\
�0��=
�^�&���8÷��3��p�Ó��3<���'��x�8���~o�8ÿ-g��Ip�{>!�0��w
�a[�a��3�*p�m
ΐ��i���t���E��b�����1T�M(��>�20������x����~������y��8���R�f�����w�W�k{�7��
�Me�8��~zB�.i|�|�_9l��` ��H��O�������Ջ��"��$��&k����G]�Zl�u�Ŭ�#�{mUU ԑ�JC*E�٪$�c�h����H���c,��,��3���h�K���~�o�oғ���{�ﱽWcj��#5���I�ߤ�z��ѻ�'=���q���D]?�G��{�"�z��ߣ{a�U�Po�ˣ{��{t�*�G�A<��S�{�~��G��rsW��[��kjtN{.�T�]{���8��0o���ÿ����x8��_�}��"|?R�h?*Y�w|\��?��UE�d��P�$.���(��ˣ=��"�=yH�Epy���Ѥ.��_g�_���_j|�pyi|���B�YF�/^�5���tm�!�:.��{��reߓ��
4��j��Q
�g4�!
}���4k�nC鯦��ET�Q�_s>���3��u
M��
M��q���F��Q#�{���G������L�[J}��j�F�w���;��p��5\�-f��5��
>��s��χΰ����i��<����w>�Q��J<�ujDb�f���ۺw!��t��s�j'�N�xU1�f11���b�)a�EO���	�mAWpd�d�G�p��1pDo� �D�I���~N�>�3,���P���[�y������&���Z�jUS�w��Մ�kJΜ�wM���ʍ�d��0�ղ^��A �2�)�D��Q� ;q��#<2O�|i<�i<r��:��\!OD�9�#ʗ�9X4
-"�Egz�`�l�M
e�t�[`"�'-�烿U�tU�S=�vÜ��.�6^�4��{�*�޷4��0D�����k���<},���8OV�W��ɬ?��c~O�S��	�ނ���]H�
�iP�o����$h�����'�y��(��(�_C�M��!=����)t�4��?VIz1��by(������'�/����e	��dhN�d�O�I�M �ќ 
�g�eʣگa�����H2�Z$a��Ť
�c}ǡ�(���ؓ�"�}{H���G}�i�W�ZykK�C16�+E>�C����4j�"6^�:�k��ak?���N�_sH�K-/��S��+o�<	��S�gc��X!tl���{��؟�k�V����]��*�He��|��<?�D�8U�e�˱�d�6{����{��Չ��(�EY�a���B���d��v1n�1���.��-i>w��s7���-^�D�84�^�����_�9�11�;�i�̑��ǘCO�
󭽙z�����<�oo��룮^\�gb�o�U=Vf�33q���J��{9����G˚ �z'��CuȢ8wqq���ܥ^�]��+E76�j_4J�ٸ�|^����k���2;�͉�2�����öFv1�:��h[��5�J��i������]���]Z�����>'/>.�������z��L�	3a&̄�0f�L�	3a&̄�C�c)!C�<��Y��&=��g��|��I�sHz�H��#=W�g���P<3�y�3��g�_j�vx"�
z�|�J�2��%�<A��KB^a_���v�3FA���3�OC��)�1J���4�����M�~�� u$k�1p�������kVp?<�WV�~6#����R�T˺�j��S�9kq�
c����	�x=xe;���E����ը+���W>4��]�/���<|x#��h%�+w��w���n齙?�����>m�����қp���������M;����X��׽����£qǧ��H�+.�+�g�+�ڴm�JX���^���Ȱe|��+�n��U�y�PpsLs<�ɱh<��G4��T�
���Ƈ���Ȼ�[���C�A�%U��-!|�|.��M��p�:���GX�wH#�芢�~��
�1>�W���^��#��Dy�{ec�a��4.����Mg�G�y��2���{m
�9A[�4�Ǩ�'_�J4�8v�h>�
,�%ۀ�_��-�3��O�8��h���
��AK}
�O��J+x"�z��A�O��5�F���_�{��NzF�����+ݲ�qv�F_'�gp�-��3��VI��~��*!ڔ�Qn�k�=6#M�'"�8W�Q����ǔ����5x�>����O�7����)r;"��4E����]��Ea�̏��(H���0L�O�/�O�����f���<�
z���	�]���t��;�)�
,dC��V�Nq#p8F���9���:=N%�8���7�8��N��q%��Җ?HCO��{3wF#�uݖ9��̝w�}_�}�}w������&�u�Q���j>�t�4�,�Ee�����
�m�t�x��a���$��w���1m ��:��|i���_mH�/D7�=��f&��K��t�OD'M�AsQx��w�Wj�s��P�_z�b���=���ty
�Y+��ʈwh<�M����� ;�T�\AϠQI4RD���@�
s�|��2����s�|�/<[�ݐ�NP�	�"	�zB��xF���̜ǪK���J|o��\n�|�=C��vN��m�o�5/�T#:fR(P��DLl��H|�6�3Ҕ�pm�7���y�+�[]X�"�)+��V������p���~Vj5�]XmD̚ml����R��8W���1��$�yVj5�
�=���fy̅�ɷ��J�&��J�&��J2�qa�V�sa�V�Ӆ�H�v�˳Y�sae�|�n�l6��x&�?l~_���5�����M�S�_����&8�aȐWy���?�;��`c��@�_�{z�G�?@�����W���m)�����L�0�0Ƥ�7ێ����eGE����\�����0l�
�ߺ�UN��A�Aj�\Q��r}d����c�������/纘�O�:m�2��R��^���\���0.��c.[T��N~��~̗����R����?*�
\���g;T���ۧC�L\����%C�R�D�:K|6�`ɀ?� �<>5�y]X]M��ߩz����{=���Ń�|����ź�F.����ͧ$��%���
�|�5�\k#���+ݷ�����!����_�%�w0��=��@}�Da�W�3��hm���(Dʁ����zl�5j��Y��ͧ�C�B��Y1�R�Ѻ7��u�Mh�(�����-�Mu�:
���V���v"��Q��G��fP��p����?܉�+p�����l�i�%q��U%�4��N��Ɲdw���� �Ýgw�%���g����h�ʡ3�׼/���;<�Xױؙ7�G�靮��w:�F�?l�ϲ����${d�G���|�=���}��%��{�Þw��N���}='ı�Q�+'K�=ǣI���v�{������;O�;udl�_���w�b�k�1
��$�J
i
��)���Da
����w<Eq(�<�&���3G���"�o#�7K�mp���n6���P��j���6$�_��6��^��yO�OIWK�,�3�IÍ��1�KV��x.$�h�.K_�qb�)F��w��;����]�ޥ�_R�F5�z�@�i1�C��"���E��o�i$4�EyrzgΏ�W~z��Ɔ�W����y�郞�x�_���ﰶ�i��4ƿ}�k;Z3g�'~1t��q]nڋM-�|UL4����;�����Y[��S�݉F���T�ʹK�~����Y��ogk����?dt|�'~=D�0�
G)�R���-�9~��0���-��Q�\L��V�������^$���-�wІ��\��m6��M[���r�[I����=��'h��~1���{Q�)�#c��{w쩱��^�����;3�=��¹mj?�L��q�ctܹn������~]u��R�l�ۑK�˿D0W�<��6G=��^!
�1k�U���[3#	k���j�,\�\�N�T��K��
C�����O�����ޞ_�]*
,�-�L�[�x�lG���+��G,yw�WZ�wN����'Լw�u�������=Ng�k,�9J+�e,���+tX�s��������*{,o����z��|�
PVO��� �� ��n5R�
b@Y��]�o����uP�T^��t-���h���O���m���aDM��a�C}���q���g��9�l�E�j�%"[���e�5�n��aY�lmA�D�($��zi��;�/� ��m*�v9�^
F�jX�6��6`NN�*]#�J��A��ؒ���zg���-Li���ψl�M�2�U૫t����!��ja쳪��ǭ�5+|p�N@��1��j�0�*\A�)�q�64�vJ���Â!��Sj�!��H�W
�|D�hM}�,A��;wv;0jE�&�۴F$��
�ۍv%z	������?���7�z߈VFzΨ27����6���}����:&�f�<��-��:D��������{J+���ɼ,�Ծ3MZ«�vP��n)�W>��Ijc�o�x�ǧ챱0����]�E�� ��h?خ��7D��=$j�����&L������<����b*�o޻�=Hmn��T�*��p��[�m������I��EعG�ud��A�oH��7�)oi�7/*)�_Y�Q�����&�����'�0}}F�AݭC�p+�_�L��p��{��o5��*�~M�o��)]��ݤ��T�)}ħ�Ν�5�e�*�N���Љ/"�̜N�$��ypC}�^�qc̉���4#D31	����8>��B0/ծ�uV�IK���o�?c|�;گ��{�җ}��eOt��4I�C�&Aw�$����N���:>*iN@�� ��o�$�z6k돱�K��s�nѨ�u������h3��\��Ӛn��Ͳ����!�V����Js�Oobn��o�ҴWs�D�Q���4�V�8j2��\r��u�֢�EX�R����w�o{���Y=6�}�Ϧ�"AkEEp���,�u\d�"����(����u�6��E����0Aͼq k.���S/|^ͤREa��W�2~�r��ғ�&��=���%e�B�=sIJFq��/�]0~�X���M��ѥ:3��2B��2s���r��F);7k�}��[#e`�7W��
k�K����M��=5�'��a�[�b���(���	�w��7���Q[o!�����±F�}���`j@������d+��~U�M\���r�
Sߦ[a����0�7��VX��EF��Ԙ ��������.�&�Q�
���l��{N���%[a)m��l�����VXJ�'[a���V��
�mY���V*[E�VX��l���o�K���m{��:ڶ��Q���.���
�oڐo��
h&�z�������i��-�	�ˉ]�CF�)�Q����y29��۽��7����7�}B'�(T^����w�o����<��������\���5���_JB�i���sʹr�|�r��|�~���*3^�r��kn��zOq��aWG�hW�C��h�/R�U�!7�ݦ� ��|a�tX��q��
��Cv�Jobr�7�¼�_�
��Yacv�Y2O��S$����7N|'���
�ʠ,��>���ξU��Z嵒�}:lZ�h)�����?��S{!�W�o$m� 4��7����@&����|`~t^�2J/c���p�lc��mȏ�+�or�ס��w�1(��b����t�����˯䟽idEC���r�-��3�72te�P�8����X��x�����V�ёD��'���?�D�����a{À���y�'r�o���v1
�+����Q��4�o
�2ݞ<z�5�\
s)�W*��Y��$\��dF]fԫq�:���d�����I���e��@�GH��oҁ�@�������tp��A��CY@�=(~j�ȏ։$���'�B]@���o��u�[[:���W����?��?Dt��({�N�
"��8�#I���wM~H�Bt֍:òN?��jw��ҕ#��z�V8���Zy�b�����ϴ��-�=�y�x�G���-о��|��c"�#	[!cd�n��R���2�
d����kK���d=����t}�A���{���r�R|�����mEƫ��f�]#w}��3'���G�x����V��{M9T���3�5]����F�@��;���2��<C�	Ҟ>c�=j�A˽d��1�>i�kru��f_F�1�o5�n<�#�;�G�����
է��U�����te&�>M���_C��M�ԋ��n�����?�4Ն�s+�y��E(\�&ɥ�Us���^� ���'w��arG���;i��+[5�g�,��<)3�8&֩�&P�n����v����m���X.��w����
��3��gL��h�Ɇ��ɫc�ˣ˛\���z��I�4F>�7�S�3(?z=��,�߽n���Q�N|�[�y�]K�J4�Hֹ��;�s�<5X�*:m�Dv	�u�]+��,��QT����5t�����;�����ټ��Ν���
��{B;xl���7������z�<xm�M�[��;[�A�:C>�v{��ɦ���:)=۔z��yO�����{�e���P��mᒇϛ�d���!��Mw�O	�l߽Ƕ�ޣ�c)K��n6Sѭ���������[?��*������;����w�5��giO���(��]+G�]5�`_�U툚����ֈ��Ƿ�M O��ɴ�������/���"�~��0���ma����k
^/��C|��
�!ըrC�xx��#yc�/�/"��-�xpL�G)�{pu�?M2��	���){��L�G���,�Km��{���U��
wY��+���I�:���6t��;�f��"� eÙ`�������_W����x`��	�!=A����R�nS[�\�� G7�M�1X�2<)�H4����n[~j�c2�&&J'��M���z��>Vsk�n:Mߡ_(�4���a��D��{T�y��T��Ɋ��<>�A��b"�'L�r"4S^��L��; |�)&�3�KN6;��,Ӡ���7ZTi9�"�:�*N�<��K���P�Ʊ���"��"�m�T��ӌ����F�<%V�o�5$�J�*�CN<�]��6Y|j��}n��/J�I�:{ɫ%9��6�<���@���#�Sb���[Y��G���b����]��䢼*H���;e���qR��j���I�n����������O�=��7�ã]�<�9=�0��P�l�C��V��ěŬx�(\��H�d��/.Ȋ����4��lW_Z�\�&i+ŪEsE�E�l�E��>}lhQ���v$_<:���]#ܥ�
/��?a��*f&���"�؟<�@�-�S�}JO�POˡ��E���x�b�����L_"���IG�"ZGm�/ZGm�b=�m��B�VJ'Im�h��^���~CJ�E�.%Z+�D��0���������6+��v�!��S�Rb�<s(Ӛ�e��v6$r1i�YG��"还�::�K����mPG멎Z�����6�W����X�f�ݦ@gYx���(���|��y+O����M,�"(��{��#����x�.x`� �U�(}b��tʦg��xL�)JS����wԗ�忬�p��F��}�)��#��!|9��H}��Co<��1�_n���0���GI����Z�
�	mK���M��w/u�@|���>ۺoO�}�/^��B>��h�k��?:������Oɾ���{�u��,�돑���{�%�(��M���'��~ӄٗ��q��]З.�C�g���M>����9&�+C���Od��d^2����I��`q
�Y�H ��5k�[-����o��)�?��ϲ������W�߮_��ж��9��m��jf���XK.�y�=�˺*�3����1��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0��`0~{P��G�,!R3��	�C�,�����ǔ?5�k
c��{���
�q�43�����=�=���w&�Iޝ���O�ӏ�;����6��������V_�7�l�(����u�S�w;<ϔ)F
����Ln�4�LD�-_�o����|�������ܒ�Kȑ��	��v�z��M�2a���Ik0����"�%��Ue��yJ�V�}Zç�#ܪ��_�J���E��ټ�lI&��he��!�+$|�˷��D�y`�*|��O�C�h�	[3��=�7)���8Gl��[��߷�e�������m�9k�~��4��6������:=w۰�t��_��������q/���>���jί����7���ė?�*�xr�W�邒�_:SP|]��[
�8���Dz,C|��i9��_\��)	�س�#����'2iʡ�D��
�!���?4
�OD�ć}
���]�N���{D}�:����d��E����g�Q�+�����wH�E��#����Ll���A��?���須�ШG����c��~.�C��ݺ��+��@���[�&������,�l�~��Wh'�^�'����6}=�`=�����kcw��pyI����}�lLW耭�-V�����E��/���¦��Z��7�F�^^��6}?s�~�@������R�U����`��e���Ϸh�����h��*�h����H�3�I��\^���P��<b�c����P�e��|R�p>�d��x����9W ^<Y�Zhx�2ž�v)qU9*'���(F�N�e�646�������G��B@���޾����]��m�;�wӤ���lR)(1_ �e�� �Lh<����զB��!���S�_����P�+�H������ыW	V�Ja��^BT+��ա��˹h<W�����[�:�>�1�E�Ƴ�X"�%��F�`p�@���P��'��Gvw���^��P��ZbcY6��qtf��R-�gE�L٢�L^1ˉ�3����% �BмU����	LUiȢ|R�|z�ƨ�
yh\)0�\3�����vu
"�v���N������ђ�S䘹��Z��~;C4�?o�Ֆᇰy�F��`y�n
lj#��@��ho�o&�V��M����ɢ?{�����\&S�������ށ�̔̂H>G�gJ���cN�˶����4���j��4i�B�� �M�~��}���Z���b�}�4ց���i�峴.���!�62�j��b����n��R�]4z	�;��᫅X��P��	Vz���8h�T{Ӛ��ɾ'V�N� )L6�6Ԉ�_}�H׮?9�����_z�w�_��_s�����:�S?z�����S���x���ӧ���Z�rq=�u�!>\�ӨY
��A����t%�Mº�(��H6�]�
�^���<_#�{��+;2#��t9����a-����ֺ��s�L;�\����#�A�p`�[��'aM	a.�J�P�ֹsn�k)5}Đ�L7�YY��Z��Py��������c�j��N.��T&���-R%��*�I@�:w+y���5�\dz����m&�b�e���J�W���}�	ϻ3�/��+Gf�U�m�<���j>K�
��� �tc(����|R�=Z"������4��ǒ��?JΩk����~�M�NU_�������+=s����G»�ו��*���G��>s*���lj6���D�do��9�X4�ߥ����掕>�8�w��>t4<w�N`�f�S��;��פ��@������v^���L�F�
J��ļm�H����f���\�����>�7��#I�[�xcu���^kZd��Jr-U_;)(�B"=��{�w�!@��?�M�������osN90��A�4��!�>��n��g
j���������_������-Ⱦn������2͠���T�84�:N�N ������N���D�j�WA������	O�����8�l��].�o�(s����4���Lm�g6�>��1��_��&���Ct��j��1���/��]�h.�$a8s�t"��P��n��
zɵ�ڽ�Kkk�m1�g��)\�����ݒrJR�e�����8%�.Qkv��.J&礻���<�ѯh�������sa��Wm-D���5{L`��V����D���5�ڶ�� ��{p��ٷ0�\տg'��{p�;m��B-�#����oc{�+�<܏�D����� "��y��Q��U  i���bC[����K���p�be6)W�S�vt �pS�������0�K���!��l��������zKq�78�]�(��V�1��=�
�?�٥��#t���H�N��`�*�s��.���bX�a1,�Ű�b���v H 