#!/system/bin/sh
# Optional SuSFS KSTAT rules. Deliberately empty by default.
# Format: /absolute/path|update or /absolute/path|clone
# 'pre' records metadata before mounts; 'post' refreshes it after mounts.
MODE=${1:-}
RULES=/data/adb/brene/custom_sus_kstat.txt
SUSFS_BIN=/data/adb/ksu/bin/susfs
LOG=/data/adb/brene/kstat.log
case "$MODE" in pre|post) ;; *) exit 2 ;; esac
[ -r "$RULES" ] || exit 0
[ -x "$SUSFS_BIN" ] || exit 0
"$SUSFS_BIN" show enabled_features 2>/dev/null | grep -q 'SUS_KSTAT' || {
    printf '%s\n' "SKIP: SUS_KSTAT unavailable" >> "$LOG"
    exit 0
}
while IFS= read -r rule || [ -n "$rule" ]; do
    case "$rule" in ''|'#'*) continue ;; esac
    case "$rule" in
        *'|'*) target=${rule%%|*}; method=${rule#*|} ;;
        *) target=$rule; method=update ;;
    esac
    case "$target" in /*) ;; *) printf 'SKIP invalid path: %s\n' "$target" >> "$LOG"; continue ;; esac
    case "$method" in update|clone) ;; *) printf 'SKIP invalid mode: %s\n' "$method" >> "$LOG"; continue ;; esac
    [ -e "$target" ] || { printf 'SKIP missing path: %s\n' "$target" >> "$LOG"; continue; }
    if [ "$MODE" = pre ]; then
        "$SUSFS_BIN" add_sus_kstat "$target" >> "$LOG" 2>&1
    elif [ "$method" = clone ]; then
        "$SUSFS_BIN" update_sus_kstat_full_clone "$target" >> "$LOG" 2>&1
    else
        "$SUSFS_BIN" update_sus_kstat "$target" >> "$LOG" 2>&1
    fi
done < "$RULES"
