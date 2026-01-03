#!/system/bin/sh

SCRIPTS_DIR=${0%/*}
MOD_DIR="$SCRIPTS_DIR/.."
AGH_DIR="$MOD_DIR/AGH"

AGH_PID_FILE="$AGH_DIR/AdGuardHome.pid"
AGH_BIN_FILE="$AGH_DIR/AdGuardHome"

. "$SCRIPTS_DIR/log.sh"
. "$SCRIPTS_DIR/tools.sh"

start_agh () {
  set_time_zone
  # 证书目录
  export SSL_CERT_DIR="/system/etc/security/cacerts/"

  log "正在启动AdGuardHome……" "Starting AdGuardHome..."
  su -g 3004 -c "$AGH_BIN_FILE -w $AGH_DIR -c AdGuardHome.yaml -l AdGuardHome.log --pidfile $AGH_PID_FILE &"

  # 等待 PID 文件出现，最多等 10 秒
  timeout=10
  while [ ! -f "$AGH_PID_FILE" ] && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
  done

  # PID 文件是否生成
  if [ ! -f "$AGH_PID_FILE" ]; then
    log "AdGuardHome启动失败：PID文件未生成，请查看日志" "AdGuardHome failed to start: PID file not created, check log"
    return 1
  fi

  # 读取 PID 并去除空白字符
  pid=$(cat "$AGH_PID_FILE" 2>/dev/null | tr -d ' \n\t\r')

  # 检查 PID 是否为空
  if [ -z "$pid" ]; then
    log "AdGuardHome启动失败：PID文件内容为空" "AdGuardHome failed to start: PID file is empty"
    rm -f "$AGH_PID_FILE"
    return 1
  fi

  # 检查 PID 是否只包含数字（POSIX 兼容方式）
  case "$pid" in
    ''|*[!0-9]*)
      log "AdGuardHome启动失败：PID文件内容无效（$pid）" "AdGuardHome failed to start: Invalid PID content ($pid)"
      rm -f "$AGH_PID_FILE"
      return 1
      ;;
  esac

  # 检查进程是否真实存在
  if kill -0 "$pid" 2>/dev/null; then
    log "AdGuardHome启动成功，PID=$pid" "AdGuardHome started successfully, PID=$pid"
    return 0
  else
    log "AdGuardHome启动失败：进程未运行（PID=$pid），请查看日志" "AdGuardHome failed to start: Process not running (PID=$pid), check log"
    rm -f "$AGH_PID_FILE"
    return 1
  fi
}

stop_agh () {
  log "正在停止AdGuardHome……" "Stopping AdGuardHome..."

  if [ ! -f "$AGH_PID_FILE" ]; then
    log "未找到PID文件，AdGuardHome可能未运行" "PID file not found, AdGuardHome may not be running"
    return 0
  fi

  # 读取 PID 并去除空白
  pid=$(cat "$AGH_PID_FILE" 2>/dev/null | tr -d ' \n\t\r')

  # PID 为空的情况
  if [ -z "$pid" ]; then
    log "PID文件内容为空，清理残留文件" "PID file is empty, cleaning up stale file"
    rm -f "$AGH_PID_FILE"
    return 0
  fi

  # 检查 PID 是否只包含数字
  case "$pid" in
    ''|*[!0-9]*)
      log "PID文件内容无效（$pid），无法正常停止，清理残留文件" "Invalid PID content ($pid), cleaning up stale file"
      rm -f "$AGH_PID_FILE"
      return 1
      ;;
  esac

  # 进程是否还在运行
  if kill -0 "$pid" 2>/dev/null; then
    log "发送终止信号给AdGuardHome (PID=$pid)" "Sending TERM signal to AdGuardHome (PID=$pid)"
    kill "$pid" 2>/dev/null

    # 最多等待 15 秒优雅退出
    timeout=15
    while kill -0 "$pid" 2>/dev/null && [ $timeout -gt 0 ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    # 若仍未退出，强制杀死
    if kill -0 "$pid" 2>/dev/null; then
      log "AdGuardHome未优雅退出，强制终止 (PID=$pid)" "AdGuardHome did not exit gracefully, forcing kill (PID=$pid)"
      kill -9 "$pid" 2>/dev/null
    fi

    log "AdGuardHome已停止" "AdGuardHome stopped"
  else
    log "PID文件存在但进程已不存在 (PID=$pid)，清理残留文件" "PID file exists but process gone (PID=$pid), cleaning up"
  fi

  # 确保 PID 文件被删除
  rm -f "$AGH_PID_FILE"
  return 0
}

case "$1" in
  start)
    start_agh
    ;;
  stop)
    stop_agh
    ;;
  *)
    log "用法：$0 {start|stop}" "Usage: $0 {start|stop}"
    ;;
esac