#!/system/bin/sh

readonly LOG_FILE="$MODULE_DIR/as.log"

# 用法：log <级别> <中文信息> <英文信息>
log() {
  # 未开启日志时，只强制输出错误日志到日志文件
  [[ "$ENABLE_MODULE_LOG" != 'true' && "$1" != 'Error' ]] && return

  local message="$2"
  [[ "$LANGUAGE" == 'zh' ]] || message="$3"

  echo "[$(date '+%Y/%m/%d %H:%M:%S') $1]: $message" >> "$LOG_FILE"
}

log_info() {
  log 'Info' "$1" "$2"
}

log_error() {
  log 'Error' "$1" "$2"
}
