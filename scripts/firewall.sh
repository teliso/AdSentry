#!/system/bin/sh

readonly AS_NAT_CHAIN_NAME='AS_RED'
readonly AS_FILTER_CHAIN_NAME='AS_REJ'

# 生成 iptables-restore / ip6tables-restore 使用的规则文本
generate_restore_config() {
  local support_nat="$1"
  local return_dst_list="$2"
  local redirect_udp_53="$3"
  local redirect_tcp_53="$4"
  local target_port="$5"
  local reject_udp_53="$6"
  local reject_tcp_53="$7"

  # --- NAT 表 ---
  # 只有在启用某一条转发规则以后，才需要设置 NAT 规则
  if [[ "$support_nat" == 'true' ]] && [[ "$redirect_udp_53" == 'true' || "$redirect_tcp_53" == 'true' ]]; then
    echo '*nat'
    echo ":$AS_NAT_CHAIN_NAME - [0:0]"
    echo "-F $AS_NAT_CHAIN_NAME"
    # 排除自身流量
    echo "-A $AS_NAT_CHAIN_NAME -m owner --uid-owner $RUNNING_USER --gid-owner $RUNNING_GROUP -j RETURN"

    # 处理忽略列表
    local dst
    for dst in $return_dst_list; do
      echo "-A $AS_NAT_CHAIN_NAME -d $dst -j RETURN"
    done

    # 进入的流量只有 UDP 53 或者 TCP 53，但是为了配合 REDIRECT 的要求，还是指定一个用于转发的匹配规则
    [[ "$redirect_udp_53" == 'true' ]] && echo "-A $AS_NAT_CHAIN_NAME -p udp -j REDIRECT --to-ports $target_port"
    [[ "$redirect_tcp_53" == 'true' ]] && echo "-A $AS_NAT_CHAIN_NAME -p tcp -j REDIRECT --to-ports $target_port"
    echo 'COMMIT'
  fi

  # --- FILTER 表 ---
  if [[ "$reject_udp_53" == 'true' || "$reject_tcp_53" == 'true' ]]; then
    echo '*filter'
    echo ":$AS_FILTER_CHAIN_NAME - [0:0]"
    echo "-F $AS_FILTER_CHAIN_NAME"
    echo "-A $AS_FILTER_CHAIN_NAME -m owner --uid-owner $RUNNING_USER --gid-owner $RUNNING_GROUP -j ACCEPT"
    # 说明同上
    [[ "$reject_udp_53" == 'true' ]] && echo "-A $AS_FILTER_CHAIN_NAME -p udp -j REJECT"
    [[ "$reject_tcp_53" == 'true' ]] && echo "-A $AS_FILTER_CHAIN_NAME -p tcp -j REJECT"
    echo 'COMMIT'
  fi
}

# 在 OUTPUT 链中添加一条把 53 端口流量跳转到自定义链的规则（已存在则跳过）
add_jump_rule() {
  local tool="$1"
  local table="$2"
  local proto="$3"
  local chain="$4"
  local error

  "$tool" -t "$table" -C OUTPUT -p "$proto" --dport 53 -j "$chain" 2>/dev/null && return

  if ! error=$("$tool" -t "$table" -A OUTPUT -p "$proto" --dport 53 -j "$chain" 2>&1); then
    log_error "在 $tool $table OUTPUT 中把 -p $proto --dport 53 跳转到链 $chain 失败：$error" \
      "Failed to jump -p $proto --dport 53 to chain $chain in $tool $table OUTPUT: $error"
    return 1
  fi
}

# 添加规则将流量跳转到自定义链
apply_rules() {
  local tool="$1"
  local redirect_udp_53="$2"
  local redirect_tcp_53="$3"
  local reject_udp_53="$4"
  local reject_tcp_53="$5"

  if [[ "$redirect_udp_53" == 'true' ]]; then
    add_jump_rule "$tool" nat udp "$AS_NAT_CHAIN_NAME" || return 1
  fi
  if [[ "$redirect_tcp_53" == 'true' ]]; then
    add_jump_rule "$tool" nat tcp "$AS_NAT_CHAIN_NAME" || return 1
  fi
  if [[ "$reject_udp_53" == 'true' ]]; then
    add_jump_rule "$tool" filter udp "$AS_FILTER_CHAIN_NAME" || return 1
  fi
  if [[ "$reject_tcp_53" == 'true' ]]; then
    add_jump_rule "$tool" filter tcp "$AS_FILTER_CHAIN_NAME" || return 1
  fi
}

# 为单个防火墙工具（iptables 或 ip6tables）加载并应用规则
add_tool_configuration() {
  local tool="$1"
  local return_dst_list="$2"
  local redirect_udp_53="$3"
  local redirect_tcp_53="$4"
  local target_port="$5"
  local reject_udp_53="$6"
  local reject_tcp_53="$7"

  # 没有启用任何规则时无需处理
  if [[ "$redirect_udp_53" != 'true' && "$redirect_tcp_53" != 'true' && "$reject_udp_53" != 'true' && "$reject_tcp_53" != 'true' ]]; then
    return
  fi

  local support_nat='true'
  # 不支持 nat 表直接忽略
  if ! "$tool" -t nat -L >/dev/null 2>&1; then
    log_info "$tool 不支持 nat 表，配置中作用于 nat 表的规则将无效" "$tool does not support nat tables; rules configured to apply to nat tables will be ineffective."
    support_nat='false'
  fi

  local restore_config
  restore_config=$(generate_restore_config "$support_nat" "$return_dst_list" "$redirect_udp_53" "$redirect_tcp_53" "$target_port" "$reject_udp_53" "$reject_tcp_53")

  # 只启用了转发规则但不支持 nat 表时，没有需要加载的规则
  if [[ -z "$restore_config" ]]; then
    log_info "$tool 没有可加载的规则，跳过" "$tool has no rules to load, skipping"
    return
  fi

  local error
  if ! error=$(echo "$restore_config" | "$tool-restore" -n 2>&1); then
    log_error "加载 $tool 规则失败：$error" "Adding $tool rules failed: $error"
    return 1
  fi

  # 加载成功则应用加载的规则到防火墙
  if [[ "$support_nat" == 'true' ]]; then
    apply_rules "$tool" "$redirect_udp_53" "$redirect_tcp_53" "$reject_udp_53" "$reject_tcp_53" || return 1
  else
    apply_rules "$tool" 'false' 'false' "$reject_udp_53" "$reject_tcp_53" || return 1
  fi

  log_info "添加 $tool 规则成功" "$tool rule added successfully"
}

add_configuration() {
  local supported_tools="$1"
  local tool

  log_info '正在添加防火墙规则……' 'Adding firewall rules...'

  for tool in $supported_tools; do
    case "$tool" in
      iptables)
        add_tool_configuration "$tool" "$IPV4_RETURN_DST_LIST" "$IPV4_REDIRECT_UDP_53" "$IPV4_REDIRECT_TCP_53" \
          "$IPV4_TARGET_PORT" "$IPV4_REJECT_UDP_53" "$IPV4_REJECT_TCP_53"
        ;;
      ip6tables)
        add_tool_configuration "$tool" "$IPV6_RETURN_DST_LIST" "$IPV6_REDIRECT_UDP_53" "$IPV6_REDIRECT_TCP_53" \
          "$IPV6_TARGET_PORT" "$IPV6_REJECT_UDP_53" "$IPV6_REJECT_TCP_53"
        ;;
    esac

    # 任意一个工具失败都回滚全部规则
    if [[ $? -ne 0 ]]; then
      remove_configuration "$supported_tools"
      return 1
    fi
  done

  log_info '防火墙规则添加成功' 'Firewall rules added successfully'
}

# 执行一条防火墙命令，失败时把命令和错误追加到 REMOVE_ERRORS
run_remove_cmd() {
  local error
  if ! error=$("$@" 2>&1); then
    REMOVE_ERRORS="${REMOVE_ERRORS}CMD: $*
Error: $error
"
  fi
}

remove_configuration() {
  local supported_tools="$1"
  local tool proto

  REMOVE_ERRORS=''

  log_info '正在移除防火墙规则……' 'Removing firewall rule...'

  for tool in $supported_tools; do
    # 删除 OUTPUT 中跳转到自定义链的规则
    for proto in udp tcp; do
      if "$tool" -t nat -C OUTPUT -p "$proto" --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>/dev/null; then
        run_remove_cmd "$tool" -t nat -D OUTPUT -p "$proto" --dport 53 -j "$AS_NAT_CHAIN_NAME"
      fi
      if "$tool" -t filter -C OUTPUT -p "$proto" --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>/dev/null; then
        run_remove_cmd "$tool" -t filter -D OUTPUT -p "$proto" --dport 53 -j "$AS_FILTER_CHAIN_NAME"
      fi
    done

    # 清空并删除自定义链
    if "$tool" -t nat -L "$AS_NAT_CHAIN_NAME" >/dev/null 2>&1; then
      run_remove_cmd "$tool" -t nat -F "$AS_NAT_CHAIN_NAME"
      run_remove_cmd "$tool" -t nat -X "$AS_NAT_CHAIN_NAME"
    fi
    if "$tool" -t filter -L "$AS_FILTER_CHAIN_NAME" >/dev/null 2>&1; then
      run_remove_cmd "$tool" -t filter -F "$AS_FILTER_CHAIN_NAME"
      run_remove_cmd "$tool" -t filter -X "$AS_FILTER_CHAIN_NAME"
    fi
  done

  if [[ "$REMOVE_ERRORS" ]]; then
    log_error "删除防火墙规则时遇到错误，请手动清理残留，否则模块可能无法启动：$REMOVE_ERRORS" \
      "If you encounter an error while deleting firewall rules, please manually clean up any remaining remnants; otherwise, the module may fail to start: $REMOVE_ERRORS"
    return 1
  fi

  log_info '防火墙规则移除成功' 'Firewall rule removed successfully'
}
