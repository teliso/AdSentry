#!/system/bin/sh

SCRIPTS_DIR=${0%/*}

readonly EVENTS=$1
readonly MONITOR_DIR=$2
readonly MONITOR_FILE=$3

if [ "${MONITOR_FILE}" = "disable" ]; then
  if [ "${EVENTS}" = "d" ]; then
    "$SCRIPTS_DIR/ad_sentry.sh" start
  elif [ "${EVENTS}" = "n" ]; then
    "$SCRIPTS_DIR/ad_sentry.sh" stop
  fi
fi

if [ "${MONITOR_FILE}" = "config.sh" ]; then
  if [ "${EVENTS}" = "w" ]; then
    "$MONITOR_DIR/config.sh"
    "$SCRIPTS_DIR/ad_sentry.sh" restart
  fi
fi