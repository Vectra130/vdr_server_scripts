#!/bin/bash
newAdress="00:08:74:2d:0b:c3"

ifconfig eth0 down
sleep 2
ifconfig eth0 hw ether $newAdress
sleep 2
ifconfig eth0 up
sleep 10
reboot
exit 0
