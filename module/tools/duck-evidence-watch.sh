#!/system/bin/sh
# BRENE: one-shot watch, then collect while DuckDetector is alive.
# Run with no parameters; use from BRENE WebUI then open DuckDetector.
# No daemon, kernel changes or continuous monitoring.
set -u
BASE=${BRENE_WATCH_BASE:-/data/adb/brene}
TOOL=${BRENE_WATCH_TOOL:-/data/adb/modules/brene/tools/duck-evidence-audit.sh}
STATUS=$BASE/duck-watch.status
LOCK=$BASE/.duck-watch.lock
LIMIT=${BRENE_WATCH_LIMIT:-90}
case "$LIMIT" in ''|*[!0-9]*) LIMIT=90 ;; esac
[ "$LIMIT" -gt 0 ] && [ "$LIMIT" -le 90 ] || LIMIT=90
mkdir -p "$BASE" || exit 1
if ! mkdir "$LOCK" 2>/dev/null; then
  echo 'Another DuckDetector capture is already active'
  exit 0
fi
trap 'rm -rf "$LOCK"' EXIT HUP INT TERM
echo '等待 DuckDetector 启动（最多 90 秒）' > "$STATUS"
i=0
while [ "$i" -lt "$LIMIT" ]; do
  pid=''
  for candidate in $(pidof com.eltavine.duckdetector 2>/dev/null); do
    case "$candidate" in ''|*[!0-9]*) continue ;; esac
    if [ -d "/proc/$candidate" ]; then pid=$candidate; break; fi
  done
  if [ -z "$pid" ]; then
    # Fallback when pidof cannot see the application.
    for entry in /proc/[0-9]*; do
      [ -r "$entry/cmdline" ] || continue
      name=$(tr '\000' '\n' < "$entry/cmdline" 2>/dev/null | head -n 1)
      case "$name" in com.eltavine.duckdetector|com.eltavine.duckdetector:*)
        pid=${entry##*/}; break ;;
      esac
    done
  fi
  if [ -n "$pid" ] && [ -r "/proc/$pid/mountinfo" ]; then
    sleep 2
    if [ -d "/proc/$pid" ]; then
      BRENE_AUDIT_PID=$pid sh "$TOOL" > "$BASE/duck-watch.last" 2>&1
      if [ "$?" -eq 0 ]; then
        printf '已采集 PID %s，报告详见 Download\n' "$pid" > "$STATUS"
        exit 0
      fi
    fi
  fi
  i=$((i+1))
  sleep 1
done
echo '采集超时：检测器在等待期间未运行或无法访问其 /proc 信息' > "$STATUS"
exit 1
