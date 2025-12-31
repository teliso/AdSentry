#!/system/bin/sh

. /data/adb/modules/AdSentry/settings.conf

add_configuration() {
  log "正在添加IPv4 DNS请求转发链……" "Adding IPv4 DNS request redirect chain..."

  # 设置iptables前先清理旧规则（仅在链存在时）
  # 清理IPv4 DNS转发
  if iptables -t nat -L ADSENTRY_REDIRECT_DNS -n &>/dev/null; then
    iptables -t nat -F ADSENTRY_REDIRECT_DNS
    iptables -t nat -D OUTPUT -j ADSENTRY_REDIRECT_DNS
    iptables -t nat -X ADSENTRY_REDIRECT_DNS
  fi

  # 清理IPv6 DNS阻断
  if ip6tables -t filter -L ADSENTRY_DROP_DNS -n &>/dev/null; then
    ip6tables -t filter -F ADSENTRY_DROP_DNS
    ip6tables -t filter -D OUTPUT -j ADSENTRY_DROP_DNS
    ip6tables -t filter -X ADSENTRY_DROP_DNS
  fi

  # 创建 IPv4 链
  iptables -t nat -N ADSENTRY_REDIRECT_DNS

  # 排除 AdGuardHome 自身流量
  iptables -t nat -A ADSENTRY_REDIRECT_DNS -m owner --uid-owner $agh_uid --gid-owner $agh_gid -j RETURN

  # 重定向 IPv4 DNS 请求到指定端口
  iptables -t nat -A ADSENTRY_REDIRECT_DNS -p udp --dport 53 -j REDIRECT --to-ports $redirect_port
  iptables -t nat -A ADSENTRY_REDIRECT_DNS -p tcp --dport 53 -j REDIRECT --to-ports $redirect_port
	
  # 将 OUTPUT 流量导入 ADSENTRY_REDIRECT_DNS 链
  iptables -t nat -I OUTPUT -j ADSENTRY_REDIRECT_DNS
  log "IPv4 DNS请求转发链添加完成" "IPv4 DNS request redirect chain added"

  # 添加 IPv6 DNS 阻断，如果开启阻止
  if [ "$block_ipv6_dns" = true ]; then
    add_drop_ipv6_dns
  fi
}

remove_configuration() {
  log "正在移除IPv4 DNS请求转发链……" "Removing IPv4 DNS request redirect chain..."

  # 移除 IPv4 规则（仅在链存在时）
  if iptables -t nat -L ADSENTRY_REDIRECT_DNS -n &>/dev/null; then
    iptables -t nat -D OUTPUT -j ADSENTRY_REDIRECT_DNS
    iptables -t nat -F ADSENTRY_REDIRECT_DNS
    iptables -t nat -X ADSENTRY_REDIRECT_DNS
	log "IPv4 DNS请求转发链移除完成" "IPv4 DNS request redirect chain removed"
  else
    log "没有IPv4 DNS请求转发链需要删除" "There is no IPv4 DNS request redirect chain to delete"
  fi
  
  # 移除 IPv6 DNS 阻断
  remove_drop_ipv6_dns
}

add_drop_ipv6_dns() {
  log "正在添加IPv6 DNS请求丢弃链……" "Adding IPv6 DNS request drop chain..."
  ip6tables -t filter -N ADSENTRY_DROP_DNS
  ip6tables -t filter -A ADSENTRY_DROP_DNS -p udp --dport 53 -j DROP
  ip6tables -t filter -A ADSENTRY_DROP_DNS -p tcp --dport 53 -j DROP
  ip6tables -t filter -I OUTPUT -j ADSENTRY_DROP_DNS
  log "IPv6 DNS请求丢弃链添加完成" "IPv6 DNS request drop chain added"
}

remove_drop_ipv6_dns() {
  log "正在移除IPv6 DNS请求丢弃链……" "Removing IPv6 DNS request drop chain..."
  
  # 移除 IPv6 阻断规则（仅在链存在时）
  if ip6tables -t filter -L ADSENTRY_DROP_DNS -n &>/dev/null; then
    ip6tables -t filter -D OUTPUT -j ADSENTRY_DROP_DNS
    ip6tables -t filter -F ADSENTRY_DROP_DNS
    ip6tables -t filter -X ADSENTRY_DROP_DNS
	log "IPv6 DNS请求丢弃链移除完成" "IPv6 DNS request drop chain removed"
	return
  fi
  log "没有IPv6 DNS请求丢弃链需要删除" "There is no IPv6 DNS request drop chain to delete"
}

case "$1" in
  add)
    add_configuration
    ;;
  remove)
    remove_configuration
    ;;
  *)
    log "用法: $0 {add|remove}" "Usage: $0 {add|remove}"
    ;;
esac
