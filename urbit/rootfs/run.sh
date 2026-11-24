#!/bin/bash
# Stage a pier for the official Vere image, then exec its entrypoint.
# /bin/start_urbit boots from a .key, a .comet, or the first pier directory
# in the working directory. Arguments must use the --name=value form.

set -eu

# Container ports declared in config.yaml. The host port for 34343/udp must
# stay 34343 if Ames is to make direct connections.
AMES_PORT=34343
HTTP_PORT=80

log() {
  printf '%s\n' "[urbit] $*"
}

fatal() {
  printf '%s\n' "[urbit] $*" >&2
  exit 1
}

bool_opt() {
  # jq's // treats false as missing, so do not use it for booleans.
  jq -r --arg key "$1" --argjson fallback "$2" \
    'if has($key) then .[$key] else $fallback end' "$OPTIONS"
}

if [ -f /urbit/options.json ]; then
  OPTIONS=/urbit/options.json
  PIER_ROOT=/urbit
elif [ -f /data/options.json ]; then
  OPTIONS=/data/options.json
  PIER_ROOT=/data
else
  fatal "options.json not found in /urbit or /data"
fi

LOOM="$(jq -r '.loom // 31' "$OPTIONS")"
SNAP_TIME="$(jq -r '.snap_time // 2' "$OPTIONS")"
COMET_NAME="$(jq -r '.comet_name // "comet"' "$OPTIONS")"
LOG_LEVEL="$(jq -r '.log_level // "info"' "$OPTIONS")"
BOOT_COMET="$(bool_opt boot_comet false)"
LOG_CODE="$(bool_opt log_code false)"
REMOVE_KEYFILE="$(bool_opt remove_keyfile true)"

case "$LOOM" in
  ''|*[!0-9]*) fatal "loom must be an integer" ;;
esac
case "$SNAP_TIME" in
  ''|*[!0-9]*) fatal "snap_time must be an integer" ;;
esac
case "$COMET_NAME" in
  ''|*[^a-z0-9-]*) fatal "comet_name must be lowercase letters, digits, and hyphens" ;;
  -*) fatal "comet_name must not start with a hyphen" ;;
esac

debug() {
  case "$LOG_LEVEL" in
    trace|debug) log "$*" ;;
  esac
}

# Directories that contain a pier (.urb). Skips dot-directories.
list_piers() {
  local root="$1"
  local dir
  [ -d "$root" ] || return 0
  for dir in "$root"/*/; do
    [ -d "$dir" ] || continue
    case "$(basename "$dir")" in
      .*) continue ;;
    esac
    if [ -d "${dir%/}/.urb" ]; then
      printf '%s\n' "${dir%/}"
    fi
  done
  return 0
}

cd "$PIER_ROOT"
rm -rf "$PIER_ROOT"/.import-*
rm -f /config/login-code.txt

mapfile -t piers < <(list_piers "$PIER_ROOT")
if [ "${#piers[@]}" -gt 1 ]; then
  fatal "More than one pier in ${PIER_ROOT}. This add-on runs one ship."
fi

pier=""
if [ "${#piers[@]}" -eq 1 ]; then
  pier="$(basename "${piers[0]}")"
  log "Found pier ${pier}"
fi

if [ -z "$pier" ] && [ -d /share/urbit ]; then
  mapfile -t shared < <(list_piers /share/urbit)
  if [ "${#shared[@]}" -gt 1 ]; then
    fatal "More than one pier in /share/urbit. Leave only the ship to import."
  fi
  if [ "${#shared[@]}" -eq 1 ]; then
    name="$(basename "${shared[0]}")"
    log "Importing pier ${name} from /share/urbit/${name}"
    log "Delete /share/urbit/${name} after the ship is up. A second copy must not be booted."
    rm -rf "${PIER_ROOT}/.import-${name}"
    cp -a "${shared[0]}" "${PIER_ROOT}/.import-${name}"
    mv "${PIER_ROOT}/.import-${name}" "${PIER_ROOT}/${name}"
    pier="$name"
  fi
fi

shopt -s nullglob
staged_keys=("$PIER_ROOT"/*.key)
config_keys=(/config/*.key)
share_keys=(/share/urbit/*.key)
shopt -u nullglob

if [ -z "$pier" ]; then
  key=""
  if [ "${#staged_keys[@]}" -gt 0 ]; then
    key="${staged_keys[0]}"
    [ "${#staged_keys[@]}" -eq 1 ] || log "Warning: more than one keyfile in ${PIER_ROOT}; using $(basename "$key")"
  elif [ "${#config_keys[@]}" -gt 0 ]; then
    key="${config_keys[0]}"
    [ "${#config_keys[@]}" -eq 1 ] || log "Warning: more than one keyfile in the app config folder; using $(basename "$key")"
  elif [ "${#share_keys[@]}" -gt 0 ]; then
    key="${share_keys[0]}"
    [ "${#share_keys[@]}" -eq 1 ] || log "Warning: more than one keyfile in /share/urbit; using $(basename "$key")"
  fi

  if [ -n "$key" ]; then
    base="$(basename "$key")"
    if [ "$key" != "${PIER_ROOT}/${base}" ]; then
      log "Staging keyfile ${base}"
      cp -f "$key" "${PIER_ROOT}/${base}"
      chmod 600 "${PIER_ROOT}/${base}"
    else
      chmod 600 "$key" || true
    fi
    debug "Booting from ${base}"
  elif [ "$BOOT_COMET" = "true" ]; then
    if [ ! -e "${PIER_ROOT}/${COMET_NAME}.comet" ]; then
      log "Creating comet boot file ${COMET_NAME}.comet"
      : > "${PIER_ROOT}/${COMET_NAME}.comet"
    fi
  else
    log "No pier found. Put <ship>.key in the app config folder or /share/urbit/, or enable boot_comet."
    log "Waiting. A keyfile or boot_comet change is picked up within a minute; restarting also works."
    while true; do
      sleep 30
      if [ -f "$OPTIONS" ]; then
        BOOT_COMET="$(bool_opt boot_comet false)"
      fi
      shopt -s nullglob
      appeared=("$PIER_ROOT"/*.key /config/*.key /share/urbit/*.key)
      shopt -u nullglob
      mapfile -t shared_now < <(list_piers /share/urbit)
      mapfile -t local_now < <(list_piers "$PIER_ROOT")
      if [ "${#appeared[@]}" -gt 0 ] || [ "${#shared_now[@]}" -gt 0 ] || [ "${#local_now[@]}" -gt 0 ] || [ "$BOOT_COMET" = "true" ]; then
        log "Ship material appeared. Starting."
        exec /bin/bash /run.sh
      fi
    done
  fi
else
  # start_urbit prefers a keyfile or comet over an existing pier.
  rm -f "$PIER_ROOT"/*.key "$PIER_ROOT"/*.comet
  if [ "$REMOVE_KEYFILE" = "true" ] && [ -f "/config/${pier}.key" ]; then
    log "Removing ${pier}.key from the app config folder"
    rm -f "/config/${pier}.key"
  fi
  if [ -f "/share/urbit/${pier}.key" ]; then
    log "A keyfile is still at /share/urbit/${pier}.key. Delete it yourself; that folder is mounted read-only."
  fi
fi

if [ "$LOOM" -lt 31 ]; then
  log "Warning: loom ${LOOM} is below the 2 GiB default. The ship may run out of memory."
elif [ "$LOOM" -gt 31 ]; then
  log "Loom ${LOOM} needs $((1 << (LOOM - 30))) GiB free. If the pier grows into it, later boots need the same size."
fi

log "Starting Vere (Ames UDP ${AMES_PORT}, HTTP ${HTTP_PORT}, loom 2^${LOOM}, snapshot every ${SNAP_TIME} min)"
log "Do not run this ship anywhere else while this add-on is running."

if [ -w /proc/1/fd/1 ]; then
  # nohup so the watcher survives exec. docker-init reaps it when it exits.
  nohup /bin/bash /code-watcher.sh "$LOG_CODE" >/proc/1/fd/1 2>/proc/1/fd/2 &
  disown || true
else
  log "Login-code watcher not started; container log is not writable"
fi

cd "$PIER_ROOT"
if [ -n "$pier" ]; then
  # Call Vere directly. start_urbit would pick the first directory, which is
  # wrong if anything other than the pier is ever created next to it.
  exec /bin/urbit -t \
    -p "$AMES_PORT" \
    --http-port "$HTTP_PORT" \
    --loom "$LOOM" \
    --snap-time "$SNAP_TIME" \
    "${PIER_ROOT}/${pier}"
fi

exec /bin/start_urbit \
  --port="${AMES_PORT}" \
  --http-port="${HTTP_PORT}" \
  --loom="${LOOM}" \
  --snap-time="${SNAP_TIME}"
