#!/system/bin/sh

. /data/adb/modules/AdSentry/settings.conf
MODDIR=${0%/*}
. "$MODDIR/scripts/output.sh"

# AdGuard Home进程文件
PID_FILE="$MODDIR/bin/AdGuardHome.pid"
AGH_DIR="$MODDIR/bin"
AGH_BIN="$AGH_DIR/AdGuardHome"

start_ad_sentry() {
  set_timezone
  # 证书目录
  export SSL_CERT_DIR="/system/etc/security/cacerts/"
  
  log "正在启动AdSentry……" "Starting AdSentry..."
  
  # 判断AdGuard Home是否已经在运行
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "AdGuardHome已经在运行，退出AdSentry启动过程" "AdGuardHome is already running, exit AdSentry startup process"
    return
  fi
  
  # 使用busybox启动AdGuard Home
  log "正在启动AdGuardHome……" "Starting AdGuardHome..."
  busybox setuidgid "$agh_uid:$agh_gid" "$AGH_BIN" --no-check-update -c "$AGH_DIR/AdGuardHome.yaml" -l "$AGH_DIR/AdGuardHome.log" --pidfile "$PID_FILE" &
  sleep 1
  
  # 检查AdGuard Home是否启动成功
  if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "AdGuardHome启动成功，PID=$(cat "$PID_FILE")" "AdGuardHome started successfully, PID=$(cat "$PID_FILE")"
  else
    log "AdGuardHome启动失败，查看日志获取详细信息：$AGH_DIR/ad_sentry.log"
    return
  fi
  
  # 如果启用iptables规则
  if [ "$enable_iptables" = true ]; then
    $MODDIR/scripts/iptables.sh add
  else
    log "未启用iptables" "iptables is not enabled"
  fi
  
  local message_zh="☺AdSentry-PID：$(cat "$PID_FILE")"
  local message_en="$message_zh"
  
  if [ "$block_ipv6_dns" = true ]; then
    message_zh="$message_zh|☺️已丢弃IPv6 DNS请求"
	message_en="$message_en|☺Dropped IPv6 DNS requests"
  else
    message_zh="$message_zh|😒️放行IPv6 DNS请求"
	message_en="$message_en|😒Allow IPv6 DNS requests"
  fi
  
  log "AdSentry启动成功" "AdSentry started successfully"
  
  # 更新模块的描述
  update_description $message_zh $message_en
}

# 导出时区
set_time_zone() {
  # 尝试获取 Android 系统时区
  local sys_tz=$(getprop persist.sys.timezone 2>/dev/null)
  
  # 判断系统时区是否可用
  if [ -n "$sys_tz" ]; then
    export TZ="$sys_tz"
	log "时区：$sys_tz-当前时间：$(date '+%F %T')" "Time zone: $sys_tz-Current time: $(date '+%F %T')"
  elif [ -n "$time_zone" ]; then
    # 使用配置文件中的时区
	export TZ="$time_zone"
	log "时区：$time_zone-当前时间：$(date '+%F %T')" "Time zone: $time_zone-Current time: $(date '+%F %T')"
  else
    # 回退到UTC
    export TZ="UTC"
	log "回退时区：UTC-当前时间：$(date '+%F %T')" "Fallback time zone: UTC-Current time: $(date '+%F %T')"
  fi
}

stop_ad_sentry() {
  log "正在停止AdSentry……" "Stopping AdSentry..."

  # 如果存在正在运行的AdGuardHome进程
  if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
	# 如果进程文件中的PID有效
    if kill -0 "$pid" 2>/dev/null; then
      log "正在停止AdGuardHome……" "Stopping AdGuardHome..."
      kill "$pid"
      sleep 1
	  # 强制停止
      if kill -0 "$pid" 2>/dev/null; then
        log "正在强制停止AdGuardHome……" "Forcing stop AdGuardHome..."
        kill -9 "$pid"
      fi
	  log "AdGuardHome已停止" "AdGuardHome has stopped"
    else
      log "AdGuardHome进程文件存在但没有进程在运行" "The AdGuardHome process file exists but no process is running"
    fi
	
	log "正在移除AdGuardHome进程文件……" "Removing AdGuardHome process files..."
	# 移除进程文件，方便判断维护
    rm -f "$PID_FILE"
	log "AdGuardHome进程文件移除完成" "AdGuardHome process files removed"
	
  # 当没有进程文件时，尝试使用AdGuard Home的PID停止，可能不会遇到这种情况
  else
    log "未发现AdGuardHome进程文件，尝试使用PID停止……" "AdGuardHome process file not found, try to stop it using PID..."
	# 根据二进制文件路径获取进程信息
    pid=$(pgrep -f "$AGH_BIN")
	# 获取成功后使用PID进行停止
    if [ -n "$pid" ]; then
      log "正在停止AdGuardHome进程……" "Stopping AdGuardHome process..."
      kill "$pid"
      sleep 1
	  # 强制停止
      if kill -0 "$pid" 2>/dev/null; then
	    log "正在强制停止AdGuardHome……" "Forcing stop AdGuardHome..."
        kill -9 "$pid"
      fi
	  log "AdGuardHome已停止" "AdGuardHome has stopped"
    else
      log "没有AdGuardHome进程在运行" "No AdGuardHome process is running"
    fi
  fi
  # 执行停止操作以后移除iptables规则
  $MODIR/scritps/iptables.sh remove
  # 输出总提示
  log "AdSentry停止成功" "AdSentry stopped successfully"
  
  # 更新模块描述
  update_description "😒AdSentry已停止️|😒iptables已停止" "😒AdSentry has stopped|😒iptables has stopped"
}

# 模块的切换操作对应action.sh
toggle_ad_sentry() {
  # 进程文件存在且存在进程
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    stop_ad_sentry
  else
    start_ad_sentry
  fi
}

case "$1" in
  start)
    start_ad_sentry
    ;;
  stop)
    stop_ad_sentry
    ;;
  toggle)
    toggle_ad_sentry
    ;;
  *)
    log "用法：$0 {start|stop|toggle}" "Usage: $0 {start|stop|toggle}"
    ;;
esac