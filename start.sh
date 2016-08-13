#!/bin/sh

if [ "$1" ]; then
  export PALAVA_RTC_ADDRESS="$1"
else
  export PALAVA_RTC_ADDRESS="4233"
fi
mix run --no-halt
