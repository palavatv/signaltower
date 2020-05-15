#!/bin/bash

mkdir -p logs

if [ "$1" ]; then
  export SIGNALTOWER_PORT="$1"
else
  export SIGNALTOWER_PORT="4233"
fi
elixir --sname signaltower -S mix run --no-halt
