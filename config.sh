#!/system/bin/sh

ksud module config set time_zone ""
ksud module config set target_port 5353
ksud module config set enable_log false
ksud module config set drop_ipv6_dns true
ksud module config set ignore_src_list ""
ksud module config set ignore_dest_list ""