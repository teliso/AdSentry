readonly target_time_zone=$(ksud module config get time_zone)

update_description() {
  local description

  [ "$language" = "zh" ] && description="$1" || description="$2"
  ksud module config set override.description "$description"
}

# 导出时区
set_time_zone() {
  # 尝试模块配置时区
  if [ -n "$target_time_zone" ]; then
    export TZ="$target_time_zone"
    # 检查 date 是否能正确显示时间
    if date '+%F %T' >/dev/null 2>&1; then
      log "使用模块配置时区：$target_time_zone-当前时间：$(date '+%F %T')" "Using configured TZ: $target_time_zone-Current time: $(date '+%F %T')"
      return
    else
      log "模块配置时区无效，尝试系统时区" "Configured TZ invalid, try system TZ"
    fi
  fi

  # 尝试系统时区
  local sys_tz=$(getprop persist.sys.timezone 2>/dev/null)
  if [ -n "$sys_tz" ]; then
    export TZ="$sys_tz"
    log "使用系统时区：$sys_tz-当前时间：$(date '+%F %T')" "Using system TZ: $sys_tz-Current time: $(date '+%F %T')"
    return
  fi

  # 系统时区也不可用，回退到 UTC
  export TZ="UTC"
  log "模块配置和系统时区均不可用，回退到 UTC-当前时间：$(date '+%F %T')" \
  "Configured and system TZ unavailable, fallback to UTC-Current time: $(date '+%F %T')"
}