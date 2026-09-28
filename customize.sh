#!/system/bin/sh

SKIPUNZIP=1

MODULE_DIR='/data/adb/modules/AdSentry'

LANGUAGE='zh'

locale=$(getprop persist.sys.locale 2>/dev/null)
[[ -z "$locale" ]] && locale=$(getprop ro.product.locale 2>/dev/null)
[[ -z "$locale" ]] && locale=$(getprop persist.sys.language 2>/dev/null)

[[ "$locale" == en* ]] && LANGUAGE='en'

# 按系统语言选择信息；用法：msg <中文> <英文>
msg() {
  if [[ "$LANGUAGE" == 'zh' ]]; then
    echo "$1"
  else
    echo "$2"
  fi
}

log() {
  ui_print "$(msg "$1" "$2")"
}

error_msg() {
  abort "$(msg "$1" "$2")"
}

DEVICE=$(getprop ro.product.device)

log "设备信息：$DEVICE - $ARCH" "Device info: $DEVICE - $ARCH"
log '开始安装AdSentry……' 'Installing AdSentry...'

# 从旧模块复制文件或目录到新模块；旧模块中不存在时跳过
preserve() {
  local src="$MODULE_DIR/$1"
  local dst="$MODPATH/$1"
  dst="${dst%/*}"
  local error

  if [[ ! -e "$src" ]]; then
    log "旧模块中没有 $1，跳过" "$1 not found in the old module, skipping"
    return
  fi

  error=$(\cp -af "$src" "$dst" 2>&1) || \
    error_msg "保留 $1 时失败，安装停止：$error" "Installation failed and stopped while retaining $1: $error"
}

preserve_configuration_installation() {
  directly_unzip

  if [[ "$KEEP_MODULE_CONFIG" == 'true' ]]; then
    log '保留模块配置文件 config.sh' 'Preserve module configuration file config.sh'
    preserve 'config.sh'
  fi

  if [[ "$KEEP_AGH_DATA" == 'true' ]]; then
    log '保留旧 AdGuardHome 的数据' 'Retain data from the old AdGuardHome'
    preserve 'agh_work/AdGuardHome.yaml'
    preserve 'agh_work/data'
  fi
}

directly_unzip() {
  local error

  log '正在解压文件……' 'Decompressing files...'

  error=$(unzip -oqq "$ZIPFILE" -x 'customize.sh' -d "$MODPATH" 2>&1) || \
    error_msg "解压模块时出现错误，安装停止：$error" "An error occurred while extracting the module, and the installation stopped: $error"

  log '解压完成' 'Decompression completed'
}

KEEP_MODULE_CONFIG='false'
KEEP_AGH_DATA='false'

# 音量键选择函数
volume_select() {
  local prompt_cn="$1"
  local prompt_en="$2"

  local timeout=10
  local key

  log "$prompt_cn" "$prompt_en"
  log '音量上 = 是，音量下 = 否，10秒超时 = 是' 'Vol Up = Yes, Vol Down = No, 10s Timeout = Yes'

  while [[ $timeout -gt 0 ]]; do
    # 读取音量键
    key=$(getevent -lqc 1 2>/dev/null | grep -E 'KEY_VOLUME(UP|DOWN).*DOWN' | head -1)

    case "$key" in
      *KEY_VOLUMEUP*)
        getevent -lc 1 >/dev/null 2>&1
        return 0
        ;;
      *KEY_VOLUMEDOWN*)
        getevent -lc 1 >/dev/null 2>&1
        return 1
        ;;
    esac

    sleep 1
    timeout=$((timeout - 1))
  done

  getevent -lc 1 >/dev/null 2>&1
  return 0
}

if [[ -d "$MODULE_DIR" ]]; then
  if volume_select '是否保留旧模块的 config.sh 配置文件？' "Should we retain the old module's config.sh configuration file?"; then
    KEEP_MODULE_CONFIG='true'
    log '已选择保留' 'Selected to keep'
  else
    log '已选择不保留' 'Selected not to keep'
  fi

  if volume_select '是否保留旧 AdGuardHome 的数据（data 目录和 AdGuardHome.yaml 文件）？' 'Should we retain the old AdGuardHome data (data directory and AdGuardHome.yaml file)?'; then
    KEEP_AGH_DATA='true'
    log '已选择保留' 'Selected to keep'
  else
    log '已选择不保留' 'Selected not to keep'
  fi
fi

if [[ "$KEEP_MODULE_CONFIG" == 'true' || "$KEEP_AGH_DATA" == 'true' ]]; then
  preserve_configuration_installation
else
  directly_unzip
fi

log '正在授权给指定文件……' 'Authorizing the specified file...'

# 文件夹 | 文件
# 750: RWX/RX/--- | 640: RW/R/---
set_perm_recursive "$MODPATH" 0 0 0750 0640
find "$MODPATH" -type f -name '*.sh' -exec chmod 0740 {} \;
chmod 0740 "$MODPATH/agh_work/AdGuardHome"

log '授权完成' 'Authorization completed'
log '安装完成' 'Installation completed'
log '请重启设备以便模块初始化' 'Please restart the device to allow the module to initialize'