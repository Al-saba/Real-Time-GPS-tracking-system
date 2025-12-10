#!/bin/bash
# gps_to_web.sh
# Usage:
# ./gps_to_web.sh path/to/gps_line.json http://server:5000/upload
# or: ./gps_to_web.sh fake_gps.txt http://localhost:5000/upload
FILE="$1"
URL="${2:-http://localhost:5000/upload}"

if [ -z "$FILE" ]; then
  echo "Usage: $0 <file> [url]"
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

# If file is a JSON with lat/lon, post its content directly
# Otherwise, try to parse simple CSV `t,id,lat,lon` first line
CONTENT=$(cat "$FILE")
if echo "$CONTENT" | jq -e . >/dev/null 2>&1; then
  echo "Posting JSON file to ${URL}"
  curl -s -X POST -H "Content-Type: application/json" -d @"$FILE" "$URL" && echo "OK"
  exit 0
fi

# Try CSV parse (first data line)
LINE=$(awk 'NR>1{print; exit}' "$FILE")
if [ -z "$LINE" ]; then
  LINE=$(head -n1 "$FILE")
fi

# Expect t,id,lat,lon
IFS=',' read -r t id lat lon <<< "$LINE"
if [[ -n "$lat" && -n "$lon" ]]; then
  json=$(jq -n \
    --arg t "${t:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}" \
    --arg id "${id:-device-1}" \
    --argjson lat "$lat" \
    --argjson lon "$lon" \
    '{t:$t,id:$id,lat:$lat,lon:$lon}')
  echo "Posting parsed CSV as JSON to ${URL}"
  curl -s -X POST -H "Content-Type: application/json" -d "$json" "$URL" && echo "OK"
  exit 0
fi

echo "Could not parse file. Ensure it's JSON or CSV t,id,lat,lon."
exit 1
