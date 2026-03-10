#!/system/bin/sh

SCRIPTS_DIR=${0%/*}

readonly EVENTS="$1"
readonly MONITOR_DIR="$2"
readonly MONITOR_FILE="$3"

process_w_event() {
  [[ -f "$MONITOR_DIR/disable" ]] && return
    
  if [[ -f "$MONITOR_DIR/runing" ]]; then
    "$SCRIPTS_DIR/ad_sentry.sh" restart
  else
    "$SCRIPTS_DIR/ad_sentry.sh" start
  fi
}

if [[ "$MONITOR_FILE" == "config.sh" ]]; then
  if [[ "$EVENTS" == "w" ]]; then
    "$MONITOR_DIR/config.sh"
    process_w_event
  fi
fi