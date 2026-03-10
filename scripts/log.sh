#!/system/bin/sh

readonly LOG_FILE="$MODULE_DIR/as.log"

log() {
  local message
  local timestamp

  # 输出到日志文件
  if [[ "$ENABLE_MODULE_LOG" == "true" ]]; then
    timestamp=$(date "+%Y/%m/%d %H:%M:%S")
	  [[ "$LANGUAGE" == "zh" ]] && message="[$timestamp $1]: $2" || message="[$timestamp $1]: $3"
    echo "$message" >> "$LOG_FILE"
    return
  fi

  # 如果遇到错误日志但是没有开启日志，强制输出错误日志到日志文件
  if [[ "$1" == "Error" ]]; then
    timestamp=$(date "+%Y/%m/%d %H:%M:%S")
	  [[ "$LANGUAGE" == "zh" ]] && message="[$timestamp $1]: $2" || message="[$timestamp $1]: $3"
    echo "$message" >> "$LOG_FILE"
  fi
}

log_info() {
  log "Info" "$1" "$2"
}

log_error() {
  log "Error" "$1" "$2"
}