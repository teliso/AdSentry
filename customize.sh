SKIPUNZIP=1

MODULES_DIR="/data/adb/modules"

language="zh"

locale=$(getprop persist.sys.locale 2>/dev/null)
[ -z "$locale" ] && locale=$(getprop ro.product.locale 2>/dev/null)
[ -z "$locale" ] && locale=$(getprop persist.sys.language 2>/dev/null)

if [ "${locale:0:2}" = "en" ]; then
  language="en"
fi

log() {
  [ "$language" = "zh" ] && ui_print "$1" || ui_print "$2"
}

DEVICE=$(getprop ro.product.device)

log "设备信息：$DEVICE $ARCH" "Device info: $DEVICE - $ARCH"
log "开始安装AdSentry……" "Installing AdSentry..."

keep_configuration() {
  log "保留配置安装，正在解压文件……" "Preserve configuration installation, extracting files..."

  cp "$MODULES_DIR/AdSentry/config.sh" "$TMPDIR"
  cp "$MODULES_DIR/AdSentry/AGH/AdGuardHome.yaml" "$TMPDIR"
  cp "$MODULES_DIR/AdSentry/AGH/data" "$TMPDIR"
  unzip -o "$ZIPFILE" -x config.sh AGH/AdGuardHome.yaml -d "$MODPATH" >/dev/null 2>&1
  mv "$TMPDIR/config.sh" "$MODPATH"
  mv "$TMPDIR/AdGuardHome.yaml" "$MODPATH/AGH"
  mv "$TMPDIR/data" "$MODPATH/AGH"

  log "解压完成" "Decompression completed"
}

dont_keep() {
  log "不保留配置安装，正在解压文件……" "Installation without retaining configuration, decompressing files..."

  unzip -o "$ZIPFILE" -d "$MODPATH" >/dev/null 2>&1

  log "解压完成" "Decompression completed"
}

if [ -d "$MODULES_DIR/AdSentry" ]; then
  log "发现旧模块，是否保存配置？" "Found the old module, whether to save the configuration?"
  log "音量上 = 是，音量下 = 否，20秒无操作 = 是" "Volume up = yes, volume down = no, no operation for 20 seconds = yes"

  START_TIME=$(date +%s)
  while true; do
    NOW_TIME=$(date +%s)
    timeout 1 getevent -lc 1 2>&1 | grep KEY_VOLUME > "$TMPDIR/events"

    if [ $((NOW_TIME - START_TIME)) -gt 19 ]; then
      keep_configuration
      break
    elif grep -q KEY_VOLUMEUP "$TMPDIR/events"; then
      keep_configuration
      break
    elif grep -q KEY_VOLUMEDOWN "$TMPDIR/events"; then
      dont_keep
      break
    fi
  done
else
  dont_keep
fi

log "正在授权给可执行文件……" "Authorizing to the executable file..."

# 755 - RWX/RX/RX 644 - RW/R/R
set_perm_recursive "$MODPATH" 0 0 0755 0644
find "$MODPATH" -type f -name "*.sh" -exec chmod 0755 {} \;
chmod 0755 "$MODPATH/AGH/AdGuardHome"

log "授权完成" "Authorization completed"
log "安装完成" "Installation completed"
log "请重启设备以便模块初始化" "Please restart the device to allow the module to initialize"