#!/system/bin/sh
# Explicit, fail-closed SuSFS KSTAT rule application. No eval or shell sourcing.
# Dynamic format: /absolute/path|update or /absolute/path|clone
# Static format: /absolute/path|ino|dev|nlink|size|atime|atime_nsec|mtime|
#                mtime_nsec|ctime|ctime_nsec|blocks|blksize
MODE=${1:-}
BASE=/data/adb/brene
BIN=/data/adb/ksu/bin/susfs
LOG=${BASE}/kstat.log
case "$MODE" in
  pre|post) RULES=${BASE}/custom_sus_kstat.txt ;;
  static)   RULES=${BASE}/custom_static_kstat.txt ;;
  *) exit 2 ;;
esac
[ -s "$RULES" ] || exit 0
[ -x "$BIN" ] || exit 0
# Keep boot-stage parsing bounded even for manually edited files.
SIZE=$(wc -c < "$RULES" 2>/dev/null)
case "$SIZE" in ''|*[!0-9]*) exit 1 ;; esac
[ "$SIZE" -le 32768 ] || { echo "SKIP: rules too large" >> "$LOG"; exit 1; }
"$BIN" show enabled_features 2>/dev/null | grep -q 'SUS_KSTAT' || {
  echo "SKIP: SUS_KSTAT is not enabled" >> "$LOG"
  exit 0
}
valid_value() {
  case "$1" in
    default) return 0 ;;
    ''|*[!0-9]*) return 1 ;;
    *) [ "${#1}" -le 20 ] ;;
  esac
}
count=0
if [ "$MODE" = static ]; then
  while IFS='|' read -r path ino dev nlink size atime atime_nsec mtime mtime_nsec ctime ctime_nsec blocks blksize || [ -n "$path" ]; do
    case "$path" in ''|'#'*) continue ;; esac
    count=$((count + 1))
    [ "$count" -le 200 ] || break
    case "$path" in /*) ;; *) echo "SKIP invalid static path" >> "$LOG"; continue ;; esac
    [ "${#path}" -le 1024 ] || continue
    valid=1
    for arg in "$ino" "$dev" "$nlink" "$size" "$atime" "$atime_nsec" "$mtime" "$mtime_nsec" "$ctime" "$ctime_nsec" "$blocks" "$blksize"; do
      valid_value "$arg" || valid=0
    done
    [ "$valid" = 1 ] || { echo "SKIP invalid static values: $path" >> "$LOG"; continue; }
    [ -e "$path" ] || { echo "SKIP missing: $path" >> "$LOG"; continue; }
    "$BIN" add_sus_kstat_statically "$path" "$ino" "$dev" "$nlink" "$size" "$atime" "$atime_nsec" "$mtime" "$mtime_nsec" "$ctime" "$ctime_nsec" "$blocks" "$blksize" >> "$LOG" 2>&1
  done < "$RULES"
else
  while IFS= read -r rule || [ -n "$rule" ]; do
    case "$rule" in ''|'#'*) continue ;; esac
    count=$((count + 1))
    [ "$count" -le 200 ] || break
    case "$rule" in *'|'*) target=${rule%%|*}; method=${rule#*|} ;; *) target=$rule; method=update ;; esac
    case "$target" in /*) ;; *) echo "SKIP invalid dynamic path" >> "$LOG"; continue ;; esac
    [ "${#target}" -le 1024 ] || continue
    case "$method" in update|clone) ;; *) echo "SKIP invalid dynamic mode" >> "$LOG"; continue ;; esac
    [ -e "$target" ] || { echo "SKIP missing: $target" >> "$LOG"; continue; }
    if [ "$MODE" = pre ]; then
      "$BIN" add_sus_kstat "$target" >> "$LOG" 2>&1
    elif [ "$method" = clone ]; then
      "$BIN" update_sus_kstat_full_clone "$target" >> "$LOG" 2>&1
    else
      "$BIN" update_sus_kstat "$target" >> "$LOG" 2>&1
    fi
  done < "$RULES"
fi
