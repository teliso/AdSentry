#!/system/bin/sh

readonly MODULE_DIR="${0%/*}"
export MODULE_DIR
readonly SCRIPTS_DIR="$MODULE_DIR/scripts"

. "$SCRIPTS_DIR/tools.sh"
export_language

_print_() {
  if [[ "$LANGUAGE" == 'zh' ]]; then
    echo "[AS]: $1"
  else
    echo "[AS]: $2"
  fi
}

if [[ -f "$MODULE_DIR/running" ]]; then
  _print_ 'AdSentry 正在运行，执行停止操作' 'AdSentry is running; execute a stop operation'
  "$SCRIPTS_DIR/ad_sentry.sh" stop
else
  _print_ 'AdSentry 未运行，执行启动操作' 'AdSentry is not running; perform the startup operation.'
  "$SCRIPTS_DIR/ad_sentry.sh" start
fi

_print_ '如果模块描述显示错误信息，请按要求解决错误' 'If the module description displays an error message, please resolve the error as required'

sleep 3
