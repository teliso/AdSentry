#!/system/bin/sh

start_agh () {
  local error

  # 导出证书目录
  export SSL_CERT_DIR="/system/etc/security/cacerts"

  if ! error=$("$AGH_BIN_FILE" -w "$AGH_WORK_DIR" --check-config 2>&1 >/dev/null); then
    log_error "AdGuardHome 配置文件有误：$error" "The AdGuardHome configuration file is corrupted: $error"
    return 1
  fi

  log_info "正在启动 AdGuardHome……" "Starting AdGuardHome..."

  if get_agh_pid; then
    log_info "已经有 AdGuardHome 进程，无需再启动" "The AdGuardHome process already exists, so there's no need to start it again"
    return
  fi

  su "$RUNNING_USER" -g "$RUNNING_GROUP" -c "$AGH_STARTUP_CMD" >/dev/null 2>&1 &

  # 等待 AdGuardHome 上线，最多等 5 秒
  local timeout=5
  local success="false"
  while [[ $timeout -gt 0 ]]; do
    # busybox wget使用的是KernelSU携带的busybox
    if busybox wget -q --spider "http://127.0.0.1:$WEB_PORT/"; then
      success="true"
      break # 成功了就跳出循环
    fi
    sleep 1
    timeout=$((timeout - 1))
  done

  # 循环结束后做最终判断
  if [[ "$success" == "false" ]]; then
    log_error "AdGuardHome 启动失败，请打开 shell 手动运行：$AGH_STARTUP_CMD，然后查看错误" "If AdGuardHome fails to start, please open a shell and manually run: $AGH_STARTUP_CMD, then check the error."
    return 1
  fi

  log_info "AdGuardHome 启动成功" "Starting AdGuardHome..."
}

stop_agh() {
  log_info "正在停止 AdGuardHome……" "Stopping AdGuardHome..."

  # 匹配进程获取 pid
  local agh_pid
  if ! agh_pid=$(get_agh_pid); then
    log_info "未找到运行中的 AdGuardHome 进程" "No running AdGuardHome process found"
    return
  fi

  local error

  # 停止进程
  if is_process_running "$agh_pid"; then
    log_info "发送终止信号给 AdGuardHome (PID=$agh_pid)" "Sending TERM signal to AdGuardHome (PID=$agh_pid)"
    if ! error=$(kill "$agh_pid" 2>&1); then
      log_error "AdGuardHome 停止失败，请手动停止：$error" "AdGuardHome failed to stop; please stop it manually: $error"
      return 1
    fi

    # 等待 5 秒
    local timeout=5
    while is_process_running "$agh_pid" && [ $timeout -gt 0 ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    # 强制终止
    if is_process_running "$agh_pid"; then
      log_info "AdGuardHome 未退出，强制终止 (PID=$agh_pid)" "AdGuardHome not logged out, forced termination (PID=$agh_pid)"
      if ! error=$(kill -9 "$agh_pid" 2>&1); then
        log_error "AdGuardHome 强制停止失败，请手动停止：$error" "Forced shutdown of AdGuardHome failed. Please stop manually: $error"
        return 1
      fi
    fi

    if is_process_running "$agh_pid"; then
      log_error "尝试停止 AdGuardHome 失败，请手动停止" "Attempt to stop AdGuardHome failed; please stop it manually"
      return 1
    fi
    log_info "AdGuardHome 停止成功" "AdGuardHome stopped successfully"
  else
    log_info "找到进程，但是进程已不存在 (PID=$agh_pid)" "The process was found, but it no longer exists (PID=$agh_pid)."
  fi
}