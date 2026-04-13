#!/system/bin/sh

set_description() {
  local description="$1"

  [[ "$LANGUAGE" == 'en' ]] && description="$2"
  
  if ! error=$(ksud module config set override.description "$description" 2>&1); then
    log_error "KernelSU 设置模块描述失败：$error" "KernelSU module description setting failed: $error"
  fi
}

update_description_with_flag() {
  local invoked_by="$1"
  # 读取模块配置时是否出现问题
  if [[ "$invoked_by" == 'read_config' ]]; then
    set_description '❌：模块配置读取失败，请查看模块下的as.log' \
      '❌: Module configuration reading failed. Please check the as.log file under the module'
    return
  fi

  # 启动 AdSentry 时是否出现问题
  if [[ "$invoked_by" == 'start_as' ]]; then
    if [[ "$error_flag" == 'true' ]]; then
      set_description '❌：模块启动失败，请查看模块下的as.log' \
        '❌: The module failed to start. Please check the as.log file under the module'
      return
    else
      update_description
      update_firewall_description
    fi
  fi

  # 关闭 AdSentry 时是否出现问题
  if [[ "$invoked_by" == 'stop_as' ]]; then
    if [[ "$error_flag" == 'true' ]]; then
      set_description '❌：模块关闭过程中遇到错误，请查看模块下的as.log' \
        '❌: If an error occurs during module shutdown, please check the as.log file in the module directory'
        return
    else
      update_description
    fi
  fi
}

update_description() {
  # 更新日志状态
  local description='Log'

  if [[ "$ENABLE_MODULE_LOG" == 'true' ]]; then
    description="$description ✅"
  else
    description="$description 🚫"
  fi

  description="$description | Rules"

  if [[ "$ENABLE_FIREWALL_RULES" == 'true' ]]; then
    description="$description ✅"
  else
    description="$description 🚫"
  fi

  # 获取 AdGuardHome 版本信息
  local agh_version='Unknown'
  local raw_agh_version
  raw_agh_version=$("$AGH_BIN_FILE" --version 2>/dev/null)
  if [[ "$raw_agh_version" ]]; then
    # 删除版本信息最后一个空格及之前的字符然后输出
    agh_version="${raw_agh_version##* }"
  fi
  
  # 获取 AdGuardHome 的PID
  local agh_pid
  agh_pid=$(get_agh_pid) || agh_pid='Stopped'

  description="$description | AGH: $agh_version - PID: $agh_pid"

  local error
  if ! error=$(ksud module config set override.description "$description" 2>&1); then
    log_error "KernelSU 设置模块描述失败：$error" "KernelSU module description setting failed: $error"
  fi
}

update_firewall_description() {
  local description

  if ! description=$(ksud module config get override.description 2>&1); then
    log_error "KernelSU 设置模块描述失败：$description" "KernelSU module description setting failed: $description"
  fi

  # IPv4 描述
  local description_ipv4='Net 4:'
  
  if [[ "$IPV4_REDIRECT_UDP_53" == 'true' ]]; then
    description_ipv4="$description_ipv4 UDP ↩️"
  else
    description_ipv4="$description_ipv4 UDP ➡️"
  fi

  if [[ "$IPV4_REDIRECT_TCP_53" == 'true' ]]; then
    description_ipv4="$description_ipv4 TCP ↩️"
  else
    description_ipv4="$description_ipv4 TCP ➡️"
  fi

  description_ipv4="$description_ipv4 | ↪️ $IPV4_TARGET_PORT |"

  if [[ "$IPV4_REJECT_UDP_53" == 'true' ]]; then
    description_ipv4="$description_ipv4 UDP 🚫"
  else
    description_ipv4="$description_ipv4 UDP ➡️"
  fi
  
  if [[ "$IPV4_REJECT_TCP_53" == 'true' ]]; then
    description_ipv4="$description_ipv4 TCP 🚫"
  else
    description_ipv4="$description_ipv4 TCP ➡️"
  fi
  
  # IPv6 描述
  local description_ipv6='Net 6:'

  if [[ "$IPV6_REDIRECT_UDP_53" == 'true' ]]; then
    description_ipv6="$description_ipv6 UDP ↩️"
  else
    description_ipv6="$description_ipv6 UDP ➡️"
  fi

  if [[ "$IPV6_REDIRECT_TCP_53" == 'true' ]]; then
    description_ipv6="$description_ipv6 TCP ↩️"
  else
    description_ipv6="$description_ipv6 TCP ➡️"
  fi

  description_ipv6="$description_ipv6 | ↪️ $IPV6_TARGET_PORT |"

  if [[ "$IPV6_REJECT_UDP_53" == 'true' ]]; then
    description_ipv6="$description_ipv6 UDP 🚫"
  else
    description_ipv6="$description_ipv6 UDP ➡️"
  fi
  
  if [[ "$IPV6_REJECT_TCP_53" == 'true' ]]; then
    description_ipv6="$description_ipv6 TCP 🚫"
  else
    description_ipv6="$description_ipv6 TCP ➡️"
  fi

  description=$(printf '%s\n%s\n%s' "$description" "$description_ipv4" "$description_ipv6")

  local error
  if ! error=$(ksud module config set override.description "$description" 2>&1); then
    log_error "KernelSU 设置模块描述失败：$error" "KernelSU module description setting failed: $error"
  fi
}