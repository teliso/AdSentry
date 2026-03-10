#!/system/bin/sh

readonly SCRIPTS_DIR="${0%/*}"
# 加载 tool.sh，先导出环境使用的语言和时区
. "$SCRIPTS_DIR/tools.sh"
export_language
export_time_zone

. "$SCRIPTS_DIR/agh.sh"
. "$SCRIPTS_DIR/firewall.sh"

readonly AGH_WORK_DIR="$MODULE_DIR/agh_work"
readonly AGH_BIN_FILE="$AGH_WORK_DIR/AdGuardHome"
readonly AGH_STARTUP_CMD="$AGH_BIN_FILE -w $AGH_WORK_DIR"

. "$SCRIPTS_DIR/update_description.sh"
. "$SCRIPTS_DIR/log.sh"

# 读取配置，如果配置不满足要求则更新模块描述并直接退出脚本
if ! . "$SCRIPTS_DIR/read_config.sh"; then
  update_description_with_flag "read_config"
  exit 1
fi

start_ad_sentry() {
  local error_flag="false"

  local supported_firewall_tools
  if ! supported_firewall_tools=$(get_supported_firewall_tools); then
    log_error "没有找到 iptables 和 ip6tables 其中的任何一个，模块无法工作" "The module cannot function because neither iptables nor ip6tables was found."
    error_flag="true"
  fi

  # 子进程启动 AdGuardHome
  if [[ "$error_flag" == "false" ]]; then
    log_info "正在启动 AdSentry……" "Starting AdSentry..."
    if ! start_agh; then
      error_flag="true"
    fi
  fi

  if [[ "$error_flag" == "false" ]]; then
    if [[ "$ENABLE_FIREWALL_RULES" == "true" ]]; then
      if ! add_configuration "$supported_firewall_tools"; then
        stop_agh
        error_flag="true"
      fi
    else
      log_info "已设置不添加防火墙规则，跳过添加防火墙规则" "Firewall rule addition is already configured to be skipped."
    fi
  fi

  if [[ "$error_flag" == "true" ]]; then
    log_info "AdSentry启动失败，请解决（手动）错误以后再试" "AdSentry failed to start. Please resolve the error manually and try again later"
  else
    log_info "AdSentry启动成功" "AdSentry started successfully"
    : > "$MODULE_DIR/running"
  fi

  # 更新模块的描述
  update_description_with_flag "start_as"
}

restart_ad_sentry() {
  log_info "正在执行 AdSentry 重启……" "Performing reboot..."
  
  stop_ad_sentry
  start_ad_sentry

  log_info "AdSentry 重启完成" "Restart completed"
}

stop_ad_sentry() {
  local error_flag="false"

  log_info "正在停止 AdSentry……" "Stopping AdSentry..."
  if ! stop_agh; then
    error_flag="true"
  fi

  local supported_firewall_tools
  if supported_firewall_tools=$(get_supported_firewall_tools); then
    if ! remove_configuration "$supported_firewall_tools"; then
      error_flag="true"
    fi
  else
    log_info "没有找到 iptables 和 ip6tables 其中的任何一个，无需删除防火墙规则" "Neither iptables nor ip6tables was found, so there is no need to delete firewall rules"
  fi

  if [[ "$error_flag" == "false" ]]; then
    log_info "AdSentry 停止成功" "AdSentry stopped successfully"
    rm -f "$MODULE_DIR/running"
  else
    log_info "停止 AdSentry 时出错，请一定要（手动）解决出现的错误，否则模块无法启动" \
      "An error occurred while stopping AdSentry. Please be sure to resolve the error manually, Otherwise the module cannot start"
  fi

  # 更新模块描述
  update_description_with_flag "stop_as"
}

case "$1" in
  start)
    start_ad_sentry
    ;;
  restart)
    restart_ad_sentry
    ;;
  stop)
    stop_ad_sentry
    ;;
  *)
    log_info "用法：$0 {start|restart|stop}" "Usage: $0 {start|restart|stop}"
    ;;
esac