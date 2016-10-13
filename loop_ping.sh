#!/bin/bash

echo "Starting loop v2.1 ($0 - incl. retry logging)"

PREFIX=192.168.101

shmcWait="0 100 300 500"
sharedWait="0 90 100"
BMCWait="0 90"

sharedIPfails=0
exitloop=0

cliqueux_new_gen --enable 0
sleep 20

while [ $exitloop -lt 5 ]
do
    let "loop +=1"
    echo -n "pinging: "
    for host in 1 2 3 10 11 12 13 14 15 16 17 18 19; do
        echo -n "$host?"
        # retry loop
        case "$host" in
                1|2) waitSeq=$shmcWait;;
                3) waitSeq=$sharedWait;;
                1[0123456789]) waitSeq=$BMCWait;;
        esac
        for wait in $waitSeq; do
                sleep $wait
                ping -c2 $PREFIX.$host > /dev/null
                if [ $? -eq 0 ]; then
                        echo -ne "\b! "
                        break
#               elif [ $wait -eq 500 ]; then
               elif [ $wait -eq $(echo $waitSeq | awk 'BEGIN {ORS=""} {print $NF}') ]; then
                        echo -ne "\bX "
                        case "$host" in
                                1|2) let "exitloop=5";;
                                3) let "exitloop +=1"; let "sharedIPfails +=1";;
                                1[0123456789]) ;;
                        esac
                else
                        echo -ne "\bx?"
                fi
        done
    done

    echo -e "\nLoop: on (#$loop) @ $(date)"
    cliqueux_new_gen --enable 1
    ping -c5 $PREFIX.0 -b &> /dev/null
    sleep 3600
    cliqueux_new_gen --enable 0
    echo "Loop: off"
    sleep 60
done

if [ $sharedIPfails -ne 0 ]; then
        echo -e " SharedIP failed to respond $sharedIPfails times in $loop loops.\n\n"
fi
