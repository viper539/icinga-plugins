#! /bin/bash
# substring-extraction.sh
#

critical=0
warning=0
ok=0

PATH="/usr/local/icinga/"
SNMPGET="/usr/bin/snmpget"
SORT="/usr/bin/sort"
SED="/bin/sed"
EXPR="/usr/bin/expr"
PROGNAME=`/usr/bin/basename $0`

PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 0.1 $' | /bin/sed -e 's/[^0-9.]//g'`

. $PROGPATH/utils.sh

print_usage() {
    echo "Usage: $PROGNAME -H Host -C Community -s SizeOID -u UsedOID -w Warn -c Critical"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME --version"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    print_usage
    echo ""
    echo "Daten via SNMP aus unterschiedlichen KM-Druckern auslesen"
    echo ""
    support
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
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

# Druckertyp C35P
#Name/OID: .1.3.6.1.2.1.1.1.0; Value (OctetString): KONICA MINOLTA bizhub C35P
oid_name=.1.3.6.1.2.1.1.1.0

#Uptime
#Name/OID: .1.3.6.1.2.1.1.3.0; Value (TimeTicks): 108 hours 4 minutes 39 seconds
oid_uptime=.1.3.6.1.2.1.1.3.0

printer_name=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_name`
printer_uptime=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_uptime`
#echo $printer_name
if [[ $printer_name == *C35P* ]]; then
﻿  array=(1 2 3 4 5 6 7 8 9 10 11 12)
elif [[ $printer_name == *20P*  ]]; then
﻿  array=(1 2)
elif [[ $printer_name == *C25*  ]]; then
﻿  array=(1 2 3 4 5 6 7 8 9 10 11 12)
elif [[ $printer_name == *C360*  ]]; then
﻿  array=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21)
else
﻿  exitstatus=3
﻿  echo "Zuordnung der Checks - Unknown - I see dead people - Something is wrong"
fi

if [[ $printer_name == *20P* ]]; then
﻿  # Display
﻿  #Name/OID: .1.3.6.1.2.1.43.18.1.1.8.1.146; Value (OctetString): Paper Jam
﻿  oid_display=.1.3.6.1.2.1.43.18.1.1.8.1.1
﻿  
﻿  printer_display_double=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_display`
﻿  printer_display_leer=$(echo $printer_display_double|/bin/sed 's/"//g')
﻿  printer_display=$(echo $printer_display_leer|/bin/sed 's/ //g')
#﻿  echo $printer_display_double
#﻿  echo $printer_display
﻿  if [[ $printer_display == "ENERGIESPAREN" ]]; then
﻿  ﻿  exitstatus=0
﻿  ﻿  arrayStatus[500]="OK - Drucker ist im Energiesparmodus"
﻿  elif [[ $printer_display == "WENIGTONER" ]]; then
﻿  ﻿  exitstatus=1
﻿  ﻿  arrayStatus[500]="WARNING - Drucker hat wenig Toner"
﻿  elif [[ $printer_display == "TONERERSETZEN" ]]; then
﻿  ﻿  exitstatus=2
﻿  ﻿  arrayStatus[500]="CRITICAL - Toner sofort tauschen"
﻿  elif [[ $printer_display == "PAPERJAM" ]]; then
﻿  ﻿  exitstatus=2
﻿  ﻿  arrayStatus[500]="CRITICAL - Drucker Papierstau!"
﻿  else
﻿  ﻿  exitstatus=0
﻿  ﻿  arrayStatus[500]="OK - Keine Stoerung"
﻿  fi
fi

# if [[ $printer_name == *C35P* ]]; then
#﻿  #Display
#﻿  #Name/OID: .1.3.6.1.2.1.43.18.1.1.8.1.4961; Value (OctetString): Paper Jam
﻿  # oid_display=.1.3.6.1.2.1.43.18.1.1.8.1.4961
﻿  
﻿  # printer_display_double=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_display`
﻿  # printer_display_leer=$(echo $printer_display_double|/bin/sed 's/"//g')
﻿  # printer_display=$(echo $printer_display_leer|/bin/sed 's/ //g')
﻿  # #echo $printer_display_double
﻿  # #echo $printer_display
﻿  # if [[ $printer_display == "ENERGIESPAREN" ]]; then
﻿  ﻿  # exitstatus=0
﻿  ﻿  # arrayStatus[500]="OK - Drucker ist im Energiesparmodus"
﻿  # elif [[ $printer_display == "WENIGTONER" ]]; then
﻿  ﻿  # exitstatus=1
﻿  ﻿  # arrayStatus[500]="WARNING - Drucker hat wenig Toner"
﻿  # elif [[ $printer_display == "TONERERSETZEN" ]]; then
﻿  ﻿  # exitstatus=2
﻿  ﻿  # arrayStatus[500]="CRITICAL - Toner sofort tauschen"
﻿  # elif [[ $printer_display == "PAPERJAM" ]]; then
﻿  ﻿  # exitstatus=2
﻿  ﻿  # arrayStatus[500]="CRITICAL - Drucker Papierstau!"
﻿  # else
﻿  ﻿  # exitstatus=0
﻿  ﻿  # arrayStatus[500]="OK - Keine Stoerung"
﻿  # fi
# fi



oid_checks=${#array[*]}
#echo "Elemente zu checken: $oid_checks"
oid_checks=$(echo "scale=0; $oid_checks - 1" | /usr/bin/bc -l)
#echo $oid_checks

oid_var=1
ANZAHL=0
while [ $ANZAHL -le $oid_checks ]
﻿  do
﻿  oid_var=${array[$ANZAHL]}
﻿  # echo "Array items:"
﻿  # for oid_var in ${array[$ANZAHL]}
﻿  # do
    # printf "   %s\n" $oid_var
﻿  # done
﻿  ﻿  #Wird leer oder voll
﻿  ﻿  #Name/OID: prtMarkerSuppliesClass.1.1-12; Value (Integer): supplyThatIsConsumed
﻿  ﻿  oid_class=.1.3.6.1.2.1.43.11.1.1.4.1.$oid_var
﻿  ﻿  #Toner oder Trommel
﻿  ﻿  #Name/OID: prtMarkerSuppliesType.1.1; Value (Integer): toner
﻿  ﻿  oid_type=.1.3.6.1.2.1.43.11.1.1.5.1.$oid_var
﻿  ﻿  #Beschreibung
﻿  ﻿  #Name/OID: prtMarkerSuppliesDescription.1.1; Value (OctetString): Cyan Toner
﻿  ﻿  oid_description=.1.3.6.1.2.1.43.11.1.1.6.1.$oid_var
﻿  ﻿  #Kapazität
﻿  ﻿  #Name/OID: prtMarkerSuppliesMaxCapacity.1.1; Value (Integer): 6000
﻿  ﻿  oid_capacity=.1.3.6.1.2.1.43.11.1.1.8.1.$oid_var
﻿  ﻿  #Level
﻿  ﻿  #Name/OID: prtMarkerSuppliesLevel.1.1; Value (Integer): 6000
﻿  ﻿  oid_level=.1.3.6.1.2.1.43.11.1.1.9.1.$oid_var
﻿  ﻿  toner_warn_perc=3
﻿  ﻿  toner_critical_perc=2
﻿  ﻿  waste_warn_perc=90
﻿  ﻿  waste_critical_perc=95
﻿  ﻿  #echo "Name:$oid_name; Uptime:$oid_uptime; Class:$oid_class; Type:$oid_type; Description:$oid_description; Capacity:$oid_capacity; Level:$oid_level;"
#﻿  ﻿  oid_var=$(echo "scale=0; $oid_var + 1" | /usr/bin/bc -l)
#﻿  ﻿  echo $oid_var

﻿  ﻿  ANZAHL=$(echo "scale=0; $ANZAHL + 1" | /usr/bin/bc -l)
#﻿  ﻿  echo $ANZAHL
﻿  
﻿  #Daten laden

printer_class=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_class`
printer_type=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_type`
printer_description_double=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_description`
printer_capacity=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_capacity`
printer_level=`/usr/bin/snmpget -O avq  -v 1 -c $comm $host $oid_level`

#Entfernen der "
printer_description=$(echo $printer_description_double|/bin/sed 's/"//g')
#Hinzufügern der ' für PNP
printer_description_pd="'"$printer_description"'"

#echo "Name:$printer_name; Uptime:$printer_uptime; Class:$printer_class; Type:$printer_type; Description:$printer_description; Capacity:$printer_capacity; Level:$printer_level"

#Auswertung

printer_level_perc=$(echo "scale=0; 100*$printer_level/$printer_capacity" | /usr/bin/bc -l)
#pd1="$printer_description=$printer_level_perc;$toner_warn_perc;$toner_critical_perc"
﻿  if ([ $printer_class == "3" ] && [ $printer_capacity -gt "0" ]); then #Toner
﻿  ﻿  pd="$printer_description_pd=$printer_level_perc;$toner_warn_perc;$toner_critical_perc"
﻿  ﻿  if [[ $printer_level_perc -lt $toner_critical_perc ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  status="CRITICAL - $printer_description bei $printer_level_perc %"
﻿  ﻿  elif [[ $printer_level_perc -lt $toner_warn_perc ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  status="WARNING - $printer_description bei $printer_level_perc %"
﻿  ﻿  elif [[ $printer_level_perc -ge $toner_warn_perc ]]; then
﻿  ﻿  ﻿  status="OK - $printer_description bei $printer_level_perc %"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Toner - Class:$class, Wert:$rem, Typ:$ven Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  elif ([ $printer_class == "3" ] && [ $printer_capacity = "-2" ]); then #Verbrauchsmaterial
#﻿  ﻿  pd="$printer_description=$printer_level;$waste_warn;$waste_critical"
﻿  ﻿  pd=""
﻿  ﻿  if [[ $printer_level == 0 ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  status="CRITICAL - $printer_description leer. Sofort tauschen!"
﻿  ﻿  elif [[ $printer_level == -2 ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  status="WARNING - $printer_description niedrig"
﻿  ﻿  elif [[ $printer_level == -3 ]]; then
﻿  ﻿  ﻿  status="OK - $printer_description nicht voll"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Verbrauchsmaterial - Class:$class, Wert:$rem, Typ:$ven Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  elif [[ $printer_class == "4" ]]; then #Resttoner
#﻿  ﻿  pd="$printer_description=$printer_level;$waste_warn;$waste_critical"
﻿  ﻿  pd=""
﻿  ﻿  if [[ $printer_level == -2 ]]; then
﻿  ﻿  ﻿  exitstatus=2
﻿  ﻿  ﻿  status="CRITICAL - $printer_description voll. Sofort tauschen!"
﻿  ﻿  elif [[ $printer_level == 1 ]]; then
﻿  ﻿  ﻿  exitstatus=1
﻿  ﻿  ﻿  status="WARNING - $printer_description bald voll"
﻿  ﻿  elif [[ $printer_level == -3 ]]; then
﻿  ﻿  ﻿  status="OK - $printer_description nicht voll"
﻿  ﻿  ﻿  exitstatus=0
﻿  ﻿  ﻿  
﻿  ﻿  else
﻿  ﻿  ﻿  exitstatus=3
﻿  ﻿  ﻿  echo "Resttoner - Class:$printer_class, Level:$printer_level, Wert:$rem, Typ:$ven Unknown - I see dead people - Something is wrong"
﻿  ﻿  fi
﻿  else
﻿  ﻿  exitstatus=3
﻿  ﻿  echo "Allgemein - Class:$class, Wert:$rem, Typ:$ven Unknown - I see dead people - Something is wrong"
﻿  fi



﻿  arrayStatus[$oid_var]=$status
﻿  arrayPD[$oid_var]=$pd
﻿  
done

# critical=0
# warning=0
# ok=0
#echo "${arrayStatus[@]}"
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
fi
done

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
