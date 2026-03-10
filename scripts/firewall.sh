#!/system/bin/sh

readonly AS_NAT_CHAIN_NAME='AS_RED'
readonly AS_FILTER_CHAIN_NAME='AS_REJ'

generate_restore_config() {
  local support_nat="$1"
  local return_dst_list="$2"
  local redirect_udp_53="$3"
  local redirect_tcp_53="$4"
  local target_port="$5"
  local reject_udp_53="$6"
  local reject_tcp_53="$7"

  # --- NAT 表 ---
  if [[ "$support_nat" == 'true' ]]; then
    # 只有在启用某一条转发规则以后，才需要设置一些额外规则，否则不设置额外规则
    if [[ "$redirect_udp_53" == 'true' || "$redirect_tcp_53" == 'true' ]]; then
      echo '*nat'
      echo ":$AS_NAT_CHAIN_NAME - [0:0]"
      echo "-F $AS_NAT_CHAIN_NAME"
      # 排除自身流量
      echo "-A $AS_NAT_CHAIN_NAME -m owner --uid-owner $RUNNING_USER --gid-owner $RUNNING_GROUP -j RETURN"
      
      # 处理忽略列表
      for d in $return_dst_list; do [[ "$d" ]] && echo "-A $AS_NAT_CHAIN_NAME -d $d -j RETURN"; done
      
      # 进入的流量只有 UDP 53 或者 TCP 53，但是为了配合 REDIRECT 的要求，还是指定一个用于转发的匹配规则
      [[ "$redirect_udp_53" == 'true' ]] && echo "-A $AS_NAT_CHAIN_NAME -p udp -j REDIRECT --to-ports $target_port"
      [[ "$redirect_tcp_53" == 'true' ]] && echo "-A $AS_NAT_CHAIN_NAME -p tcp -j REDIRECT --to-ports $target_port"
      echo 'COMMIT'
    fi
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

# 添加规则将流量跳转到自定义链
apply_rules() {
  local tool="$1"
  local redirect_udp_53="$2"
  local redirect_tcp_53="$3"
  local reject_udp_53="$4"
  local reject_tcp_53="$5"

  local error

  if [[ "$redirect_udp_53" == 'true' ]]; then
    if ! "$tool" -t nat -C OUTPUT -p udp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t nat -A OUTPUT -p udp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>&1); then
        log_error "在 $tool nat OUTPUT 中把 -p udp --dport 53 跳转到链 $AS_NAT_CHAIN_NAME 失败：$error" "Failed to jump -p udp --dport 53 to chain $AS_NAT_CHAIN_NAME in $tool nat OUTPUT: $error"
        return 1
      fi
    fi
  fi

  if [[ "$redirect_tcp_53" == 'true' ]]; then
    if ! "$tool" -t nat -C OUTPUT -p tcp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t nat -A OUTPUT -p tcp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>&1); then
        log_error "在 $tool nat OUTPUT 中把 -p tcp --dport 53 跳转到链 $AS_NAT_CHAIN_NAME 失败：$error" "Failed to jump -p tcp --dport 53 to chain $AS_NAT_CHAIN_NAME in $tool nat OUTPUT: $error"
        return 1
      fi
    fi
  fi
  
  if [[ "$reject_udp_53" == 'true' ]]; then
    if ! "$tool" -t filter -C OUTPUT -p udp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t filter -A OUTPUT -p udp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>&1); then
        log_error "在 $tool filter OUTPUT 中把 -p udp --dport 53 跳转到链 $AS_FILTER_CHAIN_NAME 失败：$error" "Failed to jump -p udp --dport 53 to chain $AS_FILTER_CHAIN_NAME in $tool filter OUTPUT: $error"
        return 1
      fi
    fi
  fi

  if [[ "$reject_tcp_53" == 'true' ]]; then
    if ! "$tool" -t filter -C OUTPUT -p tcp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t filter -A OUTPUT -p tcp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>&1); then
        log_error "在 $tool filter OUTPUT 中把 -p tcp --dport 53 跳转到链 $AS_FILTER_CHAIN_NAME 失败：$error" "Failed to jump -p tcp --dport 53 to chain $AS_FILTER_CHAIN_NAME in $tool filter OUTPUT: $error"
        return 1
      fi
    fi
  fi
}

add_configuration() {
  local supported_tools="$1"

  local error

  log_info '正在添加防火墙规则……' 'Adding firewall rules...'

  for tool in $supported_tools; do
    local support_nat='true'
    # 不支持 nat 表直接忽略
    if ! "$tool" -t nat -L >/dev/null 2>&1; then
      log_info "$tool 不支持 nat 表，配置中作用于 nat 表的规则将无效" "$tool does not support nat tables; rules configured to apply to nat tables will be ineffective."
      support_nat='false'
    fi

    local restore_config

    # 处理 iptables
    if [[ "$tool" == 'iptables' ]]; then
      # 判断是否启用防火墙规则
      if [[ "$IPV4_REDIRECT_UDP_53" == 'true' || "$IPV4_REDIRECT_TCP_53" == 'true' || "$IPV4_REJECT_UDP_53" == 'true' || "$IPV4_REJECT_TCP_53" == 'true' ]]; then
        # 生成 iptables restore 文件
        restore_config=$(generate_restore_config "$support_nat" "$IPV4_DST_LIST" "$IPV4_REDIRECT_UDP_53" "$IPV4_REDIRECT_TCP_53" "$IPV4_TARGET_PORT" "$IPV4_REJECT_UDP_53" "$IPV4_REJECT_TCP_53")

        if [[ "$restore_config" ]]; then
          # 如果加载防火墙规则失败
          if ! error=$(echo "$restore_config" | iptables-restore -n 2>&1); then
            log_error "加载 $tool 规则失败：$error" "Adding $tool rules failed: $error"
            remove_configuration "$supported_tools"
            return 1
          fi
          # 加载成功则应用加载的规则到防火墙
          if ! apply_rules "$tool" "$IPV4_REDIRECT_UDP_53" "$IPV4_REDIRECT_TCP_53" "$IPV4_REJECT_UDP_53" "$IPV4_REJECT_TCP_53"; then
            remove_configuration "$supported_tools"
            return 1
          fi
          log_info "添加 $tool 规则成功" "$tool rule added successfully"
        else
          # 如果启用了转发 53 udp 或 53 tcp 但是生成了空配置，又或者启用了 REJECT 功能但是生成了空配置
          log_error '未能成功生成 restore 文件，请调试源码或反馈' 'Failed to generate restore file. Please debug the source code or provide feedback.'
          remove_configuration "$tool"
          return 1
        fi
      fi
      if [[ "$IPV4_ENABLE_REJECT" == 'false' ]]; then
        log_info "你未启用 $tool REJECT 功能，忽略全部 REJECT 规则" "You have not enabled the $tool REJECT feature, ignoring all REJECT rules."
      fi
    # 处理 ip6tables
    elif [[ "$tool" == 'ip6tables' ]]; then
      if [[ "$IPV6_REDIRECT_UDP_53" == 'true' || "$IPV6_REDIRECT_TCP_53" == 'true' || "$IPV6_REJECT_UDP_53" == 'true' || "$IPV6_REJECT_TCP_53" == 'true' ]]; then
        # 生成 ip6tables restore 文件
        restore_config=$(generate_restore_config "$support_nat" "$IPV6_DST_LIST" "$IPV6_REDIRECT_UDP_53" "$IPV6_REDIRECT_TCP_53" "$IPV6_TARGET_PORT" "$IPV6_REJECT_UDP_53" "$IPV6_REJECT_TCP_53")
        
        if [[ "$restore_config" ]]; then
          # 如果加载防火墙规则失败
          if ! error=$(echo "$restore_config" | ip6tables-restore -n 2>&1); then
            log_error "加载 $tool 规则失败：$error" "Adding $tool rules failed: $error"
            remove_configuration "$supported_tools"
            return 1
          fi
          # 加载成功则应用加载的规则到防火墙
          if ! apply_rules "$tool" "$IPV6_REDIRECT_UDP_53" "$IPV6_REDIRECT_TCP_53" "$IPV6_REJECT_UDP_53" "$IPV6_REJECT_TCP_53"; then
            remove_configuration "$supported_tools"
            return 1
          fi
          log_info "添加 $tool 规则成功" "$tool rule added successfully"
        else
          # 如果启用了转发 53 udp 或 53 tcp 但是生成了空配置，又或者启用了 REJECT 功能但是生成了空配置
          log_error '未能成功生成 restore 文件，请调试源码或反馈' 'Failed to generate restore file. Please debug the source code or provide feedback.'
          remove_configuration "$tool"
          return 1
        fi
      fi
      if [[ "$IPV6_ENABLE_REJECT" == 'false' ]]; then
        log_info "你未启用 $tool REJECT 功能，忽略全部 REJECT 规则" "You have not enabled the $tool REJECT feature, ignoring all REJECT rules."
      fi
    fi
  done

  log_info '防火墙规则添加成功' 'Firewall rules added successfully'
}

remove_configuration() {
  local supported_tools="$1"
  local errors
  local error

  log_info '正在移除防火墙规则……' 'Removing firewall rule...'

  for tool in $supported_tools; do
    # NAT UDP 53
    if "$tool" -t nat -C OUTPUT -p udp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t nat -D OUTPUT -p udp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>&1); then
        errors=$(printf "CMD: $tool -t nat -D OUTPUT -p udp --dport 53 -j $AS_NAT_CHAIN_NAME\nError: %s\n" "$error")
      fi
    fi

    # NAT TCP 53
    if "$tool" -t nat -C OUTPUT -p tcp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t nat -D OUTPUT -p tcp --dport 53 -j "$AS_NAT_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: $tool -t nat -D OUTPUT -p tcp --dport 53 -j $AS_NAT_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi
    fi

    # FILTER UDP 53
    if "$tool" -t filter -C OUTPUT -p udp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t filter -D OUTPUT -p udp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: $tool -t filter -D OUTPUT -p udp --dport 53 -j $AS_FILTER_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi
    fi

    # FILTER TCP 53
    if "$tool" -t filter -C OUTPUT -p tcp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>/dev/null; then
      if ! error=$("$tool" -t filter -D OUTPUT -p tcp --dport 53 -j "$AS_FILTER_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: $tool -t filter -D OUTPUT -p tcp --dport 53 -j $AS_FILTER_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi
    fi

    if "$tool" -t nat -L "$AS_NAT_CHAIN_NAME" >/dev/null 2>&1; then
      if ! error=$("$tool" -t nat -F "$AS_NAT_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: $tool -t nat -F $AS_NAT_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi

      if ! error=$("$tool" -t nat -X "$AS_NAT_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: tool -t nat -X $AS_NAT_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi
    fi

    if "$tool" -t filter -L "$AS_FILTER_CHAIN_NAME" >/dev/null 2>&1; then
      if ! error=$("$tool" -t filter -F "$AS_FILTER_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: $tool -t filter -F $AS_FILTER_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi

      if ! error=$("$tool" -t filter -X "$AS_FILTER_CHAIN_NAME" 2>&1); then
        errors=$(printf "%sCMD: $tool -t filter -X $AS_FILTER_CHAIN_NAME\nError: %s\n" "$errors" "$error")
      fi
    fi
  done

  if [[ "$errors" ]]; then
    log_error "删除防火墙规则时遇到错误，请手动清理残留，否则模块可能无法启动：$errors" \
      "If you encounter an error while deleting firewall rules, please manually clean up any remaining remnants; otherwise, the module may fail to start: $errors"
    return 1
  fi

  log_info '防火墙规则移除成功' 'Firewall rule removed successfully'
}