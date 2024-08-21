#!/bin/bash

TMP_DIR=/tmp
AC_LOG=$TMP_DIR/ac.log
LOOP_COUNT_LOG=/home/admin/loop_count.log
HOST_POWER_ON_LOG=$TMP_DIR/host_power_on.log
LOOP_NUM=
DATE=
RESULT=0

function createFile () {
    if [ ! -f $LOOP_COUNT_LOG ]; then
        touch $LOOP_COUNT_LOG
    fi
}

function logCollection () {
    local LOG_DIR=$TMP_DIR/loop$LOOP_NUM
    local TRANSFER_REDAY=$TMP_DIR/transferReady.log
    local JOURNAL_LOG=$LOG_DIR/journalctl.log
    local JOURNAL_EXPORT_LOG=$LOG_DIR/journalctl_export.log

    mkdir $LOG_DIR
    while [ ! -d $LOG_DIR ]; do
        sleep 1
    done
    journalctl > $JOURNAL_LOG
    journalctl -o export > $JOURNAL_EXPORT_LOG
    dreport -d $LOG_DIR -v
    touch $TRANSFER_REDAY
}

function waitingForHostPowerOn () {
    while [ ! -f $HOST_POWER_ON_LOG ]; do
        sleep 1
    done
}

function logSelTime () {
    local SEL_LOG=/home/admin/sel.log

    echo "LOOP$LOOP_NUM   $DATE" >> $SEL_LOG
    ipmitool sel elist >> $SEL_LOG

    # VALUE format is like 06/17/24@08:01:34
    local VALUE=$(ipmitool sel elist | grep -v 'AC lost' | awk -F ' ' '{print $3 "@" $5}')
    local PRE_VALUE=0
    for VAL in $VALUE;
    do
        local SPACE=" "
        # Replace @ with space, VALUE format is like 06/17/24 08:01:34
        VAL="${VAL/@/$SPACE}"
        # Replace / with -, VALUE format is like 06-17-24 08:01:34
        VAL=$(sed 's/\//-/g' <<< $VAL)

        local YEAR=20${VAL:6:2}
        local DAY=${VAL:0:2}
        # Swap year and day, VALUE format is like 2024-17-06 08:01:34
        VAL=${VAL/${VAL:6:2}/$DAY}
        VAL=${VAL/${VAL:0:2}/$YEAR}

        local TIME_STAMP=$(date -d "$VAL" +%s)
        if [ $TIME_STAMP -lt $PRE_VALUE ]; then
            RESULT=$(($RESULT | 1))
        fi
        PRE_VALUE=$TIME_STAMP
    done
}

function logPsuStatus () {
    local PSU_LOG=/home/admin/psu.log

    echo "LOOP$LOOP_NUM   $DATE" >> $PSU_LOG
    ipmitool sensor list | grep PSU_Status >> $PSU_LOG

    local VALUE=$(ipmitool sensor list | grep PSU_Status | awk -F '|' '{print $4}')
    if [ "$VALUE" != " 0x0100" ]; then
        sleep 60
        echo "=========== $DATE ===========" >> $PSU_LOG
        ipmitool sensor list | grep PSU_Status >> $PSU_LOG
        VALUE=$(ipmitool sensor list | grep PSU_Status | awk -F '|' '{print $4}')
        if [ "$VALUE" != " 0x0100" ]; then
            RESULT=$(($RESULT | 1))
        fi
    fi
}

# Check if bmcweb is working
function logEventLog () {
    local BMC_IP=10.10.15.69
    local USERNAME=admin
    local PASSWORD=cmb9.cmb9
    local EVENT_LOG=/home/admin/event.log

    echo "LOOP$LOOP_NUM   $DATE" >> $EVENT_LOG
    curl -u $USERNAME:$PASSWORD -k https://$BMC_IP/redfish/v1/Systems/system/LogServices/EventLog >> $EVENT_LOG

    local VALUE=$(curl -u $USERNAME:$PASSWORD -k https://$BMC_IP/redfish/v1/Systems/system/LogServices/EventLog)
    if [ "$VALUE" == "Service Unavailable" ]; then
        RESULT=$(($RESULT | 1))
    fi
}

function doLog () {
    #logPsuStatus
    logSelTime
    logEventLog
    logCollection
}

function waitForTransmission () {
    local TRANSFER_DONE=$TMP_DIR/transferDone.log
    while [ ! -f $TRANSFER_DONE ]; do
        sleep 1
    done
}

function main () {
    DATE=$(date)
    createFile
    waitingForHostPowerOn
    LOOP_NUM=$(wc -l $LOOP_COUNT_LOG | awk '{print $1}')
    doLog
    ipmitool sel clear
    waitForTransmission
    echo "LOOP$LOOP_NUM   $DATE" >> $LOOP_COUNT_LOG
    if [ $RESULT -ne 0 ]; then
        exit 1
    fi
    touch $AC_LOG
}

main
