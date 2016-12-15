#!/bin/bash

SITES=15
NODES="1 2 3 4 5 6 7 8 9" # possible values 1-9 must be listed explicitly
CPUS="1 2"
VLANS="420 421 422" # VLAN 423 included by default
RETRIES=2
FAIL_TOLERANCE=3  # consecutive fails (to capture CTRL+C's)
failCount=0

myPing ()
{
        ping -c1 $1 &>> /tmp/ping.tmp
        if [ $? -eq 0 ]; then
                echo $1 - OK!
                failCount=0
        else
#TODO: Insert Retry loop, log failure after retries expended
                ping -c1 $1 &>> /tmp/ping.tmp
                if [ $? -eq 0 ]; then
                        echo $1 - OK!
                else
                        echo $1 - Failed!!
                        let failCount=failCount+1
                        if [ $failCount -ge $FAIL_TOLERANCE ]; then
                                echo "exiting after $failCount consecutive failed pings"
                                exit 1;
                        fi
                        return 1;
        fi;     fi
}

#date > /tmp/ping.log

for site in $SITES; do
        echo "=== Site: $site ==="
        echo -n "ShMC1:    "; myPing 10.$site.223.1
        echo -n "ShMC2:    "; myPing 10.$site.223.2
        echo -n "SharedIP: "; myPing 10.$site.223.3
        echo -n "Switch:   "; myPing 10.$site.223.4

        for node in $NODES; do
                echo " = Node $node = "
                echo -n "BMC: "
                myPing 10.$site.223.""$node""0
                for cpu in $CPUS; do
                        echo " == CPU $cpu =="
                        for vlan in $VLANS 223; do
                                myPing 10.$site.$vlan.$node$cpu
done;   done;   done;   done
