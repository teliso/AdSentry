#!/system/bin/sh

readonly MODULE_DIR="${0%/*}"
export MODULE_DIR
SCRIPTS_DIR="$MODULE_DIR/scripts"
readonly SCRIPTS_DIR

# 重启后进行配置初始化
if [[ ! -f "$MODULE_DIR/initialized" ]]; then
  "$MODULE_DIR/config.sh"
  # 初始化以后创建已初始化标志，下次重启不进行重复操作
  : > "$MODULE_DIR/initialized"
fi

# 启动 AdSentry
"$SCRIPTS_DIR/ad_sentry.sh" start

# 监听模块目录
inotifyd "$SCRIPTS_DIR/inotifyd.sh" "$MODULE_DIR":w &