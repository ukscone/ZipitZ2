#! /bin/bash
# ewoc-z2sid.sh 20/12/10 aka Easy Wifi Configurator -- EWoC
# By Russell K. Davis with input from jaldher, g8787/geordy, Ray Dios Haque, pcurtis, wicknix, brianith and lfod
backtitle="Easy Wifi Configurator -- EWoC"

wifidevice=eth1

if ! which dialog > /dev/null; then
	echo "Please install package: dialog"
	exit
fi
if ! which sed > /dev/null; then
        echo "Please install package: sed"
        exit
fi

if ! which gawk > /dev/null; then
	echo "Please install package: gawk"
	exit
fi

if ! which dhclient > /dev/null; then
	echo "Please install package: dhclient"
	exit
fi

current=1
if [ -e /etc/wpa_supplicant.conf ]; then
	currentssid=`grep ssid /etc/wpa_supplicant.conf | sed -e 's/.*ssid="//' -e 's/"//'`
	dialog --backtitle "$backtitle" --title "Use current Wifi settings?" --yesno "SSID: $currentssid" 6 0
	current=$?
fi


if [ $current -ne 0 ]; then 
	iwlist $wifidevice scan | grep 'ESSID' | sed -e 's/.*ESSID:"\([^"]\+\)".*/  \1/' > /tmp/ap_list.txt
#todo: needs rewriting to use --file 
	echo "dialog --nocancel --backtitle \"$backtitle\" \\" > /tmp/choose_ap.sh
	echo "--title \"Choose SSID\" \\" >> /tmp/choose_ap.sh
	echo "--radiolist \"\" \\" >> /tmp/choose_ap.sh

	LINES=`wc -l < /tmp/ap_list.txt`
	LINES=$((${LINES}+1))
	echo "8 30 ${LINES} \\" >> /tmp/choose_ap.sh
	CNT=1
	for LINE in `cat /tmp/ap_list.txt`
	do
  		echo "${CNT} $LINE off \\" >> /tmp/choose_ap.sh
    		CNT=$((${CNT}+1))
    	done
    	echo "${CNT} NAMED\ SSID on 2>/tmp/ssidnumber.ans" >>/tmp/choose_ap.sh
    
    
   	chmod 777 /tmp/choose_ap.sh
    	. /tmp/choose_ap.sh
    	
    	CHOOSENSSID=`cat /tmp/ssidnumber.ans`
    	
    	if [ $CHOOSENSSID == $LINES ]; then
		dialog --nocancel --ok-label "Submit" \
	  	--backtitle "$backtitle" \
	  	--title "SSID" \
	  	--inputbox ""  8 30 2>/tmp/ssid.ans
	else
		cat /tmp/ap_list.txt | gawk -v SSID=$CHOOSENSSID '{ if (NR==SSID) print $0 }' | sed -e 's/^[ \t]*//' >/tmp/ssid.ans
	  	
	fi
	
	dialog --nocancel --backtitle "$backtitle" \
          --title "Cipher Method" \
          --radiolist "" \
          8 30 4 \
          1 "WPA/WPA2" on \
          2 "WEP (hex)" off \
          3 "WEP (ascii)" off \
          4 "None" off 2>/tmp/cipher.ans


	SSID=`cat /tmp/ssid.ans`
	ENCRYPTION=`cat /tmp/cipher.ans`

	case $ENCRYPTION in
		'1')
			dialog --nocancel --ok-label "Submit" \
       			--backtitle "$backtitle" \
              		--title "Passphrase" \
                	--inputbox ""  8 30 2>/tmp/passphrase.ans
                	PASSPHRASE=`cat /tmp/passphrase.ans`
                
                     	
	 		wpa_passphrase $SSID $PASSPHRASE | grep -v "^#" | grep -v "#psk=" > /etc/wpa_supplicant.conf
		;;
		'2')
		 	dialog --nocancel --ok-label "Submit" \
		   	--backtitle "$backtitle" \
		   	--title "Passphrase" \
		   	--inputbox "WEP key (hex)"  8 30 2>/tmp/passphrase.ans
		   	PASSPHRASE=`cat /tmp/passphrase.ans`

	                echo "network={
                         	ssid=\"$SSID\"
                        	key_mgmt=NONE
                          	wep_key0=$PASSPHRASE
                          	}" > /etc/wpa_supplicant.conf
		;;
		'3')
			dialog --nocancel --ok-label "Submit" \
		 	  --backtitle "$backtitle" \
		 	  --title "Passphrase" \
		 	  --inputbox "WEP key (ascii)"  8 30 2>/tmp/passphrase.ans
		 	PASSPHRASE=`cat /tmp/passphrase.ans`
		                                                                 
		 	echo "network={
		               ssid=\"$SSID\"
		               key_mgmt=NONE
		               wep_key0=\"$PASSPHRASE\"
		               }" > /etc/wpa_supplicant.conf
		;;
		'4')
			echo "network={
		               ssid=\"$SSID\"
		               key_mgmt=NONE
		               }" > /etc/wpa_supplicant.conf
		;;
	esac
fi
wpa_supplicant -B -i$wifidevice -c /etc/wpa_supplicant.conf
dhclient $wifidevice -1 > /dev/tty0
nolease=$?
if [ $nolease -eq 2  ] ;  then
	dialog --backtitle "$backtitle" --title "Wifi Error" --ok-label "Poweroff" --extra-button --extra-label "Reboot" --cancel-label "Continue" --yesno "" 0 0
  
      	case $? in
     	3)
    		echo "Rebooting " > /dev/tty0
   		reboot
  		sleep 5
 		;;
        0)
 		echo "Powering off " > /dev/tty0
       		poweroff
       		sleep 5
       		;;
      esac
fi
#Uncomment if you want to set the correct time/date
#ntpdate pool.ntp.org
#Uncomment if you want to start dropbear
#dropbear
