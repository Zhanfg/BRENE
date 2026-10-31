#!/bin/sh
set -eu
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/state"
cat > "$work/susfs" <<'EOF'
#!/bin/sh
case "$*" in
 "show version") printf '%s\n' v2.3.0;;
 "show variant") printf '%s\n' GKI;;
 "show enabled_features") printf '%s\n' CONFIG_KSU_SUSFS_SUS_MAP CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT;;
 *) exit 1 ;;
esac
EOF
chmod 755 "$work/susfs"
BRENE_TESTING=1 BRENE_TEST_SUSFS="$work/susfs" sh module/tools/susfs-capability-audit.sh > "$work/audit"
grep -q 'SuSFS 内核版本: v2.3.0' "$work/audit"
grep -q 'AUTO_ADD_SUS_BIND_MOUNT: 支持' "$work/audit"
grep -q 'TRY_UMOUNT: 未报告' "$work/audit"
printf '%s\n' 'config_kernel_umount=1' > "$work/state/config.sh"
printf '%s\n' '/vendor/etc/camera/' > "$work/state/mount-hide-exclude.txt"
id=$(BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" sh module/tools/susfs-snapshot.sh backup)
echo "$id" | grep -Eq '^[0-9]{8}_[0-9]{6}(_[0-9]+)?$'
printf '%s\n' 'config_kernel_umount=0' > "$work/state/config.sh"
BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" sh module/tools/susfs-snapshot.sh restore "$id" > "$work/restore"
grep -qx 'config_kernel_umount=1' "$work/state/config.sh"
grep -qx '/vendor/etc/camera/' "$work/state/mount-hide-exclude.txt"
if BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" sh module/tools/susfs-snapshot.sh restore ../../etc/passwd >/dev/null 2>&1; then
 echo 'unsafe snapshot path accepted' >&2; exit 1
fi
printf '%s\n' 'PASS: read-only feature matrix and local snapshot restore'
