#!/bin/bash

export PALAVA_STATS_FILE="logs/room-stats.csv"
mkdir -p logs

if [ "$1" ]; then
  export PALAVA_RTC_ADDRESS="$1"
else
  export PALAVA_RTC_ADDRESS="4233"
fi
elixir --sname signaltower -S mix run --no-halt
