#!/system/bin/sh

readonly MODULE_DIR="${0%/*}"
export MODULE_DIR
readonly SCRIPTS_DIR="$MODULE_DIR/scripts"

LANGUAGE="zh"

# 依次尝试系统语言属性
locale=$(getprop persist.sys.locale 2>/dev/null)
[[ -z "$locale" ]] && locale=$(getprop ro.product.locale 2>/dev/null)
[[ -z "$locale" ]] && locale=$(getprop persist.sys.language 2>/dev/null)

# 如果获取到的语言前两位是 en，就切换为英文
[[ "$locale" == en* ]] && LANGUAGE="en"

readonly LANGUAGE

_print_() {
  local message

  [[ "$LANGUAGE" == "zh" ]] && message="[AS]: $1" || message="[AS]: $2"
  echo "$message"
}

if [[ -f "$MODULE_DIR/running" ]]; then
  _print_ "AdSentry 正在运行，执行停止操作" "AdSentry is running; execute a stop operation"
  "$SCRIPTS_DIR/ad_sentry.sh" stop
else
  _print_ "AdSentry 未运行，执行启动操作" "AdSentry is not running; perform the startup operation."
  "$SCRIPTS_DIR/ad_sentry.sh" start
fi

_print_ "如果模块描述显示错误信息，请按要求解决错误" "If the module description displays an error message, please resolve the error as required"

sleep 3