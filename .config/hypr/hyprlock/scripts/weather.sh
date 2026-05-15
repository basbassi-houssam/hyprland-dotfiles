#!/bin/bash

cache_file="$HOME/.cache/wttr_cache.txt"

if [ ! -f "$cache_file" ]; then
  mkdir -p "$(dirname "$cache_file")" # Create .cache directory if it doesn't exist
  touch "$cache_file"
fi

last_modified=$(stat -c %Y "$cache_file" 2>/dev/null)
current_date=$(date +%s)
time_diff=$((current_date - last_modified))
expiry_time=86400
cached_data=$(<"$cache_file")

if [ $time_diff -lt $expiry_time ] && [ -n "$cached_data" ]; then
  echo "$cached_data"
  exit
fi

# Fixed curl command - added quotes around the URL and a location (using :%2B for +)
response=$(curl -s "wttr.in?format=%c+%C+%t" 2>/dev/null)

# Check if we got a valid response
if [ -z "$response" ]; then
  # Try with a default location (e.g., your city or just use local)
  response=$(curl -s "wttr.in/London?format=%c+%C+%t" 2>/dev/null)
fi

# Only cache if we got a non-empty response
if [ -n "$response" ]; then
  echo "$response" >"$cache_file"
  echo "$response"
else
  echo "Error: Could not fetch weather data"
  # Return cached data if available, even if expired
  if [ -n "$cached_data" ]; then
    echo "$cached_data"
  fi
  exit 1
fi
