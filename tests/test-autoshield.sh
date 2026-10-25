#!/bin/sh
# Host-only deterministic AutoShield tests; no Android kernel or device touched.
set -eu
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
ROOT=$TMP/modules
DATA=$TMP/state
BIN=$TMP/susfs
TRACE=$TMP/trace
mkdir -p "$ROOT/alpha/zygisk" "$ROOT/bravo/zygisk/arm64" "$ROOT/disabled/zygisk" "$ROOT/brene/zygisk" "$DATA"
touch "$ROOT/alpha/zygisk/arm64-v8a.so"
touch "$ROOT/bravo/zygisk/arm64/module.so"
touch "$ROOT/disabled/zygisk/off.so"
touch "$ROOT/brene/zygisk/ignore.so"
touch "$ROOT/disabled/disable"
printf 'config_auto_hide=0\n' > "$DATA/config.sh"

cat > "$BIN" <<'SH'
#!/bin/sh
case "$1" in
  show)
    [ "$2" = enabled_features ] || exit 1
    [ "${BRENE_TEST_MAP_FEATURE:-yes}" = yes ] && echo CONFIG_KSU_SUSFS_SUS_MAP
    ;;
  add_sus_map) printf '%s\n' "$2" >> "$BRENE_TEST_TRACE" ;;
  *) exit 1 ;;
esac
SH
chmod +x "$BIN"
export BRENE_AUTO_BASE="$DATA" BRENE_AUTO_MODULES="$ROOT"
export BRENE_AUTO_BIN="$BIN" BRENE_AUTO_BOOT_ID=mock-boot
export BRENE_TEST_TRACE="$TRACE"

sh module/autoshield.sh scan
[ "$(wc -l < "$DATA/autoshield.candidates")" -eq 2 ]
grep -Fq "$ROOT/alpha/zygisk/arm64-v8a.so" "$DATA/autoshield.candidates"
grep -Fq "$ROOT/bravo/zygisk/arm64/module.so" "$DATA/autoshield.candidates"
if grep -E 'disabled|brene/zygisk' "$DATA/autoshield.candidates"; then exit 1; fi

sh module/autoshield.sh apply
[ ! -s "$TRACE" ] || { echo 'Disabled-by-default must not call kernel tool'; exit 1; }
printf 'config_auto_hide=1\n' > "$DATA/config.sh"
sh module/autoshield.sh apply
[ "$(wc -l < "$TRACE")" -eq 2 ]
sh module/autoshield.sh apply
[ "$(wc -l < "$TRACE")" -eq 2 ] || { echo 'Duplicate applied'; exit 1; }

mkdir -p "$ROOT/new/zygisk"
touch "$ROOT/new/zygisk/new.so"
sh module/autoshield.sh apply
[ "$(wc -l < "$TRACE")" -eq 3 ]
[ "$(wc -l < "$DATA/autoshield.applied")" -eq 3 ]
BRENE_TEST_MAP_FEATURE=no
export BRENE_TEST_MAP_FEATURE
touch "$ROOT/new/zygisk/newer.so"
sh module/autoshield.sh apply
[ "$(wc -l < "$TRACE")" -eq 3 ] || { echo 'Unsupported kernel feature was invoked'; exit 1; }
printf 'config_auto_hide=0\n' > "$DATA/config.sh"
sh module/autoshield.sh apply
[ "$(wc -l < "$TRACE")" -eq 3 ]
echo 'AutoShield discovery, opt-in gating, deduplication and fail-closed tests passed'
