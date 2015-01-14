#!/bin/bash

# v1.0 vdrserver
#PCI Ports resetten

pciPort=$(lspci | grep Multimedia | awk -F":" '{ print $1 }' | sort | uniq | tr "\n" " ")
if [ "x$pciPort" != "x" ]; then
        logger -t INFO "PCI Portreset wird durchgefuehrt (Ports: $(lspci | grep Multimedia | awk -F":" '{ print $1 }' | sort | uniq | tr '\n' ' '))"
        for getPort in $pciPort; do
                echo 1 > /sys/bus/pci/devices/0000:"${getPort}":00.0/rescan
                echo 1 > /sys/bus/pci/devices/0000:"${getPort}":00.0/reset
                echo 1 > /sys/bus/pci/rescan
        done
fi


