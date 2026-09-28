## VersionCode: 20260928 - Version: 1.0.4

### 改变 / Changes

* 修复 ipv4_return_dst_list / ipv6_return_dst_list 配置不生效的问题
* Fixed ipv4_return_dst_list / ipv6_return_dst_list having no effect
* 修复移除防火墙规则时错误信息丢失的问题
* Fixed error messages being lost when removing firewall rules
* 设备不支持 nat 表时跳过转发规则，照常应用拒绝规则，不再导致启动失败
* When the nat table is not supported, redirect rules are skipped and reject rules still apply, instead of failing to start
* 覆盖安装时，旧模块中缺少要保留的文件不再中止安装
* Upgrading no longer aborts when a file to be kept is missing from the old module
* 修复安装脚本的系统语言检测
* Fixed system language detection in the installer
* 重构模块脚本，精简重复代码
* Refactored the module scripts and removed duplicated code
* 完善 README
* Improved the README
