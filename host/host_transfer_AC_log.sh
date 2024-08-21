#!/bin/bash

HOST_POWER_ON_LOG=/home/s9b/host_power_on.log
LOOP_COUNT_LOG=/home/s9b/loop_count.log
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOOP_NUM=
IP=10.10.15.69
USERNAME=admin
PASSWORD=cmb9.cmb9
TMP_DIR=/tmp
TRANSFER_REDAY=/tmp/transferReady.log

function createFile () {
    if [ ! -f $HOST_POWER_ON_LOG ]; then
        touch $HOST_POWER_ON_LOG
    fi

    if [ ! -f $LOOP_COUNT_LOG ]; then
        touch $LOOP_COUNT_LOG
    fi
}

# transfer HOST_POWER_ON_LOG.log to BMC to trigger AC
function transferPowerOnLog () {
    sshpass -p $PASSWORD scp $HOST_POWER_ON_LOG $USERNAME@$IP:$TMP_DIR
    sshpass -p $PASSWORD scp $HOST_POWER_ON_LOG $USERNAME@$IP:$TMP_DIR
}

function transferLog () {
    local TARGET_LOG=/tmp/loop$LOOP_NUM
    local LOG_DIR=/home/s9b/AC_LOG
    if [ ! -d $LOG_DIR ]; then
        mkdir $LOG_DIR
    fi

    local TRANSFER_DONE=$LOG_DIR/transferDone.log

    while [ ! -f $TRANSFER_REDAY ]; do
        sshpass -p $PASSWORD scp $USERNAME@$IP:$TRANSFER_REDAY $TRANSFER_REDAY
        sleep 5
    done

    while [ ! -d $LOG_DIR/loop$LOOP_NUM ]; do
        sshpass -p $PASSWORD scp -r $USERNAME@$IP:$TARGET_LOG $LOG_DIR
        sleep 5
    done
    touch $TRANSFER_DONE
    sshpass -p $PASSWORD scp $TRANSFER_DONE $USERNAME@$IP:$TMP_DIR
}

function main () {
    createFile

    LOOP_NUM=$(wc -l $LOOP_COUNT_LOG | awk '{print $1}')
    echo "LOOP$LOOP_NUM   $DATE" >> $LOOP_COUNT_LOG

    sleep 20
    transferPowerOnLog
    transferLog
}

main
