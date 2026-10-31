#!/bin/sh
set -eu
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/base" "$work/bin"
cat > "$work/bin/susfs" <<'EOF'
#!/bin/sh
case "$*" in
 'show version') echo v3.2.0;;
 'show variant') echo GKI;;
 'show enabled_features') echo CONFIG_KSU_SUSFS_SUS_MOUNT;;
 *) exit 1;;
esac
# old, bundled valid variant
EOF
cat > "$work/upstream" <<'EOF'
#!/bin/sh
case "$*" in
 'show version') echo v3.2.0;;
 'show variant') echo GKI;;
 'show enabled_features') echo CONFIG_KSU_SUSFS_SUS_MOUNT;;
 *) exit 1;;
esac
# trusted new version
EOF
chmod 755 "$work/bin/susfs" "$work/upstream"
printf '%s\n' 'config_susfs_binary_auto_update=1' > "$work/base/config.sh"
export BRENE_BIN_TEST=1 BRENE_BIN_BASE="$work/base"
export BRENE_BIN_INSTALLED="$work/bin/susfs" BRENE_BIN_FIXTURE="$work/upstream"
BRENE_BIN_PIN=$(sha256sum "$work/upstream" | awk '{print $1}')
export BRENE_BIN_PIN
manager=module/tools/susfs-bin-manager.sh
sh "$manager" check
choice=$(sh "$manager" select "$work/bin/susfs")
test "$choice" = "$work/base/susfs.selected"
cmp "$choice" "$work/upstream"
# Install-compatible fetched file must not be executed before hash verification.
sh "$manager" update
cmp "$work/bin/susfs" "$work/upstream"
test -f "$work/base/susfs.rollback"
grep -q 'old, bundled' "$work/base/susfs.rollback"
sh "$manager" scheduled
cmp "$work/bin/susfs" "$work/upstream"
sh "$manager" rollback
grep -q 'old, bundled' "$work/bin/susfs"
grep -qx 'config_susfs_binary_auto_update=0' "$work/base/config.sh"
# Re-enable then corrupt the pinned SHA: fail closed with original binary unchanged.
sed -i 's/config_susfs_binary_auto_update=0/config_susfs_binary_auto_update=1/' "$work/base/config.sh"
BRENE_BIN_PIN=ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
export BRENE_BIN_PIN
choice=$(sh "$manager" select "$work/bin/susfs")
test "$choice" = "$work/bin/susfs"
if sh "$manager" update; then
 echo 'ERROR: untrusted download accepted' >&2; exit 1
fi
grep -q 'old, bundled' "$work/bin/susfs"
# ABI mismatch must also fail even if the downloaded hash is pinned.
cat > "$work/wrong" <<'EOF'
#!/bin/sh
case "$*" in
 'show version') echo v3.2.0;;
 'show variant') echo NON-GKI;;
 'show enabled_features') echo CONFIG_KSU_SUSFS_SUS_MOUNT;;
 *) exit 1;;
esac
EOF
chmod 755 "$work/wrong"
BRENE_BIN_FIXTURE="$work/wrong"
BRENE_BIN_PIN=$(sha256sum "$work/wrong" | awk '{print $1}')
export BRENE_BIN_FIXTURE BRENE_BIN_PIN
if sh "$manager" update; then
 echo 'ERROR: incompatible kernel variant accepted' >&2; exit 1
fi
grep -q 'old, bundled' "$work/bin/susfs"
# No network fixture and disabled auto update still give a local selection.
sed -i 's/config_susfs_binary_auto_update=1/config_susfs_binary_auto_update=0/' "$work/base/config.sh"
choice=$(sh "$manager" select "$work/bin/susfs")
test "$choice" = "$work/bin/susfs"
echo 'PASS: download hash pin, ABI comparison, offline select, rollback, automatic pause'
