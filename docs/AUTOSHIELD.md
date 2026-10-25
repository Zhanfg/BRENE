# BRENE AutoShield — 自动规则引擎（开发版）

AutoShield 是本 Fork 新增的 **用户态自动候选发现/规则应用层**，不是新的 SuSFS 内核补丁，也不能打开编译时未启用的功能。

## 工作流程

- **发现（scan）**：仅检查 `/data/adb/modules/<id>/zygisk/*.so` 和子目录一层的 `.so` 原生库；不进行全盘扫描，不深入遍历无关目录。
- **筛选**：排除 `disable` / `remove` 标记模块、BRENE 自己、符号链接、不符合条件或过长的路径；最多 64 条。
- **预览**：写入 `/data/adb/brene/autoshield.candidates`，不调用内核隐藏命令。
- **应用（apply）**：只有配置 `config_auto_hide=1` 且内核确实报告 `SUS_MAP` 时，逐条执行 `susfs add_sus_map <absolute-path>`。
- **去重**：用 `/proc/sys/kernel/random/boot_id` 区分重启，仅记录当前开机已成功提交的路径，避免同一开机重复调用。
- **停止/回退**：WebUI “关闭自动应用”将配置设回 0；本次内核已设置的规则不会马上撤销，**重启后**不再由 AutoShield 重新应用。

### WebUI

SuSFS 页面 → AutoShield：
1. **扫描与预览**（默认、安全，绝不隐藏）；
2. **启用并应用**（确认内核报告 SUS_MAP，立即提交并在后续启动自动执行）；
3. **关闭自动应用**（停止后续规则提交，等待重启才撤销当前内核设置）。

规则文件独立于用户此前手工设置的 `custom_sus_map.txt`，不会覆盖原有手动规则。

## 边界

- **自动映射文件检测并不等于自动识别所有 Root 痕迹**，更不代表能绕过设备完整性校验。
- `SUS_MAP` 只针对与内核功能相匹配的映射路径，不解决其他进程、属性、挂载或内联 Hook 的问题。
- 驱动程序可能加载的路径不同于模块的磁盘路径，此时自动候选规则可能无效，需要实际调试。
- AutoShield 不删除任何文件、不会自动切换 SELinux 模式、不修改系统属性、不会添加 `SUS_PATH`/SUS_KSTAT。
- 真实设备兼容性与效果尚未验证。GitHub Actions 使用模拟的内核程序，不等同真机安装/隐藏测试。

测试：`sh tests/test-autoshield.sh`。开发版 ZIP 通过仓库的 `BRENE module CI` 构建。
