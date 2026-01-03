#!/system/bin/sh

MOD_DIR=${0%/*}
SCRIPTS_DIR="${0%/*}/scripts"

# 重启后进行配置初始化
if [ ! -e "$MOD_DIR/initialized" ]; then
  "$MOD_DIR/config.sh"
  # 初始化以后创建已初始化标志，下次重启不进行重复操作
  touch "$MOD_DIR/initialized"
fi

# 启动AdSentry
"$SCRIPTS_DIR/ad_sentry.sh" start

# 根据模块是否禁用停止AdSentry
# 只监听需要的文件
inotifyd "$SCRIPTS_DIR/inotifyd.sh" "$MOD_DIR":ndw &