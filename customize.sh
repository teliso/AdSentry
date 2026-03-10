#!/system/bin/sh

SKIPUNZIP=1

MODULE_DIR="/data/adb/modules/AdSentry"

LANGUAGE="zh"

locale=$(getprop persist.sys.locale 2>/dev/null)
[[ -z "$locale" ]] && locale=$(getprop ro.product.locale 2>/dev/null)
[[ -z "$locale" ]] && locale=$(getprop persist.sys.LANGUAGE 2>/dev/null)

[[ "$locale" == en* ]] && LANGUAGE="en"

log() {
  if [[ "$LANGUAGE" == "zh" ]]; then
    ui_print "$1"
  else
    ui_print "$2"
  fi
}

error() {
  if [[ "$LANGUAGE" == "zh" ]]; then
    abort "$1"
  else
    abort "$2"
  fi
}

DEVICE=$(getprop ro.product.device)

log "设备信息：$DEVICE - $ARCH" "Device info: $DEVICE - $ARCH"
log "开始安装AdSentry……" "Installing AdSentry..."

preserve_configuration_installation() {
  local error

  directly_unzip

  if [[ "$KEEP_MODULE_CONFIG" == "true" ]]; then
    log "保留模块配置文件 config.sh" "Preserve module configuration file config.sh"

    error=$(\cp -af "$MODULE_DIR/config.sh" "$MODPATH" 2>&1 >/dev/null) || \
      error "保留模块配置文件 config.sh 时失败，安装停止：$error" "Installation failed and stopped while retaining the module configuration file config.sh: $error"
  fi

  if [[ "$KEEP_AGH_CONFIG" == "true" ]]; then
    log "保留旧 AdGuardHome 的 AdGuardHome.yaml 文件" "Keep the old AdGuardHome.yaml file"

    error=$(\cp -af "$MODULE_DIR/agh_work/AdGuardHome.yaml" "$MODPATH/agh_work" 2>&1 >/dev/null) || \
      error "保留旧 AdGuardHome 的 AdGuardHome.yaml 时失败，安装停止：$error" "Installation failed while trying to retain the old AdGuardHome.yaml file, and the installation stopped: $error"
  fi

  if [[ "$KEEP_AGH_DATA" == "true" ]]; then
    log "保留旧 AdGuardHome 的 data 目录" "Retain the old AdGuardHome data directory"
    
    error=$(\cp -af "$MODULE_DIR/agh_work/data" "$MODPATH/agh_work" 2>&1 >/dev/null) || \
      error "保留旧 AdGuardHome 的 data 目录时失败，安装停止：$error" "Installation failed while trying to preserve the old AdGuardHome data directory, and stopped: $error"
  fi
}

directly_unzip() {
  local error

  log "正在解压文件……" "Installation without retaining configuration, decompressing files..."

  error=$(unzip -o "$ZIPFILE" -d "$MODPATH" 2>&1 >/dev/null) || \
    error "解压模块时出现错误，安装停止：$error" "An error occurred while extracting the module, and the installation stopped: $error"

  log "解压完成" "Decompression completed"
}

KEEP_MODULE_CONFIG="false"
KEEP_AGH_CONFIG="false"
KEEP_AGH_DATA="false"

# 音量键选择函数
volume_select() {
  local prompt_cn="$1"
  local prompt_en="$2"

  local timeout=10

  log "$prompt_cn" "$prompt_en"
  log "音量上 = 是，音量下 = 否，10秒超时 = 是" "Vol Up = Yes, Vol Down = No, 10s Timeout = Yes"

  while [ $timeout -gt 0 ]; do
    # 读取音量键
    local key
    key=$(getevent -lqc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN).*DOWN" | head -1)

    if echo "$key" | grep -q "KEY_VOLUMEUP"; then
      getevent -lc 1 >/dev/null 2>&1
      return 0
    elif echo "$key" | grep -q "KEY_VOLUMEDOWN"; then
      getevent -lc 1 >/dev/null 2>&1
      return 1
    fi

    sleep 1
    timeout=$((timeout - 1))
  done

  getevent -lc 1 >/dev/null 2>&1
  return 0
}

if [[ -d "$MODULE_DIR" ]]; then
  if volume_select "是否保留旧模块的 config.sh 配置文件？" "Should we retain the old module's config.sh configuration file?"; then
    KEEP_MODULE_CONFIG="true"
    log "已选择保留" "Selected to keep"
  else
    log "已选择不保留" "Selected not to keep"
  fi

  if volume_select "是否保留旧 AdGuardHome 的 AdGuardHome.yaml 文件？" "Should we keep the old AdGuardHome.yaml file?"; then
    KEEP_AGH_CONFIG="true"
    log "已选择保留" "Selected to keep"
  else
    log "已选择不保留" "Selected not to keep"
  fi

  if volume_select "是否保留旧 AdGuardHome 的 data 目录？" "Should we retain the old AdGuardHome's data directory?"; then
    KEEP_AGH_DATA="true"
    log "已选择保留" "Selected to keep"
  else
    log "已选择不保留" "Selected not to keep"
  fi
else
  directly_unzip
fi

if [[ "$KEEP_MODULE_CONFIG" == "true" || "$KEEP_AGH_CONFIG" == "true" || "$KEEP_AGH_DATA" == "true" ]]; then
  preserve_configuration_installation
else
  directly_unzip
fi

log "正在授权给指定文件……" "Authorizing the specified file..."

# 文件夹 | 文件
# 750: RWX/RX/--- | 640: RW/R/---
set_perm_recursive "$MODPATH" 0 0 0750 0640
find "$MODPATH" -type f -name "*.sh" -exec chmod 0740 {} \;
chmod 0740 "$MODPATH/agh_work/AdGuardHome"

log "授权完成" "Authorization completed"
log "安装完成" "Installation completed"
log "请重启设备以便模块初始化" "Please restart the device to allow the module to initialize"