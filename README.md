## 说明

一个基于KernelSU和AdGuardHome的DNS过滤模块。

如果你想自己打包，你需要把AdGuardHome二进制文件放在AGH目录下。

> [!WARNING]
> 由于是第一版，所以还没有测试通过管理器更新是否可行，可能有错误，反正目前手动安装是可以正常运行的。
>
> 忽略源地址和目标地址可能无法正常工作，因为我用不到所以暂时没有测试。

## 特点

* 使用KernelSU提供的模块配置功能管理配置，要修改配置可以修改模块目录下config.sh文件，修改保存后可以自动触发配置更新和重启AdSentry。
* 禁用开关和切换按钮可以动态启动/关闭AdSentry。
* 动态更新描述，显示模块运行信息，包括AdGuardHome的PID和是否丢弃IPv6 DNS请求。
* 模块全局日志（不含AdGuardHome）输出支持自动识别系统语言，但仅支持输出为中文和英文。

## 配置

| 配置项 | 说明 |
| ---- | ---- |
| time_zone | 运行环境的时区，默认使用系统时区 |
| target_port | 转发的目标端口 |
| enables_log | 是否启用日志输出，位于模块目录下ad_sentry.log |
| drop_ipv6_dns | 是否丢弃IPv6 DNS请求，默认丢弃 |
| ignore_src_list | 忽略的源地址，默认无，请以空格隔开iptables可识别的地址格式 |
| ignore_dest_list | 忽略的目标地址，默认无，同上 |

## 感谢

想法源于：[twoone-3/AdGuardHomeForRoot](https://github.com/twoone-3/AdGuardHomeForRoot)