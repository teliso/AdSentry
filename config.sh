#!/system/bin/sh

# 模块日志开关 / Module log switch
ksud module config set enable_module_log 'false'
# 是否应用防火墙规则 / Apply firewall rules
ksud module config set enable_firewall_rules 'true'

# 转发流量的目标端口 / The target port for forwarded traffic
ksud module config set ipv4_target_port '35533'
ksud module config set ipv6_target_port '35533'

# AdGuardHome 运行信息 / AdGuardHome running info
# 设置为 AdGuardHome.yaml 中的网页端口，否则会启动失败
# Set the port to the web port specified in AdGuardHome.yaml; otherwise, startup will fail
ksud module config set web_port '3000'
# 以下两项配置填写以后不需要在 AdGuardHome.yaml 中再配置用户和组
# After filling in the following two configuration items, you do not need to configure users and groups in AdGuardHome.yaml
# 0 - root | 3004 - net_raw
ksud module config set running_user '0'
ksud module config set running_group '3004'

# 以下三项配置将作用于 iptables nat，请确保你的 iptables 支持 nat 表
# The following three configurations will apply to iptables nat. Please ensure that your iptables supports nat
# 返回匹配 -d $dst 的流量，仅优先于转发规则 / Returns traffic matching -d $dst, taking precedence only over forwarding rules
ksud module config set ipv4_return_dst_list ''

# 转发规则 / Forwarding rules
ksud module config set ipv4_redirect_udp_53 'true'
ksud module config set ipv4_redirect_tcp_53 'true'

# 拒绝规则；以下两项配置作用于 iptables filter / Reject rules; the following two configurations apply to iptables filter
ksud module config set ipv4_reject_udp_53 'false'
ksud module config set ipv4_reject_tcp_53 'false'

# 以下三项配置将作用于 ip6tables nat，请确保你的 ip6tables 支持 nat 表
# The following three configurations will apply to ip6tables nat. Please ensure that your ip6tables supports nat
# 返回发往某个 IPv6:53 的流量，仅优先于转发规则 / Returns traffic matching -d $dst, taking precedence only over forwarding rules
ksud module config set ipv6_return_dst_list ''

# 转发规则 / Forwarding rules
ksud module config set ipv6_redirect_udp_53 'false'
ksud module config set ipv6_redirect_tcp_53 'false'

# 拒绝规则；以下两项配置作用于 ip6tables filter / Reject rules; the following two configurations apply to ip6tables filter
ksud module config set ipv6_reject_udp_53 'true'
ksud module config set ipv6_reject_tcp_53 'true'