# AdSentry

[English](https://github.com/teliso/AdSentry/blob/main/docs/README_EN.md)

一个基于 KernelSU 和 AdGuardHome 的 DNS 过滤模块。模块在设备上运行 AdGuardHome，并通过 iptables / ip6tables 把本机发出的 DNS 请求（53 端口）转发给 AdGuardHome，从而实现全局广告和跟踪器过滤。

## 特点

* 使用 KernelSU 的模块配置功能管理配置。修改模块目录下的 `config.sh` 并保存后，会自动更新配置并重启 AdSentry。
* 动态更新模块描述，显示运行状态：日志开关、防火墙规则开关、AdGuardHome 版本和 PID，以及当前生效的防火墙规则。
* IPv4 / IPv6 的转发和拒绝规则可以分别对 UDP、TCP 单独配置。
* 启动失败或配置有误时，模块描述会显示错误提示，详细原因写入日志。
* 自动识别系统语言，输出信息支持中文和英文。

## 要求

* 已安装 [KernelSU](https://kernelsu.org/)，且版本支持模块配置功能（`ksud module config`）
* arm64 或 armv7 设备
* 系统提供 `iptables` 或 `ip6tables`；转发规则需要 nat 表支持

## 安装

1. 从 [Releases](https://github.com/teliso/AdSentry/releases) 下载与设备架构对应的压缩包（`AdSentry_arm64.zip` 或 `AdSentry_armv7.zip`）。
2. 在 KernelSU 管理器中安装模块。
3. 如果是覆盖安装，安装过程中会用音量键询问（10 秒无操作默认为“是”）：
   * 是否保留旧模块的 `config.sh`
   * 是否保留旧 AdGuardHome 的数据（`data` 目录和 `AdGuardHome.yaml`）
4. 重启设备。模块会在开机时初始化配置并自动启动。

## 使用

* **启动 / 停止**：在 KernelSU 管理器中点击模块的操作按钮，可在启动和停止之间切换。
* **AdGuardHome 后台**：`http://127.0.0.1:3000/`，默认账户 `admin`，密码 `admin`。建议登录后立即修改密码。
* **修改配置**：编辑模块目录（`/data/adb/modules/AdSentry`）下的 `config.sh`，保存后自动生效。

## 配置说明

所有配置项都在 `config.sh` 中，布尔值只能是 `'true'` 或 `'false'`。

| 配置项 | 默认值 | 说明 |
| --- | --- | --- |
| `enable_module_log` | `false` | 是否记录日志。关闭时仍会记录错误日志 |
| `enable_firewall_rules` | `true` | 是否应用防火墙规则。关闭后只运行 AdGuardHome，不转发流量 |
| `ipv4_target_port` / `ipv6_target_port` | `35533` | DNS 流量转发的目标端口，需与 `AdGuardHome.yaml` 中的 DNS 监听端口一致 |
| `web_port` | `3000` | AdGuardHome 网页端口，需与 `AdGuardHome.yaml` 一致，否则会判定启动失败 |
| `running_user` / `running_group` | `0` / `3004` | 运行 AdGuardHome 的用户和组（0 为 root，3004 为 net_raw）。该用户和组的流量不会被转发，避免回环 |
| `ipv4_return_dst_list` / `ipv6_return_dst_list` | 空 | 不转发的目标地址，多个地址用空格分隔，例如 `'192.168.1.1 10.0.0.0/8'` |
| `ipv4_redirect_udp_53` / `ipv4_redirect_tcp_53` | `true` / `true` | 是否把 IPv4 的 UDP / TCP 53 端口流量转发给 AdGuardHome |
| `ipv4_reject_udp_53` / `ipv4_reject_tcp_53` | `false` / `false` | 是否拒绝 IPv4 的 UDP / TCP 53 端口流量 |
| `ipv6_redirect_udp_53` / `ipv6_redirect_tcp_53` | `false` / `false` | 是否把 IPv6 的 UDP / TCP 53 端口流量转发给 AdGuardHome |
| `ipv6_reject_udp_53` / `ipv6_reject_tcp_53` | `true` / `true` | 是否拒绝 IPv6 的 UDP / TCP 53 端口流量 |

默认配置下，IPv4 DNS 请求会转发给 AdGuardHome，IPv6 DNS 请求会被拒绝，使系统回落到 IPv4 DNS，避免 DNS 请求绕过过滤。

转发和忽略列表作用于 nat 表，拒绝规则作用于 filter 表。如果设备的 iptables / ip6tables 不支持 nat 表，转发规则会被跳过，拒绝规则仍然生效。

## 模块描述

模块启动后，描述会显示类似下面的内容：

```
Log 🚫 | Rules ✅ | AGH: v0.107.xx - PID: 12345
Net 4: UDP ↩️ TCP ↩️ | ↪️ 35533 | UDP ➡️ TCP ➡️
Net 6: UDP ➡️ TCP ➡️ | ↪️ 35533 | UDP 🚫 TCP 🚫
```

* 第一行：日志开关、防火墙规则开关、AdGuardHome 版本和 PID
* `Net 4` / `Net 6`：竖线前是转发规则，中间是转发目标端口，竖线后是拒绝规则
* ✅ 已开启，🚫 已关闭或已拒绝，↩️ 转发给 AdGuardHome，➡️ 放行

如果描述以 ❌ 开头，说明读取配置、启动或停止时出错，请查看日志。

## 日志

日志文件位于模块目录下的 `as.log`。即使关闭了日志，错误信息也会写入该文件。

## 自行打包

1. 克隆本仓库。
2. 从 [AdGuardHome Releases](https://github.com/AdguardTeam/AdGuardHome/releases) 下载对应架构（linux_arm64 或 linux_armv7）的 AdGuardHome，把二进制文件和 `AdGuardHome.yaml` 放入 `agh_work` 目录，**文件名不能改**。
3. 确认 `AdGuardHome.yaml` 中的 DNS 端口和网页端口与 `config.sh` 中的 `ipv4_target_port` / `ipv6_target_port` 和 `web_port` 一致。
4. 把仓库根目录下的文件打包成 zip（`module.prop` 位于压缩包根目录），`version` 目录不需要打包。

## 感谢

想法源于：[twoone-3/AdGuardHomeForRoot](https://github.com/twoone-3/AdGuardHomeForRoot)

功能支持：[AdguardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)
