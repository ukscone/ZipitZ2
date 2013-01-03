#!/bin/bash
##########################################################################################################################
# ewoc-cli.sh v0.02 (15/01/2011) aka Easy Wifi Configurator -- EWoC                                                      #
# By Russell K. Davis with input from jaldher, g8787/geordy, Ray Dios Haque, pcurtis, wicknix, brianith and lfod et al.  #
# This version is tailored for use on debian based distros, it definatly won't work on IZ2S/IZ2Se/EZ2S but it might work #
# on other distros.                                                                                                      #
##########################################################################################################################
# Read the desired wifi device from the command line, else use the default.
wifidevice=$1
if [ "$wifidevice" == "" ]; then
	wifidevice=eth0
fi

# Make sure the wifi device is ready for use (scanning)
ifconfig $wifidevice down
sleep 5
ifconfig $wifidevice up
sleep 5


# Do you want to use the existing settings in /etc/wpa_supplicant.conf                				
if [ -e /etc/wpa_supplicant.conf ]; then
	currentssid=`grep ssid /etc/wpa_supplicant.conf | sed -e 's/.*ssid="//' -e 's/"//'`
	echo -n "Use existing wpa_supplicant.conf settings ($currentssid) [Y/n] "
	read existingsettings
fi
if [ "$existingsettings" == "n" ]; then
# No we do not want to use the existing settings in /etc/wpa_supplicant.conf
	array=(`iwlist $wifidevice scan | grep 'ESSID' | sed -e 's/.*ESSID:"\([^"]\+\)".*/  \1/'`)
	LIST=${array[@]}
	select SSID in $LIST; do
		NEWSSID=$SSID
		break
	done
	
	LIST="WPA/WPA2 WEP(Hex) WEP(ASCII) None"
	select OPT in $LIST; do
		CIPHER=$OPT
		break
	done
	case $CIPHER in
		"WPA/WPA2")
			echo -n "Enter Passphrase: "
			read passphrase
			wpa_passphrase $NEWSSID $passphrase | grep -v "^#" | grep -v "#psk=" > /etc/wpa_supplicant.conf
			;;
		"WEP(Hex)")
			echo -n "Enter Hex WEP Key: "
			read passphrase
			 echo "network={
				ssid=\"$NEWSSID\"
			        key_mgmt=NONE
			        wep_key0=$passphrase
			        }" > /etc/wpa_supplicant.conf
			;;
		"WEP(Ascii)")
			echo -n "Enter ASCII WEP Key: "
			read passphrase
			echo "network={
		i		ssid=\"$NEWSSID\"
				key_mgmt=NONE
				wep_key0=i\"$passphrase\"
			}" > /etc/wpa_supplicant.conf
			                                                                                                                                                                                 
			;;
		"None")
			echo "network={
				ssid=\"$NEWSSID\"
     		                key_mgmt=NONE
			}" > /etc/wpa_supplicant.conf
			;;
	esac
fi
# Try to start wifi
wpa_supplicant -B -i$wifidevice -c /etc/wpa_supplicant.conf
dhclient $wifidevice -1 > /dev/tty
nolease=$?
if [ $nolease -eq 2  ] ;  then
	LIST="Poweroff Reboot Continue"
	select OPT in $LIST; do
		case $OPT in
			Poweroff)
				echo "Powering off"
				poweroff
				;;
			Reboot)
				echo "Rebooting"
				reboot
				;;
			Continue)
				echo "Exitting. If you wish to start wifi later"
				echo "then rerun the ewoc-cli.sh script."
				;;
		esac
	done
fi
