#!/bin/bash

DEVICE="${1:-device-1}"
INTERVAL="${2:-10}"
URL="${3:-http://localhost:5000/upload}"

# start location (Dhaka center)
lat=23.7775
lon=90.3995

echo "Sending fake GPS every ${INTERVAL}s to ${URL} as ${DEVICE}. Ctrl-C to stop."

while true; do
  # small random delta to simulate motion
  # generate a small movement ~ up to ~0.0004 degrees (~40m)
  delta_lat=$(awk -v min=-0.0003 -v max=0.0003 'BEGIN{srand(); print min + (max-min)*rand()}')
  delta_lon=$(awk -v min=-0.0003 -v max=0.0003 'BEGIN{srand(); print min + (max-min)*rand()}')

  lat=$(awk -v a="$lat" -v b="$delta_lat" 'BEGIN{printf "%.6f", a + b}')
  lon=$(awk -v a="$lon" -v b="$delta_lon" 'BEGIN{printf "%.6f", a + b}')

  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  json=$(cat <<JSON
{
  "t": "${timestamp}",
  "id": "${DEVICE}",
  "lat": ${lat},
  "lon": ${lon}
}
JSON
)

  echo "$(date +"%T") -> POST ${lat}, ${lon}"
  curl -s -X POST -H "Content-Type: application/json" -d "${json}" "${URL}" >/dev/null || echo "Post failed"
  sleep "${INTERVAL}"
done
