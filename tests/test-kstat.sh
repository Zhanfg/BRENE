#!/bin/sh
# Host-side dry-run tests for BRENE's KSTAT parser; never touches a real kernel.
set -eu
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT HUP INT TERM
mkdir -p "$TMPROOT/persist"
touch "$TMPROOT/target"
cat > "$TMPROOT/susfs" <<'SH'
#!/bin/sh
if [ "$1" = show ] && [ "$2" = enabled_features ]; then
  echo "CONFIG_KSU_SUSFS_SUS_KSTAT"
  exit 0
fi
printf '%s\n' "$*" >> "$CALL_LOG"
SH
chmod +x "$TMPROOT/susfs"
sed -e "s|/data/adb/brene|$TMPROOT/persist|g" \
    -e "s|/data/adb/ksu/bin/susfs|$TMPROOT/susfs|g" \
    module/kstat-rules.sh > "$TMPROOT/runner.sh"

RULE="$TMPROOT/target"
STATIC_FILE="$TMPROOT/persist/custom_static_kstat.txt"
DYNAMIC_FILE="$TMPROOT/persist/custom_sus_kstat.txt"
row="$RULE"
for unused in 1 2 3 4 5 6 7 8 9 10 11 12; do
  row="$row|default"
done
# Valid rules should execute exactly once; malformed / excess rows should not.
printf '%s\n' "$row" > "$STATIC_FILE"
printf '%s\n' "$RULE|default|bad|default|default|default|default|default|default|default|default|default|default" >> "$STATIC_FILE"
CALL_LOG="$TMPROOT/calls" export CALL_LOG
sh "$TMPROOT/runner.sh" static
[ "$(grep -c '^add_sus_kstat_statically ' "$CALL_LOG")" -eq 1 ]
printf '%s\n' "$RULE|update" > "$DYNAMIC_FILE"
sh "$TMPROOT/runner.sh" pre
sh "$TMPROOT/runner.sh" post
grep -q '^add_sus_kstat ' "$CALL_LOG"
grep -q '^update_sus_kstat ' "$CALL_LOG"

# Failure to enumerate the compiled feature must safely produce no writes.
cat > "$TMPROOT/susfs" <<'SH'
#!/bin/sh
if [ "$1" = show ]; then exit 1; fi
printf '%s\n' "$*" >> "$CALL_LOG"
SH
chmod +x "$TMPROOT/susfs"
: > "$TMPROOT/calls"
sh "$TMPROOT/runner.sh" static
[ ! -s "$TMPROOT/calls" ]
echo "KSTAT parser and unavailable-feature checks passed"
