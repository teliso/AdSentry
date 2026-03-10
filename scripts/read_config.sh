#!/system/bin/sh

get_num_from_config() {
  local key="$1"
  local value
  if ! value=$(ksud module config get "$key" 2>&1); then
    # 读取配置失败时，value 应该会被赋值为 stderr
    log_error "KernelSU 读取配置项 $key 时出现错误：$value" "KernelSU encountered an error while reading configuration item $key: $value"
    return 1
  fi

  # 如果 value 为空，或者包含任何一个“非数字”字符
  if [[ -z "$value" || "$value" == *[!0-9]* ]]; then
    log_error "配置项 '$key' 对应的值无效" "Configuration item '$key' does not exist or is empty"
    return 1
  fi

  echo "$value"
}

get_bool_from_config() {
  local key="$1"
  local value
  if ! value=$(ksud module config get "$key" 2>&1); then
    # 读取配置失败时，value 应该会被赋值为 stderr
    log_error "KernelSU 读取配置项 $key 时出现错误：$value" "KernelSU encountered an error while reading configuration item $key: $value"
    return 1
  fi

  case "$value" in
    "true")  echo "true" ;;
    "false") echo "false" ;;
    *)
      log_error "错误：配置项 '$key' 必须是 \"true\" 或 \"false\"，实际得到：\"$value\"" "Error: Configuration item '$key' must be \"true\" or \"false\", but the actual value is \"$value\""
      return 1
      ;;
  esac
}

RETURN_CODE=0

# 一次性读取所有配置
ENABLE_MODULE_LOG=$(get_bool_from_config "enable_module_log") || RETURN_CODE=1;         readonly ENABLE_MODULE_LOG
ENABLE_FIREWALL_RULES=$(get_bool_from_config "enable_firewall_rules") || RETURN_CODE=1; readonly ENABLE_FIREWALL_RULES

IPV4_TARGET_PORT=$(get_num_from_config "ipv4_target_port") || RETURN_CODE=1;            readonly IPV4_TARGET_PORT
IPV6_TARGET_PORT=$(get_num_from_config "ipv6_target_port") || RETURN_CODE=1;            readonly IPV6_TARGET_PORT

WEB_PORT=$(get_num_from_config "web_port") || RETURN_CODE=1;                            readonly WEB_PORT
RUNNING_USER=$(get_num_from_config "running_user") || RETURN_CODE=1;                    readonly RUNNING_USER
RUNNING_GROUP=$(get_num_from_config "running_group") || RETURN_CODE=1;                  readonly RUNNING_GROUP

# IPv4
IPV4_RETURN_DST_LIST=$(ksud module config get "ipv4_return_dst_list") || RETURN_CODE=1; readonly IPV4_RETURN_DST_LIST

IPV4_REDIRECT_UDP_53=$(get_bool_from_config "ipv4_redirect_udp_53") || RETURN_CODE=1;   readonly IPV4_REDIRECT_UDP_53
IPV4_REDIRECT_TCP_53=$(get_bool_from_config "ipv4_redirect_tcp_53") || RETURN_CODE=1;   readonly IPV4_REDIRECT_TCP_53

IPV4_REJECT_UDP_53=$(get_bool_from_config "ipv4_reject_udp_53") || RETURN_CODE=1;       readonly IPV4_REJECT_UDP_53
IPV4_REJECT_TCP_53=$(get_bool_from_config "ipv4_reject_tcp_53") || RETURN_CODE=1;       readonly IPV4_REJECT_TCP_53

# ----
# IPv6
IPV6_RETURN_DST_LIST=$(ksud module config get "ipv6_return_dst_list") || RETURN_CODE=1; readonly IPV6_RETURN_DST_LIST

IPV6_REDIRECT_UDP_53=$(get_bool_from_config "ipv6_redirect_udp_53") || RETURN_CODE=1;   readonly IPV6_REDIRECT_UDP_53
IPV6_REDIRECT_TCP_53=$(get_bool_from_config "ipv6_redirect_tcp_53") || RETURN_CODE=1;   readonly IPV6_REDIRECT_TCP_53

IPV6_REJECT_UDP_53=$(get_bool_from_config "ipv6_reject_udp_53") || RETURN_CODE=1;       readonly IPV6_REJECT_UDP_53
IPV6_REJECT_TCP_53=$(get_bool_from_config "ipv6_reject_tcp_53") || RETURN_CODE=1;       readonly IPV6_REJECT_TCP_53

return $RETURN_CODE