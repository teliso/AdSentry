readonly SCRIPTS_DIR=${0%/*}
readonly LOG_FILE="$SCRIPTS_DIR/../ad_sentry.log"

readonly enable_log=$(ksud module config get enable_log)

# 默认中文
language="zh"

# 依次尝试系统语言属性
locale=$(getprop persist.sys.locale 2>/dev/null)
[ -z "$locale" ] && locale=$(getprop ro.product.locale 2>/dev/null)
[ -z "$locale" ] && locale=$(getprop persist.sys.language 2>/dev/null)

# 如果获取到的语言前两位是 zh，就切换为中文
if [ "${locale:0:2}" = "en" ]; then
    language="en"
fi

log() {
  local message
  
  # 在实时shell中输出
  [ "$language" = "zh" ] && message="[AS]: $1" || message="[AS]: $2"
  echo "$message"

  if [ "$enable_log" = true ]; then
    local timestamp=$(date "+%Y/%m/%d %H:%M:%S")
	  [ "$language" = "zh" ] && message="[$timestamp]: $1" || message="[$timestamp]: $2"
    echo "$message" >> "$LOG_FILE"
  fi
}