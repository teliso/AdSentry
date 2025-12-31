#!/system/bin/sh

. /data/adb/modules/AdSentry/settings.conf

CURRENT_DIR=${0%/*}

$CURRENT_DIR/scripts/ad_sentry.sh start

# 根据模块是否禁用停止AdSentry
inotifyd "$CURRENT_DIR/scripts/inotify.sh" $CURRENT_DIR:nd &