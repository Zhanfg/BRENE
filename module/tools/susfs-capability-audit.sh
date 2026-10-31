#!/system/bin/sh
# BRENE read-only SuSFS capability report (no kernel state changes)
BIN=/data/adb/ksu/bin/susfs
if [ "${BRENE_TESTING:-0}" = 1 ] && [ -n "${BRENE_TEST_SUSFS:-}" ]; then BIN="$BRENE_TEST_SUSFS"; fi
if [ ! -x "$BIN" ]; then printf '%s\n' '状态: 不可用（缺少可执行 SuSFS CLI）'; exit 1; fi
version=$("$BIN" show version 2>/dev/null) || version=
variant=$("$BIN" show variant 2>/dev/null) || variant=
features=$("$BIN" show enabled_features 2>/dev/null) || features=
[ -n "$version" ] || { printf '%s\n' '状态: SuSFS 内核接口未响应'; exit 1; }
printf 'SuSFS 内核版本: %s\n内核变体: %s\n' "$version" "${variant:-未知}"
printf '%s\n' '--- 内核编译能力（只读） ---'
for feature in SUS_MOUNT AUTO_ADD_SUS_KSU_DEFAULT_MOUNT AUTO_ADD_SUS_BIND_MOUNT AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT TRY_UMOUNT SUS_PATH SUS_PATH_LOOP SUS_MAP SUS_KSTAT OPEN_REDIRECT; do
 if printf '%s\n' "$features" | grep -Fqx "CONFIG_KSU_SUSFS_$feature"; then
   printf '%s: 支持\n' "$feature"
 else
   printf '%s: 未报告（不代表一定缺失）\n' "$feature"
 fi
done
printf '%s\n' '--- 适配说明 ---'
case "$version" in
 v1.*) printf '%s\n' '旧版接口：可能提供 Zygote isolation 相关独立命令；需检查实际 CLI 支持。' ;;
 v2.*|v3.*) printf '%s\n' '新版接口：不要直接复用旧版 isolation service 命令或标记文件。' ;;
 *) printf '%s\n' '无法识别版本：仅输出能力列表，不应用规则。' ;;
esac
printf '%s\n' '内核 AUTO_ADD_* 通常是编译时能力；BRENE 不会伪装成运行时可开启。'
printf '%s\n' '本报告不能证明单个应用命名空间中的 Mount 隐藏是否有效。'
