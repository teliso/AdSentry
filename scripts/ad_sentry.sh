#!/system/bin/sh

SCRIPTS_DIR=${0%/*}

. "$SCRIPTS_DIR/tools.sh"
. "$SCRIPTS_DIR/log.sh"

MOD_DIR="$SCRIPTS_DIR/.."
AGH_DIR="$MOD_DIR/AGH"

AGH_PID_FILE="$AGH_DIR/AdGuardHome.pid"

readonly drop_ipv6_dns=$(ksud module config get drop_ipv6_dns)

start_ad_sentry() {
  log "正在启动AdSentry……" "Starting AdSentry..."
  
  "$SCRIPTS_DIR/agh.sh" start
  "$SCRIPTS_DIR/firewall.sh" add
  
  local message_zh="☺AdSentry-PID：$(cat "$AGH_PID_FILE")"
  local message_en="$message_zh"
  
  if [ "$drop_ipv6_dns" = true ]; then
    "$SCRIPTS_DIR/firewall.sh" add_drop
    message_zh="$message_zh|☺️已丢弃IPv6 DNS请求"
	  message_en="$message_en|☺Dropped IPv6 DNS requests"
  else
    message_zh="$message_zh|😒️放行IPv6 DNS请求"
	  message_en="$message_en|😒Allow IPv6 DNS requests"
  fi
  
  log "AdSentry启动成功" "AdSentry started successfully"
  
  # 更新模块的描述
  update_description "$message_zh" "$message_en"
}

restart_ad_sentry() {
  log "正在执行重启清理……" "Performing reboot cleanup..."

  "$SCRIPTS_DIR/agh.sh" stop
  "$SCRIPTS_DIR/firewall.sh" remove
  "$SCRIPTS_DIR/firewall.sh" remove_drop

  start_ad_sentry

  log "重启完成" "Restart completed"
}

stop_ad_sentry() {
  log "正在停止AdSentry……" "Stopping AdSentry..."
    
  "$SCRIPTS_DIR/agh.sh" stop
  "$SCRIPTS_DIR/firewall.sh" remove
  "$SCRIPTS_DIR/firewall.sh" remove_drop

  # 输出总提示
  log "AdSentry停止成功" "AdSentry stopped successfully"

  # 更新模块描述
  update_description "😒AdSentry已停止️|😒iptables已停止" "😒AdSentry has stopped|😒iptables has stopped"
}

# 模块的切换操作对应action.sh
toggle_ad_sentry() {
  local ADGUARDHOME_PID=""
  
  # 1. 读取PID文件（如果存在）
  if [ -f "$AGH_PID_FILE" ]; then
    local stored_pid=$(cat "$pid_file" 2>/dev/null)
    
    # 2. 验证PID是否有效
    if [ -n "$stored_pid" ] && kill -0 "$stored_pid" 2>/dev/null; then
      ADGUARDHOME_PID="$stored_pid"
    else
      # PID文件存在但进程已死，清理无效PID文件
      rm -f "$AGH_PID_FILE"
    fi
  fi
  
  # 4. 根据PID状态执行操作
  if [ -n "$ADGUARDHOME_PID" ]; then
    log "检测到AdGuardHome正在运行(PID: $ADGUARDHOME_PID)，执行停止操作…" \
        "AdGuardHome detected running (PID: $ADGUARDHOME_PID), stopping..."
    stop_ad_sentry
  else
    log "未检测到AdGuardHome运行，执行启动操作…" \
        "AdGuardHome not running, starting..."
    start_ad_sentry
  fi
}

case "$1" in
  start)
    start_ad_sentry
    ;;
  restart)
    restart_ad_sentry
    ;;
  stop)
    stop_ad_sentry
    ;;
  toggle)
    toggle_ad_sentry
    ;;
  *)
    log "用法：$0 {start|restart|stop|toggle}" "Usage: $0 {start|restart|stop|toggle}"
    ;;
esac