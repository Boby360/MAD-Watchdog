#!/system/bin/sh
#GC watchdog script

#ver='0.3.35'
productmodel=$(su -c "getprop ro.product.model")

#Adjust for gateway
routerIP=$(getprop net.dns1)


#What percentage down of workers do we want before restarting?
#This math doesn't math, but its close.
percentage_down="50"


#adjust these if adapters are different
wifi_mac=$(cat /sys/class/net/wlan0/address) 2>&1 > /dev/nulll
eth0_mac=$(cat /sys/class/net/eth0/address) 2>&1 > /dev/null


echo "after startup stuff"
sleep 1
#To run at phone startup: 
#su
#rm /data/adb/service.d/*.sh
#mv /sdcard/GC_watchdog.sh /data/adb/service.d/GC_watchdog.sh && chmod 777 /data/adb/service.d/GC_watchdog.sh && chown 0.0 /data/adb/service.d/GC_watchdog.sh
echo "before while"
while [ "$(getprop sys.boot_completed)" != 1 ]
do sleep 1
done


sleep 2
echo "after while"


echo "hostname command:"
hostname=$(su -c "awk -F'\"' '/device_name/ {print \$4}' /data/local/tmp/config.json")
echo "workers count command:"
workers_count=$(su -c awk -F'[:,]' '/workers_count/ {gsub(/^[ \t]+/,"",$2); print $2}' /data/local/tmp/config.json)
echo "$hostname"
echo "This is my hostname"
su -c "hostname $hostname"
su -c "setprop net.hostname $hostname"
echo "after hostnames"
su -c "setprop net.bt.name $hostname"
echo "some way through"
su -c "settings put system device_name $hostname"
su -c "settings put global device_name $hostname"
echo "some more way through"
su -c "setprop persist.usb.serialno $hostname"
su -c "settings put secure bluetooth_name $hostname"
su -c "settings put global synced_account_name $hostname"
echo "start optimizations"
#Optimizations:

#Enable ADB, and make sure its on 5555:
su -c "setprop service.adb.tcp.port 5555"
#On my android 11 S6E, there was still some weirdness/problems

#Supress any crash popups:
su -c "settings put global anr_show_background_apps 0"

#whitelist pogo and launcher so we get all of the logcat errors.
su -c 'logcat -P ""'

echo "set logcat whitelist"
sleep 1

#ATV optimizations
echo "Any errors below are just missing packages, not to worry"
su -c "pm disable com.google.android.tts 2>&1 > /dev/null"
su -c "pm disable com.droidlogic.BluetoothRemote 2>&1 > /dev/null"
su -c "pm disable com.google.android.apps.turbo 2>&1 > /dev/null"


######This is kind of risky

#If ethernet has a valid IP address, disable WIFI completely.
# su -c "ping -c1 -I wlan0 8.8.8.8" > /dev/null
# if [ $? -eq 0 ]; then
	# svc wifi disable
# fi

######This is kind of risky

#We could look at this?
#settings get global wifi_on 0/1

if [[ -e "/sys/class/net/wlan0/address" && -e "/sys/class/net/eth0/address" ]]; then
echo "Why...... does both wifi and eth have a mac?"
echo "Disable one......"

#lets assume eth0 is what we actually want
mac=$eth0_mac
adapter="eth0"
fi

#If wifi mac is empty, we use eth0 mac for our reference.
if [[ ! -e "/sys/class/net/wlan0/address" && -e "/sys/class/net/eth0/address" ]]; then
mac=$eth0_mac
adapter="eth0"
fi

#if eth0 mac is empty, we use wifi mac as our reference.
if [[ -e "/sys/class/net/wlan0/address" && ! -e "/sys/class/net/eth0/address" ]]; then
mac=$wifi_mac
adapter="wlan0"
fi

#ATV A9:
#Ethernet: /sys/class/net/eth0/address
#Wifi: /sys/class/net/wlan0/address

#For A7 ATVs this was used:
# echo 1 > /sys/class/unifykeys/lock
# echo mac > /sys/class/unifykeys/name
# echo "$new_mac" > /sys/class/unifykeys/write
# cat /sys/class/unifykeys/read
# echo 0 > /sys/class/unifykeys/lock


if [[ $mac == "00:15:18:01:81:31" || $mac == "02:00:00:00:00:00" ]]; then

new_mac=$(xxd -l 6 -p /dev/urandom |sed 's/../&:/g;s/:$//')

ifconfig $adapter down
su -c "ip link set dev $adapter address $new_mac"
#or
su -c "ifconfig $adapter hw ether $new_mac"
#su -c "echo $new_mac > /efs/wifi/.mac.info"

#Make it persistant in A9?
echo 1 > /sys/class/unifykeys/lock
echo mac > /sys/class/unifykeys/name
echo "$new_mac" > /sys/class/unifykeys/write
cat /sys/class/unifykeys/read
echo 0 > /sys/class/unifykeys/lock

echo "$newmac" > /sys/class/net/$adapter/address

ifconfig $adapter up

echo "New MAC address: $new_mac" > /sdcard/$new_mac.txt

fi

sleep 60
#Lets see if GC is running.
########Is GC running?
if [[ $(pidof com.gocheats.launcher) == "" ]]
then
#Start GC
monkey -p com.gocheats.launcher 1
fi
sleep 5

echo "OOM"
##Keep things alive (OOM score)
#Script
rm /sdcard/pid-*.txt
script_pid=`echo $$`
echo $script_pid > /sdcard/pid-$script_pid.txt
su -c "echo -900 >> /proc/$script_pid/oom_score_adj"
echo "script done"

#Launcher (Default when checked was 906)
launcher_pid=$(pidof com.gocheats.launcher)
echo $launcher_pid > /sdcard/pid-$launcher_pid.txt
su -c 'echo -900 >> /proc/'$launcher_pid'/oom_score_adj'

#Pogo default when checked was 700

echo "Be nice"
##Lets be nice to the launcher
su -c "renice -n -15 $launcher_pid"
su -c "renice -n -14 $script_pid"

###############################Check Loop:
echo "loop start"
while true
do
#########Lets Grep the logcat and look for some stupid user error problems...
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/your-webhook-id/your-webhook-token"


# Capture the logcat output
log_output=$(logcat -d)

# Check if the logcat contains a mismatch game version.
if echo "$log_output" | grep -q "Mismatching game version!"; then
    log_line=$(echo "$log_output" | grep "Mismatching game version!")
    curl -X POST -H "Content-Type: application/json" -d '{"content": "Mismatching game version detected on '"$hostname"':\n'"$log_line"'"}' "$DISCORD_WEBHOOK_URL"
    sleep 300
fi

# Check if the logcat contains a License validation error
if echo "$log_output" | grep -q "License validation failed!"; then
    log_line=$(echo "$log_output" | grep "License validation failed!")
    curl -X POST -H "Content-Type: application/json" -d '{"content": "License Validation error found on $hostname' "$DISCORD_WEBHOOK_URL"
	sleep 300
fi


sleep 1
#########Verify ADB is running, ifnot, reset service.
if netstat -tuln | awk '/5555/' > "/dev/null"; then
echo "Online"
else
adb start-server
fi

sleep 1
########Is SELinux set to enforce after starting GC?
if [[ $(pidof com.gocheats.launcher) != "" ]]; then
echo "GC is running"
if [[ $(getenforce) == "Permissive" ]]; then
echo "Device is Permissive"
sleep 5
su -c 'setenforce 1'
fi
fi


sleep 1
########Are most of GC instances running?
#worker_50percentage=$(expr $workers_count \* $percentage_down / 100)


#This doesn't really math, as we will have 1 more connection for the MITM, seperate from the workers on 7070.
if [[ $(netstat -t | grep -c 7070) < 3 ]]; then #we could use a percentage of $workers_count in the future
sleep 120


#If after sleep we are still only running 1 instance or less, then restart.
if [[ $(netstat -t | grep -c 7070) < 3 ]]; then
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


sleep 1
########Is GC running?
if [[ $(pidof com.gocheats.launcher) == "" ]]
then

#Grab log of crash
time=$(date +"%Y-%m-%d %H:%M:%S")
logcat -d > /sdcard/logcat_GC_crash_$time.txt

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
echo "GC crashed at $time" >> /sdcard/GC_crashed.txt

#We pulled the logs for the crash. Clear up the logcat.
su -c 'logcat -c'

echo "Done GC check"
fi



sleep 1
#########Check WiFi/Ethernet
#Wifi can die/crash and still be in a enabled state. Ping local router verifies if wifi works or not.

#>>>>>>Check if wifi is enabled prior to testing......

su -c "ping -c1 $routerIP" > /dev/null
if [ $? -eq 0 ] #|| $? != 'connect: Network is unreachable'
	then 
		echo "Ping good"
		#echo "The value:" $?
	else
		date >> /sdcard/watchdog_pingfail.txt							   
		echo "Ping Fail" >> /sdcard/watchdog_pingfail.txt
		#echo "The value:" $?
		
		if [ $(settings get global wifi_on) == 1 ]
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
echo "Done all checks"
sleep 300

#Need to use ctrl+C to kill, or kill process ID.
done 