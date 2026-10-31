# BRENE v0.0.78-dev — SuSFS 二进制在线更新

## 固定可信上游
- 仓库：https://github.com/sidex15/susfs4ksu-binaries
- 分支：universal-binary
- 固定上游提交：041f69d7fe23a7bd928f9bd90eb3535774d00456
- 文件：ksu_susfs_arm64 （ARM64 ELF）
- 固定 SHA-256：8a626ce3bae27a7bcaa2e7f5f7b91e786ecc57f8e57d19c7856719a89b54b6fa

固定提交不等于永久自动追随最新分支：新的上游二进制必须先更新本仓库固定 SHA-256 并重新运行 CI，防止自动执行未知 root ELF 文件。

## 安装自动流程
1. 安装时自动访问固定可信提交，支持 curl、系统 wget、BusyBox wget；不使用 --no-check-certificate。
2. 下载后限制大小，并验证固定 SHA-256、64-bit AArch64 ELF 格式。
3. 通过摘要和架构检查后，才允许用 show version / variant / enabled_features 进行只读运行时检查；若现有工具可用，再要求版本、变体、功能集合保持一致。
4. 下载或兼容检查失败时回退到当前可用工具或模块自带工具。没有兼容选项时中止安装，不覆盖共享目录。
5. 首次外部二进制保留在 /data/adb/brene/susfs.previous，上一版保存在 susfs.rollback，更新在同目录暂存后原子替换。
6. 安装完成立即复核，生成内核能力持久化记录。开机完成后在后台限流检查；当前版本已匹配可信摘要时不再联网。

## WebUI
在 内核 → SuSFS → 二进制更新 中可以看状态、关闭自动更新、检查可信版本、立即更新、恢复上一版本。手动更新独立于自动开关；回滚自动暂停下一次启动的更新。

## 边界
- 该工具不执行未经认可的 latest 分支提交；需要在后续 BRENE 版本中重新固定上游摘要。
- CI 额外从固定上游提交下载文件，核对 SHA-256 和 ELF 架构；不在 CI 中执行 ARM64 二进制。
- Android 无可验证 HTTPS 下载工具时，退回离线安装；不要求 Termux。
- 通过 ABI 检查不代表所有 SuSFS 3.2.0 内核能力已真机验证。
