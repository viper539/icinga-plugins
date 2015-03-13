#! /bin/bash
#

critical=0
warning=0
ok=0
arrayvar=1

PATH="/usr/lib/icinga/"
SNMPGET="/usr/bin/snmpget"
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
if [ $# -lt 4 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

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
        --warn)
            warn=$2
            shift
            ;;
        -w)
            warn=$2
            shift
            ;;
        --critical)
            critical=$2
            shift
            ;;
        -c)
            critical=$2
            shift
            ;;
        --size)
            sizeoid=$2
            shift
            ;;
        -s)
            sizeoid=$2
            shift
            ;;
        --used)
            usedoid=$2
            shift
            ;;
        -u)
            usedoid=$2
            shift
            ;;
        -n)
            name=$2
            shift
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


# Traffic in vr0 (LAN)
# IF-MIB::ifTable.ifEntry.ifInOctets.1 = Counter32
oid_traffic_lan_in=1.3.6.1.2.1.2.2.1.10.1
traffic_lan_in_name="LAN-IN"
# IF-MIB::ifTable.ifEntry.ifOutOctets.1 = Counter32
oid_traffic_lan_out=1.3.6.1.2.1.2.2.1.16.1
traffic_lan_out_name="LAN-OUT"

# Traffic in vr1 (WAN)
# IF-MIB::ifTable.ifEntry.ifInOctets.2 = Counter32
oid_traffic_wan_in=1.3.6.1.2.1.2.2.1.10.2
traffic_wan_in_name="WAN-IN"
# IF-MIB::ifTable.ifEntry.ifOutOctets.2 = Counter32
oid_traffic_wan_out=1.3.6.1.2.1.2.2.1.16.2
traffic_wan_out_name="WAN-OUT"

# Traffic in vr2 (OPT)
# IF-MIB::ifTable.ifEntry.ifInOctets.3 = Counter32
# 1.3.6.1.2.1.2.2.1.10.3
# IF-MIB::ifTable.ifEntry.ifOutOctets.3 = Counter32
# 1.3.6.1.2.1.2.2.1.16.3

# Traffic in tun0 (VPN)
# IF-MIB::ifTable.ifEntry.ifInOctets.8 = Counter32
# 1.3.6.1.2.1.2.2.1.10.1
# IF-MIB::ifTable.ifEntry.ifOutOctets.8 = Counter32
# 1.3.6.1.2.1.2.2.1.16.1

# CPU load
# HOST-RESOURCES-MIB::hrDevice.hrProcessorTable.hrProcessorEntry.hrProcessorLoad.3 = INTEGER
﻿  if [[ $host = 192.168.1.1 ]]; then
﻿  ﻿  oid_cpu_load=1.3.6.1.2.1.25.3.3.1.2.7
﻿  elif [[ $host=192.168.1.2 ]]; then
﻿  ﻿  oid_cpu_load=1.3.6.1.2.1.25.3.3.1.2.7
﻿  fi
# oid_cpu_load=1.3.6.1.2.1.25.3.3.1.2.7
cpu_load_warn=80
cpu_load_critical=90
cpu_load_name="CPU-Auslastung"


# Memory
# HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageSize.1 = INTEGER
oid_memory_size=1.3.6.1.2.1.25.2.3.1.5.1
# HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageUsed.1 = INTEGER
oid_memory_used=1.3.6.1.2.1.25.2.3.1.6.1
memory_warn=80
memory_critical=90
memory_name=Arbeitsspeicher

# Shared memory
# HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageSize.2 = INTEGER
oid_shared_mem_size=1.3.6.1.2.1.25.2.3.1.5.2
# HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageUsed.2 = INTEGER
oid_shared_mem_used=1.3.6.1.2.1.25.2.3.1.6.2
shared_mem_warn=80
shared_mem_critical=90
shared_mem_name="Shared Memory"

# Swap
# HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageSize.3 = INTEGER
oid_swap_size=1.3.6.1.2.1.25.2.3.1.5.3
# HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageUsed.3 = INTEGER
oid_swap_used=1.3.6.1.2.1.25.2.3.1.6.3
swap_warn=80
swap_critical=90
swap_name=Swap

# # Used space on ad0s1a (/)
# # HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageSize.4 = INTEGER
# 1.3.6.1.2.1.25.2.3.1.5.4
# # HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageUsed.4 = INTEGER
# 1.3.6.1.2.1.25.2.3.1.6.4

# # Used space on md0 (/var/run)
# # HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageSize.6 = INTEGER
# 1.3.6.1.2.1.25.2.3.1.5.6
# # HOST-RESOURCES-MIB::hrStorage.hrStorageTable.hrStorageEntry.hrStorageUsed.6 = INTEGER
# 1.3.6.1.2.1.25.2.3.1.6.6

# Number of processes
# HOST-RESOURCES-MIB::hrSystemProcesses.0 = Gauge32
oid_processes=1.3.6.1.2.1.25.1.6.0
processes_warn=120
processes_critical=200
processes_name="laufene Prozesse"

# Number of users
# HOST-RESOURCES-MIB::hrSystemNumUsers.0 = Gauge32
oid_users=1.3.6.1.2.1.25.1.5.0
users_name="angemeldete Benutzer"

# # Number of pfilter states
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfStateTable.pfStateTableCount.0 = Gauge32
oid_pfilter_states=1.3.6.1.4.1.12325.1.200.1.3.1.0
pfilter_states_name="Filter gesamt"

# # Number of pfilter state inserts
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfStateTable.pfStateTableInserts.0 = Counter64
oid_pfilter_inserts=1.3.6.1.4.1.12325.1.200.1.3.3.0
pfilter_inserts_name="Filter eingefuegt"

# # Number of pfilter state removal
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfStateTable.pfStateTableRemovals.0 = Counter64
oid_pfilter_removal=1.3.6.1.4.1.12325.1.200.1.3.4.0
pfilter_removal_name="Filter entfernt"

# # Number of pfilter matches
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfCounter.pfCounterMatch.0 = Counter64
oid_pfilter_matches=1.3.6.1.4.1.12325.1.200.1.2.1.0
pfilter_matches_name="Filter zutreffend"

# # Accepted packets in vr0 (LAN)
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfInterfaces.pfInterfacesIfTable.pfInterfacesIfEntry.pfInterfacesIf4PktsInPass.5 = Counter64
oid_packets_lan_accepted=1.3.6.1.4.1.12325.1.200.1.8.2.1.11.5
packets_lan_accepted_name="LAN angenommen"

# # Blocked packets in vr0 (LAN)
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfInterfaces.pfInterfacesIfTable.pfInterfacesIfEntry.pfInterfacesIf4PktsInBlock.5 = Counter64
oid_packets_lan_blocked=1.3.6.1.4.1.12325.1.200.1.8.2.1.12.5
packets_lan_blocked_name="LAN geblockt"

# # Accepted packets in vr1 (WAN)
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfInterfaces.pfInterfacesIfTable.pfInterfacesIfEntry.pfInterfacesIf4PktsInPass.6 = Counter64
oid_packets_wan_accepted=1.3.6.1.4.1.12325.1.200.1.8.2.1.11.6
packets_wan_accepted_name="WAN angenommen"

# # Blocked packets in vr1 (WAN)
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfInterfaces.pfInterfacesIfTable.pfInterfacesIfEntry.pfInterfacesIf4PktsInBlock.6 = Counter64
oid_packets_wan_blocked=1.3.6.1.4.1.12325.1.200.1.8.2.1.12.6
packets_wan_blocked_name="WAN geblockt"

# # Accepted packets in vr2 (OPT)
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfInterfaces.pfInterfacesIfTable.pfInterfacesIfEntry.pfInterfacesIf4PktsInPass.7 = Counter64
# 1.3.6.1.4.1.12325.1.200.1.8.2.1.11.7

# # Blocked packets in vr2 (OPT)
# # SNMPv2-SMI::enterprises::BEGEMOT-PF-MIB::pfInterfaces.pfInterfacesIfTable.pfInterfacesIfEntry.pfInterfacesIf4PktsInBlock.7 = Counter64
# 1.3.6.1.4.1.12325.1.200.1.8.2.1.12.7
﻿  
﻿  #Daten laden

traffic_lan_in=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_traffic_lan_in`
traffic_lan_out=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_traffic_lan_out`
traffic_wan_in=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_traffic_wan_in`
traffic_wan_out=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_traffic_wan_out`
cpu_load=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_cpu_load`
memory_size=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_memory_size`
memory_used=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_memory_used`
shared_mem_size=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_shared_mem_size`
shared_mem_used=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_shared_mem_used`
swap_size=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_swap_size`
swap_used=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_swap_used`
processes=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_processes`
users=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_users`

pfilter_states=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_memory_size`
pfilter_inserts=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_memory_used`
pfilter_removal=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_shared_mem_size`
pfilter_matches=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_shared_mem_used`
packets_lan_accepted=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_swap_size`
packets_lan_blocked=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_swap_used`
packets_wan_accepted=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_processes`
packets_wan_blocked=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_users`

#temp-Dir erstellen und mit aktuellem Wert befüllen
﻿  statepath=$TEMP
﻿  statedir=$statepath/.$host
﻿  datadump_ci=$statedir/datadump.snmp
﻿  source $datadump_ci
﻿  
﻿  if [ ! -d $statedir ]; then
﻿  ﻿  echo "Temp-Verzeichnis "$statedir" wird angelegt"
﻿  ﻿  /bin/mkdir $statedir
﻿  ﻿  /bin/touch $datadump_ci
﻿  ﻿  echo "0" > $datadump_ci
﻿  ﻿  exit 1
﻿  fi

# Auswertung
﻿  # Traffic
﻿  ﻿  #fi=File in; ss=snmpsub; ci=countin:Pfad und Dateiname; di=dump in: Gespeicherte Daten aus dem Dump
﻿  ﻿  ﻿  let traffic_lan_in_ss=$traffic_lan_in-$traffic_lan_in_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="traffic_lan_in_di="$traffic_lan_in;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$traffic_lan_in_name = $traffic_lan_in_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'LAN_IN'=$traffic_lan_in_ss";
﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let traffic_lan_out_ss=$traffic_lan_out-$traffic_lan_out_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="traffic_lan_out_di="$traffic_lan_out;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$traffic_lan_out_name = $traffic_lan_out_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'LAN_OUT'=$traffic_lan_out_ss";
﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let traffic_wan_in_ss=$traffic_wan_in-$traffic_wan_in_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="traffic_wan_in_di="$traffic_wan_in;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$traffic_wan_in_name = $traffic_wan_in_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'WAN_IN'=$traffic_wan_in_ss";
﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let traffic_wan_out_ss=$traffic_wan_out-$traffic_wan_out_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="traffic_wan_out_di="$traffic_wan_out;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$traffic_wan_out_name = $traffic_wan_out_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'WAN_OUT'=$traffic_wan_out_ss";
﻿  ﻿  ﻿  
﻿  # PFilter
﻿  ﻿  ﻿  let pfilter_states_ss=$pfilter_states-$pfilter_states_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="pfilter_states_di="$pfilter_states;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$pfilter_states_name = $pfilter_states_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'PFILTER_STATES'=$pfilter_states_ss";

﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let pfilter_inserts_ss=$pfilter_inserts-$pfilter_inserts_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="pfilter_inserts_di="$pfilter_inserts;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$pfilter_inserts_name = $pfilter_inserts_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'PFILTER_INSERTS'=$pfilter_inserts_ss";

﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let pfilter_removal_ss=$pfilter_removal-$pfilter_removal_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="pfilter_removal_di="$pfilter_removal;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$pfilter_removal_name = $pfilter_removal_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'PFILTER_REMOVAL'=$pfilter_removal_ss";

﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let pfilter_matches_ss=$pfilter_matches-$pfilter_matches_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1;
﻿  ﻿  ﻿  arrayDump[$arrayvar]="pfilter_matches_di="$pfilter_matches;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$pfilter_matches_name = $pfilter_matches_ss";
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'PFILTER_MATCHES'=$pfilter_matches_ss";

﻿  # Packets
﻿  ﻿  ﻿  let packets_lan_accepted_ss=$packets_lan_accepted-$packets_lan_accepted_di;
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  ﻿  arrayDump[$arrayvar]="packets_lan_accepted_di="$packets_lan_accepted;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$packets_lan_accepted_name = $packets_lan_accepted_ss"
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'LAN_ACCEPTED'=$packets_lan_accepted_ss"
﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let packets_lan_blocked_ss=$packets_lan_blocked-$packets_lan_blocked_di
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  ﻿  arrayDump[$arrayvar]="packets_lan_blocked_di="$packets_lan_blocked;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$packets_lan_blocked_name = $packets_lan_blocked_ss"
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'LAN_BLOCKED'=$packets_lan_blocked_ss"
﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let packets_wan_accepted_ss=$packets_wan_accepted-$packets_wan_accepted_di
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  ﻿  arrayDump[$arrayvar]="packets_wan_accepted_di="$packets_wan_accepted;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$packets_wan_accepted_name = $packets_wan_accepted_ss"
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'WAN_ACCEPTED'=$packets_wan_accepted_ss"
﻿  ﻿  ﻿  
﻿  ﻿  ﻿  let packets_wan_blocked_ss=$packets_wan_blocked-$packets_wan_blocked_di
﻿  ﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  ﻿  arrayDump[$arrayvar]="packets_wan_blocked_di="$packets_wan_blocked;
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="$packets_wan_blocked_name = $packets_wan_blocked_ss"
﻿  ﻿  ﻿  arrayPD[$arrayvar]="'WAN_BLOCKED'=$packets_wan_blocked_ss"﻿  
﻿  ﻿  
echo "${arrayDump[@]}" > $datadump_ci

﻿  # CPU-Load
﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  arrayPD[$arrayvar]="'cpu_load'=$cpu_load%;$cpu_load_warn;$cpu_load_critical"
﻿  ﻿  if [[ $cpu_load -ge $cpu_load_critical ]]; then
﻿  ﻿  ﻿  exitstatus=2
#﻿  ﻿  ﻿  echo "Critical - $cpu_load_name bei $cpu_load % | $cpu_load_name=$cpu_load;$cpu_load_warn;$cpu_load_critical"
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="Critical - $cpu_load_name bei $cpu_load %"
﻿  ﻿  elif [[ $cpu_load -ge $cpu_load_warn ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="WARNING - $cpu_load_name bei $cpu_load %"
﻿  ﻿  elif [[ $cpu_load -lt $cpu_load_warn ]]; then
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="OK - $cpu_load_name bei $cpu_load %"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  # Memory
﻿  ﻿  #RAM
﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  memperc=$(echo "scale=0; 100*$memory_used/$memory_size" | /usr/bin/bc -l)
﻿  ﻿  arrayPD[$arrayvar]="'physical_memory'=$memperc%;$memory_warn;$memory_critical"
﻿  ﻿  if [[ $memperc -ge $memory_critical ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="Critical - $memory_name bei $memperc %"
﻿  ﻿  elif [[ $memperc -ge $memory_warn ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="WARNING - $memory_name bei $memperc %"
﻿  ﻿  elif [[ $memperc -lt $memory_warn ]]; then
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="OK - $memory_name bei $memperc %"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  ﻿  
﻿  ﻿  #Shared
﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  shared_mem_perc=$(echo "scale=0; 100*$shared_mem_used/$shared_mem_size" | /usr/bin/bc -l)
﻿  ﻿  arrayPD[$arrayvar]="'shared_memory'=$shared_mem_perc%;$shared_mem_warn;$shared_mem_critical"
﻿  ﻿  if [[ $shared_mem_perc -ge $shared_mem_critical ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="Critical - $shared_mem_name bei $shared_mem_perc %"
﻿  ﻿  elif [[ $shared_mem_perc -ge $shared_mem_warn ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="WARNING - $shared_mem_name bei $shared_mem_perc %"
﻿  ﻿  elif [[ $shared_mem_perc -lt $shared_mem_warn ]]; then
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="OK - $shared_mem_name bei $shared_mem_perc %"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  # Swap
﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  swapperc=$(echo "scale=0; 100*$swap_used/$swap_size" | /usr/bin/bc -l)
﻿  ﻿  arrayPD[$arrayvar]="'swap'=$swapperc;$swap_warn;$swap_critical"
﻿  ﻿  if [[ $swapperc -ge $swap_critical ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="Critical - $swap_name bei $swapperc %"
﻿  ﻿  elif [[ $swapperc -ge $swap_warn ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="WARNING - $swap_name bei swapperc %"
﻿  ﻿  elif [[ $swapperc -lt $swap_warn ]]; then
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="OK - $swap_name bei $swapperc %"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  # Processes
﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  arrayPD[$arrayvar]="'processes'=$processes;$processes_warn;$processes_critical"
﻿  ﻿  if [[ $processes -ge $processes_critical ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="Critical - $processes $processes_name"
﻿  ﻿  elif [[ $processes -ge $processes_warn ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="WARNING - $processes $processes_name"
﻿  ﻿  elif [[ $processes -lt $processes_warn ]]; then
﻿  ﻿  ﻿  arrayStatus[$arrayvar]="OK - $processes $processes_name"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  # Users
﻿  ﻿  let arrayvar=$arrayvar+1
﻿  ﻿  arrayStatus[$arrayvar]="OK - $users $users_name"
﻿  ﻿  arrayPD[$arrayvar]="'users'=$users"
﻿  ﻿  exitstatus=0
﻿  
#Array ausgeben
#echo "${arrayStatus[@]}"
#Warning/Critical zählen
for werte in "${arrayStatus[@]}"; do
if [[ $werte == *CRITICAL* ]]; then
﻿  ﻿  critical=$(echo "scale=0; $critical + 1" | /usr/bin/bc -l)
﻿  ﻿  arrayCritical[$critical]=$werte
﻿  elif [[ $werte == *WARNING*﻿  ]]; then
﻿  ﻿  warning=$(echo "scale=0; $warning + 1" | /usr/bin/bc -l)
﻿  ﻿  arrayWarning[$warning]=$werte
﻿  elif [[ $werte == *OK*﻿  ]]; then
﻿  ﻿  ok=$(echo "scale=0; $ok + 1" | /usr/bin/bc -l)
﻿  ﻿  arrayOK[$ok]=$werte
﻿  else
﻿  ﻿  ok=$(echo "scale=0; $ok + 1" | /usr/bin/bc -l)
﻿  ﻿  arrayOK[$ok]=$werte
fi
done
#Warnung/Critical auswerten und Exitstatus setzen
if [[ $warning -ge 1 ]]; then
﻿  ﻿  exitstatus=1;
fi
if [[ $critical -ge 1 ]]; then
﻿  ﻿  exitstatus=2;
fi

typeset -i i=1
if [[ $critical -ge 1 ]]; then
﻿  while (( i <= $critical ))
﻿  ﻿  do
﻿  ﻿  echo ${arrayCritical[$i]}
﻿  ﻿  i=i+1
﻿  done
fi
if [[ $warning -ge 1 ]]; then
﻿  typeset -i i=1
﻿  while (( i <= $warning ))
﻿  ﻿  do
﻿  ﻿  echo ${arrayWarning[$i]}
﻿  ﻿  i=i+1
﻿  done
fi
if [[ $ok -ge 1 ]]; then
﻿  typeset -i i=1
﻿  ﻿  while (( i <= $ok ))
﻿  ﻿  do
﻿  ﻿  echo ${arrayOK[$i]}
﻿  ﻿  i=i+1
﻿  done
fi

echo "|"${arrayPD[*]}
#echo $exitstatus
exit $exitstatus

