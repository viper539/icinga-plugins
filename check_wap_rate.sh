#! /bin/bash
#
# --------------------------
# -------- OVERVIEW --------
# --------------------------
#
# This script forms the basis of a Data Input Method for Cacti.
# The purpose is to query a Cisco Wireless Access Point for all
# connected clients' current TX rate
# These values are indexed against client MAC addresses and are
# not directly graphable. So we return a count of the number of
# clients within particular 'rates'
# This should provide a more precise indication of the general
# service offered by an AP than does the Average Client RSSI
#
# Note: The data is returned in a format designed for a Cacti AREA/STACK graph
#
# ---------------------------
# -------- CHANGELOG --------
# ---------------------------
#
# 20081003 (BC)
#       Initial version
# 20081007 (BC)
#       Changed rate_avg to output an integer, rrdtool was storing NaN's
# 20081016 (BC)
#       Added debug mode that prints error messages - normally suppressed by returning '0' for all values
#
# ----------------------------------------
# -------- CAVEATS / BUGS / TO DO --------
# ----------------------------------------
#
# -----------------------------
# -------- GLOBAL VARS --------
# -----------------------------

#set version 1.1

# Default vars
oid=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.3.1.1.1
#set oid .1.3.6.1.4.1.9.9.273.1.3.1.1.1
debug=0
#set usage "Usage: $argv0 <?-d?> <hostname|ip_address> <community_string> <snmp_version>"
#set result_err "rate_1_cnt:0 rate_2_cnt:0 rate_5_5_cnt:0 rate_6_cnt:0 rate_9_cnt:0 rate_11_cnt:0 rate_12_cnt:0 rate_18_cnt:0 rate_24_cnt:0 rate_36_cnt:0 rate_48_cnt:0 rate_54_cnt:0 rate_avg:0"
#set valid_rates [list 1.0 2.0 5.5 6.0 9.0 11.0 12.0 18.0 24.0 36.0 48.0 54.0]

#set comstr public
#set ver 2c
#set host 10.50.0.36

# ------------------------------
# -------- PROCESS ARGS --------
# ------------------------------

# Process command line optionscritical=0
warning=0
ok=0
arrayvar=1
mbps1=0
mbps2=0
mbps3=0
mbps4=0
mbps5=0
mbps6=0
mbps7=0


PATH="/usr/lib/icinga/"
SNMPGET="/usr/bin/snmpget"
SED="/bin/sed"
EXPR="/usr/bin/expr"
TEMP="/var/tmp"
PROGNAME=`/usr/bin/basename $0`


PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 0.1 $' | /bin/sed -e 's/[^0-9.]//g'`

. $PROGPATH/utils.sh

print_usage() {
    echo "Usage: $PROGNAME -H Host -C Community"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME --version"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    print_usage
    echo ""
    echo "Daten via SNMP aus einer PfSense auslesen"
    echo ""
﻿  echo ""
    support
}


# Make sure the correct number of command line
# arguments have been supplied
#-H 1.2.3.4 = 2 Arguments
#-- Argument1
#   ------- Argument2
#if [ $# -lt 4 ]; then
#    print_usage
#    exit $STATE_UNKNOWN
#fi

# Grab the command line arguments
exitstatus=$STATE_WARNING #default
while test -n "$1"; do
    case "$1" in
        --version)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        -V)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        --community)
            comm=$2
            shift
            ;;
        -C)
            comm=$2
            shift
            ;;
        --host)
            host=$2
            shift
            ;;
        -H)
            host=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

# OID vorhanden ja/nein 1/
# Name/OID: .1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.1.1.1.1; Value (Integer): 1
oid_janein=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.1.1.1.1

#Name/OID: .1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.2.1.1.1; Value (OctetString): A4:17:31:6B:8F:E7
oid_mac=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.2.1.1.1
#Name/OID: .1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.3.1.1.1; Value (OctetString): 78 Mbps
oid_range_speed=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.3.1.1
#oid_speed=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.3.1.1.1
#Name/OID: .1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.4.1.1.1; Value (OctetString): -45 dBm
oid_attenuation=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.4.1.1.1
#Name/OID: .1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.5.1.1.1; Value (OctetString): Connected
oid_state=.1.3.6.1.4.1.9.6.1.32.4410.1.3.3.3.1.5.1.1.1

#IFS=" "
walk_result=`/usr/bin/snmpwalk -O avq  -v 1 -c $comm $host $oid_range_speed`

#echo $walk_result

arrayWalk=(${walk_result//\"/})

#arrayRaten=(130 65 117 58 54 78 104 52 2 12 39 13 48 19)
#echo "Walk: "${arrayWalk[@]}

arrayCount[0]=0 #mbps
arrayCount[1]=0 #1-19
arrayCount[2]=0 #20-39
arrayCount[3]=0 #40-59
arrayCount[4]=0 #60-79
arrayCount[5]=0 #80-99
arrayCount[6]=0 #100-119
arrayCount[7]=0 #120-max

#echo ${arrayWalk[@]}

werte=$(echo $werte|/bin/sed 's/"//g')

for werte in "${arrayWalk[@]}"; do
#echo "Werte: "$werte

#arrayCount: keiner 50=1, 50-99=2, größer 100=3

﻿  if [[ $werte = "Mbps" ]]; then
﻿  ﻿  let arrayCount[0]=$(( 1 + ${arrayCount[0]} ));
#﻿  ﻿  echo "Mbps plus 1"
﻿  elif [[ $werte < 20 ]]; then
#﻿  ﻿  echo "unter 20"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[1]=$(( 1 + ${arrayCount[1]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  elif [[ $werte < 40 ]]; then
#﻿  ﻿  echo "unter 50"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[2]=$(( 1 + ${arrayCount[2]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  elif [[ $werte < 60 ]]; then
#﻿  ﻿  echo "unter 50"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[3]=$(( 1 + ${arrayCount[3]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  elif [[ $werte < 80 ]]; then
#﻿  ﻿  echo "unter 50"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[4]=$(( 1 + ${arrayCount[4]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  elif [[ $werte < 100 ]]; then
#﻿  ﻿  echo "unter 50"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[5]=$(( 1 + ${arrayCount[5]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  elif [[ $werte < 120 ]]; then
#﻿  ﻿  echo "unter 100"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[6]=$(( 1 + ${arrayCount[6]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  elif [[ $werte > 119 ]]; then
#﻿  ﻿  echo "unter 100"
#﻿  ﻿  echo "vorher: Werte: " $werte " "${arrayCount[1]}
﻿  ﻿  let arrayCount[7]=$(( 1 + ${arrayCount[7]} ));
#﻿  ﻿  echo "nacher: Werte: " $werte " "${arrayCount[1]}
﻿  else
﻿  ﻿  echo "Problem"
﻿  fi


done

echo "1-19Mbps:"${arrayCount[1]}" 20-39Mbps:"${arrayCount[2]}" 40-59Mbps:"${arrayCount[3]}" 60-79Mbps:"${arrayCount[4]}" 80-99Mbps:"${arrayCount[5]}" 100-119Mbps:"${arrayCount[6]}" 120Mbps-max:"${arrayCount[7]} # Zusammenfassung für die Übersicht
echo "Langsamer als 20 Mbps:  " ${arrayCount[1]} " Clients"
echo "Langsamer als 40 Mbps:  " ${arrayCount[2]} " Clients"
echo "Langsamer als 60 Mbps:  " ${arrayCount[3]} " Clients"
echo "Langsamer als 80 Mbps:  " ${arrayCount[4]} " Clients"
echo "Langsamer als 100 Mbps: " ${arrayCount[5]} " Clients"
echo "Langsamer als 100 Mbps: " ${arrayCount[6]} " Clients"
echo "Schneller als 120 Mbps: " ${arrayCount[7]} " Clients"

#echo "| '1-49 Mbps'="${arrayCount[1]}" '50-99 Mbps'="${arrayCount[2]}" '100- Mbps'="${arrayCount[3]}
echo "| '1-19 Mbps'="${arrayCount[1]}" '20-39 Mbps'="${arrayCount[2]}" '40-59 Mbps'="${arrayCount[3]}" '60-79 Mbps'="${arrayCount[4]}" '80-99 Mbps'="${arrayCount[5]}" '100-119 Mbps'="${arrayCount[6]}" '120 Mbps-max'="${arrayCount[7]}

exit
