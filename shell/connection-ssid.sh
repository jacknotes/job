#!/bin/sh
#for CentOS-7.6
#-D wext is general mode
ifconfig wlan0 up
wpa_passphrase "2123" "Dd2020year" >> /etc/wpa_supplicant/wpa_supplicant.conf
wpa_supplicant -B -D wext -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
dhclient wlan0
