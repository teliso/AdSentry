#!/system/bin/sh

ui_print "Authorizing to the executable file..."

# 授予脚本可执行权限
chmod +x "$MODPATH"/*.sh "$MODPATH/scripts"/*.sh "$MODPATH/bin/AdGuardHome"
# 更改AdGuardHome二进制文件的用户组
chown root:net_raw "$MODPATH/bin/AdGuardHome"

ui_print "Authorization completed"