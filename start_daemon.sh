#!/bin/sh

DATETIME=`date +"%F-%T"`
LOG_FILE="log-$DATETIME"

mkdir -p logs
export PALAVA_RTC_ADDRESS="4233"
nohup mix run --no-halt > logs/$LOG_FILE 2>&1 &
