#!/bin/sh

DATETIME=`date +"%F-%T"`
LOG_FILE="log-$DATETIME"

mkdir -p logs
if [ "$1" ]; then
  export PALAVA_RTC_ADDRESS="$1"
else
  export PALAVA_RTC_ADDRESS="4233"
fi
nohup mix run --no-halt > logs/$LOG_FILE 2>&1 &
