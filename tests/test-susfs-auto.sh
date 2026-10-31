#!/bin/sh
set -eu
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT HUP INT TERM
mkdir -p "$dir/state"
printf '%s\n' '6.6.147-android15-9' > "$dir/kernel"
cat > "$dir/susfs" <<'EOF'
#!/bin/sh
case "$*" in
 'show version') printf '%s\n' v3.2.0 ;;
 'show variant') printf '%s\n' GKI ;;
 'show enabled_features')
   if [ -f "$BRENE_AUTO_FEATURE_FIXTURE" ]; then cat "$BRENE_AUTO_FEATURE_FIXTURE"; fi ;;
 'hide_sus_mnts_for_non_su_procs 1') printf '%s\n' 'applied' >> "$BRENE_AUTO_CALL_LOG" ;;
 *) exit 1 ;;
esac
EOF
chmod 700 "$dir/susfs"
printf '%s\n' 'CONFIG_KSU_SUSFS_SUS_MOUNT' 'CONFIG_KSU_SUSFS_SUS_MAP' 'CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT' > "$dir/features"
printf '%s\n' 'config_susfs_auto_enable=1' 'config_hide_sus_mnts_for_non_su_procs=1' > "$dir/state/config.sh"
export BRENE_AUTO_TEST=1 BRENE_AUTO_BASE="$dir/state" BRENE_AUTO_BIN="$dir/susfs"
export BRENE_AUTO_KERNEL="$dir/kernel" BRENE_AUTO_FEATURE_FIXTURE="$dir/features" BRENE_AUTO_CALL_LOG="$dir/calls"
auto=module/tools/susfs-auto.sh
sh "$auto" install
test -s "$dir/state/auto-profile.txt"
grep -Fq 'SuSFS：v3.2.0' "$dir/state/auto-profile.txt"
grep -Fxq 'CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT' "$dir/state/auto-features.list"
test -s "$dir/state/auto-signature.txt"
sig=$(cat "$dir/state/auto-signature.txt")
sh "$auto" probe
test "$(cat "$dir/state/auto-signature.txt")" = "$sig"
sh "$auto" early
test "$(grep -c '^applied$' "$dir/calls")" = 1
# User disables mount visibility: do not apply again.
sed -i 's/config_hide_sus_mnts_for_non_su_procs=1/config_hide_sus_mnts_for_non_su_procs=0/' "$dir/state/config.sh"
sh "$auto" early
test "$(grep -c '^applied$' "$dir/calls")" = 1
# Unsupported kernel: preserve user config and fail closed.
printf '%s\n' 'CONFIG_KSU_SUSFS_SUS_MAP' > "$dir/features"
sed -i 's/config_hide_sus_mnts_for_non_su_procs=0/config_hide_sus_mnts_for_non_su_procs=1/' "$dir/state/config.sh"
sh "$auto" early
test "$(grep -c '^applied$' "$dir/calls")" = 1
test "$(cat "$dir/state/auto-signature.txt")" != "$sig"
# Kernel fingerprint change must be discovered automatically.
before=$(cat "$dir/state/auto-signature.txt")
printf '%s\n' '6.6.201-android15-9' > "$dir/kernel"
sh "$auto" late
test "$(cat "$dir/state/auto-signature.txt")" != "$before"
# Unknown/absent capability response must never enable a hidden setting.
: > "$dir/features"
before=$(cat "$dir/state/auto-signature.txt")
sh "$auto" early
test "$(cat "$dir/state/auto-signature.txt")" = "$before"
test "$(grep -c '^applied$' "$dir/calls")" = 1
# User opt-out survives reboot; no capabilities used to override it.
printf '%s\n' 'CONFIG_KSU_SUSFS_SUS_MOUNT' > "$dir/features"
sed -i 's/config_susfs_auto_enable=1/config_susfs_auto_enable=0/' "$dir/state/config.sh"
sh "$auto" early
test "$(grep -c '^applied$' "$dir/calls")" = 1
sh "$auto" status | grep -Fq '状态：'
printf '%s\n' 'PASS: install negotiation, persistence, kernel changes, manual opt-out, fail-closed'
