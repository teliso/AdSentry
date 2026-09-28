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

----

## VersionCode: 20260413 - Version: 1.0.3

### 改变 / Changes

* 修复 inotifyd.sh 中的判断条件
* Fix the conditional statement in inotifyd.sh
* 优化模块描述
* Optimization Module Description
* 修复模块配置功能
* Fixed the module configuration feature

----

## VersionCode: 20260310 - Version: 1.0.2

### 改变 / Changes

* 改用语义化版本
* Switch to a semantic version
* 修复 AdGuardHome 的自动更新，不再依赖模块集成新版本
* Fix AdGuardHome's automatic updates, no longer relying on modules to integrate new versions
* 优化模块整体代码
* Optimize the overall module code
* 默认集成 AdGuardHome v0.107.72
* AdGuardHome v0.107.72 is integrated by default

### 备注 / Remark

AdGuardHome 的自动更新因中国网络问题可能需要开启网络代理。

AdGuard Home's automatic updates may require enabling a network proxy due to China's network issues.

如果空间紧张，AdGuardHome 自动更新成功以后，可以自行去模块目录删除 agh_work/agh-backup。

If space is tight, after AdGuardHome successfully updates automatically, you can delete agh_work/agh-backup from the module directory by yourself.

----

## VersionCode: 20260105 - Version: 0.1.1

### 改变

* 修复自定义安装过程脚本错误
* 移除自定义时区功能
* 修复AdSentry启动脚本错误

### 备注

现在应该可以通过管理器自动更新到新版本，也可以手动覆盖安装，都可以选择保留旧配置或者不保留。

----

## VersionCode: 20260103 - Version: 0.1.0

### 备注

首版发布，目前运行没有问题。