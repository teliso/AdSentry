## VersionCode: 20260310 - Version: 1.0.2

### 改变

* 改用语义化版本
* 修复 AdGuardHome 的自动更新，不再依赖模块集成新版本
* 优化模块整体代码
* 默认集成 AdGuardHome v0.107.72

### 备注

AdGuardHome 的自动更新因中国网络问题可能需要开启网络代理。

如果空间紧张，AdGuardHome 自动更新成功以后，可以自行去模块目录删除 agh_work/agh-backup。