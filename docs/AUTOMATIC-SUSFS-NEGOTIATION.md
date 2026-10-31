# BRENE v0.0.77-dev：安装与开机自动适配

## 运行顺序

1. **安装期 `customize.sh`**：保留原配置后立即读取捆绑的 SuSFS CLI；验证内核版本/变体/`show enabled_features`，将结果写入 `/data/adb/brene/auto-profile.txt`、`auto-features.list` 和 `auto-signature.txt`。原配置不会被自动重置。
2. **早期启动 `post-fs-data.sh`**：在 Zygote 启动前重新探测；仅当内核报告 `CONFIG_KSU_SUSFS_SUS_MOUNT` 且 `config_hide_sus_mnts_for_non_su_procs=1` 时启用非 SU Mount 视图隐藏。失败则跳过自动操作。
3. **挂载完成 `post-mount.sh`**：在 KernelSU/MetaModule 完成挂载后更新自动诊断候选；仅在用户此前明确启用 `config_mount_hide_auto_bind=1` 时才提交 KernelSU per-process Umount 规则。
4. **开机完成 `boot-completed.sh`**：再次复核内核/CLI 版本和编译能力；内核变化自动生成新指纹，完整能力档案继续保留。

## 自动规则与用户优先级

- 新配置项 `config_susfs_auto_enable=1`：默认开启。用户可以通过 BRENE WebUI 关闭，升级时不覆盖其选择。
- 支持的 `SUS_PATH`、`SUS_MAP`、`OPEN_REDIRECT` 等既有规则由用户原始文件决定，自动探测负责跳过内核未报告的功能，不主动创建可能破坏兼容性的隐藏规则。
- `AUTO_ADD_*MOUNT` 属于内核编译期功能，模块只能识别和报告，不能通过 shell 假装编译进去。
- KernelSU Umount、温控节点、GPU 驱动、相机等高风险挂载**不会因自动适配而被额外卸载**。
- 探测失败时不抹掉旧配置、也不调用未知内核 ABI；`auto-status.txt` 保存最近一次错误，避免历史成功报告误导用户。

## 持久化与恢复

- 根目录 `/data/adb/brene` 权限设为 0700，自动档案权限 0600。能力列表为数据文件，不会作为 shell 代码执行。
- `auto-profile.txt` 包含过滤后的内核 release、SuSFS 版本、变体、能力计数和策略解释；不写入设备 ID、密钥、Token 或完整系统属性。
- 新内核、SuSFS 版本、变体或能力列表发生变化时自动更新签名，不需手工运行探测命令。
- 配置修改出错仍可使用 BRENE WebUI 的本地快照恢复；清除能力档案不影响用户自定义规则。

## 兼容性边界

- 仅在当前 CLI 能正常报告内核接口与实际能力列表后执行安全自动策略。SuSFS `v3.2.0` 版本字符串本身不证明所有旧 CLI 命令都兼容。
- `zygote_next` 隔离进程中能否完整隐藏 Mount 记录仍需 PJZ110 真机验证；CI 的 Shell Mock 与 Chromium 测试无法证明隐藏效果。
- KernelSU 安装钩子及 `post-fs-data`、`post-mount`、`boot-completed` 生命周期参见 https://kernelsu.org/guide/module.html 。
