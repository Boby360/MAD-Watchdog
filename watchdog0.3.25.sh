#!/system/bin/sh
#MAD watchdog script
ver='0.3.25'
productmodel=`getprop ro.product.model`
#To run at phone startup: 
#su
#rm /data/adb/service.d/*.sh 
#mv /sdcard/watchdog0.3.25.sh /data/adb/service.d/watchdog0.3.25.sh && chmod 777 /data/adb/service.d/watchdog0.3.25.sh && chown 0.0 /data/adb/service.d/watchdog0.3.25.sh
while [ "$(getprop sys.boot_completed)" != 1 ];
do sleep 1;
done
sleep 5

#clean old and make new
rm '/sdcard/watchdog'$ver'_start.txt'
su -c 'echo "Script has started" >> /sdcard/watchdog'$ver'_start.txt'
#used to be a safteynet flag?
rm -r /sdcard/twrp/


#ATVs have a method. Don't screw with them.
#Cleanup random crap we may have put on it
if [ $productmodel == 'atvXperience_v2FF' ]
then
rm /sdcard/awk
rm /sdcard/curl
rm /sdcard/adb_keys
rm /sdcard/acc*.zip
fi

if [ $productmodel != 'atvXperience_v2FF' ]
then

#AWK and curl are pretty handy.
#some devices this doesn't work. They say read-only. on 10a5.
su -c 'cp /sdcard/awk /system/bin/'
su -c 'chmod 777 /system/bin/awk'
su -c 'cp /sdcard/curl /system/bin/'
su -c 'chmod 777 /system/bin/curl'

#Enable ADB over Wifi
setprop service.adb.tcp.port 5555 #( or add line to build.prop?)

#Install ADB key after each reboot to ensure reliability
su -c 'cp /sdcard/adb_keys /data/misc/adb/adb_keys'
su -c 'chown system:shell /data/misc/adb/adb_keys'
sleep 1
#To insert vs override:
#su -c 'cat /sdcard/adb_keys >> /data/misc/adb/adb_keys'


#If I am doing testing, don't reset adb...
FILE=/data/adb/service.d/watchdog$ver.sh
if test -f "$FILE"; then
    su -c 'setprop ctl.restart adbd'
fi

#Global Settings
settings put global bluetooth_on 0
svc nfc disable
svc power stayon true  
settings put global stay_on_while_plugged_in 3
#9hrs. Doesn't seem to stick though.
settings put system screen_off_timeout 40000000

#Rotate Fix (turns off rotation, and does not break samsung lock
settings put system accelerometer_rotation 0

#seems to do nothing:
#settings put system user_rotation 0


#Set hostname in many areas. Works on most devices.
rm /sdcard/hostname*.txt
su -c 'cp /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml /sdcard/'
#This would of been much simpler if I remembered how to handle quotes, in quotes, in quotes.
(sed -n 's:.*<string name="websocket_origin">\(.*\)</string>.*:\1:p' /sdcard/de.grennith.rgc.remotegpscontroller_preferences.xml) >> /sdcard/hostname.txt
hostname=`cat /sdcard/hostname.txt`
echo Device: $hostname
hostname $hostname
setprop net.hostname $hostname
setprop net.bt.name $hostname
settings put system device_name $hostname
settings put global device_name $hostname
setprop persist.usb.serialno $hostname
mv /sdcard/hostname.txt /sdcard/hostname_$hostname.txt
fi

#Do we want to actualy edit buildprop? ro is read only.
#These both push the phone model number
#ro.build.product
#ro.product.name
#ro.product.model

#ATVs are already pretty debloated. Don't screw with them.
if [ $productmodel != 'atvXperience_v2FF' ]
then
echo "not ATV"
#Have we debloated yet?
FILE2=/sdcard/debloat_true.txt
if test -f "$FILE2"; then
    debloat=0;
	else
	debloat=1;
fi
fi
#Debloat
#Alot pulled from https://gist.github.com/gsurrel/40cc506ac7e31134a87be4ba01a71103

#personal list/cherry picked
if [ $debloat == 1 ]
then
	pm uninstall -k --user 0 com.sec.android.diagmonagent
	pm uninstall -k --user 0 com.qualcomm.qcrilmsgtunnel
	pm uninstall -k --user 0 com.samsung.android.widgetapp.briefing
	pm uninstall -k --user 0 flipboard.boxer.app
	pm uninstall -k --user 0 com.samsung.android.email.provider
	pm uninstall -k --user 0 com.android.email
	pm uninstall -k --user 0 com.google.android.email
	pm uninstall -k --user 0 com.android.calendar
	pm uninstall -k --user 0 com.android.musicfx
	pm uninstall -k --user 0 com.android.printspooler
	pm uninstall -k --user 0 com.android.providers.calendar
	pm uninstall -k --user 0 com.google.android.calendar
	pm uninstall -k --user 0 com.telus.myaccount
	pm uninstall -k --user 0 com.telus.featuredapps
	pm uninstall -k --user 0 com.sec.android.app.sbrowser
	pm uninstall -k --user 0 com.android.browser
	pm uninstall -k --user 0 com.instagram.android
	pm uninstall -k --user 0 com.sec.android.provider.badge
	pm uninstall -k --user 0 com.sec.spp.push
	pm uninstall -k --user 0 com.trustonic.tuiservice
	pm uninstall -k --user 0 com.samsung.android.scloud
	pm uninstall -k --user 0 com.samsung.android.contacts
	pm uninstall -k --user 0 com.sec.android.app.soundalive
	pm uninstall -k --user 0 com.android.providers.blockednumber
	pm uninstall -k --user 0 com.android.smspush
	pm uninstall -k --user 0 com.qualcomm.embms
	pm uninstall -k --user 0 in.amazon.mShop.android.shopping
	pm uninstall -k --user 0 com.amazon.mShop.android.shopping
	pm uninstall -k --user 0 com.facebook.katana
	pm uninstall -k --user 0 com.microsoft.skydrive

	#ANT+
	pm uninstall -k --user 0 com.dsi.ant.plugins.antplus # ANT+ Plugins Service
	pm uninstall -k --user 0 com.dsi.ant.sample.acquirechannels # ANT + DUT
	pm uninstall -k --user 0 com.dsi.ant.server # ANT+ HAL service
	pm uninstall -k --user 0 com.dsi.ant.service.socket # ANT Radio Service

	# SmartThings
	pm uninstall -k --user 0 com.samsung.android.beaconmanager # SmartThings. It is required to enable the "Settings -> Connections -> More connections settings -> Nearby device scanning". This *may* be required for detecting Chromecast and other smart TVs.
	pm uninstall -k --user 0 com.samsung.android.ststub # SmartThings
	pm uninstall -k --user 0 com.samsung.android.easysetup # SmartThings
	pm uninstall -k --user 0 com.samsung.android.oneconnect # SmartThings. I added
	pm uninstall -k --user 0 com.samsung.android.service.stplatform # SmartThings. I added
	
	pm uninstall -k --user 0 com.enhance.gameservice
	pm uninstall -k --user 0 com.samsung.android.game.gamehome
	pm uninstall -k --user 0 com.samsung.android.game.gametools
	pm uninstall -k --user 0 com.samsung.android.game.gos

	#bixby
	pm uninstall -k --user 0 com.samsung.android.app.spage # Bixby Home
	pm uninstall -k --user 0 com.samsung.android.app.settings.bixby # SettingsBixby
	pm uninstall -k --user 0 com.samsung.android.bixby.agent
	pm uninstall -k --user 0 com.samsung.android.bixby.agent.dummy
	pm uninstall -k --user 0 com.samsung.android.bixby.es.globalaction
	pm uninstall -k --user 0 com.samsung.android.bixby.plmsync
	pm uninstall -k --user 0 com.samsung.android.bixby.service
	pm uninstall -k --user 0 com.samsung.android.bixby.voiceinput
	pm uninstall -k --user 0 com.samsung.android.bixby.wakeup
	pm uninstall -k --user 0 com.samsung.android.svoice # SVoice
	pm uninstall -k --user 0 com.samsung.svoice.sync # Voice Service, S Voice is the ancestor of Bixby
	pm uninstall -k --user 0 com.samsung.systemui.bixby
	pm uninstall -k --user 0 com.samsung.systemui.bixby2
	pm uninstall -k --user 0 com.samsung.android.visionintelligence # Bixby Vision
	pm uninstall -k --user 0 com.samsung.visionprovider # VisionProvider, maybe linked to Bixby?

	#dex
	pm uninstall -k --user 0 com.samsung.desktopsystemui  #Samsung DeX System UI
	pm uninstall -k --user 0 com.sec.android.app.desktoplauncher # Samsung DeX Home
	pm uninstall -k --user 0 com.sec.android.desktopcommunity # Samsung DeX community
	pm uninstall -k --user 0 com.sec.android.desktopmode.uiservice # Samsung DeX

	#google
	pm uninstall -k --user 0 com.google.android.apps.docs # Google Drive
	pm uninstall -k --user 0 com.google.android.apps.maps # Google Maps
	pm uninstall -k --user 0 com.google.android.apps.photos # Google Photos
	pm uninstall -k --user 0 com.google.android.GoogleCamera # Google Camera
	pm uninstall -k --user 0 com.google.android.gm # Gmail
	pm uninstall -k --user 0 com.google.android.videos # Google Movies
	pm uninstall -k --user 0 com.google.android.youtube # Google's YouTube
	pm uninstall -k --user 0 com.google.android.music # Google Music

	#random apps
	pm uninstall -k --user 0 com.linkedin.android # LinkedIn
	pm uninstall -k --user 0 com.microsoft.office.excel # Microsoft Excel
	pm uninstall -k --user 0 com.microsoft.office.powerpoint # Microsoft PowerPoint
	pm uninstall -k --user 0 com.microsoft.office.word # Microsoft Word
	pm uninstall -k --user 0 com.microsoft.skydrive # Microsoft SkyDrive
	pm uninstall -k --user 0 de.axelspringer.yana.zeropage # upday
	pm uninstall -k --user 0 flipboard.boxer.app # Flipboard
	pm uninstall -k --user 0 com.facebook.appmanager # Facebook
	pm uninstall -k --user 0 com.facebook.katana # Facebook
	pm uninstall -k --user 0 com.facebook.services # Facebook
	pm uninstall -k --user 0 com.facebook.system # Facebook
	pm uninstall -k --user 0 com.google.android.youtube.player 
	pm uninstall -k --user 0 com.google.android.youtube
	echo "Debloated" >> /sdcard/debloat_true.txt
fi

#badrgc=0;
#15min x 384 = 4 days (old math)
i=1; while [ $i -le 576 ] ;
 
##for i in `seq 1 384`; 
do
#seems to often get overriden by the device randomly
settings put system screen_off_timeout 40000000
#echo "Loop Start"

#Set/Reset ACC(Advanced Charging Controller)
#https://themagisk.com/advanced-charging-controller-acc/
#install it by just extracting a zip into modules folder? (/data/adb/modules/?)
#ACC MAY CAUSE BOOTLOOP in rare cases!
#--install-module is not supported for every version from the looks of it.
#magisk --install-module  /sdcard/acc_v2022.6.4_202206040.zip ? && reboot
acc=/data/adb/modules/acc/acc.sh
if test -f "$acc"; then
	su -c 'acc 70 65'hot swap
	su -c 'accd' #resets daemon
	echo "Restarted ACC"
	sleep 2
	else
	echo "acc not installed"
fi
#Check RGC

#Fix RGC die due to obvious crash
echo "rgc crash popup check" >> /sdcard/rgc_crash_check.txt
date >> /sdcard/dumsys_result.txt
(dumpsys window | grep mCurrentFocus= |tr -s " " | cut -b 34-96) >> /sdcard/dumsys_result.txt
if [[ $(dumpsys window | grep 'mCurrentFocus=' | tr -s " " | cut -b 34-96) == "Application Not Responding: de.grennith.rgc.remotegpscontroller" ]]
then
	echo "rgc crashed" >> /sdcard/rgc_crash.txt
	settings put system accelerometer_rotation 0
	#if [[ $(wm size) == "Physical size: 1440x2560"
	#or
	if [[ $(dumpsys window | grep cur= | tr -s " " | cut -d " " -f 4 | cut -d "=" -f 2 | sed 2d) == "1440x2560" ]]
	then
		echo "RGC popup click" >> /sdcard/rgc_crash_popup_click.txt
		input tap 475 1397
		su -c 'rm /sdcard/logcat*.txt'
		su -c 'logcat -d -f /sdcard/logcat_'$hostname'.txt'
	fi
	if [[ $(dumpsys window | grep cur= | tr -s " " | cut -d " " -f 4 | cut -d "=" -f 2 | sed 2d) == "1080x1920" ]]
	then
		echo "RGC popup click" >> /sdcard/rgc_crash_popup_click.txt
		input tap 330 1041
		su -c 'rm /sdcard/logcat*.txt'
		su -c 'logcat -d -f /sdcard/logcat_'$hostname'.txt'
	fi
	if [[ $(dumpsys window | grep cur= | tr -s " " | cut -d " " -f 4 | cut -d "=" -f 2 | sed 2d) == "720x1280" ]]
	then
		echo "RGC popup click" >> /sdcard/rgc_crash_popup_click.txt
		input tap 229 701
		su -c 'rm /sdcard/logcat*.txt'
		su -c 'logcat -d -f /sdcard/logcat_'$hostname'.txt'
	fi
fi
echo "Done RGC check 1"
sleep 3


#####TEST
FILE3=/sdcard/logcat_$hostname.txt
if test -f "$FILE3"; then
    crash_check_test_success=1;
	else
	crash_check_test_success=0;
fi

if [$crash_check_test_success == 0]
then
	(dumpsys window | grep mCurrentFocus= |tr -s " " | cut -b 34-96) >> /sdcard/dumsys_result_backup.txt
	check_backup=`cat /sdcard/dumsys_result_backup.txt`
	if [$check_backup == "Application Not Responding: de.grennith.rgc.remotegpscontroller"]
		then
			echo "rgc crashed" >> /sdcard/rgc_crash_backup.txt
			input tap 330 1041
			su -c 'rm /sdcard/logcat*.txt'
			su -c 'logcat -d -f /sdcard/logcat_'$hostname'_backup.txt'
		fi
fi

#if RGC doesn't give us a valid PID, its not running, so run it. Keyevent 66 clicks the RGC popup away.
[[ $(pidof de.grennith.rgc.remotegpscontroller) == "" ]] && monkey -p de.grennith.rgc.remotegpscontroller 1 && sleep 4 && settings put system accelerometer_rotation 0 && input keyevent 66 && input keyevent 66
echo "Done RGC check 2"


#Fix RGC die due to screen inactivity
#this value stored in XML doesn't update that frequently. Not sure when. Not frequently enough.
#Under mLocation has a valid gps from the looks of it.
#dumpsys location | grep Location

#if [[ $(dumpsys window windows | grep -E 'mCurrentFocus' | cut -d '/' -f1 | sed 's/.* //g') == "com.nianticlabs.pokemongo" ]]
#then
#		location= su -c 'grep last_location_latitude /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml'
#		echo $location
#		sleep 600;
#		location2= su -c 'grep last_location_latitude /data/data/de.grennith.rgc.remotegpscontroller/shared_prefs/de.grennith.rgc.remotegpscontroller_preferences.xml'
#		if [$location == $location2]
#		then
#			#badrgc=`expr $i + 1`;
#			input swipe 374 49 260 700
#			input swipe 374 49 260 700
#			input swipe 260 700 374 49
#			input swipe 260 700 374 49
#			input swipe 260 700 374 49
#			echo "Did scrolly fix" >> /sdcard/watchdog_rgcfail.txt	
#		fi
#fi
#echo "Done RGC check 3"


#Check WiFi
#Wifi can die/crash and still be in a enabled state. Pinging Google DNS verifies if there is indeed a internet connection or not.
ping -c1 8.8.8.8 > /dev/null
if [ $? -eq 0 ] #|| $? != 'connect: Network is unreachable'
	then 
		echo "Ping good"
		#echo "The value:" $?
	else
		echo "Ping Fail" #>> /sdcard/watchdog_pingfail.txt
		#echo "The value:" $?
		svc wifi disable
		sleep 3;
		svc wifi enable
fi
echo "Done all checks" #>> /sdcard/watchdog_success.txt

#seems to often get overriden by the device randomly
settings put system screen_off_timeout 40000000
#15min
sleep 600; 
#echo "Done sleeping"
echo "Ending loop number" $i >> /sdcard/watchdog_loops.txt
i=`expr $i + 1`; done
echo "I lived 4 days!!!!" >> /sdcard/watchdog_4day_success.txt
#device probably due for a reboot?
reboot