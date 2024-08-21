#!/bin/bash

function AC () {
    # power off
    python /home/relay/relay/relay_all_on.py

    sleep 5

    # power on
    python /home/relay/relay/relay_all_off.py
}

function main () {
    local TARGET_AC_LOG=/tmp/ac.log
    local RELAY_AC_LOG=/home/relay/relay/ac.log
    local LOOP_COUNT_LOG=/home/relay/relay/loop_count.log
    local DATE=$(date)
    local USERNAME=admin
    local PASSWORD=cmb9.cmb9
    local IP=10.10.15.69

    if [ ! -f $LOOP_COUNT_LOG ]; then
        touch $LOOP_COUNT_LOG
    fi

    local LOOP_NUM=$(wc -l $LOOP_COUNT_LOG | awk '{print $1}')

    while true
    do
        while [ ! -f $RELAY_AC_LOG ]; do
            sshpass -p $PASSWORD scp $USERNAME@$IP:$TARGET_AC_LOG $RELAY_AC_LOG
            sleep 5
        done
        AC
        echo "LOOP$LOOP_NUM   $DATE" >> $LOOP_COUNT_LOG
        mv $RELAY_AC_LOG /tmp
        LOOP_NUM=$(wc -l $LOOP_COUNT_LOG | awk '{print $1}')
        DATE=$(date)
    done
}

main
