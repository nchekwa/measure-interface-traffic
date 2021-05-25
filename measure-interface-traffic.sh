#!/bin/bash
#########################################################################
#
# File:         measure-interface-traffic.sh
# Description:  Measure ifDescr/ifOperStatus/ifSpeed/ifHCInOctets/ifHCOutOctets and generate CSV file
# Language:     GNU Bourne-Again SHell
# Version:		1.0.0
# Date:			2021-05-24
# Corp.:		Nchekwa
# Author:		Artur Zdolinski
# WWW:			https://www.nchekwa.com
#########################################################################
# Bugs:
# The Latest Version will be released in https://github.com/nchekwa/measure-interface-traffic
# You can send bugs to https://github.com/nchekwa/measure-interface-traffic/issues,
# or email to me directly: artur@nchekwa.com
#########################################################################
# Todo:
# 
#########################################################################
# ChangeLog:
#
# Version 1.0.0
# 2021-05-24
# Original Version.
unset LANG

print_help_msg(){
	print_version
	echo "Usage: $0 -h to get help."
	echo "---"
}
print_version(){
	echo $(cat $0 | head -n 7 | tail -n 1|sed 's/\# //')
}

print_full_help_msg(){
	print_version
	echo "Usage:"
	echo "$0 [ -a ADDRESS_IP ] [ -c COMMUNITY ] [ -i INTERVAL ] [ -l LOOP-NUMBER ]"
	echo "Example:"
	echo "${0} -a 192.168.1.226 -c public -i 10 -l 10"
}

if [ $# -lt 1 ]; then
	print_help_msg
	exit 3
else
	while getopts :a:c:l:i: OPTION
	do
		case $OPTION
			in
			a) address=$OPTARG;;
			c) community=$OPTARG;;
			l) loops=$OPTARG;;
			i) interval=$OPTARG;;
			h)
			print_full_help_msg
			exit 3
			;;
			?)
			echo "Error: Illegal Option."
			print_help_msg
			exit 3
			;;
		esac
	done
	if [ -z $community ]; then
		community="public"
	fi
	if [ -z $loops ]; then
		loops=10
	fi
	if [ -z $interval ]; then
		interval=60
	fi
	if [ -z $address ]; then
		echo "Please set option: [-a IP] - it is mandatory"
		print_full_help_msg
		exit 3
	fi
fi

declare -A interfaces
declare -A interfacesOperStatus
declare -A interfacesSpeed

echo "ID;NAME;OP-STATUS;SPEED;LOOP-ID;DATE;TIME;TS;ifInOctets(Counter);ifInUtl(%);ifInOctets(KBps);ifInOctets(MBps);ifInOctets(Kbps);ifInOctets(Mbps);ifOutOctets(Counter);ifOutUtl(%);ifOutOctets(KBps);ifOutOctets(MBps);ifOutOctets(Kbps);ifOutOctets(Mbps)"

if=`snmpwalk -v 2c -c $community $address IF-MIB::ifDescr 2>/dev/null | sed -r 's/IF-MIB::ifDescr.//g' | awk '{printf "%s___%s\n", $1, $4}'`
for iface in $if
do
	arrIF=(${iface//___/ })
	interfaces["${arrIF[0]}"]=${arrIF[1]} 
done

if=`snmpwalk -v 2c -c $community $address IF-MIB::ifOperStatus 2>/dev/null | sed -r 's/IF-MIB::ifOperStatus.//g' | awk '{printf "%s___%s\n", $1, $4}'`
for iface in $if
do
	arrIF=(${iface//___/ })
	interfacesOperStatus["${arrIF[0]}"]=${arrIF[1]} 
done

if=`snmpwalk -v 2c -c $community $address IF-MIB::ifSpeed 2>/dev/null | sed -r 's/IF-MIB::ifSpeed.//g' | awk '{printf "%s___%s\n", $1, $4}'`
for iface in $if
do
	arrIF=(${iface//___/ })
	interfacesSpeed["${arrIF[0]}"]=${arrIF[1]} 
done

# Initiate last_ ARRAY as reference
declare -A last_interfacesIn64
declare -A last_interfacesOut64
ifIN=`snmpwalk -v 2c -c $community $address IF-MIB::ifHCInOctets 2>/dev/null | sed -r 's/IF-MIB::ifHCInOctets.//g' | awk '{printf "%s___%s\n", $1, $4}'`
ifOUT=`snmpwalk -v 2c -c $community $address IF-MIB::ifHCOutOctets 2>/dev/null | sed -r 's/IF-MIB::ifHCOutOctets.//g' | awk '{printf "%s___%s\n", $1, $4}'`
for iface in $ifIN
do
	arrIF=(${iface//___/ })
	last_interfacesIn64["${arrIF[0]}"]=${arrIF[1]} 
done
for iface in $ifOUT
do
	arrIF=(${iface//___/ })
	last_interfacesOut64["${arrIF[0]}"]=${arrIF[1]} 
done


# Start LOOP
ts_now=$(date +'%s')
next_run_at=$ts_now
#echo $(ts_now)
#echo ${next_run_at}
for ((i=1; i<=$loops; i++))
do
	# Do sleep loop to keep identical and equal intervals
	while (test $next_run_at -gt $ts_now )
	do
		sleep 0.2
		ts_now=$(date +'%s')
		#echo "Next run at: $next_run_at"
		#echo "Now: $ts_now"
	done
	
	declare -A interfacesIn64
	declare -A interfacesOut64
	next_run_at=$(($(date +'%s')+$interval))

	# Current data and time
	now_date="$(date +'%Y-%m-%d')"
	now_time="$(date +'%T')"
	#echo "[For $i/$loops] - $now_date $now_time"
	
	
	# SNMP collect ifHCInOctets+ifHCOutOctets
	ifIN=`snmpwalk -v 2c -c $community $address IF-MIB::ifHCInOctets 2>/dev/null | sed -r 's/IF-MIB::ifHCInOctets.//g' | awk '{printf "%s___%s\n", $1, $4}'`
	ifOUT=`snmpwalk -v 2c -c $community $address IF-MIB::ifHCOutOctets 2>/dev/null | sed -r 's/IF-MIB::ifHCOutOctets.//g' | awk '{printf "%s___%s\n", $1, $4}'`
		
	# Process ifHCInOctets
	for iface in $ifIN
	do
		arrIF=(${iface//___/ })
		interfacesIn64["${arrIF[0]}"]=${arrIF[1]} 
	done
	
	# Process ifHCIifHCOutOctetsnOctets
	for iface in $ifOUT
	do
		arrIF=(${iface//___/ })
		interfacesOut64["${arrIF[0]}"]=${arrIF[1]} 
	done
	
	for key in $( echo ${!interfaces[@]} | tr ' ' $'\n' | sort -g ); do
		if_id=${key}
		if_name=${interfaces[${key}]}
		if_status=${interfacesOperStatus[${key}]}
		if_speed=${interfacesSpeed[${key}]}
		
		if_In64=${interfacesIn64[${key}]}
		if_In64_diff=$((${interfacesIn64[${key}]}-${last_interfacesIn64[${key}]}))
		if_In64_KBps=$(echo "scale=3; $if_In64_diff/1000/$interval" | bc | sed 's/^\./0./')
		if_In64_MBps=$(echo "scale=3; $if_In64_diff/1000000/$interval" | bc | sed 's/^\./0./')
		if_In64_Kbps=$(echo "scale=3; $if_In64_diff*8/1000/$interval" | bc | sed 's/^\./0./')
		if_In64_Mbps=$(echo "scale=3; $if_In64_diff*8/1000000/$interval" | bc | sed 's/^\./0./')
		
		if_Out64=${interfacesOut64[${key}]}
		if_Out64_diff=$((${interfacesOut64[${key}]}-${last_interfacesOut64[${key}]}))
		if_Out64_KBps=$(echo "scale=3; $if_Out64_diff/1000/$interval" | bc | sed 's/^\./0./')
		if_Out64_MBps=$(echo "scale=3; $if_Out64_diff/1000000/$interval" | bc | sed 's/^\./0./')
		if_Out64_Kbps=$(echo "scale=3; $if_Out64_diff*8/1000/$interval" | bc | sed 's/^\./0./')
		if_Out64_Mbps=$(echo "scale=3; $if_Out64_diff*8/1000000/$interval" | bc | sed 's/^\./0./')
		
		if [ $if_speed -ne "0"  ]; then
			if_In_prc=$(echo "scale=5; ((($if_In64_diff*8)/$interval)/$if_speed)*100" | bc | sed 's/^\./0./')
			if_Out_prc=$(echo "scale=5; ((($if_Out64_diff*8)/$interval)/$if_speed)*100" | bc | sed 's/^\./0./')
		fi
		
		echo "$if_id;$if_name;$if_status;$if_speed;$i;$now_date;$now_time;$ts_now;$if_In64;$if_In_prc%;$if_In64_KBps;$if_In64_MBps;$if_In64_Kbps;$if_In64_Mbps;$if_Out64;$if_Out_prc%;$if_Out64_KBps;$if_Out64_MBps;$if_Out64_Kbps;$if_Out64_Mbps"
		last_interfacesIn64[${if_id}]=$if_In64
		last_interfacesOut64[${if_id}]=$if_Out64
	done
done

exit
