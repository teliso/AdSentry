#!/system/bin/sh

. /data/adb/modules/AdSentry/settings.conf

MODDIR=${0%/*}
language="zh"

# 获取系统语言
locale=$(getprop persist.sys.locale)
[ -z "$locale" ] && locale=$(getprop ro.product.locale)
[ -z "$locale" ] && locale=$(getprop persist.sys.language)

# 如果获取到的系统语言不是zh，就设置为en
if ! echo "$locale" | grep -qi "zh"; then
  language="en"
fi

log() {
  local LOG_FILE="$MODDIR/ad_sentry.log"
  local message
  
  [ "$language" = "zh" ] && message="[AS]: $1" || message="[AS]: $2"
  echo "$message"
  
  if [ "$enable_log" = true ]; then
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	[ "$language" = "zh" ] && message="[$timestamp]: $1" || message="[$timestamp]: $2"
    echo "$message" >> "$LOG_FILE"
  fi
}

update_description() {
  local PROP_FILE="$MODDIR/module.prop"
  local description
  
  [ "$language" = "zh" ] && description="$1" || description="$2"
  sed -i "/^description=/c\description=$description" "$PROP_FILE"
}