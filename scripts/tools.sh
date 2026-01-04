update_description() {
  local description

  [ "$language" = "zh" ] && description="$1" || description="$2"
  ksud module config set override.description "$description"
}

# 导出时区
set_time_zone() {
  # 首先尝试系统时区
  local sys_tz=$(getprop persist.sys.timezone 2>/dev/null)
  if [ -n "$sys_tz" ]; then
    export TZ="$sys_tz"
    log "使用系统时区：$sys_tz-当前时间：$(date '+%F %T')" "Using system TZ: $sys_tz-Current time: $(date '+%F %T')"
    return
  fi

  # 如果系统时区不可用，回退到 UTC
  export TZ="UTC"
  log "模块配置和系统时区均不可用，回退到 UTC-当前时间：$(date '+%F %T')" \
  "Configured and system TZ unavailable, fallback to UTC-Current time: $(date '+%F %T')"
}