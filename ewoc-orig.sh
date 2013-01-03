# setup-wifi.sh 07/04/10-5 aka Easy Wifi Configurator -- EWoC
. /mnt/sd0/etc/brand.cfg

currentssid=`grep ssid /mnt/sd0/etc/wpa_supplicant.conf | /mnt/sd0/bin/sed -e 's/.*ssid="/\1/' -e 's/"/\1/'`
dialog --backtitle "$backtitle" --title "Use current Wifi settings?" --yesno "SSID: $currentssid" 6 0
if [ $? -ne 0 ]; then 
	/mnt/sd0/bin/iwlist eth0 scan | /mnt/sd0/bin/grep 'ESSID' | /mnt/sd0/bin/sed -e 's/.*ESSID:"\([^"]\+\)".*/  \1/' > /tmp/ap_list.txt

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
          --title "Encryption Method" \
          --radiolist "" \
          8 30 4 \
          1 "WPA/WPA2" on \
          2 "WEP (hex)" off \
          3 "WEP (ascii)" off \
          4 "None" off 2>/tmp/encryption.ans


	echo "ctrl_interface=/tmp/wpa_ctrl" > /mnt/sd0/etc/wpa_supplicant.conf

	SSID=`cat /tmp/ssid.ans`
	ENCRYPTION=`cat /tmp/encryption.ans`

	case $ENCRYPTION in
		'1')
			dialog --nocancel --ok-label "Submit" \
       			--backtitle "$backtitle" \
              		--title "Passphrase" \
                	--inputbox ""  8 30 2>/tmp/passphrase.ans
                	PASSPHRASE=`cat /tmp/passphrase.ans`
                
                     	
	 		/mnt/sd0/bin/wpa_passphrase $SSID $PASSPHRASE | grep -v "^#" | grep -v "#psk=" >> /mnt/sd0/etc/wpa_supplicant.conf
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
                          	}" >> /mnt/sd0/etc/wpa_supplicant.conf
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
		               }" >> /mnt/sd0/etc/wpa_supplicant.conf
		;;
		'4')
			echo "network={
		               ssid=\"$SSID\"
		               key_mgmt=NONE
		               }" >> /mnt/sd0/etc/wpa_supplicant.conf
		;;
	esac
fi
/mnt/ffs/wpa_supplicant/wpa_supplicant -B -ieth0 -c /mnt/sd0/etc/wpa_supplicant.conf
echo Obtaining an IP address ... > /dev/tty0
udhcpc -n | /mnt/sd0/bin/busybox tee /tmp/udhcpc.log > /dev/tty0
/mnt/sd0/bin/grep "No lease, failing" /tmp/udhcpc.log
nolease=$?
if [ $nolease -eq 0  ] ;  then
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
else
	/mnt/sd0/bin/ntpdate 0.pool.ntp.org
fi
