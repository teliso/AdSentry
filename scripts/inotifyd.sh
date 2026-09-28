#!/system/bin/sh

readonly SCRIPTS_DIR="${0%/*}"

readonly EVENTS="$1"
readonly MONITOR_DIR="$2"
readonly MONITOR_FILE="$3"

# 只处理 config.sh 的写入事件
[[ "$MONITOR_FILE" == 'config.sh' && "$EVENTS" == 'w' ]] || exit 0

# 重新写入模块配置
"$MONITOR_DIR/config.sh"

# 模块被禁用时不启动
[[ -f "$MONITOR_DIR/disable" ]] && exit 0

if [[ -f "$MONITOR_DIR/running" ]]; then
  "$SCRIPTS_DIR/ad_sentry.sh" restart
else
  "$SCRIPTS_DIR/ad_sentry.sh" start
fi
