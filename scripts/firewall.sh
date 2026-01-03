#!/system/bin/sh

SCRIPTS_DIR=${0%/*}

. "$SCRIPTS_DIR/log.sh"

readonly target_port=$(ksud module config get target_port)
readonly ignore_dest_list=$(ksud module config get ignore_dest_list)
readonly ignore_src_list=$(ksud module config get ignore_src_list)
readonly drop_ipv6_dns=$(ksud module config get drop_ipv6_dns)

add_configuration() {
  log "正在添加IPv4 DNS请求转发链……" "Adding IPv4 DNS request redirect chain..."

  # 创建自用链
  if ! iptables -t nat -L ADSENTRY_REDIRECT -n >/dev/null 2>&1; then
    iptables -t nat -N ADSENTRY_REDIRECT
  else
      iptables -t nat -F ADSENTRY_REDIRECT
  fi

  # 忽略 AdGuardHome 自身流量（UID + GID 唯一组合）
  iptables -t nat -A ADSENTRY_REDIRECT \
  -m owner --uid-owner nobody --gid-owner net_raw -j RETURN

  # 忽略目的地址（如本地、保留地址、上游 DNS）
  for subnet in $ignore_dest_list; do
    iptables -t nat -A ADSENTRY_REDIRECT -d "$subnet" -j RETURN
  done

  # 忽略源地址（如 VPN、容器、特定接口）
  for subnet in $ignore_src_list; do
    iptables -t nat -A ADSENTRY_REDIRECT -s "$subnet" -j RETURN
  done

  # 剩余 DNS → 重定向到 AdGuardHome
  iptables -t nat -A ADSENTRY_REDIRECT -p udp --dport 53 -j REDIRECT --to-ports "$target_port"
  iptables -t nat -A ADSENTRY_REDIRECT -p tcp --dport 53 -j REDIRECT --to-ports "$target_port"

  # 把OUTPUT的明文DNS流量导入到自定义链
  iptables -t nat -I OUTPUT -p udp --dport 53 -j ADSENTRY_REDIRECT
  iptables -t nat -I OUTPUT -p tcp --dport 53 -j ADSENTRY_REDIRECT

  log "IPv4 DNS请求转发链添加完成" "IPv4 DNS request redirect chain added"
}

remove_configuration() {
  log "正在移除IPv4 DNS请求转发链……" "Removing IPv4 DNS request redirect chain..."

  # 检查自定义链是否存在
  if iptables -t nat -L ADSENTRY_REDIRECT -n &>/dev/null; then
    # 移除 OUTPUT 链中指向自定义链的规则
    iptables -t nat -D OUTPUT -p udp --dport 53 -j ADSENTRY_REDIRECT 2>/dev/null
    iptables -t nat -D OUTPUT -p tcp --dport 53 -j ADSENTRY_REDIRECT 2>/dev/null

    # 清空自定义链中的规则
    iptables -t nat -F ADSENTRY_REDIRECT 2>/dev/null

    # 删除自定义链
    iptables -t nat -X ADSENTRY_REDIRECT 2>/dev/null

    log "IPv4 DNS请求转发链移除完成" "IPv4 DNS request redirect chain removed"
  else
    log "没有IPv4 DNS请求转发链需要删除" "There is no IPv4 DNS request redirect chain to delete"
  fi
}

# 添加丢弃IPv6 DNS
add_drop_ipv6_dns() {
  log "正在添加 IPv6 DNS 请求丢弃规则..." "Adding IPv6 DNS request drop rules..."

  # UDP 53
  if ! ip6tables -t filter -C OUTPUT -p udp --dport 53 -j DROP 2>/dev/null; then
    ip6tables -t filter -A OUTPUT -p udp --dport 53 -j DROP
    log "已添加 UDP 53 DROP 规则" "Added UDP 53 DROP rule"
  else
    log "UDP 53 DROP 规则已存在，跳过" "UDP 53 DROP rule already exists, skipped"
  fi

  # TCP 53
  if ! ip6tables -t filter -C OUTPUT -p tcp --dport 53 -j DROP 2>/dev/null; then
    ip6tables -t filter -A OUTPUT -p tcp --dport 53 -j DROP
    log "已添加 TCP 53 DROP 规则" "Added TCP 53 DROP rule"
  else
    log "TCP 53 DROP 规则已存在，跳过" "TCP 53 DROP rule already exists, skipped"
  fi

  log "IPv6 DNS 请求丢弃规则添加完成" "IPv6 DNS request drop rules added"
}

# 移除丢弃IPv6 DNS
remove_drop_ipv6_dns() {
  log "正在移除 IPv6 DNS DROP 规则..." "Removing IPv6 DNS DROP rules..."

  # UDP
  if ip6tables -t filter -C OUTPUT -p udp --dport 53 -j DROP 2>/dev/null; then
    ip6tables -t filter -D OUTPUT -p udp --dport 53 -j DROP
    log "已删除 UDP 53 DROP 规则" "Deleted UDP 53 DROP rule"
  else
    log "UDP 53 DROP 规则不存在，跳过" "UDP 53 DROP rule does not exist, skipped"
  fi

  # TCP
  if ip6tables -t filter -C OUTPUT -p tcp --dport 53 -j DROP 2>/dev/null; then
    ip6tables -t filter -D OUTPUT -p tcp --dport 53 -j DROP
    log "已删除 TCP 53 DROP 规则" "Deleted TCP 53 DROP rule"
  else
    log "TCP 53 DROP 规则不存在，跳过" "TCP 53 DROP rule does not exist, skipped"
  fi

  log "IPv6 DNS DROP 规则移除完成" "IPv6 DNS DROP rules removed"
}

case "$1" in
  add)
    add_configuration
    ;;
  remove)
    remove_configuration
    ;;
  add_drop)
    add_drop_ipv6_dns
    ;;
  remove_drop)
    remove_drop_ipv6_dns
    ;;
  *)
    log "用法: $0 {add|remove|add_drop|remove_drop}" "Usage: $0 {add|remove|add_drop|remove_drop}"
    ;;
esac
