#!/bin/bash

RPC=${1:-http://localhost:8545}

latest=$(cast block-number --rpc-url $RPC)

start=$((latest-100))

total_tx=0
first_ts=0
last_ts=0

for ((i=start;i<=latest;i++))
do
  block=$(cast block $i --rpc-url $RPC --json)

  tx_count=$(echo "$block" | jq '.transactions | length')
  ts=$(echo "$block" | jq '.timestamp')

  if [ "$first_ts" -eq 0 ]; then
    first_ts=$ts
  fi

  last_ts=$ts
  total_tx=$((total_tx + tx_count))
done

time_diff=$((last_ts - first_ts))

tps=$(awk "BEGIN {print $total_tx/$time_diff}")

echo "Blocks analyzed: $start -> $latest"
echo "Total tx: $total_tx"
echo "Time window: $time_diff sec"
echo "Average TPS: $tps"