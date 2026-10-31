# BRENE SuSFS 对照与补齐（v0.0.76-dev）

## 参考实现

- [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module)：运行时功能开关、userspace auto try_umount、合法挂载排除、配置导入导出。
- [ahmed-alnassif/ReSuSFS](https://github.com/ahmed-alnassif/ReSuSFS)：功能仪表盘、配置备份/恢复、用户脚本管理。
- [ifoknr/NextSUSFS](https://github.com/ifoknr/NextSUSFS)：规则管理、状态诊断和备份恢复。

仅参考用户体验与能力分类，没有复制第三方项目受版权保护的源代码。

## 已补齐

1. **只读内核能力报告**：`module/tools/susfs-capability-audit.sh`，从当前 SuSFS CLI 查询真实版本、变体和编译功能列表。未报告 != 绝对不支持。不会运行任何修改内核状态的命令。
2. **本地配置快照与恢复**：`module/tools/susfs-snapshot.sh`，白名单文件、私有目录、64 KiB 单文件限制、防止快照路径穿越、恢复前自动备份当前配置。没有自动上传或任意外部归档导入。
3. **Mount 排除列表**：`/data/adb/brene/mount-hide-exclude.txt`，每行绝对路径；末尾 `/` 是目录前缀。预览中明确标出“排除”和“温控保护”，实际应用不会提交已排除项。
4. **防止启动脚本长时间阻塞**：共享存储不可用时最多等待 12 秒后继续执行其他操作，避免导致后续内核规则完全不执行。
5. **保留 BRENE 既有中文/英文 WebUI 和原五项底栏导航**，新增功能在「内核 → SuSFS」，不改变现有规则文件结构。

## 暂未补齐（不能只在用户态可靠实现）

- **自动标记 SUS_MOUNT / Bind Mount**：依赖特定内核编译功能，必须检查 `CONFIG_KSU_SUSFS_AUTO_ADD_*`；不能把 WebUI 按钮当成内核实现。
- **zygote_next 隔离服务强制卸载**：旧版 SuSFS 有过独立 CLI 命令，但不能假定 SuSFS v2.1+/v2.3+ 或用户声称的 3.2.0 仍兼容。
- **完整 userspace auto try_umount**：BRENE 既有版本只提供 opt-in 的 Lucky_Control 定向规则；不把所有模块的挂载通配加入内核 Umount 列表，以防 GPU 驱动、相机和温控失效。
- **任意脚本调度、导入外部配置、自动更新二进制**：未经完整安全审查的导入或脚本执行会扩大模块攻击面，因此当前没有加入。

## 安装与验证

从 `Zhanfg/BRENE` Draft PR #1 开发分支的 GitHub Actions 获取 **BRENE-Flashable-Dev.zip**。
安装后进入 **概览 → 挂载管理 / 内核 → SuSFS**：先刷新能力、备份当前配置、预览挂载候选、配置排除规则，再决定是否开启可选规则。
真正的 root/Mount 检测结果必须用实际 OnePlus PJZ110 的 Android 17 隔离进程复测，CI 只能覆盖脚本与模拟 WebUI。
