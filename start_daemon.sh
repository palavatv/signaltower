#!/bin/sh

DATETIME=$(date +"%F-%T")
LOG_FILE="log-$DATETIME"

mkdir -p logs
if [ "$1" ]; then
  export SIGNALTOWER_PORT="$1"
else
  export SIGNALTOWER_PORT="4233"
fi
nohup elixir --sname signaltower -S mix run --no-halt > "logs/$LOG_FILE" 2>&1 &
