## 说明

[README_EN](https://github.com/teliso/AdSentry/blob/main/docs/README_EN.md)

一个基于 KernelSU 和 AdGuardHome 的 DNS 过滤模块。

如果你想自己打包，你需要把 AdGuardHome 二进制文件和 AdGuardHome.yaml 配置文件放在 `agh_work `目录下且**文件名不能变**。

切换按钮可以启动或者关闭 AdSentry。

模块中的 AdGuardHome 的默认后台是：`http://127.0.0.1:3000/`

账户：`admin`

密码：`admin`

## 特点

* 使用 KernelSU 提供的模块配置功能管理配置，要修改配置可以修改模块目录下的 `config.sh` 文件，修改保存后可以自动触发配置更新和重启 AdSentry。
* 动态更新模块描述，显示模块运行信息，包括：
  - 模块日志
  - 是否应用防火墙规则
  - AdGuardHome 的版本和 PID
  - 读取到的防火墙规则
* 更灵活的模块配置，更精细的日志输出。
* 模块信息输出支持自动识别系统语言，但仅支持输出为中文和英文。

## 感谢

想法源于：[twoone-3/AdGuardHomeForRoot](https://github.com/twoone-3/AdGuardHomeForRoot)

功能支持：[AdguardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)