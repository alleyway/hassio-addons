#!/bin/bash
# Poll Vere's loopback interface and save the Landscape login code.
# Started in the background by /run.sh. Never print the code unless asked.

set -eu

log_code="${1:-false}"

for _ in $(seq 1 1440); do
  code=$(/bin/get_urbit_code 2>/dev/null || true)
  code=$(printf '%s' "$code" | tr -d '[:space:]~%"%')
  # Four lowercase words. Avoid grep interval syntax; BusyBox is picky.
  if printf '%s' "$code" | grep -Eq '^[a-z]+-[a-z]+-[a-z]+-[a-z]+$'; then
    if [ -d /config ] && [ -w /config ]; then
      umask 077
      printf '%s\n' "$code" > /config/login-code.txt
      printf '%s\n' "[urbit] Landscape login code written to the app config folder as login-code.txt"
    else
      printf '%s\n' "[urbit] Landscape login code is ready, but the app config folder is not writable"
      log_code=true
    fi
    if [ "$log_code" = "true" ]; then
      printf '%s\n' "[urbit] Landscape login code: ${code}"
    fi
    exit 0
  fi
  sleep 5
done

printf '%s\n' "[urbit] Login code was not ready after two hours. Once the ship is live, /bin/get_urbit_code reads it from the loopback port."
