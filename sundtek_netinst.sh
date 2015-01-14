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
	echo "Sollten Sie nicht ausreichend Speicher in /$tmp zur VerfÃ¼gung haben, verwenden Sie"
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
	    echo "Sundtek Ã¼bernimmt keinerlei Haftung fÃ¼r SchÃ¤den welche eventuell durch"
	    echo "das System oder die angebotenen Dateien entstehen kÃ¶nnen."
	    echo ""
	    echo "Dieses Softwarepaket darf ausschlieÃŸlich mit Geraeten von authorisierten"
	    echo "Distributoren oder Sundtek Deutschland verwendet werden"
	    echo "Der Virtuelle AnalogTV Treiber (vivi) kann fÃ¼r Testzwecke ohne jegliche"
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
‹ Þ˜DR ì<kt[Ezs%?Ç±oÞ&qÉ5(ÄlcùIâ@Ø#Ç‘‰´y´²+Ë’bdIè‘»qkb"ØÛ³íYZºÍ²»=…Æm)PJbCR?ÚãÝ“³Ívië³dÏ‘I ¦Ô…õûæ!Í½‘’ì8í9þÂxî7ó½æ›¹£™oæâë¿ B½¾ò9AÀú[n¡9€!o^ßÜºŽ4·´´47µ´®oi%MÍ-Ím·­éó2H†d<ái‰E"‰+Ñ]­þÿ)üžÃu‡¢(9ÜD,„bevÒÙÉE„”«ÄÝF4RFêÉ
²rBëÚˆ¦	xÆT
©’Òšì4-ç%¼ŽkŠZàÁ¢Øiª‚^/Ñ Øiz¡šÐ„ò‰ÊëUL]4„Ç4™—› ÓLvš\ S9—ß
ö6†üÉNxðÙâ[ùH!eô{´‹êú¤JH¡R;Y€*ªíTÎ,ÈF›zJìT÷˜ÉN*˜æs—A[Ý`ãR.}ÓøBŽ/âùbHÖö¨Â|5±6EÑ 7:pà‹®d|ÑåŒ/:ÿÊ]\PÿJî÷r®[ÈÁ¶U0Ûi°íÕÂ¿ UÜî%ÜnÐvm^ÎÚCu¢ÿ®ãåó®ÁNô×Š+Ô¿IÃq@mUÉŸ“üøYL>È¾KX?²ú²oãŒm†[È«XÏùÂ¿!?©æéß7àoÖŒþƒl9(›‘êñU’éû Ÿ©²“„ù¬U²ýHÝ®Aú&¤) Ÿáô_…4	xˆãØW8þj)^ApÒž€úµ¼>ið‡†ãœuð}¼ý?
x—‰áß‚4øi^ß)*Ù»Ò`ïl{gq_ã{Áì)'O¢?¡¾„ë'ž`8˜ ž=‡½ržo0˜?ôã‰@Ì³'æ íž”,½s¯g;/ïyãñ@œD¢0‰¼~âEâOÄ|QÌüIšùúc˜%"!JëR4ŒDÈ†x~
ðtÝ½­ckw§ÇÕ½mK÷¶Í`ÈvW—gk‡›x6»îÚÔáòÜuÇ;;=;;6¹hT"°Ûæ÷&¼ÄÓ%ž {ôôÆãüaÁZx†Š°ÞÚg{jMÝÔ“æ©ì±5*yõh-?Z¹BâkGi&(ÍŸšµ¡'Gè8*ß°fÞ¬ffcêUZ&Óèg\NzF,dÊ¬‘ck¤.%uP&Ëêâ²êfanzxŸ)!Ï®™Í*Vkæ{ÔîÐÐ£#Î¡C#*ùÑÑ%äi°ÿØÑÝ [èÌfé´A„Ì™T¾Í5Ð^Úî¡Ô®IuÓ(¡ãÚNyV²)‡ ,»:ü\Î~jÌ„êÇ™ä»iþaV[^B:­~.ÏÂåh@ïçþ@YcÕ[ó²Œ(ÄlT;€=œùíµ°åÕiÞv‹òJA×iõëe¾Ú@£r[Ë€NU¶–N—5´/4ª¯þ‰CLÿ›Ÿ[ÓV2~´©äøÑº™#ffkg´ºËZWOH—ÔFfÃÛ#VòúQH´|-±Ó¾­'¯¯±’“#uõv˜àË¬=ø4Êwr¤­p-ë ›Ö.'ö%Bf-ð¬%'†bô.acÓd­/yýh5ïK¬7Iõ&^_Îë³Y†›8¤‘ºÌ„|0>i/9¶ý$ÆÕwe~š€~ÚýÔNò~²““˜FŠùÛ*ÚÔÈ}>[£qUÂ>ª¥|…}TKNŒT@ÛVòv¢¼ ¯ázJëmP†>jzÖ÷½ªð‹(+ãeî“&2q´Œ?#oÈ0Iu€S_FÀ#v¢÷Uèæ«#à«{ÁW»%_õ€¯üäï¡'àùÄÚ±˜·ÁŸ·ÝJÈ&:žë4XWñq¸¯Úauð…™´u-Ø*ä®¸F¹û‹È­àrÝhùÝV¹ÞºÆ¹_P§tj×¨s¨ˆN•ëü–"ü/[.·å)n‹ 9ïíÎ:ì@‹ãÕFJ­öõ¡~#×¿Ïq‡Yñˆë8nûð×Kü
Øÿ«è«ý5ôYúœ\ß•xðœÏýu-ò5i¼v\c?^¤›ãêÛÐOî"ï-×¡q¿,æ6‹÷|>è–u>:UhÇ½ä•p½nhËB.§Ú-@+Ï%g³ŒçJ·4 7Ÿà=÷|¤Ç0ôÈÿ¾±õÇ˜î7¹DÝ¿UD½˜u~Û®{õ}œ½aùÅ¬z®)€W·®PÁîº}Sfä[Aj¬2^cÀ—ð¥|‰_lÀð…¼Ú€Wðù€Ðßÿ‡®¾F«}H¿æê)»¶5Wco0ÜŠ“/!°Øn„öôûc¤ÅÖFšll­­lŠ´¹-jƒ¨ùì! ç¿*Tò½ÎU`èì<;dHk¿¬÷GpïƒûÜãà¾÷2¸Á=îS¢œ÷ ¸ïÀ½ÙÜÙy«V¿yÛ®›µV[«­EWÒfkþ5J¸ª`ô¢äÒo@ZEØ^ìJõ£å´~B®o‡Qt=¯Ùry=–ˆzæ7}}TÏí+
Ü¾â`‹?8ðöBû$š÷‹§`öZQbÃínÁlþÃÞ Øú½ñ~Š3Ë1¤‡žî‰l[»Ý;@d²7Nltïg‹EèÞÈègÛ:bó%"1¨ö³ì>ˆ`$±¶ˆ ¹/¢pÿdóEaÀüÞdŸÍÛlm!¶(¼:×¸—ñ	›b1"np#aq¤c1*'€“ âk7ÙiÌéÉÇIã*·ÿ@:ŒÍÝË¼LÐaº°Òa,iÆ&Oá48ÉwA:Œ=õ”°˜“±[ø3òã8	ÂC†v |E¢£±xp[òtb3÷Û¾wî*÷3ÊóIt8þTØì.@$ùþˆ]´Z?;½Htc@7V—!Ëû&§c“p`)@w@¢³ ¥]J¢SNUë}B¢ÃX”¦âšüòv|[¢Ã˜“»ˆ¼?ÉÓ©kêQq]£—‡´Of7Ê›Ä8¨Êæ£Þ9¦J(Ý=.êÆ¤g¬¿~!Ñ¨;n§ÝTv,ä¶å`!'
È“c†§—ÿJYœ°äÇý<ƒ¼’Z°Sb”m2Â>²Ìœ
ßk†3Zgfs8k¾go-¾wgo»˜‡Í4BGr1F3Yî*³¨§˜—Í4ÒÊÆ?ÃYv,‡W2yüwÖL#xlÜ2¼ŠUçðjÖžÎF;‡³NíÉá,=™Ãõ]3Ÿ!ïÉáKõËør^cÀ¯ÓõS	ù k1à‹ø
¾š6˜Ù«€?padÉáU¤ƒäý§€ÿ0–©æê«‰—·W¡øb°ÃJ^Ô«äë×sŒÏCC~êk8=Æ8Õò|½Ñ¾g0—ìÃƒ…JÉ¾qƒ}ÿ`°ïgcxyùFÿü»ÿÈ€›¶î¨W?þ6à:c-Ç—*ùñ®˜Ìäz…­3*a¨›Lr£¢©Iê0=­Š>ÆÞ¥ècìNÀ›DŒÜ¤’]Š>&üUE3ö)ú˜ò}’>s¦?&vr/­·Ç8ÎôYÈ·}Ìú}Lû»Š>Æÿ#EQÑÇÈbøo)ú˜ú}ÌýŒä¯:àxGÑÇè§òfýB™I†0ß¤ù«&ý™ÀrS^ßBà°Js ©Ý¤×÷e©ý¹Ó¤?“ ¾X¢Ù¶ƒàú×j6–¡2XÃíÙ%OçÎ»¶{\Ý;vz<€ué0‡ÓsÇöŽ­Ï&Çæîm´èÎÎ\=,Þ¢¡@"à·µ´lh'QÌÖaü?âéEz½!]z¼É}$Ò{_À—°µ´¶µþ÷'úÛºòêÂT‹ç¼_N4*móÆ|ý¾þ€ï~l.æXÀžpC&N;«ÈÅø=þ`<Zà¬ £ÿ<âé÷†ý¡@î|ðCˆâGâ°€®žé‘†8¨N!tÇ'ü”C>kÎ8MÎ	¦ç/üx¢ðiQÐ~pÆJ
¿ð£‚Ç5ì@fþ¯ƒ¯ÿþum½ÁÏõjÃ•ïÀ‹¾¾5wÿ£¹e=ijnnni»ÿñE Þÿ0éî|™þ¶‹õ—O¬ÎóØI;üªÙaŸ¬ÑÕo©Dg'v]ÞÄ{D.Ö2¸ÊÆ•u”—GMv]^ËéD.ïÄ¾Yh”ó°åp.;"±­¹ž•Ö\ß£Ëws;zLz>~ƒØ9ŸÓ‹ü7Lä¢}bOÿ8—÷8o—È5–üžÉýË„Ÿ¿Ã–ùÛuy§k3ð}øÊÉµƒ°s;×WÌ/Þ.‘‹~ZZ0,í¯IÆ6×µáí›P0œÜ×°¯}]Ãº6<€oÉíóPÇæm»(½ðçÇqƒ®AZlo¥¤C‘hJI>>ƒúqç…»­ùœV!WÞ3‚›HþÎŽŠ”o+RŽzµå+ŠÐ·)ï+RÞP¤üî"å«Š”÷)ßY¤–}‘0[5ÀL\¯XG¢ÉD\,Z¢±`8±G¬Šèr§/œôôºÀÙˆÅƒ‘0_EÈ‹¾´ñ0:¦….‡6»º7uzZl-6·áY*íw“áŸBwxùØHrEpR=Èñ©U=4Çq#ÇfˆÆÊqÌÉcÆ"•Ë1U*—c5R¹<iRy™T^/•Ëïw“T.ïÛ¥rù~•]*¯ÊR¹|Ì-•Ëï˜sø¼%cdîÄ?ÝeXtÒr"{ËÓ×i$»úð·z•žïG–é)<\XýGˆ£ë¦')þûˆ£Ë¦'(þâèªé1Š@»`úÅ¿8ºlz”â1ÄÑUÓC¿q4w:Jñ^ÄÑ5Ó=¿qtÉ´›âÛGWLÛ¥Øzó{Ý©Í™ú…søìŒ{g÷©‰™ùvâ<õ©ÄìÔØ'g"Àpat}áL—>Y£çÁ‰„);I]1:tûRMv9S¿LTŸ»Ñ9<aq¦J?²ìO€þ¤O«Îƒ?Iž}£ô]À”·NìrßþÃeÀ…LË^¦®™•ãí0w§N¼Õ‘}ç­££(ÔùÐù¦†#ão‚]”<s3X•rd†3d_Èyøo¦>ÉfÓƒ™Wpgž»„•çÏ<iÇùáYû^‡óðA$s¦3Õ/<•då©ƒoÃöÕ¹QlÅØeç–±g„sùç4}ÂÖ€•Ãç›œ©Á3Îôàj*³r˜23<8Cª=‚Í<œœJÎ¼‚]‘)¥µ Ïüó§Ùìðà…Š¤ßyØ1Î:ÓŽÙêí%Õ/N¤“Ãƒ“JÂM‰¥çnŸ?d^žSÜ÷“smãç°èû¬ˆ6¦ŽJxÉ®V¿43^¶@8ÎçJ;Nç¬ïI¾êL%ÇN9pãM†_5%50F;4Ý~¼v—p"YTŠ úM™jR2ªELázÚÊç¦ûL”Áœl–n@c¨á*Tdžål¸–ÿR-û”öÝ$øxò¸E_¸HKÎ8‡Ï„ØÏ¼>†zê`©#^¹H] @Ñ‹y^'fËÄÄ©˜YIÌD!2%»xî†B•LÆ)ÇEŠNÒy*ÓÎŒ yRŽ7u‚™WU¬•FÑ§?AÑgæq1§>)ÒÊËÄ¦b2F1F²=”ì<måe•ÝLÆ)Çy6œf”doÚqö6Ç…ý7§™Û³ûëÒ[Ï§weÒÉ³ã¶ÜðüËqx>Gu;¼¸H°õl:9›¼Ð‘z­#5™úÔ¥qgŽaˆ1Ð!_Î9ÓŽçpúýÏ{lÕ«fóy*d=ãJí·Î:7˜iÄuøö‹!Kù­S.¨Ì¸R	ëŒ3u¯f·óí®›?íH]êN}è|íSswêtæÜƒ¾—¨mþ9Îû®Ô/\©÷»RÿÕ‘]òoÎáŠsÃ¿$ßu¦ïµÂØYUWÚo­qÁ“æJ'¬õ®ô~kÌšíh¾w;šŽÓê9œLÓÃ¸
uŸ³8‡g³É÷vÿÎ['èïÏCéTKïÑvˆsõ®@"àKüZkìjµŽh4ôy¸˜ÈUÑ¯®*öö†Z"¢ù)Ñ­ÚjžÑ7ôêNèx"îÓpñ¡Ýµ¨lô¿
}MƒvGG·ËÑ¥ÕÇ$ƒ1ÐIËù²FûòíŒs­ÖIˆÒ[sÒn†£¬4ß†k>üÁ«æºq,AŽ±êý0ð"Ùn˜Þ„¼ò)þû%Î3•ol'Ê>U1W–[F¶Â4ûºg‘ £J}ÄÔ¹@¬5°n#¤ß²ØÙ˜-PñWüýû™éòz£Þ•\ïÎ{èSöË! /^`û† ÏÙÈ#¦GÊöTÙ‡ËŸ0.y\¿Ç›ƒ9˜ƒ9˜ƒ9˜ƒ9˜ƒ9˜ƒ9˜ƒ9˜ƒÏ²ŠáÄYˆ8OgMü~?Æ$c•g*â>å‡—²Ìg9.öýn~¿RÄjÌgy.Î,ÄQ¤þvbþì%ÃÏuDÂÂqq¶"n/Öóûœ¢\å¸8kúæðKYÖžn–ãÂO3ÿ)¯ÿ¢@œWák¼ŸÂ<ÿ]ž?Áóïòü/x~œçÿÈóåùû<¿Äs#4qýº.0¤f }Ä<½‘ßCý"Æ•ð»q\a#•÷|N^'çãìo+õ¸þ,oOîØ¯ÑØ5úb‘x<‰„Â}Í¶õ¶¦Æ„7ÖHÄ÷µ¯ó¬kkH†ïG¾æGÝ}ádco2ò³¿lôÅ“ü²ÝÕÅÆc¾Æ>úAP‹m²â1¹Ö±Ck±µ4eˆ»ˆûÁÁ>cÃŸ‰±ÊB¢–í*3[VZV[£ÿ//ùkÚ ü(Ê'Uà¯Âí•Ï¸]D\y¤½<Ï$Æ¹BÙ’¼½±i‹IíP! ¹FÙb*eebš­Š©ŠžübÍçÍÃ{EÎ^1ÀÍÕ
/Óq^íÞÁsÑÜ<M}çF0Ê9y.Ì9^„ÿZ¾G
G[Ç¦î†„·ØÀ5E¾GÂq“@F<1ü¦)äEBþ%ôß/þfÉƒWù‚I|#E¿]‚?L6“£ÿ”‰~ÉäñÆ¼á¾@\ üK+VÕÛìŒ„€xæ<ÿ{¿‰BÈßÃbx­Þx_¿•’ï>äï91\3ÐçiùÛ(±.ãN^.ægù~B3¤à7Uð‹uÄ¬Á~#¿ ù›+±Î¨á‡vÞ`ñ–ñ÷_þA¬[ÜÜ@±N`ô~£••ìë‚Ÿr~ñm°ßdÈñ»ªK¿XwÌp~¶_ Þ*‘ä‰uŽÊŠvý'Ê0ð‹uS=g¿šˆVàßl‰už˜ošÊôtŒãg¯ß™›o>Q„_¬W2ð‹{*_ø1,T=J5ð‹ùqŒ/„«ôFûýû7Áù'8ÿ?èý÷þü}A†XFýß7ðOrþIÎú*úŸ'Ò7wD¾?Èp£¿Œü/øë9ý5òÿÝÿ°w6ÐQUw¿ïÍ˜ÀGóa7(ä$~ŒFW(*‚b0|LÝ,$m¢-a–Ó(tµuÀxJ]»Zu±r”í‰’%ÑÃîf-]c›îêhfÏ¦6Çš:ûÿß÷î»ó^2¸@[ïœ7oþ÷þï÷}÷¾ßÿ>%|ˆ‡å9ë«r;am'Â[|'“Û¤ó_/òõ¦’¾àÇúòGN_ÿU	/îS<|Ý(áßQÂßÁ¹­;
˜¬ž?j~~K,Bš_Wà¬¯öŸ÷xú*«-Â+&„6Ž·~’>&âÖÊÃ·*îjøÜ%|F—)žªîXÍ9üÃ—²£º@€ªp	¿—‡_<Jú.áEÂ£•?ÍÆ’o­<|ñ(éËç¾¼5³c±8sˆóý¯Sú+g²ão”ÈO†·E[Mq=bw×Íë»»Ç¼~°»æuÝ}Œ9ßÛÝÇšó¸ÝýÇûv´ñptgÎ§v÷ñæ<iwŸ`ÎvwŸ9¯ÙÝ³ÌùÊî>Ñœ‡ìî“ÌùÅîî7ç»{¶9ØÝ'›ã¼Ýý\sü¶»ÌqÙî~žãs	´)ã¨Ýýs|´»ç˜ãžÝýBs<³»;¯(è±­v'»«WÁÂý÷<÷ü47<ÐfSu÷º¸£m¬í>Wi÷o¸èÓ4ÒÛk.a¶¬j{ÝDÝÓÛk)Ow±’.½É•êYœßô‰(õåñlÏ0ÿßãù/Pòçù/UÜBÝ³©=§¼½âR®Ã<?«œnõÿ®‹ûû<žý¼\Ïr÷ÿáîKØ:Œ­‚mÈ%D«5=½Ÿ_HêÉ$ äÿr÷y4žôóëz´Uu8_nÑœyþ5Ô=‹ Mˆ5W4pwuüit‰g¯‹ûÏ4g;ˆv÷c.ñ|@ÝÓÇ½¤‹þ—.î—è8§Zã¤¸Þ™FXJ¯·Ù¨¯ç•ŠûõºsüËtVo„ÇßÂÝïuÑÄÅýqÙöªãÛ^ý—¸þ&Eÿ—x~áO7ºëY”Äí]Þ!~Eõæ/|¨R\c³-^µ~½d$’¹‘±dQìl;lÙÏ˜UŽvÆp˜yš¬ˆG1^³~ít^ts[j¼bÕ†«¢¦·6nt+l%C\f:SU%Û»pk˜šÜÎ—©:™ÔØRû5.›ýŽ“Ý/Zò(h²hÇã˜1ËLGñ¾ñ›à·ºö×¬VŽecjf(äZhab]Ù`×aæFj8Ë`šY)þ´1˜¥4ZÙ}™58Mðk±ÕDî£¤ôéLcdûßò²ÒRÓþ·|Öfÿ[:ë¬ýï™ØÒ×g+äø·^|v4Ì_âúïãH)„k[sý÷fÐïaq—×ÇûÞÅ›/îxÍz.±Öv7Sƒ°¸œ@îòúîI°?mxq‚®]"¯ï^þEà‡;2ð¸›=ÜÑÒ,iã^@Øµ„ðC[Y§ºëÃ£M¬œ>Úk$¥üSÛW§-Ç¾¾<}uÃL[G´m½˜×>+ö©YJÔ¢ÎDýŽ%–íÆƒu‡÷â>’¾ÕHÿÅšÝbÃz‰(þ*òµŠŒwO};/æ%r=Wñ¯VäŠ¼\‘§*r±"ÿ•"»Û˜*Ê29-3ÿáˆeYjôl’mOu›íivmm¶ævîæ§²NçþÐ÷pmÒfxqy {ñÀ‡Gh?¡ð"Ð1rñ¢ Ð±‚x„ÎU„Gè(Óð)ÞÞòþmÑ¤‘À4ïÚ|øôÇØ.\ppÛÛõcÔRêf4ö¬ƒN‡68©C³Ô”aøÅ0©)˜CÙÖsÊl/™­'æ8‚Eä¶ž˜ó>Bâ¶žX‚H1m=±$‘"bÚzb‰"X¹ÜÖK	ÓÖK©"¦­'–4‚ÝÛzb‰#ø6œÚz¦¦`É#øêä£R…i)ûï»[ŽSÓÏ[#¥;0Vø¹eIäÜïÞÄµÌî“×Wó¼DCJ@ELÏ…Ÿ×‡ôw¤ú³ª~4¼RmèøþŸÝ³áã#c0€vÇ]ËCÑ¤7:/ˆUÈí=·µ×gE“¾º¥º£~jïÙòþæd4rçuAz/ÒiO@–ßµì(7=ž^vn@#3P…ZŒ`ânOÉ¤_RËÏA´ü¼–«¢Eå¶AÓî3)Û}švŸIÉî3)Ù}&M»Ï$³ûÄb…DVca/¦úÛ?Ð<D›É¤í»-ŠÇ¹áYVQíSª6Ä¥¢/Ñúsh|ÃÔ
ÇÂÃ¦égO´©‡š~öèõô_5’ÄAÛÑÎ0ýÀCÿLp<'ŽÔ¶³—™b$Ôú³Ó•KQå§0ÃÅÂ½oÞysÐ€úëa(Î-Ñäâ–Üh/îˆ†ô†Ëb·wÄ®1¢íFŒ¶K¢ÁL[¶ xÛ)´§)ÚWrí¦•È¡ÔõÑn‡ñ4ÌQÂ\ÅÃ\ÍÂ\,¼½1‚Î[y·ê´ƒ\ÅKë³CÓÌô f5µì6õ’úéPÜ#VsXÍF5¤š m×Ò#ú)¢#F4}˜÷AQ·‹ÚXfÚ?ÅÅÿÚ];Ãøè„$>Dœói°îX¸»%|ÌÊc7úE¿È °T³…jöÉy”#šóE…¥šUÌÞt„ÂRµ™-¨Sa©ÿgŸÓh:ÃtPŽ6%µ†±pß•áÆrn3zy,œ€nì^ðåú&lýjÚEO†ùL3À4ýLÓ‡'7ÀÃ­Æpm,œ°íbyêŠv,¾sùÎUÃx†/?¼³þ2²ó]Óä¥KnK|þn>ü“ó ¯I_âùÏR©¯ÀÀ°3Š¿S;_OéÛRõÁ²Oca?KÕÇN}ìÕ©ÝÿˆZÑ#Úì/7üg´Ãw×Ý+–ŽåÙøwÛkxnÿû˜­Aq5Çb1wAß‚2Ü	ó^'áœûu³=»ÝÎn§osZÞvel5¼xÖÎï¶Ã=&ÞØ×ëp<2ž¦øŽB|Lþþ× gtífÂøc|‡‹|ë¾¨áÅÿq8Rˆ“XßCÆg=¸#+„yAŽxQÔP_Ïg´=m…»	Ê²ö{aö°ÿö€ýUØß‚ý×°ûç[¥ôl o‚¼n.ë¸ð†éeÅ3ŠËOVá+Ä)Á_‡³GÕì‰>¶á¥¼åõf™ÞË¦^éVÖÆ=¼­Åö3+¾4.x£ŠwBöL¼³vfhæWƒGŒqÛ5œ·]QVjnËfÃMªÖ\Klhovó_R]IMMåCWÏX´ªxã©K,¾÷Í}ÇçÊžªÊ$ÅÅ%Ú¸zMÝÆ’ukX³¡¶Ff~¥÷´YÇèØC<YZaIá¼e…ëÖ•”PÚ×ÐÁ;'I¸Ÿ>ÜÑ’\æX¨aHÊªb%€]Ë“§2.wŒŽÌ3Ír!Ö„¹¹vLú—;¬óPøcd•°c½’ÿÉó´_‰¥5QÚLIÚ?'vVfdé3MÍþÝC1 È,,}ö¨¼Ã”™UÁ¼âÜ±]cv†¤‡û,b±©8§à»Ï>V#Ö3ÅùÄbPq: ³¹GÍßÄbMqîXäa|¬HWe$SŠsÎzã»ätqÃçŠãxœ³âñÞÜ*Êë%=œãöyØÜgðò	½b±”ØßÃÎ•‰xë$=ìó•àÑ­èá.³¥ø<™ÖýÏéÄ€âùÕ>ÞÎ=‹të‰åÀs¬w¼Ïzß“ôÀMÕ	Îëüÿ€Xì}Ö<Éù;m’>PÊuÑû{I"]¾“ð±˜Gú}{~.ãYŠŸE8Ä‡û«’^ÛN"¶gÂBï°¤WÚfxK]¾»ð&±˜D|brÑì¤ØPïyI~ï(z	?3›ˆû5>¸»Tr?Qô–M¶s‚šôGÖ{ôòâó)zmçÚ¿ƒ!ò§²~} w‘C|*Ó¼ˆñÜdäï)Tæòo~OÇAB¬ï)DL™E°Ý”Y
ÇL™µŽSLf½N\ËšßS0e ÆM™ÕÆ>Sf–`ÆV!³äJSf‚xþ3™½!iß!dö¦¥×”±ç-“Ù÷O™¹¦Ì× )3j¢È”ÙL1`Êì…Ú )³;<˜Ì¾§2åÑ¿§`—/Rä‹9W‘/±µ³Û÷DùqõÌB©üÈZ•HåGVÏýJ^ß:Ô÷­¼<ì‚èúý|&npßï|[ÒWÓÇq<GJß—ˆöÁï%ü’>~¥m‡ßA%¾ô‡ô^äþ8Ž,üÃûÏ\~GÑGÆY´2UCR}ÝOÆiv9W³Ú_ÓÏ%S4«} }K¥
ÇÞR…þ;Ø=ädH‘fõW”—Jú°¯Uä‡5ÖÅû¸ÍJü»4«¿#{ôÅÿçŠ|D³¿ßû•âÿ¡"ã;)Q>?”/ r%—³õóI!~¯ài!g“bñµÊ2^>ùûß"E^¥[ç²J÷cxIÞ èoQô[ÿ§ù§ ÿPÔî# ãûžK<L~S·Æüžƒ`šN¸T1cAµ«7¡4k$~éÏY²S4¥n¸RäÑŠµu+"ßNC}JÍïK»âF¥
Tª¾+V£ÒQð©²p%,³sJ*ÀUªRX¥öïGcEÛ‰«R'©xSiÐ„qáMr1¤®fE}î–‹ïÙôµã˜În_müWùiùº$ÛFá¿J+*KÍï?€ˆüWyÅYþëŒlnüWëVÆUsù¯sHü^’Æõë¹„à“Ð.* ×üø¯¸DPø/êöø=Åø² ÂpoÄá%îÌá·¯Š í¢“à¿Dø“á·Ð}2±ø-¼ÛÀ;•ßÒ¥r‹zü–¸Ãô^ï	ªŽ8ó[~Eþÿ¿Ž3î¹ÜÇÃß¨Ä‡v]91ëzO‹¸ÿZ.ŸÏå-\ß<XÉå5\6k<}Á¸¯ Îü–ÓLo1]Å¢ßO²ÏÙ”âJç²ÂåHwq¤Ë‚Á(†˜˜3ÌÅïfx.ön9HÒy®ï;Ïõ4÷?g<Woœñ\}qÆoˆ3~+GèÉ8ã·âŒßŒ3~k(Îø­á8ã·È“ßÂU‘Ñ%1A­!’7“ÔŒcqä´zâ‚ÓÂ”eNs sZ˜™ÓÂÉœæLæ´0‡2§…9•9-Ì±ÌiaÎeNK`qZ˜1™¿Š `üÕ>¸?KÜeã¯Ä;?d0¥¼]„?¶|˜.uM7V7Íóü{´òõçFÛù@H½ýbþmo7ôƒþcúÏÈ(Ä6Y€Yã: º¥º™N“•‹ðÄS1Y?¶1YïüQ˜¬ßÉLž¯ÎLÖç6&kš`²îÉ„É
bŒ“˜¬
pœŽƒ“•Ç™,Î ,Cÿ#YK—ÜM6¶,8Ô>Á4!duMìöC˜j	ì¨ƒ¨:Ãûq`Ž5Œ5ˆ-Øÿûg'=ñÆ¤ÇÛ·ÿ{ÑëÛ»&ý¢áZ'(®Õp(z•ÞPk:»AÄôBgø¹4¦}<¦bMÏÅìsŠ)+qœVXûGÏé<>OÃ[|máøƒ4¾'½,¾¶XS<¶àI§ø.†(b×[˜WÙ—,ö›æõVÖ+ŒR€¥Bêz,ÚtŒÔ_s–Ç• ªôh~ý…Í_ŽM[ùžEÓå¢ôUp¥žžb‘ð.$âñbkøwÅÂ]-á£V»Ð/ôE¥šWQÍ+‡r4¿û<ƒ‚RÍÿ¥š½®¥JoS¥>§‚Rÿ—X$á>tŒ6 xWÏ•áâ]½W†“ˆwqL«—S=üÙ‚­þÅ´Úéy5Ÿi˜¦ŸiB¸$—àáâîNNà]í,OíÑŽÆ;ï^A/6f.]r‚\OÄº^„I;ñÄg©5^dH×Î]ìê~}HŸ}dã…œóênAÒ‹ó\×ÏþrÃ  ¹Ø¸Ú’l©‰*ï’ÉöØZŽLý–dhëp(ŸÈãiXçÂ'‰0æ57ƒZ’2sÁ3xJÕç—ýfçÏi6ŸÓA4‰~ýRc¾•çîlüNN„]‹)n¬âscnl^Çà%EG”±-ƒüù_5g[ê9Û²›³-hgëÄ¶tÇÛ‚×Ž2ÛRÏÙ–õ.lË\…mÉûŠl‹·Â}qèp3YØËa¿ö[a¿ö°o‘˜–aè'2>RQ\×Ÿ#»T—á…âˆ.™„â:ô›²2§2Èùl¬ï_ù]ãUÞ7õ}1Ö^ïFY;ˆí8±ó*ò:daQZ\YÁñ	¶b]MÍtšýébq7È8g-Ö´¤Ý)HEþoGNfRä„’~];rF
©.…w
I)•ª‘ä7ˆøž’(ãMåôV†}ý¼1:ö[O‰–7-oÎÒ<JÈ€#vbO8Îa+çÑ±;{ÆsµÕ«§M›>'²/m¼R<`•Ï&Ïdç	ð´òŒÓ¸|–­1ÙšL7™¥¡Ï‡2`ièsœXœ«ª3`ipÛKƒs^½Îæ:52KƒsU^,Îqs3`is3Kƒsj½‡Íµ#±4xÚuxˆíM²(‡ÌÒô‚^/èíWêYeiðÙ`+8®–>TèÄÒà0ò*)"]™¥	ÀY˜0:K“½d,}n8at–fô†\ôd–oüñâh4–†>ôÎÒàs £ñ©,^Kuûìk¸9±4ÆH7ËnûéÄÒà3–s9T–õ‘d7–¦5‹­A(67–&zoeÀÒ¼4É~ž»±4oƒÞ½ñ©ŒÌÜlÆ×¨z*#S}cÃp…|êÆÈÁIžFbd
#S¤02Õ
#³[adêF&Oadæ*ŒÌz…‘©W™Sf7½¦Ì™V“™a=iPad&Ã™¤ÂÈàyÇd6™2_.ngdSf3ÀQSfŒL·)³;ìçLfŒŒß”O?#c—ó9?¡ñ)r‘"—(òEn#ìZedRö+þ¸î¡¨odbð<2ål6–Æ-&Ÿ•Ñgœ„17¿‡£oð?Ÿ®£×'¥ç—§ô‘q”ÒŸªñû'žþLÍêÈè\§Ùó³HbR0~µ>dÆå£ŠÜ£1ÆH0<ïüÈop¹_ÑÿT³ú28?ùÅ;lñyó­„1)È¬ˆúE†¤\·ÎôŸ-°W+ò·tv¾ˆw*5Ü_¼“iÐ­ó™œïèVÏÖÏ#qý>ž¿•üâú<ò;›áþâÍqY¼³ÁGÅ¢üÈèøðúbÅè\2>j_ÌË7•qâÏ•\ïxnöXçÖÏ{}Ý§È¿¤¿™Ç'Þ=¦èïSâžë‹wHÿò«³sd|Gp?gvÞõXãK6Œ/ïy¬ñ2<«î©N/Îo“-j+B3KÖ¬_[B_'_úòEgæÎùT,’$QE3Ce¸ÒÌY³]¤Ó³HÒ™¹Ïœk:(‰dØé”QJ.pÕŸ
»ôÿÃ•äjN*6æˆ49°dn”ÓˆL“ ÐÎÂM™l5‘ûêêj*ÊOg#ó?e³f™ë?U–Í*£ë?•—ŸåÎÄFù]ºXÒéÅ·æ'Å¸	¹à(u Ð7èåE€ü|'ì2w	Ò~¾†Ãd²ÖÂ™ÔÅvÏ²‚WŸpÊvaÞÖz>Òx.‰?~t'ì–[A€´ Ÿï„]’¿ÕõïßâR4<ç?)ãî&þ#Ø’ŽÿàMÀÔeßOÿQÑ!ÜŠýZ6^Úmå8–Ù`ìàWä- ·å=\!È+áØÎåAŽHñÍñ“‰ø>ÌÈféW€?^j¶rÿµ o‚c—[@n†c—W‚ŒX~=—Ÿ ¹²ÙÅåVñeb„Ëß¹Ž<Ðýu§`±Ð ¬ÚZñXÍòü ûyt™X¨èz€ÿ‡vÖÎãÿ¡ñÚoŒøm7Vü‡vòŠÿÐFãÄhŸñâ?´ÍñÚÅ'þC›d‰ÿÐéÿÝ…©¾F¯þl«F‚Õ„\]M´ìj2~J3È^Ï³¡BR°°™4N°iq!™baÐ¿ù=Š½í¹‰=ÕZ–!âÚõ:É¡ñi¾mvéÏ6ç¾ëºzña8ˆ¯PÄ]‘‹—†÷Îo÷kG`{^ö±]Ç‰¯JXµ—TÍïók›õl¾‚’ˆs/	†&£i*ä'ß?°°Ù(”ý«ö¦N@žµ'!H3 éy£ÇY> ]?-¤‰icz¨ƒî<Ÿ¦ß<èõóà„›=•Ð}~?Õà÷c¾ žæóàS»¿è¦å>nLkÕŒÊÆù6Í+ð“PíÄdâ¿ùHÙ–jmÂ÷W^¼©5ÂÃNÓ“æP>Éi~”Ï¦P›A@o×ó£;†}ÿÍ¤ªjY„úàçÛžOr“±WA<Ô«ë¨5ßÈ>P)ùéÜOç~9!’Jñÿ>ñ¿öFgÓæU„4C[ÐvíO7­ºko×vV>2Ê–¯õQRù+²Ê7þe3ß°óòay…º¢å#ãAïÇ\Ï‡îô±Œ‡¼nG}ðónþ?ö®¸ªêÌŸûÞ}yï‘¹Á>%À[›º±yI$h´AcMh³’¶ìÈ¢Pµ¢DH×8‡G*®HXW4Ñb—.ÔÍv­:Xq×v‘°+­qjþÁéÄ.Ý¡£r÷ûÎŸ{¾{ßÍj¤NÇ—¹¹÷wÎw¾óïü¹çÞóï~™E6F™‰å œš–ëJ^à:‰å•º>¼îÆöôÅ^-Â'b)ôÃÃ‹‘wg”YuÌ¼FÒ£|²ÓÈ§x½tI½,½ÔI½Tlí`•’ÊZ!ë!ùVBû33pA¾<ï&V×Ñ×P'²Ä¤¬4må0ik íƒ$m|ýñ÷¤~«jX`HòBÜÂax,_%<
%]DÑ-°Ï„ç©³:H•áª-\QcDT;(„¼eÿª ž…¨“G§j7Ø„Î#©¶Ãé¢¼ü”g½Ï%£ð¼^µ3Â3åC7MÒE meÇ‡?V|dF ìCÝ@úŒçm”·›u,%äÿhºHyò{P¦IzäV<¿1]xyÎ“i
|xRº|I—ºðÄç| øH]$äX†cPsFÈl­ËÔ`ß¯ÌˆübËv³$ÓÁ’™—YAæ–|$ùAûb•’®è, ‹]2c¯ý½²T‰qL¤…üªFê¯Ìhërîqë™Õþ‹ã½úoÞï®í`!q¿³­Û÷[èKgžÉLÏ°õ×dÌæ(«½ª—±ºèÐËpLµ>™11®¹€Õ6O›Òð­^ëJ¸¾¢9*îWÙÌhžq¢j~Æ>áÜ+!ÏÖ§ø=,÷°uß¹ç"È¼cëzkj×½7¥áª÷l»8ÊïÏEÍÁ¦uØ”-ÐLƒþÝb‡>|÷h2½Õm7¼uÊn:’kgŽÌ´7Y`o=r‡ýè‘Ívç‘Ýö®#Ýv×‘SöóGsí}GgÚû.°½Ã>|t³Ý{t·}âh·=tô”}y=Üm?ÿð){ï6 Ý6Ó~uÛ{ÿ¶;ìƒÛ6Û‡¶í¶{¶uÛ‡·²µçÚ½í3íãíìíwØï·o¶‡ÚwÛ§Û»í3íPÈë5ë5ë Èu ä: r ¹€\@® ×«òê¹ºA®n«äê¹ºA®n)×zk=ÈÕ´- WÈÕrµ€\- WÈÕrµ‚\­ W+ÈÕ
rµ‚\­ W+ÈÕ:Žra›EÙ°^T›‘/ÊIù:ó¢¤eÌ»Ü2qŽ†shKe¢öG³3¶ãJBµŸ¶"æcC|ôcŸé9êûw¿öÎM-ãáˆÅÂ[-–[Ç1œ§Ážo$ƒ¾a,úÚô¡Qß­úØgÊœŸ= zîÖÏßÚDÐb&ž‡çE´7áùºÎ!‹Úàœx;Ï±¸d”e"ÏøÌ‹Ï>H¼ð9ø"‹Ñ=gGÄÜ¥ñjÛ>áu«…Œœ‡ g};v,?(OŸ5ä{ýû#Ûý14ýãO•bíWêWéÛ‚órævQÀé}l¨¦—Äb¼±Öá·_ò)fî-CïÈ|ÇhØ°úž•kn™U>'õé™žK&#Ìe°X[x-^ÄCU:â’Jý_­Y¹vÜ%’Å¾åŒ÷“G¨¼å1š?u•ÍHq<Uîk£˜oL2F°[„ßË\-Mæ9Zü}õxÍ±ÛËŒéŽÁö¿à €†,æbˆüÍ˜îÄ¢a†»Œ65¦rŠ­
–6êLLûD—øGLú£û»\ºßŒ{T]ŒÖ–ÓÏ«½å9|x-žJG±¼„ûv)±¿)¹æZÉ…›_ž?LFÌ0Åûyç½úe™aŠ÷èÎ»tõË2Ãó>'¨%ñYf˜bžÀç
Cl3L1¯àsj‚â˜aÊ9A@Ìøœ`:É×1ÃÄ9„¤«cüÖÓ”t'Ÿ‹Ä<å@|'¡ƒy
Ÿ»´É°‹	Ý=’Ž¸ó{¹ÛHüî#t•Œš}èZ5ÎøÁ¯>`Ný^p˜ñƒÂÂK÷°¦›ø*ã‡ëç5¯¤t~f„ês²A1oäÓ?óÊ t‡/Ý?:‹O_üóýB:¶âÌ=ÇQíe/“æšbþç¬yÍ5NøÞðð•¯[Ò…î4ÐÁ!×4‡4?œÿæ{÷¶(~ÿ-óŽN•c¤ºƒ>üœÏ»]¤£úSüúÉ5“t~æŸžÏµò5Ÿ&B§äõ|–WyßÌægä¸éâH“ö¡‹{è6¿K}äó˜NÙQI:ùç´j9ü!ÏkÙ°æŸ_ºèO}øeýäº'_•¸Pâ€ÄÕ%Þ.±)0óK·ây'è¸Aàcâ°ÄŠ^ÚLñ1	qT`SÉ3AâJ‰sæc	â˜Ä‡%ÎXŒA¹¶I07þ”Ï‰ˆ-‰¥m¦0þý—ãI+y.”XéG®ƒñ>‡X®Oñ¾…xŠÀùŠÿEœðà‹%î‘ØeüdnãÏ ç“÷A·ù:âé<Ãƒ“ügŒmÌi7&³?`Ät[â9\éÁ7xðù|ˆës¯'þßUý¢~ÞTõcˆúPõ#Íñ†¤¾pˆú²!~HÆOÆ~ùuêüŒ‹…—N|àæáå3ê€¿©å3êñ9]ËgÜ¥Ú›ÁÛ›Ñì–×Øˆt$¿'ï ùyôg¼àÆéü%×«{Eú@Úb90Î	‰¯öÐ×xð7=øf‹åa™+&‰ôª}'¹>ñ(ïÿ à}€Óÿ`ÔGµÄ?€Ç‡]€-‰ÿâw®•ø%Àx_+–¸Ûm?8
éQŸU2þ]À8–§$þ_ÀXþ¤Ä6à Gæÿf¼ð*>øÐ?ÖO¥Ä%üœ°'@<è·hùƒ‹,1¬,”ø&Õ^-®¿à*9^Êøµ>Iò[¸ŠðÛüð~\âÇ,öo?ù|ü
>ñ1]þà?Cú´þ‚¯@yÑ¢@âÿ Ü¨õ|è»ýåõ}üðóºü¦sIŠV1Éƒ/yR:?3í¶ß0¿¢ÆçI|¬0‚<[týšK ¾Xço~ò/Öú2×àûPY~/Íû@¿ü;*ùOÍvà×£õiv¸íEÌ½Ào‰.¯¹0ò«‘¸òOèöjöŽú!à¿à cþ1Cà·Q×W(î¶O	ý­ŸP
èt~¡JÀ·\ã¶g	}â›´>B· ®$ù­vÛ»„Ö»í]BOAþÇµ~C?|Z··Ð€÷òüp“n_¡_ªþnñþzòïX'ãß¼]÷¯Ð¿Pæ8ÆÛ¼WuýäÄ'ôx’“\§ë#§òßKpðÃñ8!1´§¼3:ÿœ:ÀE$¿å€{µ~r`üÍÛCø5>¤õ™³	òë%øÀ‡t}ä<ô5º|9ÏÞªõ•ó"`S÷ÿœ_ ^AÊ÷+¥?h¯ ¿œw€ÿV"ï)|Ïx»ÄB|§.o8ì¶W
_ñ5ÿð!¿
BãU^ÁWƒþŠtùÂ ¾Qç†öuAR÷ÇðJñ>V•'|7àf=„ï<¤õÆñ>NâÿÖmOþ!Ä×~?Qó1>†ùèö>üÛ´þÃ‡!ý1Ržÿq¯áßCü.Í?|P—/2øÇµ¾"8¾›º=D@_±.]¿‘«Ýü#_~‡uÿ,\­ëå-×å4¿ç‰<(ïaÂoÄï'ôÞ®ë'ò„Ûþ,‚ýu§Öwúk^†Èý5/Mð/êúŒüpÁï¿cD?0ÞÇÞ×úBéóp|÷óèDˆoÐúŠNœÑúŒþ¹[_Ñ+-\bqÆèWÜõ]ä¶§‹.sÙÓ±(´·¼”¯¢ÐÞòž#ü6ãÚÜ§º&8Þ
òÖå‹îPóñ|>>£ž&ñç‡ènà·Ôáç¿—B¾Tç²ÒO¼±b–Æw_ÅÜ’¹ø™i8ÍÎ³+æ7ú–NöéìÁÈ’à\¶gŒÃÊÃØwgè·äõkït½3_§Æï4¬YVZº¬‰îâp"JÒ¡ÉÊ(*ÊV+yÌ<îJ3PÖ®Lw+Ò–%äzŽ¦)+Ün•áÎ5/Á<½{MœØyúº¤œS³Å‘º„\“Ôe<ŸÅÕóK—];1î/qòH©Rßêè@• ”h
µæhjžKS.$J4ú®]HH0ìæG±¥$…;Ã4/˜*—ÿn§D%#ï¬!Š Å¥•WæR×<ª.Õ°¸ÂSTÞì;N¹H>¥4MÖ®•¦ºÿCvû8Ú ­[‹ªŒˆ-}™o›C5ájìîŽäêŠ%´I“ì©ŽËÜMrŽ»+ëkÑ¨ÎîVQîjÈir¢h®tø uìÙåT]YÖî(Wî³SJv”(ÎuM• Š}«™tý¤Éu)fUÏ.-§|i÷Ž-ÝÌh6.­¥¼C‘·i”»ªb®«$¥®Ê­ ™`udíÓÃeJû-6–FŒ* ‚"½ÏÌ‰« ˜JOo7´D×eäºœªÖUSsÈõ<ßnZçäÓ[ß³è`²LmsD+õn‡#w>QÄý_õkî„)ýè÷8ÿFñÿ\š./wü?£ûûTIIyªìóý_çã—íÿ¹ˆ¿œîi1Ç'ów¨&nÿš q—
_u1Æê¶ˆC-Þ©Å.íZU†8¨èFÀëÅ1¼hq,‰#$Ã0>6ƒÈýäÈx\`ILÄÃà¾:ÁÜþ¡ñ›[×‹#ÉÈæ06¼è°Œ¿âiþø wšÈŸ™lú/Æ'M–é2²ÁŒ¹ýK£ÌS™ö/‹9øBÛo±^¥AÚ‘7Âôæ2ê—Býð;mâŸqA£š`\ì®%˜æ—dbOþm$}Y4Œþ¤3ã‹É-ã‹«G	þ";	Æˆ.‚Ñ8`/ÁèŸz?ÁÞÙ¨Þ;Æ·tÕß¼†^µÉËÙò…ûÉø2ßbb™Ú{†›ÅäÖ±ìífjœ–ëi„àýC=d$<hKÑë$®²6ÙD#@ƒMÁ…<£_	<ãBž!¾ Ïø}'<CEâ*¿ÏPùÅx††“ÂóÜ´	ç\ü^œ¡ATâýõÎ4-ê¿š±Sæ¡ûÍÞ'ŽO·g÷ñðÞŽÁzêýlðàfîõGlé?øáÞAuý*¹ÞK®Ÿ#×{ÈõNr½ƒ\o'×[Èu¹n&×äz^wu°ÞÎÓzâx^²³ÏL‚ülÖ µ¯cÐÜ7k0Æ:c©ŽÁ7lûÔëpßÄØŠûaŒ€s!„cy“ÉŽÁ`ê¡Þ€Õþ.êF…¶=•êåØ&ai-Kýj±ÅFª5ÀRÿÂø… WäUùq©­œ×`^OìíÌ¿ÐžOùÆ'Š–·¯³žõžÙµ°þÛ‹ú#À£x1«sàI›¥:û
R¹ƒ©©œ×tÆ^œÍ‚þXêºþ6u0huö3;ž–´	¤…ð¿œ€4U&Ÿ±ÇUš8Ä'Ò7ÀO‹¥:’éÜAh2'1< Ã2šÞI–êå×¹N¦!oÖÙ;´ ŸÝöÄ	,SófwyŠ ,E,t3•—ç»DÆ„,ÏePžKSú²,’«%—ÂÇ~ÐÃ8q	Ò[gA˜™zc0×)¸6¤ÞñËÝet‰“µ ÏÛÏb …nq²
ÂV@˜!Ã KD~]%oôa]¢,‹IšâTvyÛ ¼pìõ”»Ê]å®¶r1=Ö_•”	ô|I5—»ÚJ;çYxaÇà²Ì¼}Éz¡éb>é†&uÎ#épÝ[é¸Ò>‹åär/°|Ò?é/'éÃ’&Bh6~¿¶@Çà…2Œëêç
¨[û¬SºB~ ç	ÅÉ©\Ð_8-¶¬ãßŸÕmé¡OõS~§|øMßàYÝf¿
ÉOÑ“4Øv ¬'iÜ›$=òGšwdêá¿ä5ò¬ þi<KY÷¡ì$¯%}‘GVÅoÏÊNùýPÒúðS4OHš¤,;{„¤GþI9Þ`‚yÉ%Eo‚·£û \/ŽK¼^l„þRdMÄð$„oü°ÍÀ-çd!–!õ 3á\ô	 }„Ý{VôC¤cŒ¸®ñés=Ð×ÃqŽãpœ€Ã„ù)Æ]ýúž‘éì4@›îìì»x×Zƒµ0×òñ¾¾7|¨÷º¿èê3’-½Ð'–mèòŠ@¿ãýä•GÞ…q»¯ øUmý!V×÷¶}%ŽáC×¿Äe‰Ù¶mÁq¢MßWé?FÿÒã´%}^÷£dÎØë†5Œúü÷ùï3ú[¾úÛqíçåø¼„+©ø¼µb³0&Ãg>|&Ãg+|6± +ß¯xìZ/ž¿zZ¤ÔõâÙrsY¶Ïtt¶‡ÏhÀ@}¦ïl×;ZÅs>ÇQŸéÍ­Â-ÊŠ>Ó¿ÝzîeNLÔ=µ°íÜ×ÏµÓ©€†Ñ‹M_»A|Óý\	þ ž4‰×ÏºµA¼³ÀºŽÉº¦Æ·…œþy‡>!éVmv?S?§ù:ŠÓ§ìë×Ü™ímeýÍ·û~ÍÞ»“jDÖk×Ü2{¥\©[V’òìØ™Ç½Š¹'q¹Ñ˜ºèÓ“û®ñ”›ï"úFÖ^#WÈOxÙîÆÿÆ‡äém9zƒË81kK´¬àcöìÔìÙüŸò†ŽM-X
€À6|„â©ÉflßÁ8z0é¨ý¢–3±0˜Ë€¤ê§èr¼À¸&?ü«G±˜›MBóo\4¯®zÑWYN bDIfÜ˜l\L—>k×AØ+V6Ý¾¢‰nÒoù¹ºöqÃ>^Þ×åµJƒbÕ76®¹ýæïÁÜnÄñŸþ¨ovþnÖÝ7;‡jŒ²)ˆ‰{â.ctßìx¯<mŒî›ï­=ým9*õÍŽ÷ÄoÁ7;ÞK›¥ñöH¾Ùñ^¼c¾ÙñÞ>Lo“ñ¹„Žúfç÷“¹<+¾Ô7;¿ßš£ûfÇ÷ö=¸5'›ßzB‡ýtEnöfüQßìØW›€î˜ôÍÞ€ßäk1Q¾˜‡îqÂo)Ð-Æ—:há;n¬cñnÝŸu0QÒáÜË†n¯Ì—èâÃÐ½Â´w±f Ö¼›‚~ÂA2Œ}~x¼Nèª®Úòß<ô&Ó¾Ùñ]áBËsÎæ~çŽt»}è<tg,ßì¿õÐÕÂ$³¨Ë³:4.ôÉý«Sºã@·Ø‡_ÂCW¯†`%ße×Iƒ
ÏÄõ70)?¯¯÷gn®O¾žÍ>,]XlÌø:v³K_
ývŒ¾Þq¼d<½ Úè`‘ó.†§,j¼§EaÑêÔ\^ùzov°ðõ¾ÃÁBk;,|½ÇÚ"
œ+òs°è­+6+,V–š,\bÿXøz_ê`±z“ÏÊ×»å`a‘w°¸£$,G KañdTí`áë}¡ƒÏ¿¯wþ,(ŸÑ·x>Á8ÚqÃ]‚1^éŸü¯pæ<yœ^µäˆñ=m:=Æ«òãv'Ä&áO5€¾Í1^Ï©.àüžüW‘ü§{Ò_ÎtýP?è¢ÚSÞjOy—Œ÷t¬1=½ˆÝÄtý£¯÷8Áø$‹M}¹‡ÿrÿíÿÓí}ËÇ	ÆQàÇžòàæžÄ¦KÅ‡‡ÿmß×¿¥±
ðB¿êûnú%÷kÌëó~wüÁM»7b~`#ýñMnú%›5öÖnUýWñë^´~pC—ê/F`2ÃoÉ:úäóq6FðLC÷7#çòëg÷\.Oš`Œ¯ 8mèöˆ¾ó¿l¸×‹¿n¸×‹—¢¼&¾äñÞÒãÄÇØ=†{=y;X“püÀƒjèþƒ¾ò_2ÜëÍ¯¢ýc~èÿmÃ½þü"?ú¾ÿÐÐã	ú–´¾O\#ãÑ7þ¥÷úup-I_k‡Í²|=ñKîõîïÜëÝèûŸÊsÀ½þý˜‡ßÎ€{=ü9Oü~ûzüFüŸ÷úùožõó hßéK?Ôã÷ï5¢.¬g…+±âu,ª‰Õô0öÑÚG}znÊŸÈmÛ¸æ^·z‚ÜÆdH:vóã«‡ñØîµ\ó1ðRæWÃzžO{e¬ü¨kÇš›[zdæ5¼Mû9Ñusv¹Šw¹ŽøÃ¯,<1™ôš¨" Z¶,Û€’3q^Ê´×ˆÑm¸èµ”ƒXÂËeö§l…‰[°Ùx6e~—–Fvîå…ýßj|ÿò©ýF³ÿ+Ÿ;×±ÿ+-/Eû¿¹%©ÏíÿÎÇïÿÙ»þà¨Žûþ}ï’ ½Ë®\ÞÁ]ƒJOpr|>	¹Å1v¢¦JC‚ŒÇ?n€ÎŽgr€l+cÌ)5IŒƒÙµ2C}ØÆ3LG2
Æ:a:nìÎÐ©;®‰‰ÑÊ±•šöúýî{ûVï¤Æ4Îh5«»ïíw¿ûÝïîÛ·»ïóÝ'ðwIZâÿF{ø~øsÿÇŽŸi1œ­èø>ÇàQÅ÷u Ý±›Ç©ð}gçò¨âûÜjŠ‹	šoA|_s5EƒÅÃßa+ÍvóèÀôñ}jù´÷ñŽ¢ÿ´ñ}+KÃ÷;@^ÚK®a¯è yÎ¹èrß0	¦ïÎ¡hn£Înƒàœ†VYãÊŒÑPç8wBpNsç0´Ç¦ÎIhM¢ÎI¨¿½­Ð´‡6¢ÎYŠbþ´ÛÛ5… OW‘€ú¡ñD«XÀ(ÃZlíÃ~ØÀ'E:ÃZWˆ¬ØÀÙX)°s6p®ÀÎØÀ*Ža \ ¶ÓÅÿ4àbdìé÷t\àqxÍ1â{·ò}ƒò½c¸ÀËç/žÁ¸ësçÁëð³¯U0„¬ë7†óù†°“0}‰·&'íýá/Ó™Áºµ˜gm‚òmYÓÔÎðÖ¼K˜’æöÃçMÂ³8Ÿ',‰ù«ï¿‰ï¡>_>g8{ßÏç¿Pùuv^?².t`[4Òxˆ±S`©\Â
l¡ø-R+ð…ôä[cX_äMŠu Ì«c	§rT`÷Oc˜Õ0†?¸–Ã#O_¸¬áì\_øµ|á„à¿®á7+øÂ¯ _Ø‰¶üK+ˆ—Ò„qZ¯àg|¡MØ:ç­óÊµ’{Î¹kØRkˆõ&|“ƒ1µ/XëŸÂú{
Î0¥à=ïçÌ?|~Uœ¡Ì77$ßhÍáóK5œ¡ÀSžk8Ã”‚3ÔóÃü4œ¡§á{y„3Ì˜‡ÏÏ
Á^˜&Îðü8Ã·§‰3ü—p†Ã“à‚3<©à‡'Áþxš8Ã¦À~oš8Ã¿-gøIp†{>!Î0­áw
œa[œa›†3Ü*p†m
Î¾·i×í£tîãûEÝ·bìÁˆ÷†1Tñ…M(³Í>Œ20†àÇ¬ÃÒxÁûÄ~„÷ä½àæóyŠ½8ï±ñþRïfºÆ÷Ä¤wüWÄk{÷7ùü6Þ3œjÿ>AŸ:Ñ÷k‹?üìœ‡=f‚ÂÎHgÏ„€¯Õâ8*Ö?ôl‡ÖhÃÿwv7_—=ÓÃÿ	üß‰"ø¿^ÿwïàÿšü_ªgú14|†q€ñ‡ù3njÓ
¥Meà8Àã~zBß.i|Ç|¹_9lëÚ` ¹ÎHø‚O†üíÁÿýˆÕ‹¼¯"’®$ìõ&k®Á¡÷G]ËZluÔÅ¬Õ#¿{mUU Ô‘­JC*EýÙª$øcÕhÝÃüúHôðëc,ï×,Æ’3®âýh“KàýØ~ßo¢oÒ“¼›Á{Äï±½WcjüÛ#5¦ÆïIœß¤‡z¿×Ñ»Ù'=Ôø½qØä÷D]?¿G÷´{­"‡zƒß£{a¯UüPo‰Ë£{é‰ð{tï*¿G×A<Ž£Sñ{ì~™¿Gûî£rsW“·[åÃkjtN{.ùTü]{ã“ã÷8ž×0oÁåÉÃ¿©íøžx8ž­_á£}ªÆ"|?Røh?*Y—w|\ßë?¬ûUEÞd¸¼Pø$.ÏÖø(Ë£=·Ž"ø=yH¸Epyÿ¬ñÑ¤.—÷_g”_›º¼_j|Åpyi|„ËóBäYF/^—5‚¸¼tmø!ë:.ð{±reß“áÌ o–ó±èëP—wh1À_•ˆË£qÕQpm-Ð¼d§Çž-Ð¼•‡5\žœcK\^¯†Ë;¡áò†4\^\Ãå¥
4Çåj¸¼Q—7^ ù¢·5\ž[ÀÕñ–iÔpyI—×¬áò|Ñ|_±th¸<®.JŽk¸1IpsOÚ[âàFsŽÃ“ýAâðF{üüAÞF×OÃóç:U¡8;‰+2PÝ7Ý®ËfòÝÂzÌ†[Áo?‰{kTpoô.™d!½º€ÏÍTû¬ÓìsT¡éÈŸŽno!P{® è'ðs@“7 ÙwL±ç‹øÿ´ÂOå)ü4þŽkòÆ5y	¥½Âì×®ØïgøWìGX¾]ÀÍUÃ/4ûîùÄcÁòOôçúŽ(t…ÁýˆUþ÷”t¢“ZÿjÖèKŠ}–(Õçˆ~„¿¸AÊw8¬Ð7#ÿ™GXe
üg4þ!§xFÃ)&ý[5}ˆ­f£
}Ûôö4kánCé¯¦ÍüETúQÃ_s>ÓÇß3à¸Ãu
Méí
Mï’öq‡à‡FðöQ#ø{ÀàúG€ãðÎþõLô[J}Œïjô‡Fð™w…é„;¬Òp€Ë5\ß-fðø5œß×÷©âÀwL|%œÞ_Ô\ „ûÛ ¤E:Q-Ó£Àpñy,Õ÷Ÿ4þÕpƒïk8Àq­|:µ\Í_­ÑµVð½kó/·‚ÏìÿØ
>³ÿs‹÷Ï‡Î°ÃòÇëiá·<¸ýîÍw>¸QÀ»J<ÇujDbâf „Ûºw!ÕÔtµŽs½j'¸NÝxU1Œf11ñàÔbÆ)aŠEOìÏ	ÇmAWpdæd¨GõpÈ®1pDoé ÇDÈIêéŒ~NÖ>Ž3,ýÔÀPØâÝ[¿yÿ¶ô´¶¦&Çÿ­Z¹jUSÿwÓêÕ„ÿkJÎœÿwMÃÿ™ÊÐd¼²0ØÕ²^ÍËA è2·)ôDÃãQ… ;q±É#<2O¤|i<‡i<r÷Ç:ð—ê\!OD¨9Î#Ê—Ó9X4
-"ƒEgz¢` lM)–ûe=˜Æ£ìÞy~½&¿VD¦ÛæÈ‚L¸5Ù«Ý"ái…ø@‚§5Éß@À%6xàË`|8AJK¿„þÐäÌ›EÓÈyàE»˜<Ï<ÀìåEz˜½?ŠA<†J“sQ‹|Õâ8iÓL‹í¿4ËÏþ”¿<Í—øÒü6Kx'{Çž7ëúž^¤ûÓQ¡“
e¤tø[`"®'-˜çƒ¿UÀtUòS=åvÃœò¨.ê6^õ4ôý{¡*ÀÞ·4Œí0Dºñ÷ÍÀkÂÎâ<},Ÿ·—8OV€W‰×É¬?¶c~O¤SøÒ	…Þ‚´£Ð]HÛ
½iPèo‚Çßß$h¼¾«éý'øyÿð(¦(é_CúM…Ž!=¤Ð¤)t«4„Ã?VIz1ÿˆby(¼¾‚ùûù'Þ/µÉÃ€e	óÔdhNÜdÀOëIÀM õÑœ Å~*pR1ÂIä·ßvçŸ¡*ë×µm¼£¥]ŸtÈ;ïÊ ”ûÈÿ$øÓ Py0$€!ˆ¤ÿt}³¶·m™‹ú7¹ˆÙHË>}ŽÒSõ`6zªÍ:8kÌäNB}n ììžL7¥Û¿²9m9ãlS*;Àåcg5„œÖ†Cý6ò±Mœ†›Ë{Jçµ=7{’oæX#PÑ0xÔ@¿ÅtY¸‰e{2‰ìó(ïˆ¸F~Üzæ‚KuÊ>šY—íÍÐ¶<äŽ€{jsƒP‡åwªu²?‡Â<gÑnîepr/¡=ŽAÙ$eBK_«ÃÞ‘WëÁõ)ùè7÷îE—ÜÖEã°Æ^‚kØ½n;Êéê‹¡Re©(´ìû–ÐËyÑuP÷/vØ»ûÜ6¬G¤.íöòZ/ÿkØ^Ã5‘Arû×8}h7‹zdQ,ê!ìOEPîžE—©þÔFÂž]$s¾ÃÇ3Ë
·gÑeÊ£Ú¯aðãáÜÉH2÷Z$aõÅ¤E=·-Š×q<†òî´ù;h»S¨Ï)¾uñØ£ph8ñìiüÍ‹ÇÜ²õ•Ž|ñ`š§§¡<Ö¾­Ð‚v½NÊÄ<õ{_‡F{zí&¾™Jßs§"q[Œµ"ÝTÒM‘^Îé|^Ð–Jg1ZCbY´CíÐ0i–vÂöÂöOå^ƒfÝ>¹Óàa=¼IìãÈú }¾(êâb‡Û*‹Ø§žxBíó:Ôc½*±ŽŸ—ò¿Ëa×O_+Ÿ?àoI²ò³sdíM¼>då7ñnF¾+Úû,–›š Ó$lñîCÁw)Œ·	ãem"õ:Ð*6”½ºÏ_cC³ÛÚ°²0_‚·	¤²h{ìçžÒ&ýØ&°M:µ6©Ã6éÊ½Ý(£ëÙ%úCÐ…[.ÚhŸ¼ãx×çÖš8ê’Ôt©Ã>hù}- sa	2‹Èdýq®mŒÉßPv»+K”aaõ%”‘(RÆ<-o…šw®m6Ë†÷ü¶­iF™ÍºLäcýÝ+0}CHz
Ëc}Ç¡¨(ŸÑýØ“åµ"ú}{Hþ¸äG}i–Wå¹ZykKÈC16ÿ+E>öCºŽÛô4jƒ"6^‹:±k¿·ak?½×N¡_sHýK-/ÌÞS•—+oŠ<	ÅÞSÊgc‡ŸX!tlÆßø{³×ØŸÃk£VüžÄß]å÷*åHeßÀ|ÿˆ<?…DÈ8U‡eµË±“d±6{–ÝÃâ{­Õ‰²â(ËEYÍa²ÄøBòØŽd£œv1nÀ1°ÇÀ.ýþ-i>wëës7¼§£-^…Dî84æ^ÁûçËØ_Â9Ì11§;˜i„Ì‘ô÷Ç˜COÆ
ó­½™zœóÕ»à<¦oo‡ë£®^\»gbûoÆU=Vf¿33q–ßìJÄÌ{9ÉÀ¹ËGËš ‚z'³¨CuÈ¢8wqqîâàÜ¥^Ì]šó+E76j_4JÇÙ¸Ñ|^î¯kÊÿ÷2;™Í‰‚2Õ÷£ÓüÃ¶Fv1Ý:¨Õh[£«5ºJ£çiô®ÔèÙ]¡Ñå]Zàíºÿ˜>'/>.™Îü™­”ð»z¦ìL˜	3a&Ì„™0fÂL˜	3a&Ì„ÒC˜c)!Cÿ<ŒüY¸è&=·¤g•ô|’žIÒsHzöHÏé#=W¤g‰ôüP<3äy«3òàgÉ_jÏvx"¾È:ü¹»
zæ|¯J¾2ÚÇ%Û<AØüKB^a_’§¡vþ3FAé¦ô3OCé«è)˜1JñÄð4«ØÆ¹ßM£~º« u$k¾1pûí·÷ìíÙkVp?<êWV’~6#Üïû×RÁTËº­jã¡Sí9kqá
cÊæ²ëÂ‹î‚	éx=xe;ÙõàEËôŒÕ¨+µ»—W>4Äó]ö/™í»<|x#ÓÙh%Ò+w†¤wùé—né½™?™¿¹>mÿÅí›ïÒ›púªÿâ·µÿëM;¦çËÈX¶ß×½ñþ»ÒÂ£qÇ§äÒHÚ+.+îgÉ+îÚ´mÕJX‘îÞ^¤ÂƒïæÈ°e|™²+únŽãUÀyÉPpsLs<‘É±h<šÊG4½ÖTò0|™)“|´—¿¤Û$Ã`1V¿È+ù(ÒjÜm’a³(íBž>&ìK Ý&–‹á¹.†Ô÷«werÌÃ]}N)WºMna8-Îwù0²çj¹|7Gvc÷¹#!öóÝfb¥jgy¯ÛíóÑ}ŸÝû‡Bä=îóÑ=•ÝW;Bøž€B? ¬Ã[…”ûCŸ¯çCÝŸéÈæ9l®æöwTá»„|—Šð½¢ðáØA1´Ü>Ÿ¢‹ªóùý5…Ïö3TÞO‰ÏX>ä#]š<â=£ðe/SDÞ[ Ý![/ãôÑï,\ñ_˜;ä¹4¨®=1ê{í
Ÿ´å˜Æ‡ú÷†È»ä[ü„ºC•A¾%UøÛ-!|ƒ|.éæMÔÏpñ:úµÂGX¢wH#©èŠ¢Ý~É×
û1>•W¶‡æ^¹Ô#ØèDyº{ec¯aêû4.®†¢î•Mg¹GèyÇö2°¯ {m
ú9A[‚4¯Ç¨Í'_£J4³8v•h>Æ
,©%Û€_Œž-è3‚æOŒ8†™hŽ÷ëKºMó9;Ñó=$hŽ-eã£9T¬,ÙÎìúgtTÐ—Ía‘-z¾ mA×
ÚôAK}
ºOÐçJ+x"úz¾A£O£ë5úF–ý_Ú{‘–NzFü¬ø‰ì+Ý²±qv®F_'ígpû-•ö3¸ýVIûÜ~¸¦*!Ú”˜Qnšk’=6#Mý'"è8WìQøõò¿òÇ”ò÷Éö5xû>¥•ÿöO‘7 É¦¹)r;"ýç4Eú€ ÿ]ãÿEaýÌúü(H•òú0L†OŸ/ûOŒõã÷‘fõ³™<Ã`hiœ	`l‚<ïœÆÀ(ßé£kÜ/i^ª±;ˆñ5ž×K»^Œƒ²ÿFYÿ5rAŒ°q&ˆ!6Þ	b¢‹AÌ±ñ?²¾QV_³R`ÜE}Í*y=óú™åõ5éz1— =Ç"ÌDãlzA´¹^–góò¾´—¹5ˆ¡6{ƒkó`°=Ìç¥~ïbÅô~%ý¥ fÛüInþL“÷ó æÛ|/ˆ	7?bÆÍ˜ò­÷í=‘ÿjùÆ5­¾IñkZ½®š¿ÛtŽì¿2÷µ[h3¥ÏÚ=éÝÛv¤Ã0ßWîÆVÄïj:·×î¡Š¥#[Àum—µ‰nj·ïJÈß÷àÝØd(yr?º•S8·maKØpÇ6Vÿ	]ÜfÂ$Aøÿm¾ïS,cŠóÿ‰¦dÁÿïóÉ&òÿK&WÏøÿ]‹ Îÿ/LòÉý¾§Ë˜ctâÍd–íäþW¡Ÿÿ/ ÅóÿéAIÃc1àüÇ‹Iwã—nL£îüGÁcñ8ÎÎ(ò	¦Ð•îœv‹täC?ÈEwšyÈ è±H“ŠŠó´=Pœÿ¦°¥ëþ{ç=˜x¶?MB?4Ç>±ÐÕ×ÂømÁÓ6‹Û)Så1y;MÕ÷ËcrÎ M‹šAðÏÄIO:õWÏ’LÛL.{æO=ÒdGÌŸæg@Z8¼¥i¢“Ÿ4M€Õ³'G#«9Õ¬Äô$Ê¥³¶ðwõÌÉ§"Þ›,QŽ|ßA•–.®²/Qýå»l^/¶à#»‘ÍŠÁoR¾ËwÈ¾5~•ÿ-ýO5ºE£i±1$Ú'ŠÚAKß­ÑßÐèNîÕèå@çðóR£Øªké;4šÃ¨ßpzN`¡ÎæôÅß‰PÜ‰M¾ß ð.„‰ÎwÜŸ.ÔOÎw¬#:ámÇ<ï„¯6wá÷ê"žr¾Sÿ´”ï|È	¾3¡F¼3áÇ|gÂ+"=…¶ý¶AÛ øiÑÙø¡3yðsµŸåtÆ~VÐYø9›ÎÄÁÏJ:û?±ÃvÑ'Jî¦Ï**¡>UÿØ¡†ØÈAk$?ØP's6äÜÌž¬…¥¹™ƒÙÙãÛ1 Ê†˜·{®Jï³8y³0b90Ø@tÊNÚ³IûPÃ’¡z+¶kÄÚ3T$ïóu-PJÙ¿y¼+e/%Ú´'è6A·	z­ ×
z ×	º]Ðí‚ît‡ ;Ý)è‚Þ è.Aw	º[ÐÝH·b}ºúÐVã4"ER»f÷¸ Ïg#ðBÃxÞpÝÏ0zPžÚ5ï}×ƒŠTz^ÅRŽäjáÙÜ.´[æòyÞì-`¦úìÖ¾³˜ÇE»;ðr®^Ê-¯¶ŽåZ šjšT…Ý´l®½~Ù’¾/™{ûjp[¿ì´aW´€8¸ìyÀ¶^<`›ûXãf°¹–Ûëa<ïÕÆœïb;Y./kM?–“År²XNË`íÇöjÁúØöž}´Áp=Ê½¹Á‡íýPým»Ç%^å2…7?lhŒœÌÅ#¯åbcý8Ú›©7«ÚÜXœqÞ'\8•ÃHÇõÁðX‰Ã)¬ïél,Ž×¤Ì}Hð:Œ÷tvŸOg¹ZkÑ&2o=ò5Âë{ñr#°©–÷EÓš6Û[£4SI3•´|>ø=vaÈÂ:d±ÙDd°AÖqÛ$‰m’ ^·f8kf:ûu#}¥Ž«DÝ°®Ž¨[%øu«g¼~Ýêáõl%êµTèHùê§NÈ‹@kµ[¬±y,·R|¿SèOö>‹öî2ÉÑ³SI»¤¤‘}Ô4»z+Ë²¡õ@ÌéÒ¹G‘E¶AdÑÙfðmsmÓ¶i¶éDÛl€7°M†rX/²wµ¨×¿>x­´²®bŽÇtˆWßê>)Ê³Dû’žh)'Z‚œFEÎ,!gDÐ_±xIŽÁîu%ÈK(òæy’¿Bã¿Î–Cù›«ÛÜ"¿‡uñ°ÝWÀ,w§ø-…¿¥þ½«ŽâºîofWÒ‚Vh$XcèYì5È1‚Z°8•Ó±zŒcâ’VuÝ
,dCÍVÂNq#p8F¶”ê¸9¨Ž“:=N%Û8¦­°7»8¥­NÂéq%™Ò–?HCOÔû{3wF#ÄuÝ–9çíÌwß}_÷}Ì}wïÕô¦Éñ&ßu©Q•íÉj>ÿtè4•,Ee¸Ý“¤›
ÐmÔtƒxàõa—Âé$©ÿwþ¡¶1m š:ù|iíÑ’_mH¹/D7¬=Âèf& ÄKÓûtŸOD'MíAsQxúÍwµWjúsðçPÅ_zŸbïãú=ø©®ty
íY+ÞîÊˆwh<þM§œ÷š´ ;â«Tõ\AÏ QI4RD£–Ñ@ù3îi|wÑøîjbãÞÜ±gy\í¼yò5ªë¾ÞJñ*Íá¯/¼LkYŸÜK$i1÷Å1·§G®ýsŸÍSÙú»p*– }F¢c[×ÜYq]÷=Ø+;Xãæ&{ì¹•öÜôÛÎ<¤‹Šêy7&Ëíscøßò²§ÕÜôZåKmú*ÕëZÛ^¦µM­kµzb®÷äþëªS‡òaÍŽ3ïªûØXYÊìshý{zt¬zæè˜3O­—ÍJFípì±ñ{'³/ê³Â÷Eæ²ø—¸òÿ§K½.W'W}{L6®¡¿sX\G‘|Î²²¤£FQ‡ÖØøxOHˆ-SÆÇ7±ø\É¸rÈkŽI/ã­#HßÄû´3k”1s©¬$E‘ÿe _Úªù8M EnœJu<½ *õLúâ6Ë•¼èbÊ<Fn32Pòà)ùÒÅ”yŒœÈ“<¿2’Él¶OM¬Ì£d5Gle*sbe%ÛŒ(™N°¾8Œ26Ð!cy.ª¾éÇ)óÏ:d3ýÑ‰•yŒmsÈv`cÜÔ#ÎêûGÂ3°„±ÙPà—[z0<5Æ•¿us%õ};ÃƒL1GÓ–1ßîO2<ÈÀ:¦)c0ßnáñd1ùiáJ?Ï2¼¾Ò,…på–ç…QªZž®Ìó†#¼Øx}Ï!<Ç	Ï—Û,ONÃ”jþšáA6”ž€Þ!†Y]Æ	o¿¿óðÈ
sŽ|å ï2¼„·s‚|¿/<[éÝÅNP	¿"	ðzBèÐxFö¿ ÌœÇªK‹šÎJ|oÞß\n‹|”=C™ávNŒÅm–oª5/ T#:fR(Pü¾DLl³‹H|’6Ë3Ò”žpm–7¸°Êy+‚[]Xµ"æ)+‰ùV³æ«ÙÎÈpÍò~Vj5§]XmDÌšml–÷¸°R¹À8W°šÉ1ž¬$½yVj5Ÿ
Ö=¨÷ÆfyÌ…ÕÉ·ãÂJ­&éÂJ­&íÂJ2žqa¥V“sa¥V³Ó…ÕHèváË³Yžsae³|¿n¬l6—ãx&«?l~_ÏêÖ5¬þÕ”óš¾MôS—_“«ï&8ªaÈWyøÁü?‡;Ëé¦`cû¹@þ_§{zšG¯?@þ°¯Ôñ˜W°›m)øü³ú»Lú0à0Æ¤á7ÛŽ‹”åñ¿eGE•åñÃ\âøîÔ0lœ<é—ØRûÂ˜P6žÅƒûî³üg[X<ÖãÏ38IáËúß´<þ/'þÕòø¯ŒøïÝ þ0lRó3‡Û?Óöêñ)[-™úVÚÞxDýÒ¶ÇïevBÜlÃŽ‘Ë¥Íjìƒ_ÒøwòÛÈòƒÅúö@ü0lVóöïcåqˆþë÷°øþ@zì£ø™È?èý0€ÿï™ð]pNÚ˜.…ÿ™É»žÌâ%5LOfñ’%Y=™UwÞqËŠ†Oß¹Bž
ÕßºÂUN¹¢AóAjÐ\Q™¹r}d®–õ÷c¦¸ëÌÅñ/çº˜þO¦:mô2éôR‘®^œ©É\Ñÿù0.£ÿc.[TÊýN~‡ú~Ì—ÉïèÿRÜÚ»ú?*ä…
\ÿŠÝg;TðÏìÛ§C…L\…ýñê%CÂRúD…:K|6Ž`É€?Ð ê<>5¼y]X]M¼Öß©zè£‘–{=ìæñÅƒ¯|éÌÒøÅºüF.…¯ìÓÍ§$¾ð%‚¯þÊ/þ½W <¿fÁËÈŸŒNL9‹C½±O5ž—øÞÝ\ð±'vxiñœ´ö‰ƒý¾××—X.—8Ãÿ…•,þ6ÔÅ%@˜)ŸDisÜI¡þ$Äó?(¯­’ø1qÝYúf
«|…5†\k#ƒß”+Ý·°ø“ü!ŸÚÎâ_¤%€w0Ýò¨=æ”@}¿Da‹Wž3°hmÓûí(DÊ››ÃÞzlÊ5j°©Y·¡Í§¬CÏB§¹Y1·RØÑº7˜èuàMhê(•žææÖ-´Mu·:
’ûÅV­üËv"§ÌQ…¾G©ÝfPÓÅp§Çò?Ü‰‘+p§—ÀÜlÜi%q§ÂU%î4°àN˜Ædwˆµ¸Ó ¬Ãgw¼%ùžãgþ¹êýhßÊ¡3½×¼/ý Û;<íX×±Ø™7†Gáé®¡Øw:‡FÖ?lžÏ²çÓìù${dÏGÙóö|ˆ=÷³ç}ìù%öü{ÞÃžw³çNö¼Ï}='Ä±žQç+'K’=Ç£Iª£¨vò{‡£ùªá¸Ø;Oï;udlì_šˆwîbŒkþ1
……$…J
i
µ²)¬¢ÐDa…õrH“­zÑéïÓ¨?átH$Ó3uùÔåû-Ê/Fï¬$•1ypþèÍØÂRKq ƒ44·M]@i8{‡RºJÚÝ†vl¶¦çš±EÇAËÐYE4ëâz†mD?5Tÿ£Û‡b·½:NÏ‰‰¦H÷¯HW¤¯‘´~Eˆ¿ªÿømCÑô-CâšáˆÓsÜº±çÄ.ë —Þ?O°Ci²”†æüçLš8Å;™ß¶TùgYéž‰Lñ0±ò)¼·õ{[¿§!pJ¤Ég‹='2”· ¾¸mHì<0²~—WJªCR'©¨ÇÃ¬lŽ®Ç<ªÇ¬ômCŽ®ÃTjï»4ž,#½ÿ‚ã„?•ðihÌ~Œâbô.J}XIÏ•ôŒºàÿsxFùi­šJCôÔJjÇ¥Šæ‰áÒšxªŽÞUÓ;K¿£¡}
ôúª¿w<Eq(Ë<–&•ö×3Gõì¤ð"«o#Õ7KõmpŠ‡‘n6¥Ëê²P»ÎjåÝ6$Ò_”´6–ï^¨ëªyOöOIWKé’,þ3·IÃ”ö1ªKV–—x.$ýhñ.K_¤qbç)Fï¢wÄÚ;ü‹óê]šÞ¥©_RŸF5Þz·@÷i1ÆCòÙ"ý–ÄEÿ£o¨i$4¾EyrzgÎ§W~zïž÷Æ†¡W«éœüyï¨®§xÜ_²ô ï°¶¯i»Ã4Æ¿}Þk;Z3gí'~1tÀ³q]nÚ‹M-Ñ|UL4¾›Ò;”ïŒ­Y[‰ÆSêÝ‰FÉ÷âTœÊ¹Kã~þ©±±YšogkÞÿÔ?dt|›'~=Dá0…
G)îR¾áÿ-Þ9~íù0õÒ—-¬©Qû\L‰îV·ÊÄ½© ^$ïÝô-òwÐ†à·î\½èm6öžM[’íår´[I¶ÊÌÝ=õÖ'hîÖ~1ëâÜ{Q¬)Ø#cÁ{wì©±‡Æ^º–àÙÂ;3=¦öÂ¹mj?œLí»q¶ctÜ¹nû¹¸Òöè~]uãðR®lÜÛ‘KŸË¿D0Wý<áú6G=–¬^!
£1kŠU­°¦[3#	k–ÍÔjÖ,\œ\œN×T§ÓK’•­÷lXû`2×F›Ã­kÛ[oš 2ŽUà¬A‰:Õ™Ú>®Û÷ÑBêÖWJâïwñG¶«§u»üçzû<ºnI‹0í´¯kÍµ/’FcàgÞµ*´~Ó­‹XÛvÿCí‹¶TÁîL{Õ½\»qÑºM-÷cƒ¨%ÊÀL3mA«e=íM«ˆRóÃK6·6ß×ÒR%kxcK{3ç×ÅÍhÒE¾WžuŸÅé…ÕÂêPå.—åÆvåËýàG¦Ü“±JôYY7|qÛA£?áUÚsD®²-²meº\™Ç^€]"ozÃ/ÛtY¹3ÃA`µH©e²ÇEæhÐÕ;Bˆ’2s.ƒ7¢ÇpÖïòâ'£z®ZsIê3žÔ\á˜g¥Hctx¤æSœ©¿óvŸªÌh[g²×³‘ráwve;ôlŒ¾ægøÀÅ¬adfî†/^£ï‚y;oAWÏ“ñ˜sðjáé»`žÏEÔüÌw™ðôS0ŸßUó<ÒšÿmAöaŒdjžŒ†ûp¿™áÉyš"Žðäyªü³ãé}’áG›ŠÃó]ÍÚü¹¾Xù¬âÝÍðð“Ž‡ëW@¿gšn%Çƒ	¥R‡u¶v<£ß<|3ÕM€·Mx2*%glõðú£“ÑÃú|ŽðVè!|á5Ð÷ZCI¸þÌ—„§O‚oÅ•%~coÂ1Gí+†¾2ÆzŒ,¹½DËÈÂkÂ/£Û_â×{2e=Às¦é?Ûòàu”†¥§óáýSÞ© =Gñn°|A=–ÃŽÒkÒ3¼g®ÆBô©¶†Ìo"=–‘9B$Ù^¦à…yFOó‰‚UÎyV1?(Xõ²Ù×=–AVz,§]XIó;¬Z£i—•ËzVz,FŽiôX2zOhôXj]XI~ë\X›‡qa¥ÇrÎ…ÕÌÐPb`%)^éÂ\ªëé±xpE ž€gà™8€¯öõ“Ñ;1í‰‘nöŽêš"k4êúfÉ{òæé¡ôFôÖ1zH_ÇÒ#> †Á¼Æ Ÿ^YÔ_Ø›þ°¨?¾±Ä”ªLÒ÷ö1©'c`[ç—cñÐ›Aÿ¨ù \Æ×ºß%R¦ÖÍOéÍleé;lè÷³xè#BN•`ô3.ý¸xÁÁˆ¿Ý­O¹8hÄ{ûŸ©²<,¿ÐðaVžÝŸ÷âÿ,ƒ¿¯á3ëN?þNËòïòà`!Þôv
CÂß’ÜúO“ùòþ„Þž_–]*
,¯-»L”[Þx³lG–Ïû+’ôG,yw‡WZÂwN²ˆà‚'Ô¼w­u–ÿœ£ÑòŸü=Ngøk,ÿ9J+Áe,¾ÍòŸ+tXþs•üž±üç*{,o¼–ÓøzÞòŸ³|ƒÈ$…o<…åÿ÷ßÀà<‡Á#úµüç2?'øj†³ýç4%¶ÿœf:Á¿Øáá_kûÏm ‡ÄÏmn²ýísÁ×³üVÙŠÿlèñÄÄ§mÿ¹ÎïÚþò·Úþsè-™ù8IóÃglo¾+§ùéQ‚«Y~OÊó… ýgžËð¿Jp	ƒ¡çd1ø€í?7zËöŸ½ËÊçPù çTÅÒŸ`‹5ú÷g/añÑˆ?~V$pî„/|±,l©µ"µY¤ÖùžV4jõ£å+nýõO^ªžÓâe™eáHÍÞwR3}ô´=âS€ÚtÏï·¶l¦äKn¢ä,Æ¯±„dQwº€ö”Ñ_ò+ï„ªé¶æ–µ76?¼amsÛbÿA;æòp–ª9öfIà|ÌÖùØôa üòÔÇxžz´kpoŽÇÔúÏáôASà”Ð‹I‡úü\ìöJmÈ(š?}°èS“[^Êœ{”([Ó+À2d8Pí;©ôkf¹Xr¡:dÂÆ¶	WÕÑçÿ×ËÓÿ ¶KøçÎä¯‹éÿT/fú?7ÁþOM:½äŠþÏ‡qIýÛ³ÿ#7Ø‚eåŸí2B\µ:'œa %åßá”
PVO«‡© Á¡ õÑn5Rœ
b@Y„³]¢o¶ˆ€ëuP¦T^’å²t-„µ†h«à•OŠ’ÖmþÔÍaDMº¢aúC}Âúq˜õÝg„—9ÌlÅE¶jò%"[š“ùeí5²nÙèaY‡lmA©Dò($µŸziÑ;©/ƒ ÄÒm*Åv9™^
F¦jXª6åÔ6`NN©*]#øJ¶°Aµ™Ø’ƒ¹ŸzgŸ´-Li›ÒÝÏˆlÝMö2ªUà««t¾³„â!”ñjaì³ª¶ÇÇ­­5+|p—N@Ÿ‹1Š„j‡0Õ*\A•)ðq64íŠvJˆñ×Ã‚!ÐõSj§!ŒýHùWÉdÊ¾&•7[„í³¸V‰#Õü í;zæ‚4½'ðÓx5ÑëfôþMQäzýq ÿ¹ ¼Tó¶7)ÿúÆãûü°þŠ³ò¾À3 ðßªü¤½Ñé§Yü` ýñ œ5pR•§4@Ä‡OCñ¾––æve•+|©¿€Ù£ÐÍÃ[±qêXPÿ@T²Â÷¤!ŠZZ\›dQÎ’êùrå3©µ„ç3ÔöæSöë-Þõ,ÇeÉ†ŽPs¬úCT½{øŸ£{ž†0î‡hxãNóYîGhøã>@C÷£4äqXwâ…i¸£aƒûIâÜ©Ëq§ygî4~fâ~–¦Ï)ßªOf\ßªðé®ü«&ŒÕ¸cß»G¤8>U#aþTåQßõ'Î¾ù{œ}‘ÙùëàëU$òÃGëüÄØù:âÊ§þÓé¿þœÓ¡RÃy‚ó>Dð!&ø0ƒ|„Á0ø(ÁGüÁï1xàA#øƒO|’Á#0ø4Á§|†à3>KðYÀ!í³|þÌkçæÖÑJ–Ú^<Ðõ5!æ]DSÖØ¹ÈŸŽ¤Ð7uE÷“Âþº˜È^+Íõ¾H}õ¼¨€õÞ"AcZžï¹>r_‰Þ—EEoŸò'Ü½¼Ì©ÈŠ9u4+IÿÂ-Ngj¹Ó­ü;ÛR«(ýšî¹1Ç^VW&ê;¡E€úè/ReO_[V‘j þ&:Ä*çÆŠìØ9Ñ¦ýØ//êv²¢ ÊOå9™ÚîtH˜òé¹¥Ì¯tQyº¨<]TÃ7HOå!«ˆF!•»4ê
¨|DƒhM}­,Aïê;wv;0jE£&õÛ´F$¥å
ÂÛv%z	Àš¶»þÌ?ðóÞ7£zßˆVFzÎ¨27”öÁ6ñ¶Äé}‹Ê÷–:&‰fÅ<™î-‘ì:Dï²ð·…¯ú›À{J+û’ÒÉ¼,õÔ¾3MZÂ«ØvP¤´n)€W>®£Ijc¨o³x›Ç§ì±±0¸‹‚ò‹]ÐEõš šŽh?Ø®ïë7Dõí=$j©¼µú&L¹©¾¿ªË<›ðª¾b*«oÞ»õ=Hmn‹©Tæ*“Žpàó[ÎmÝËÕþÞIäðEØ¹G•udïäAÕoHŽÕ7û)oi½7/*)î_YÜQ§ý…»ñ&ÿÝËõÞ'›0}}F¬AÝ­C“p+µ_ñLµüp³ö{‘Úo5µß*Ý~M½o‹»)]ŠÊÝ¤û«Tç)}Ä§¨ÎË5Ãe“*ßNŒò”öÐ‰/"¬ÌœNù$èÄypC}±^·qcÌ‰¼©û4#D31	š£àÇ8>åõB0/Õ®ñ„uVÇIKˆ…„oú?c|Â;Ú¯¼{²Ò—}­ñeOtŽé4IƒCå°&AwÆ$éÎÐÍN€— :>*iN@‡ø Áúoé$Úz6kë±öKÑûsšnÑ¨Ðu’¾¨Îùšh3š¨\èÃÓšnŒÑÍ²ñãñÇ!¹VêüÜñJsùOobnññ“oîÒ´WsÚD£Q£Õ4ŽVÑ8j2ãÈ\rí¢u€Ö¢­EX›R«œí”Ïw¹o{øµŸY=6ª}ÚÏ¦µ"AkEEp¡ö,u\dÏ"ŠÃö(ÿ—ôÍuÙ6ˆ²EÉËìê0AÍ¼q k.ù¢S/|^Í¤REa·çWå2~ÇrŽŸÒ“Å&ßø=ëÏÌ%e‹Bâ=sIJFq¶/Í]0~úXÿ«ŒMÎîÑ¥:3ã¾Ì2B¸²2s™ï°ëržï±F);7k„}‰Á[#e`Š7W„ù*»ÆGáHùÓ~áùp1r8ì­Œ2¢`õiz–ðÔD`&Éø(£ï++LÝå6æ£Œæ~)OZÊò5fš<e…DAò>Ïþ6Eã5P4äX[4½bVßœ0ê[’¯%osõCï~s‚Åû#©ï{xÁ qqµ‘_mõð0^ä˜©É÷qáòöö>sJA3I„çtÐëá—WšçÝÂ¨[Õ»²Ó0u«/3¼NÂëœ ïy†G´Ýäûg¯Gûx3ôM†Gu•r©0zßbxûj¾!xXóµ/3Èœ¤Ü‰×Ã˜5:Äð(!4ß¿®Ï3ø|‘r§ä±w50v×yî}oÿ~ûƒ½ÀÆûžó‚×Á^ï²ëe]Lýü“°‰´ÔšÊâ².þyÅžËº¾6n³´NžÓ‚j"Èm£ØW"n¶üÕR©äH©Q—¨jwT®ÚÀ;¼ž3sæÞ¹óî}^på|«»óæÌœ33gæÎ{ççD”ÃZæ%ã}Ùˆ§Ã^Û
k¼K„õ¢ãM¿¡=5Þ'ÂÐaï[éb›Ÿˆ(‡µ¬	ûw³¿7¿óßQ[o!û¸±Â±FŸ}º…å`j@¶ÂÈï’ˆüd+ÌÕ~UõM\¶Âä·rØ
Sß¦[a²Ï­0Ù7ˆÀVXµ¶EF¶ÂÔ˜ °¦¾­¶ÂÔó.°&ïQØ
“÷¢l…É{N¶Âä½%[a)mûŒl…ù¶ÉÈVXJË'[a²í‹ÀV˜Ø
“mYø¶ÂV*[EÁVXù£l…ùõoÛK•×ñm{©ò:Ú¶éÇQúù¼.¿£·çjå·mWÉÞBùÇ%â˜ÿøåüùÿÆ?Ëø	ár‰Âíü=éùû;+??°òó
ÔoÚo—ÿÈ¯^…áÿn…¿ã3pOÿ/p<bräÿP·wÇ•·D®?ðÏ•ÏjŽ´íätjùôm~ixîÁñ—Ö‘­¯Ïé<“­¯ßÏE8÷‡ç"œ@žÔ¿²åŒZé}Ýò?B÷O[“š§ú–þTx®Ây…î§Á&Y~ç_ÃsÎ-þ×-ÿ[á¹çm+üLØïŠð\;Ç»Ðšš\LÏm´â_nùÓZ¿eìjºÿ±¼hS Û’ßžëpoÏu¸7[ò×[þ;tzdûl«O«pÏJ/<Wd¬í™ñF¿ârŸ¾îk‚cÀ×¹ª§¯§÷W;âOg:ßºŸèÕ=±§é9š;©pBQÄÜOè¸y,qPh
h&‹zÂ‡÷„ø±¦Žüiªó-Ò	­Ë‰]CFÑ)á¤QüŠ›¨y29ÙôÛ½Žæ7‡ïÎç7ö}B'ÿ(T^ÿÓÓÕw­oÿ«÷š<ÿ§»»§‹×ÿ\àú×5†í®_JBÊiÖö¾sÊ¹r|ýr•É|ù~€ãï*3^Êr…²kn¸þzOq©øaWGìhWÏC›Çhú/RÁUã›!7˜Ý¦ï ª|a²tX¹ÉqƒÏøš:Tü°ë/iò]¡ß+uùž¦r…\¼SjW®-êë]²uS_¯o_Lï_Ž¶/&YzóêßEpœ€ï(zMMP’ð6>}æß‰êI¦ydOœt4=Cß×TNÃ1úÎúh½'†þ;1ô­1ôÎúÇÐ?†~S}E$}ö¹>#\4Vc=êèñóçFþ!ÔÚ|—Ök?š…j'þ;AÊ¹ïWl[¡J@Çþ#AªýÙtœ›©Ž ã»JM9O’í×¦§Ep”—IÇooõtì—"è8O9+‚î	uùô‘Z÷™iG¤¦3¥oçÛÂ}hHàGÆú›ÐíÏˆü$„Ô&ž¹Ñ¾%]¿_ˆé•¢cjë¾õ“ëöíÙ’x~ßè%ÓA˜7a‚ÂjÃaû: ¬‹Âú­°„µRXÚ
…°CvØJobr7©Â¼Ó_ø
ÄçYacv„ÂŽY2O‚ÌS$ó§ßóÀ7N|'­°„PØ †,l(2Õÿ•	úÞ‡:Ý‹)×«][*}wr¥Pýò¬tŽÔœÕêæ1ëij¾—Z´^÷‹ô$´–‘:¼“_µS[D
ÒÊ ,»î°>õ…òÎ¾UšžZåµ’Ü}:lZÚh)¹ÇÅðÛ?÷ÒS{!Wío$mÖ 4¤÷7ˆÚéö@&æóùÁ|`~t^Â2J/cº çp½lcæómÈÎ+æorƒ×¡Ëì§wë’1(ûãbè¡åÁït¥´£ô Ë¯äŸ½idECÒëï‡r¯-ýò3È72teáP»8àÁ…úXù˜xˆšãËVˆÑ‘D¢°'»¶Ð?–Dž…§ãa{Ã€æà™yµ'r¹o‹Áþv1
ú+Œ¶‹ƒQ†4Ðo
õ2Ýž<zî5Â\
s)ôW*ÑïYú÷$\˜ædF]fÔ«qï:ôáò—dù§÷Š‰I¸”ÎeŒòŒ@ÞGH¯áoÒè@Ô©·‚Ž§tpîÒAäÔCY@ù=(~j…ÈÖ‰$–ü‡'áB]@½¶Ðoëõu”[[:û¤¬W¼Ú–?ô ?Dt‡è({¬N¤
"™†8ƒ#IÌËÙwM~HãBtÖ:Ã²N?áÔjwä‰Ò•#¨¾z§V8µËŠZyŸbû½õþÏ´ž°-ã=…y¶x—Gðé²¼-Ð¾–Ê|´‹c"‘#	[!cdÜnÉÈR¼”Ž2ß
dºï€îòkK¼«ùd=í‡¡­t}ŸA—ú¤{´ôõräR|¡ÚÊ—™mEÆ«“õfÊ]#w}¼Ü3'¹»¹G¬xñòØV¬ð{M9T· ƒ3»5]ééÌëF@€;²Ž¨2œÙ<CÝ	Òž>c¤=j•AË½d†º1å>iökru¼Ýf_Fº1Ão5ån<ê#°;¿G÷­…½À}Æ ö‡àßEþ†ÔÕ—ýdƒt=ì+ ÉþdÏæ¯FªQ¿Ó+{Ú¢Â>d¤Vòì"£$ãÀH}H–·'¹º°ç3 ï®¯öÜp3ð¡Ì÷ß5ú‰cªÿTòAÇ. /Ø·¶ôÞð¹Ï¤ÑI×;4Ò ýbz`ðº	!v§'_Zù”XóÀT{vÏÂõŸ­ôÌ¾®$àÚ€2Äàˆ˜·kd…È­ôJ/ëçdLžÔ3íÉÒäÙ*6òöG§Ã slïÄÀàÞ©y»®›*•hü°|d^¢°÷—gL@Þ~Wœ'oÀw=ôûK§`¬¸ŒÆ‡‡ü<AÚoCÚeyKãùÞ­3ÈÇ´ÔÙJÓKþ¶T‚¶Ûë?çëçùB¿ôEc,qGéÆ‡qÄ›QcäßóûL¡¡=Û›óÄž¿Yõá}…†¹›FV­ïGÿžƒM-×ÎÔÖªÖe«Z'×‰Z5V“åMc{€1ÙØFÀ=ŽÏ]£› ÷ip“à>n¸ƒ[îApkÀÅ{Çt#àÖ‹ýÜ7¥­æ8nH¦ñÞîÈq6­pŸÉº)D¥µSˆJë§‹7ë¯£R/Y•lÅ•…ŒöâJ„8RNË0¹¹‡u$W¯íPsNóOÉ	ùO“_~ÿH	GS¥ü‰aòW+¿«ç(uÎÿš\ýC‡‡Â ïð~X ?Ía;zî_¯ÝÐß4”y¡Úè5)\µ 5'ž&¿Ö“C~š3;ß±)§qZ¥[}\ù>
Õ§£éUÑôÔóÑte&‚>M¯‰_C¯ßM¿Ô‹¦Ïn‰¡‹¤“?å4Õ†és+·yŒÂE(\¤&É¥úUsçàÒ^ã ¹ƒä®'wˆÜarG•üèï‹†;i¯ì+[5Øg­,ìÆ<)3á¢8&Ö©»&P™n‚¾ùèvø«õým®ÅÑX.å½’wÊÿ©ä›~ÿKùQýö¦Í÷mÞºdã=;vî\’ÏoT¿ð¾Å]½=êh¾%ù÷o¾§1ß»ýîí;îß¾XžF·ø«Ûï]¢Îç=,þª\»zj@ñ)Ê’;ïõ3ü„’3CrÁ1€Ý}ÝTì”,ö±ØÛÅ–gÚg~ÀO¤Zö'³—Öûg^$õ„ÏQ¬sõÍ‘xM8óæ©5µj ±ˆóp/u@­>¸©>Úý(xÖæ¯¹hÛËŠv*ÑR^ˆªáD]@ýÈ6N/hQï¿òª^¹4øsu1­æ½çÎí‡ï@é;ò›ôJ_¹Æ7¼Ð÷Bgü8 ×#¨ô|XÙ¼˜†¹îN›J5ùi¾©lÞIÃÐàœ“¹×¿ùã¸uîì‘v­ÆmÄ¯ÇwÚ•ó€UF¾5¿œ?Á<ñëñ¢?nÔãC³ü7ã6â7O-”háü»†{‹üiâ'Wê/*ÿˆ†lÍŸ#~r=?¨Çµfù·ri|¬Ÿ¿þsØž7ÓßÁï?¹æd%€6íjðëñ€?.è¨þ^QÖ~q_¯üEnèHB›ÿkåüô~¡Ý²¸é×GM"èý@Ïïj·lÜa¦¯MÇšü4ÞÑnEþ'Êùõx³)*¾í:‚ŸÂýqmºÿ³"Xï¯ù©¾BóÕæºæÇrýCyúÍôþ§ÝŠåà§uþz&ÿ¿œŸßIWà7×dõ[ÚÎ:°øÑý7ÃOë ôû¥ÿžiÃì†~ëýT»±ùÇûÿrþ9‡­ôíöc¦?aùøüRJÄòûçN²Ìö0]_?Çþ;>}')bù[u¾Óø›*ð?Nqþ*ž¿ìUWÐzg^~k-½‰OÓ{PÖCFg\˜õ_f:8Àbêÿ“öR¤øu÷ôÚ{c}¦[ãŸž úI‹Nßuüï6šnßÑtzŽ„»m½V?x¾úôZ¢ç,z¢ûÏAM¯'ºgÑÝni:­¥õŸGš®¾_ÏM—küƒçˆOŸMôÓ]½çZßôÚûû„ÞôÓ>½YÑý~WÓé»H¸?Õ{"ès½Å®Gõ=Ì	÷kzÏ@ýrEŸcç'l9 _Co‹¡*†nßošÞCOÇÐ3d‡ÖìÛ˜C_C_C¿!†Ž{›t}õþªë·çj³]ý$FÎÏèöyÚ‰nŸ:‘íÓipÊëHÎNÐÇŒø×Ï‹ÑžkzúüùwVùŸ4èƒFþñ¢s»yŸ:wÇ”ë~#?æs?¦¾œ¯ÇÐÏEÓÝZC>«å# É ëõ½@¿2FÎU1ôÞz.â!3ô?HGöî–¦ ?šíÍÝMç)YíÇýó¦òþã3]ž.Æ‹¡^'ç¾jÈ?mÐ_kòÛ¿ú.,ä~F÷gåý6<PÜw‚øêû¸GM»ÿ—ŠÔCÂ‰úèôÙÑùLdæG>GAº³õ<Ãc@_ÖèF¦ûùù‘Ï¯Ä—ŒzÑåÅtoÉÏ¶úÞz1¨_³?O|+ºÞß‹‘3ÿG1ñß
âÏ3âÿgLüéhùÉ†èøÉ«cèË£Ë›\Ýäúz¦ñI­4F>“7íS÷3(?z=è¶,–ß½n¾QúN|¯[²yë]KäJ4ˆHÖ¹í;ùs·<5X—*:mÂ…˜Dv	õu÷]+òè,ÙQTÁúšß5t‘¿žÏÜ;ªóÎûîÙ¼³óÎÛ´™
öË{B;xlëáó•7ù§þÎÈÀzÈ<xmê´M™[æÒ;[èA¾:C>Ûv{„—É¦ü»¶:)=Û”zÈÐyO™½öËÀ{e¨ÔÐP½má’‡Ï›Þd™¶ï!‹ë–Mw‹O	¯lß½Ç¶ïÞ£·c)Kìþn6SÑ­âãÀÆá»ñàßÍ[?‘“*îÿ¹¦»§;°ÿÝÓwí5¸ÿgiOïÿ¹(·ÿ]+G¯]5ò`_ÑUíˆš”ÇÿÖˆ¹åÇ·ÿM OõÑÉ´ÿÝâà•“Ö/æÁ¾"¿~¬0¼äÆmaþ‹ÈÉkŒ®ðR,õá”ô)C¨Ée@VÇÅ·9xåä5Bñª1ÒÈ:xåä•ê…Q‡Ñù¾þþó\zÿÞ|ƒxÏÏÙzô`Ø îˆ/á¨Á«W­ôqº)'ùoqs²\G’êp´ÚDN*oqˆðòž‡ˆ”iqüzHGpÐY«ÒËÓ&©<m^Ê£Anu |ù+_¾]ñå1–J;º %p‘ï4¸çªrvÑÎÌÊ×öbžj(®*ÿóŽƒbmc]ëóú¸$ÔËi‚t¢7e`Z¨/Ô©¶™õ1ln­pC?Ö¡ùþŸÒ¤!ý¸á|Þ7!çhºa°YÕi#äÄìaÜ/‚ëÔù8•9o„§ájSÂi}„²K>nÄ®cà¿MöJÌøøacÂ{]Ž¼ÖýUh/£Aæ½µ1'í;6¶ÑÞÕ!ˆ¿Žäáf~¯IÝ‹è×ÇÀµQþ±~°í
^/˜ÉC|ýñ
ë!Õ¨rCùxxñ„#yc¨/ð/"ÿ—-ùxpLÂG)ü{pu?M2”	ÊÇö){ô‘L®G—ä®,¹Km¾’{©‚íU´ç
wYÑÖ+ÚÁ¹IË:¯¸Â6t½÷;ØfÇ"Æ eÃ™`£¹þ¥øú°_W¨žÓêx`üŸ	ò!=A¡ŽìÓRÔnS[¶\‚ G7ÆMè1X—2<)¾H4ßõãÏn[~j÷c2&&J'´ŠM‰Ž¶zû‹>Vsk¶n:Mß¡_(ª4“š÷aÉûD¢Õ{T†yµËTŠ¿ÉŠª±<>äAºµb"‘'L³r"4S^ÉËL±Î; |ß)&Å3¦KN6;ù¤,Ó ÷µâ°7ZTi9Ú"ž:Ú*N <èôK¥òõP˜Æ±‚ÒÏ"ÐÉ"àm§TþæÓŒïÊõÙFú<%VÉoÿ5$ãJª*ÌCN<ø]­ƒ6Y|jì§ó}n•î/Jé¹I±:{É«%9­ÿ6£<¹–Ù@Öþ¢#ÙSbõ˜­[Yÿ÷GÕÿb›÷§Å]À»ä¢¼*HëÇâ;eíóÚqR”×jˆ—²I‘nÖõ‰ºÂô¢Ò¤ôOž=± 7ùÃ£]É<š9=–0ÛáPóšl¦CˆåV¥Ä›Å¬xñ(\’¾HädÛè/.ÈŠ—‹™Ž4ÿêlW_Zò½\Ü&i+ÅªEsE®EËlžEâ¥á>}lhQíÛÍv$_<:›êÃ]#Ü¥ð
/•”?aùá*f&Ç ƒ"è ØŸ<±@·-ÔSÇ}JOãPOË¡žúE §œx¯bœŽ°¬ºL_"Î¤IGõ"ZGm’/ZGmâ¥b=”m•åµBüVJ'Im½h¨£^ˆ¯ê~CJëEÓ.%Z+éD×û0Ôû¦ˆ´»ÄøÑ6+î˜¸˜vä!¥ãSþRb•<s(ÓšóeŒÉv6$r1i‚YG ÿ"è¿˜á::°KÕÑÔÑmPGë©ŽZ¡Ž† Ž6‰W ýŒÃï—ŠXþfÒÝ¦@gYxúËû(“òõ|óç²y+O­§µM,ã"(£–{Åå¾#·žäêx¢.x`ø ¤Uï(}bšðtÊ¦g˜æxLš)JSó×ÆðwÔ—çå¿¬¶pê±‘Fââ}Ò)ª²#áË!|9¥ßH}«öCo<¦ï1¼_n‰àï0øÈÿGI¯íÒËZéPz•x°/Ðæsg"?íu}DÖI”Ž1”§5ò÷…ë{à<ùë(ÿLÓ‹Ò÷ùÒëI¯O—¡ï™ÈÇ~ž!Ôo©{
Ê	mKõ•ŸM­†w/u¯@|¨£€>ÛºoOÁ}Ð/^¹¯B>þ¹h÷kêþ?:—ò×ë÷OÉ¾ËñÉ{äu€¼,Èë‘‡ùÆ{Ò%™(úMè‹Ð'‡Œ~Ó„Ù—öï qô¥]Ð—.´C‡gö÷¡M>ýÿ³ð¬9&Ç+CÌOdÆÆd^2‡ÇýñI¿÷`q§>zP<xuË5eF‡DÆCê²odÒcn¦Ãs3]C.òC×vòO—ç$E÷U~Ò‡:8eÿ>ÜCÏÁóïÙ"¤_Ä<÷Ó8UŽÿ¶ã©6È·Î£b¿àÔ¹Ò 5–ºü8ø 4î¹Rê*àõåëqp
ËY˜H ßå¢5kú[-ÿË™åo¶ü)Ë?ÛòÏ²üõ–¿ÎòWƒß®_ÔÏÐ¶òñ¦9¦Ïm³ÞjfþŽàXK.ÞyÝ=Ëº*ï3û¤ö˜1ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0ƒÁ`0~{P˜îGÅ,!R3ˆæ	‘C·,î©¦œþ™‡ßÇ”?5îk9ÑÚ˜‡à·Gñþ¿]«ŽêºÎ÷½]¡¿EÚ	´Ù•Ú·Z	®lVH	ôG;a¼ûv÷I»°ì®Lp-ÓÔ…ÁŽ‹qˆk»3tìzhšéxÆ‰ë8™í$ÁÓ¡°™Úm5TšÎ8.A­J
cõœ{ïûÕ
›q“43ºÒÝ÷Î=ß=÷ÿçœw&—IÞ†çOÂÓï;º»ï÷6ïØýùû¼í¾V_ë¯7…l€(ÒÙéïu¨S¯w;<Ï”)FMTÃwx‚´“jJƒ¦Îú=]®€¿‰t¢0?¾(‘â™”"¥äÜþ‰¼”Q¤ÈD"“RÀLÉI)’Ú¼ÑÏÓ
©¬ô•Ln¿4žLD¢-_›oãúèÁ|ÀïßØÚêßÜ’óKÈ‘¢ù	Íòvz¾ÖMÐ2a’ÕÀIk0õ©à"Î%¶²Ue÷”yJ Vú}ZÃ§‘#Üªª€_ûJø¿­E¶¤Ù¼’lI&Ò‡heý!š+$|£Ë·‹¤DÄy`Û*|¯¯O´CÅhÎ	[3¦õ=Ñ7)–©é8GlÕÂ[Þß·“eøÞÿ¯¶¥mÃ9k«~ßÐ4œ¾6‡š„™Êé:=wÛ°ÏtÀ”_ÏˆÍóù˜¢òq/°òÃ>îÅÂjÎ¯£ü­“7åøÄ—?œ*ÈxrìWßé‚’Ë_:SP|]Ûú[
ò8ñå”ñDz,C|±Ãi9•ˆ_\ÎÇ)	¢Ø³#¾ñô„ï ’Ë'2iÊ¡äDø
Ê!øÝÕ?4
…ODòÄ‡}%dbrA&>%ËÉ)…ø¢…LØ1öØ’KÆB)ê8žQùHØô'šI¥”4¤Å”ÈÄxHÎÉéq%¯’¼Œ‰ä”ƒ*ƒåecPBŠ¦øäH¢-P´‹…U89	Û³j„ DB–ø®ƒXÊqM€k†×€³ó'î­KÉ"®p=€«³à¾Ÿá¨¼½€Û¸›¼W±b	Çíƒ	ùÏ«â0öC¬ä¸2["ìá“'pî‰ÃmwÖ„rÕFÚû¡gmq·K‚	=ÔrEÇ ~Ìq~Ø'ü 2ô•Ú/\6æÇýd^^)Ò_5àü°8ý¥¼a<¨gÍF=SaÑ‘÷´‡{ÛuÀ=\wŠèó`ö‰!à8µÜ¸`M¢.Ã(ïÏ8Î¦eèxZqß6à€ï,[ ÷ºÂœN Š•û¦çœ(‘vüµãåZ@ÞyçÓ(¬Eb/°úSÜE“ŠèóêGTœ·HýÞ3ä!+Ð»…UÞB÷V­JC°‹ÇWíËÿ°àÎÎ^dÞß²à¾-šë§âÊ3îàþ¸ˆ¼ZÁÜŽ8zÆ@«ý¼Ò‚++)Þ.¢Í)×\¤\uŽªa²R aXká}+Ñ÷ƒr‹¼+.ê8_^±€û%¡ùªI£YÉ=ÍJØ«Ñ¬ ÜÏ]ÂÚbSi¶ËàþÄh¶+â>Äh6ª¸ß0ºœµQ£+¿T¥Ùâw«´ƒ>¯k4ÛñqÝ3ºŠ>q}3ºZm²“Ñl––i´KerÚMi¯F{˜|®¡tX£k)}Q£—YèåÄl¦éz¥…^e¡ë-ôj½ÆB7Xh¯…^kš'vò‹9‡…n†çS|<pCß`á·Yè-ô·ÓI0ˆÿ-ÿGì•ö— w‰>>ŒÏ4ÑÇS€ñüO¢— ã…—?ìozY…þÆ— Æ÷åÈ7”ßôeà×qü 'Ë®_¯@×œV¿A×I±~!Á\¿”`®ßa,ß¥Ë·ö×3‚™¾e¡KqIÂÝ÷
ÌïÙ]öN¯Íø{D}þ:¡ý€šd´øE¶ž¼gûQß+ÿ°¨¯wH”E¦û#ŸçåáLl„øœA¾ò?´›é ˆÿÐ¨G¿Æéïcù¼~.ÑCÞÙÝºŒò+Éû@£þ[â&êûƒö‡,å»lú~ùWh'Ð^ '¹ŽŒò‚6}=»`=ïõÿÎßkcwùïpyI›¾ž±}‡lLWè€­Ï-V’Çð¾ùÛE–ÿ/šãÿÂ¦ÇZèá7€FÄ^^ÞÛ6}?sÃ~ö@£âçÿÄRþU›¾ÿ¸`ÿ¹e£÷Ï·höØÙþh§ø*Òh×ëã‚úH†3ÒI·Ý\^¿ÙPÔú<bÀcÿ¸¶·PÅe”ø|Rþp>¦dóªx’’“ò9W ^<Y Zhx¿2Å¾¸v)qU9*'“¡ñ(F´N¨e‚646Õ…º÷Ž„úG÷„B@õ˜¨Þ¾Ðö‘®]½¡m½;úwÓ¤Ý lR)(1_ °eÉâ£ ±Lh<™‰ÈÉÕ¦BòÄ!’‰ìS¢_ ­½P+›H¥«å÷îîÑ‹W	V´JaÁê»^BT+á×Õ¡¨ŸË¹h<W¢û¡éØ[ô:ý>â¡1ªE†Æ³¡X"Ÿ% ·Fã¹`pÇ@ÿ¶îPÀç'¡žGvwíêï†^ÝýPÿîZbcY6„ªqtf¦¶R-ÓgE¤LÙ¢ÉL^1Ë‰å3¡¸œŽ% °BÐ¼UŽ³…¼	LUiÈ¢|Rá|z…Æ¨Ú
yh\)0é\3×á€ô„vua™¤Y”V'^:¨Ü\|JN¤U M	aŠ97f<')éÁ1à¹³¹Dº0fBÓVg²ŠY†ÂnÇÀà¶®Ðàöí£½{B{º¶ôÂD¡¦RxËûá-–H‡&ò
"‡vðìNÊù¼’‡¢Ñ’Sä˜¹úúZ…é¾~;C4¾?oÿÕ–á‡°yãFú„`y¶n
lj#­@ Õhoóo&þVÿ¦M›‰×ÿÉ¢?{˜Àìõ’\&S¸î“ø¿¥áñÞíÌ”Ì‚H>Gï›gJØ÷ŠcN¦Ë¶Ãí£”4ƒ´œj‘í4i¼B˜½ µM¼~àí}Ìî¤Zš‡óbÔ}ƒ4Öšˆ‘i«å³´.ýÐ!¨62jÁ–bì¢ï®—Ýn÷áRŒ]4z	»;©¼á«…X±¾Póã	Vz¢úò8h›T{Óš·‘É¾'V‰Nç )L6©6Ôˆ_}éH×®?9òæúýµ_záw«_›Ú_sð½ù¹«:ùS?zë§êþ“Sõ¯¾xªþÑÓ§ê¥ÝÌZë‚rq=ïuë!>\¢Ó¨Yü^ˆ{4P®@Û18!å!x^0ðñù3kÍn¶F¯ÆïTšôs†ü_Ä10ÐBì4à	ž„Ø—›èÑ×Ò7ìòÀ;~ÂÒ“¦è¹Ì®ôäW~˜ÐBÊX6Í…ÊÉ	8Ãôàg‚ö¦þ±Ù'Ý^æN$–bŽÇ9]WÕE^á†z|ç÷m/¾ó‰Ý„ïÜ¶ÚŒï\iß€ïÜÐëÇwn”nÇwnPëÀwfv!øÎæA|çºU¾3Sù±tMj,9oŸrtÚÏÛ/9Z+»fÒ%gÊaÕú+ª¬—ßáO¸$ž_'|.Øz&
êõAæÞÁÙt%™MÂº¼(†—H6ø]œ³|5P'D;¤Š—Ö=aü–“&˜ØGŠñ°Ïð°ëàaŸ6-ÀÃ>ö/ÀÃ>ï\€‡cÐ· ÇdÏ<£ð<³ä<ÃCðpL¿FŠ„f•™±íÒ’‹0—íï•\ªì*'ì×_í]·"®5u=Ã“ÒiéUéÉõ/ƒ¯Éuk—Ÿp¾ïüg×?íXÛ÷lxmßÜ¡£~ÇÓÂ´ï+þ¥€rŸõÿ÷3Bv.+L;×Ã<Ø?»o6s!^NúppO…8 ï%—·Tûqû¥ºµÂñõ»’Îf¾÷4~ùdÝVé’'F®úh­÷œ¼ÝêpÃoý°«K8Þsu'R£}'{Ÿ½ØÐÚûl[Ì£¬[GñÀ[êÚBñžXM µz$8½,ÐtbäY²ùÔí¶ÎÖ5î{O®£2ìœ¨}ÀvBø  y Œ'—i‘rDà,ÎÜ´[ñù¯Ò°í›G¶Þ;ˆ­¨±_¶]¿EìŽ Ý;qÿÅ=¶qpêñù§ú]ø»bÛÖJë…ôRšºš¶mèK[=<qä<±uJÅµfYÅ‘žX“–¶f¤êÖ~b&òÓÜŒì8ÐàÆÔ†a¨µ\/»%aúFØé/9.ÒgÅq7”P½[K%iWC¤x ÅES„+BC5¯EÃ°ó€K^-{"ŽKX—J-Ï/†šgm6¶³ÚgPžG iÛÏAÛ{ æ£®™™®‡úÕŒ`VŸ˜‘=PO·|ú”~šJ·Áì¡5‚éÒ_§ÈYæ-9ÁÞÄ†ÿk\3bô2ý5Šžäè
š^éžØã<_#ä{Úö+;2#ÿÔt9ô°ïêa-­Òê†ëÖºÃs„L;†\­¸–å#£A”p`¹[•Ÿ'aM	a.¡J“PëÖ¹snµk)5}Ä‹L7¸YY±Z™÷PyµÃËÜø‹õé¹c‹j¹äN.¹ÜT&¡ýŽ-R%¬ç*æI@®:w+y‹Ôô5†\dzä¨Á¹Æm&²b´eØÓÖJßWŽúà}ý	Ï»3òŠ/ÎÈ+GfäUÃm±<ìžñj>KÝm ÿ9˜‡xÏxžá%Aò<ÛKƒpÆé}ï,xOÁ»ÌY>g«@îj»æ d¯vKX‚«–1^ÊV
”€» –tc(È×Ã¹|Rª=Z"ÿþªÝ÷†4ºÿÇ’ûÒ?JÎ©k’£Óù~ã MèNU_ªëð¤×ö­í+=sáÁ²àGÂ»±×•—Ç*»„ÃG·Ì>s*Œçêlj6©ïªÇDdoÎÍ9æX4îß¥—ž”†æŽ•>Ý8è‰wªÞ>t4<wìN`ýfãSŽ®;žï×¤™ô@¦‹óÙýÁv^„ûÃLÚFï7A°ÞÞüåÜœñN€w')’HKÉ<éQ
J´ Ä¼mH¢àíÊf“‰¨\À›ÎÛÔ>7‘–#IÅ[Èxcu¿÷ž^kZdˆˆJr-U_;)(ùB"=îÅ{žwð!@úè?âM¼ïö®þÞosN90‘ÈAÑ4ß!½>ÀònðŽg
jêýš¼ûø½ª˜_œª»àýåœ-È¾nÁüø¯ç2Í ç þƒT84Š:N¸N ±–ËÁë£ÎN¼ÎýDüj…WAüå¹øÝß	OôÀò®Ãó†8ÿlÿô].Õo“(sÇîÏÓ4¬Ö¿Lmàg6†>˜ó1ˆ“_‚ø&ÄË¯CtÀÚj†Ø1ñÞó™/Üèž]‰h.£$a8s™t"š—P‹òn“ó
zÉµùÚ½¿Kkk m1ÓgËô)\–ÐßèîÝ’rJRöe“³ƒÒÝ8%©.Qkvœ¢.J&ç¤»ÅüŠ<¾Ñ¯h–ûÏàÚÄïsa¢“Wm-D÷ïÁ5{L`¶ÕV¡®™D÷ïÁ5ÙÚ¶–û Ñý{pÍÞÙ·0µ\Õ¿g'Ñý{p­;mºB-Ã#üúÎoc{Ê+ç<Ü¢D÷ÇÁ½é "†úyùóQŽêU  iú¦ÉbÂ€C[ÐØÜÂKæËËp¸be6)WõSÂvt ®pSœÚÞÇ¸š¥0¾K‹ûý!Ñýl˜ˆõïùºç¥zKqÜ78Ô]š(÷ÞVÄ1û³=Ù8”ÿ²AÞà¦–šŸUüŸÝ§‹Ù«Šû¿ý•AžŽ*BõZ#ãˆî„ºZ_Uñöþ1û  ._ÄßÅêóýjBþŽÌÇYýbž‡CÍ	s=(ÚÉÂ~1gPiH¸¿˜f‹_Ì1‹_®SF³VßÐhfitZübüÍ3ç4šõ`“æ7Ã4g4¿~ip¨43þth43 á|f43êÔñóVõ‹ñj4ó‹iÖh6s6h4ó‹™Òhæó¡F³ÑQ¥ÒÌ/¦O£Õ›áô2Ú£?äí!Ðlñ4ÖèœFûßÛýP.h£íý6[èmz—¡?è/úý6†þ@?ƒð¼ÂË¡¼§xûØ­–ú¢}ÂÎi\gÁ%:ÞZþwáYo(ÿo‰>^Œ×EKù¸w©ÔåYÛwÃBLÕW.s|Tõ–ÛœvYüJê}ü±†½ˆXEº-ô}~"ó{Qç‡æÇ>Ál/>4Úì„ùm<%èóéS‚ÙžŒ¶Í+¼½ÀÝP_/Äóôb¬â+Éßfûó”`¶g(°õÁüä–¡¾ˆ/Íöeô£1Ú—ÑoÆhÏîÍöì]Hsy.ÑM¾t“FW“q ÑvçíýŠh¶SÔ×úY¼,šíáßÍöíwÐ¯Æ€O4ÛëÿM4ÛÏi‘[Úón¢ŸŠXAJlúþãÆÕ8À¾ 0óö ûâ<0Ïî=b–õù¾ŸÚŸÂà<QÜMBw©Ø¸©uAF(;T õN~wç*qîÅ?[¿¯û®z1ÜáÛ{`žïê bvXX?‰ÿ–N˜?N˜}wü@ou·Ìó¤X¼ì[‹¹¢&Ï
“?‹Ù¥á“Ý#t—«×HàNþæž`ö*Ìs²¨.ì£­ÓbX‹a1,†Å°Ãbøáè¼v H 