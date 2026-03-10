#!/system/bin/sh

export_language() {
  local language='zh'

  # 依次尝试系统语言属性
  local locale
  locale=$(getprop persist.sys.locale 2>/dev/null)
  [[ -z "$locale" ]] && locale=$(getprop ro.product.locale 2>/dev/null)
  [[ -z "$locale" ]] && locale=$(getprop persist.sys.language 2>/dev/null)

  # 如果获取到的语言前两位是 en，就切换为英文
  [[ "$locale" == en* ]] && language='en'

  readonly LANGUAGE="$language"
  export LANGUAGE
}

export_time_zone() {
  # 首先尝试系统时区
  local sys_tz
  sys_tz=$(getprop persist.sys.timezone 2>/dev/null)
  
  if [[ "$sys_tz" ]]; then
    readonly TZ="$sys_tz"
    export TZ
    return
  fi

  # 如果系统时区不可用，回退到 UTC
  readonly TZ='UTC'
  export TZ
}

get_agh_pid() {
  # 通过启动命令匹配 AdGuardHome 进程，AGH_STARTUP_CMD 来自加载该文件的 Shell Script
  local pid
  pid=$(pgrep -f "$AGH_STARTUP_CMD" | head -n1)

  if [[ -z "$pid" ]]; then
    return 1
  fi

  echo "$pid"
}

is_process_running() {
    local pid="$1"

    # 返回值：运行中返回 0，未运行返回 1
    [[ "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

get_supported_firewall_tools() {
  local tools

  which iptables >/dev/null 2>&1 && tools='iptables'
  
  if which ip6tables >/dev/null 2>&1; then
    if [[ "$tools" ]]; then
      tools="$tools ip6tables"
    else
      tools='ip6tables'
    fi
  fi

  if [[ -z "$tools" ]]; then
    return 1
  fi

  echo "$tools"
}