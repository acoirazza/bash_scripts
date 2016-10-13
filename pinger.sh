#!/bin/bash
recursive script to:
- scan IP range
- identify responding components (if BMC) with ipmitool
- include upstream ShMC Type & IP config

START=`date +%s`

MAX_THREADS=200
OUTPUT_LOG=/tmp/outlog.txt
LIVE_HOSTS=/tmp/pinged.txt
PING_INTERVAL=0.3
START_IP=
MASK_BITS=
NODES_Found=

Nodes=0
IPMBs="0x82
0x84
0x86
0x88
0x8a
0x8c
0x8e
0x90
0x92"

# LOG is Logfiles are valid?

case $# in
        2) # pinger++
                if [[ -f $2 ]]; then
                        OUTPUT_LOG=$2
                        IP=$1
                        PING=$(ping -c2 -w2 -i$PING_INTERVAL $IP |grep ttl |wc -l 2> /dev/null)
                        if [ $PING -gt 0 ]; then
                                echo "$IP pinged!       " >> $LIVE_HOSTS
                                #[[ -f $LIVE_HOSTS ]] || echo $IP >> $LIVE_HOSTS
                                #if curl http://$IP:9090/Version &> /dev/null; then... ??
                                PROD=$(ipmitool -Ilan -H$IP -Uadmin -Padmin mc info 2> /dev/null |awk '/Product ID/ {print $(NF-1)}')
                                if [[ $PROD ]]; then
                                        case $PROD in
                                                "4003") PROD="MSP800x";;
                                                "4005") PROD="MSP802x";;
                                                "4007") PROD="MSP803x";;
                                                "4008") PROD="MSP8040";;
                                                "4009") PROD="MSP8050";;
                                                "4301") PROD="MSH8900";;
                                                "4302") PROD="MSH8910";;
                                                "4303") PROD="MSH8911";;
                                                "5008") PROD="AT8060";;
                                                "43707")
                                                        PROD="CS3160"
                                                        echo -e "\r                     \r\e[1A$IP: $PROD"
                                                        exit 0;;
                                                "93")
                                                        PROD="CG2200"
                                                        echo -e "\r                     \r\e[1A$IP: $PROD"
                                                        exit 0;;
                                                "113")
                                                        PROD="CG2300"
                                                        echo -e "\r                     \r\e[1A$IP: $PROD"
                                                        exit 0;;
                                                *);;
                                        esac

                                        IPMB=$(ipmitool -Ilan -H$IP -Uadmin -Padmin sdr elist mcloc 2> /dev/null |awk '{print "0x"substr($NF,0,2)}')
                                        if [[ $PROD == MS* ]]; then
                                                [[ "$IPMB" == "0x20" ]] && SHMC="0x10" || SHMC="0x20"

                                                if [ "$IPMB" == "0x20" ] || [ "$IPMB" == "0x10" ]; then
                                                        # Test IPMB is correct for SHMCs
                                                        ipmitool -Ilan -H$IP -Uadmin -Padmin -m$IPMB -t$SHMC mc info &> /dev/null
                                                        if [ $? -ne 0 ]; then # test inverted, else OK (actually 0x20)
                                                                ipmitool -Ilan -H$IP -Uadmin -Padmin -m$SHMC -t$IPMB mc info &> /dev/null
                                                                if [ $? -eq 0 ]; then # SHMC actually 0x10
                                                                        TEMP=$SHMC; SHMC=$IPMB; IPMB=$TEMP
                                                                else
# Fix ShMC error logic
                                                                        echo "ShMC IPMB Addr issue detected! ($IP)"
                                                                fi
                                                        fi

                                                        for nIPMB in $IPMBs
                                                        do
                                                                nPROD=$(ipmitool -Ilan -H$IP -Uadmin -Padmin -m$IPMB -t$nIPMB mc info 2> /dev/null |awk '/Product ID/ {print $(NF-1)}')
                                                                [ -z $nPROD ] || ((Nodes++))
                                                        done
                                                        NODES_Found=" + $Nodes nodes"
                                                fi
                                                SHMC_TYP=$(ipmitool -Ilan -H$IP -Uadmin -Padmin -m$IPMB -t$SHMC mc info 2> /dev/null |awk '/Product ID/ {print $(NF-1)}')
                                                if [[ $SHMC_TYP ]]; then
                                                        SHMC_IP=$(ipmitool -Ilan -H$IP -Uadmin -Padmin -m$IPMB -t$SHMC lan print 2> /dev/null |awk '/IP Address * :/ {print $NF}')
                                                        case $SHMC_TYP in
                                                                "4301") SHMC_TYP="MSH8900";;
                                                                "4302") SHMC_TYP="MSH8910";;
                                                                "4303") SHMC_TYP="MSH8911";;
                                                                *);;
                                                        esac

        # Add SHMC_IP to scan list?
        # Scan Chassis?
                                                        echo "$IP: $PROD@$IPMB (SHMC $SHMC_TYP@$SHMC - $SHMC_IP)$NODES_Found" | tee -a $OUTPUT_LOG
                                                else
                                                        echo "$IP: $PROD@$IPMB (No SHMC@$SHMC)$NODES_Found" | tee -a $OUTPUT_LOG
                                                fi # if ShMC_TYP
                                        else
                                                echo "$IP: $PROD@$IPMB$NODES_Found" | tee -a $OUTPUT_LOG
                                        fi
                                else
# Toggle display of 'ping-onlys'
                                        echo "$IP pinged!       "
                                fi # if PROD
                        fi # if PING
                else
                        echo "$2 is not a valid file - Exiting (21)"
                        exit 21
                fi # if -f $2

                exit 20;;

        1) # main
                case $1 in
                        "odin" | "Odin" )       IP_Subnet="192.168.10.0/24";;
                        "titan" | "Titan" )     IP_Subnet="192.168.8.0/24";;
                        "helios" | "Helios" | "Helios-VM" ) IP_Subnet="172.16.0.0/16";;
                        "?" )   echo "$0 usage: $0 [odin|titan|helios|IP-Address/Subnet|?]";;
                        *)
                                IP_Subnet=$1
                                MASK_BITS=$(awk -F/ '{ print $2}' <<<"${IP_Subnet}")
                                case $MASK_BITS in
                                        8)
                                                O2_START=255; O2_END=0
                                                O3_START=255; O3_END=0;;
                                        16)
                                                O2_START=$(awk -F. '{ print $2}' <<<"${IP_Subnet}")
                                                O2_END=$O2_START
                                                O3_START=255; O3_END=0;;
                                        24)
                                                O2_START=$(awk -F. '{ print $2}' <<<"${IP_Subnet}")
                                                O2_END=$O2_START
                                                O3_START=$(awk -F. '{ print $3}' <<<"${IP_Subnet}")
                                                O3_END=$O3_START;;
                                        *)
                                                echo "Only subnets with 8, 16 or 24 bits are supported ATM (CIDR notation) - Exiting (22)"
                                                exit 22;;
                                esac

                                OCT1=$(awk -F. '{ print $1}' <<<"${IP_Subnet}")
                                #OCT2=$(awk -F. '{ print $2}' <<<"${IP_Subnet}")
                                #OCT3=$(awk -F. '{ print $3}' <<<"${IP_Subnet}")
                                O4_START=254; O4_END=1
                                echo "Parsed: $OCT1.$O2_END.$O3_END.0/$MASK_BITS";;
                esac

                echo starting $0 on $(date) >> $OUTPUT_LOG
                echo starting $0 on $(date) >> $LIVE_HOSTS

                for (( O2=$O2_START; O2>=$O2_END; O2-- )); do
                        for (( O3=$O3_START; O3>=$O3_END; O3-- )); do
                                echo -en "Starting $OCT1.$O2.$O3.0...\r"
                                for (( O4=$O4_START; O4>=$O4_END; O4-- )); do
                                        while [[ $(ps -a |grep ${0#./} |wc -l) -gt $MAX_THREADS ]]; do
                                                sleep 0.5 # 500ms
                                        done

                                        sleep 0.1
                                        $0 $OCT1.$O2.$O3.$O4 $OUTPUT_LOG &
# Throbber?
                done;   done;   done
# Stats on what was found?
# Logfile sort?

                while [[ $(ps -a |grep $0 |wc -l) -gt $MAX_THREADS ]]; do
                        sleep 0.5 # 500ms
                done

                secs=$((`date +%s`-START))
                printf "Script ran for "'%dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))
                #echo "script ran for "$((`date +%s`-START))" seconds."

                exit 0;;
        *)
                echo "Invalid number of arguments ($#) - Exiting (2)"
                exit 2;;
esac

# Keepalive until last pings complete

exit 99;
