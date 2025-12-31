#!/system/bin/sh

MODDIR=${0%/*}

readonly EVENTS=$1
readonly MONITOR_DIR=$2
readonly MONITOR_FILE=$3

if [ "${MONITOR_FILE}" = "disable" ]; then
  if [ "${EVENTS}" = "d" ]; then
    $MODDIR/scritps/ad_sentry.sh start
  elif [ "${EVENTS}" = "n" ]; then
    $MODDIR/scripts/ad_sentry.sh stop
  fi
fi