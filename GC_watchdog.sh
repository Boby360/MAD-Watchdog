#!/system/bin/sh
#GC watchdog script

ver='0.3.35'
productmodel=`getprop ro.product.model`
routerIP='192.168.0.1'
#To run at phone startup: 
#su
#rm /data/adb/service.d/*.sh
#mv /sdcard/watchdog0.3.35.sh /data/adb/service.d/watchdog0.3.35.sh && chmod 777 /data/adb/service.d/watchdog0.3.35.sh && chown 0.0 /data/adb/service.d/watchdog0.3.35.sh

while [ "$(getprop sys.boot_completed)" != 1 ];
do sleep 1;
done
sleep 2

get_current_time() {
    date +"%Y-%m-%d %H:%M:%S"
}

hostname = `cat /data/local/tmp/config.json | jq -r '.device_name'`
workers_count = `cat config.json | jq -r '.workers_count'`
su -c 'hostname '$hostname''
su -c 'setprop net.hostname '$hostname''
su -c 'setprop net.bt.name '$hostname''
su -c 'settings put system device_name '$hostname''
su -c 'settings put global device_name '$hostname''
su -c 'setprop persist.usb.serialno '$hostname''
su -c 'settings put secure bluetooth_name '$hostname''
su -c 'settings put global synced_account_name '$hostname''

#Optimizations:

#whitelist pogo and launcher so we get all of the logcat errors.
logcat -P "com.nianticlabs.pokemongo"
logcat -P "com.gocheats.launcher"


#ATV optimizations
pm disable com.google.android.tts
pm disable com.droidlogic.BluetoothRemote
pm disable com.google.android.apps.turbo


##Keep things alive (OOM score)
#Script
rm /sdcard/pid-*.txt
script_pid=`echo $$`
echo $script_pid > /sdcard/pid-$script_pid.txt
su -c 'echo -900 >> /proc/'$script_pid'/oom_score_adj'

#Launcher (Default when checked was 906)
launcher_pid=`pidof com.gocheats.launcher`
echo $launcher_pid > /sdcard/pid-$launcher_pid.txt
su -c 'echo -900 >> /proc/'$launcher_pid'/oom_score_adj'

#Pogo default when checked was 700


##Lets be nice to the launcher
su -c 'renice -n -15 -p $launcher_pid'
su -c 'renice -n -14 -p $script_pid'

###############################Check Loop:


#########Lets Grep the logcat and look for some stupid user error problems...
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/your-webhook-id/your-webhook-token"


# Check if the logcat contains a mismatch game version.
if logcat -d | grep -q "Mismatching game version!"; then
    LOG_LINE=$(logcat -d | grep "Mismatching game version!")
    curl -X POST -H "Content-Type: application/json" -d '{"content": "Mismatching game version detected on $hostname:\n'"$LOG_LINE"'"}' "$DISCORD_WEBHOOK_URL"
	sleep 300
else
fi

# Check if the logcat contains a License validation error
if logcat -d | grep -q "Mismatching game version!"; then
    LOG_LINE=$(logcat -d | grep "License validation failed!")
    curl -X POST -H "Content-Type: application/json" -d '{"content": "License Validation error found on $hostname' "$DISCORD_WEBHOOK_URL"
	sleep 300
else
fi


#########Verify ADB is running, ifnot, reset service.
if busybox netstat -tuln | grep -q "5555"; then
else
adb start-server
fi


########Is SELinux set to enforce after starting GC?
if [[ $(pidof com.gocheats.launcher) != "" ]]
then
if [[ $(getenforce) == "Permissive" ]]
then
sleep 20
su -c 'setenforce 1'
fi
fi


########Are most of GC instances running?
#If only 1 is running, then sleep and double check we aren't in the process of starting.
if [[ $(netstat -t | grep -c 7070) < 2 ]] #we could use a percentage of $workers_count in the future
then
sleep 120

#If after sleep we are still only running 1 instance or less, then restart.
if [[ $(netstat -t | grep -c 7070) < 2 ]]
then
am force-stop com.nianticlabs.pokemongo
am force-stop com.gocheats.launcher
sleep 2
#Restart GC
monkey -p com.gocheats.launcher 1

#redo optimizations
launcher_pid=`pidof com.gocheats.launcher`
echo $launcher_pid > /sdcard/pid-$launcher_pid.txt
su -c 'echo -900 >> /proc/'$launcher_pid'/oom_score_adj'
su -c 'renice -n -15 -p $launcher_pid'

fi
fi



########Is GC running?
if [[ $(pidof com.gocheats.launcher) == "" ]]
then

#Grab log of crash
logcat -d > /sdcard/logcat_GC_crash_$(get_current_time).txt

am force-stop com.nianticlabs.pokemongo
am force-stop com.gocheats.launcher

#Restart GC
monkey -p com.gocheats.launcher 1

#redo optimizations
launcher_pid=`pidof com.gocheats.launcher`
echo $launcher_pid > /sdcard/pid-$launcher_pid.txt
su -c 'echo -900 >> /proc/'$launcher_pid'/oom_score_adj'
su -c 'renice -n -15 -p $launcher_pid'


#Log that it crashed 
echo "GC crashed at $(get_current_time)" >> /sdcard/GC_crashed.txt

#We pulled the logs for the crash. Clear up the logcat.
su -c 'logcat -c'

echo "Done GC check"
fi




#########Check WiFi/Ethernet
#Wifi can die/crash and still be in a enabled state. Ping local router verifies if wifi works or not.

#>>>>>>Check if wifi is enabled prior to testing......

ping -c1 $routerIP > /dev/null
if [ $? -eq 0 ] #|| $? != 'connect: Network is unreachable'
	then 
		echo "Ping good"
		#echo "The value:" $?
	else
		date >> /sdcard/watchdog_pingfail.txt							   
		echo "Ping Fail" >> /sdcard/watchdog_pingfail.txt
		#echo "The value:" $?
		
		if [ settings get global wifi_on == 1 ]
		then
		svc wifi disable
		sleep 5;
		svc wifi enable
		else
		#untested
		ifconfig eth0 down
		sleep 5
		ifconfig eth0 up
		fi
		
fi
echo "Done all checks" #>> /sdcard/watchdog_success.txt