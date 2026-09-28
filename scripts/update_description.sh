#!/system/bin/sh

# 写入模块描述
write_description() {
  local error
  if ! error=$(ksud module config set override.description "$1" 2>&1); then
    log_error "KernelSU 设置模块描述失败：$error" "KernelSU module description setting failed: $error"
  fi
}

# 按系统语言写入模块描述；用法：set_description <中文> <英文>
set_description() {
  if [[ "$LANGUAGE" == 'en' ]]; then
    write_description "$2"
  else
    write_description "$1"
  fi
}

# 用法：icon <配置值> <为 true 时的图标> <为 false 时的图标>
icon() {
  if [[ "$1" == 'true' ]]; then
    echo "$2"
  else
    echo "$3"
  fi
}

# 模块日志、防火墙规则开关以及 AdGuardHome 版本和 PID
status_description() {
  # 获取 AdGuardHome 版本信息，删除版本信息最后一个空格及之前的字符
  local agh_version
  agh_version=$("$AGH_BIN_FILE" --version 2>/dev/null)
  agh_version="${agh_version##* }"
  [[ "$agh_version" ]] || agh_version='Unknown'

  # 获取 AdGuardHome 的 PID
  local agh_pid
  agh_pid=$(get_agh_pid) || agh_pid='Stopped'

  echo "Log $(icon "$ENABLE_MODULE_LOG" ✅ 🚫) | Rules $(icon "$ENABLE_FIREWALL_RULES" ✅ 🚫) | AGH: $agh_version - PID: $agh_pid"
}

# 用法：firewall_description <名称> <转发 UDP> <转发 TCP> <目标端口> <拒绝 UDP> <拒绝 TCP>
firewall_description() {
  echo "$1: UDP $(icon "$2" ↩️ ➡️) TCP $(icon "$3" ↩️ ➡️) | ↪️ $4 | UDP $(icon "$5" 🚫 ➡️) TCP $(icon "$6" 🚫 ➡️)"
}

# 用法：update_description_with_flag <read_config|start_as|stop_as> [error_flag]
update_description_with_flag() {
  local invoked_by="$1"
  local error_flag="$2"

  case "$invoked_by" in
    read_config)
      set_description '❌：模块配置读取失败，请查看模块下的as.log' \
        '❌: Module configuration reading failed. Please check the as.log file under the module'
      ;;
    start_as)
      if [[ "$error_flag" == 'true' ]]; then
        set_description '❌：模块启动失败，请查看模块下的as.log' \
          '❌: The module failed to start. Please check the as.log file under the module'
        return
      fi

      write_description "$(status_description)
$(firewall_description 'Net 4' "$IPV4_REDIRECT_UDP_53" "$IPV4_REDIRECT_TCP_53" "$IPV4_TARGET_PORT" "$IPV4_REJECT_UDP_53" "$IPV4_REJECT_TCP_53")
$(firewall_description 'Net 6' "$IPV6_REDIRECT_UDP_53" "$IPV6_REDIRECT_TCP_53" "$IPV6_TARGET_PORT" "$IPV6_REJECT_UDP_53" "$IPV6_REJECT_TCP_53")"
      ;;
    stop_as)
      if [[ "$error_flag" == 'true' ]]; then
        set_description '❌：模块关闭过程中遇到错误，请查看模块下的as.log' \
          '❌: An error occurred during module shutdown. Please check the as.log file under the module'
        return
      fi

      write_description "$(status_description)"
      ;;
  esac
}
