#!/system/bin/sh
# BRENE / Duck Detector forensic audit. READ ONLY except for writing its report.
# Android launch: sh duck-evidence-audit.sh (no arguments).
set -u
OUTDIR=${BRENE_AUDIT_OUTPUT_DIR:-/sdcard/Download}
STAMP=$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo unknown)
REPORT=$OUTDIR/BRENE_Duck_Evidence_$STAMP.txt
if ! mkdir -p "$OUTDIR" 2>/dev/null; then
  OUTDIR=${TMPDIR:-/data/local/tmp}
  mkdir -p "$OUTDIR" 2>/dev/null || exit 1
  REPORT=$OUTDIR/BRENE_Duck_Evidence_$STAMP.txt
fi

pick_pid() {
  if [ -n "${BRENE_AUDIT_PID:-}" ]; then
    case "$BRENE_AUDIT_PID" in ''|*[!0-9]*) return 1 ;; esac
    [ -d "/proc/$BRENE_AUDIT_PID" ] || return 1
    printf '%s' "$BRENE_AUDIT_PID"
    return
  fi
  for candidate in $(pidof com.eltavine.duckdetector 2>/dev/null); do
    case "$candidate" in ''|*[!0-9]*) continue ;; esac
    [ -d "/proc/$candidate" ] && { printf '%s' "$candidate"; return; }
  done
  # Android's pidof may not see other app processes in some contexts.
  for entry in /proc/[0-9]*; do
    [ -r "$entry/cmdline" ] || continue
    cmd=$(tr '\000' '\n' < "$entry/cmdline" 2>/dev/null | head -n 1)
    case "$cmd" in
      com.eltavine.duckdetector|com.eltavine.duckdetector:*)
        candidate=${entry##*/}
        [ -d "/proc/$candidate" ] && { printf '%s' "$candidate"; return; }
        ;;
    esac
  done
}
TARGET_PID=$(pick_pid 2>/dev/null || true)
SMAPS=${BRENE_AUDIT_SMAPS:-}
MOUNTINFO=${BRENE_AUDIT_MOUNTINFO:-}
SOURCE='current audit process (DuckDetector not running / not visible)'
if [ -z "$SMAPS" ] && [ -n "$TARGET_PID" ]; then SMAPS=/proc/$TARGET_PID/smaps; fi
if [ -z "$MOUNTINFO" ] && [ -n "$TARGET_PID" ]; then
  MOUNTINFO=/proc/$TARGET_PID/mountinfo
  SOURCE="DuckDetector process PID $TARGET_PID"
fi
if [ -n "${BRENE_AUDIT_MOUNTINFO:-}" ]; then SOURCE='explicit diagnostic fixture'; fi
[ -n "$MOUNTINFO" ] || MOUNTINFO=/proc/self/mountinfo

{
  echo "BRENE — DuckDetector evidence audit (no hiding applied)"
  date 2>/dev/null
  echo "Kernel: $(uname -r 2>/dev/null)"
  echo "Target PID: ${TARGET_PID:-not_running_or_not_visible}"
  echo "Mountinfo source: $SOURCE"
  echo "Snapshot of current state; may differ from an earlier scan."
  echo
  echo "== Filesystem types and canonical paths observed by this audit shell =="
  for path in /system /vendor; do
    kind=$(stat -f -c %T "$path" 2>/dev/null || echo unavailable)
    canonical=$(readlink -f "$path" 2>/dev/null || echo unknown)
    printf '%s resolved=%s statfs-type=%s\n' "$path" "$canonical" "$kind"
    ls -ld "$path" 2>/dev/null || true
  done
  echo
  echo "== Mount records from: $SOURCE =="
  if [ -r "$MOUNTINFO" ]; then
    awk '
      {
        split($0, parts, " - "); split(parts[2], tail, " ")
        fs=tail[1]
        if ($5=="/system" || $5=="/vendor") {
          printf "Exact partition mount: %s\n", $0
          if ($5=="/system") systemfs=fs
          if ($5=="/vendor") vendorfs=fs
        }
        if (fs=="overlay") {
          total++
          if ($0 ~ /lowerdir=[^ ]*\/my_(region|preload|product|heytap|stock|engineering)/ ||
              $0 ~ /lowerdir=[^ ]*\/mnt\/opex\//) {
            oplus++
            if (oplus<=30) print "OPlus-like candidate (NOT VERIFIED): " $0
          } else {
            unclassified++
            if (unclassified<=30) print "Unclassified candidate (REVIEW): " $0
          }
        }
      }
      END {
        printf "Overlays total=%d OPlus-like=%d unclassified=%d\n",total+0,oplus+0,unclassified+0
        printf "Exact /system mount type=%s /vendor mount type=%s\n",systemfs==""?"not-present":systemfs,vendorfs==""?"not-present":vendorfs
        print "NOTE: match the resolved path, specific namespace, and effective mount stack before comparing with statfs."
      }
    ' "$MOUNTINFO"
  else
    echo "Unavailable: mountinfo; denied access is not evidence of a hidden mount."
  fi
  echo
  echo "== BusyBox location and metadata =="
  for path in /system/bin/busybox /system/xbin/busybox; do
    if [ -e "$path" ]; then
      ls -ld "$path" 2>/dev/null
      stat -c 'inode=%i size=%s owner=%u:%g' "$path" 2>/dev/null || true
    else
      printf 'not visible: %s\n' "$path"
    fi
  done
  echo
  echo "== Executable system/vendor map accounting: Shared_Dirty and Swap (KiB) =="
  if [ -n "$SMAPS" ] && [ -r "$SMAPS" ]; then
    awk '
      function flushmap() {
        if (library != "") {
          shared[library] += dirty
          swapped[library] += swap
          counts[library]++
        }
      }
      /^[[:xdigit:]]+-[[:xdigit:]]+[[:space:]]/ {
        flushmap()
        library = ""; dirty=0; swap=0
        if ($2 ~ /x/ && $0 ~ /\/(vendor|system|system_ext|product)\/lib(64)?\// && $NF ~ /^\//) {
          library=$NF
        }
        next
      }
      /^Shared_Dirty:[[:space:]]/ { if (library != "") dirty += $2 }
      /^Swap:[[:space:]]/ { if (library != "") swap += $2 }
      END {
        flushmap()
        count=0
        for (p in counts) {
          if (shared[p] > 0 || swapped[p] > 0) {
            printf "Shared_Dirty=%d KiB Swap=%d KiB exec_segments=%d %s\n",
              shared[p], swapped[p], counts[p], p
            count++
          }
        }
        printf "Nonzero findings: %d libraries\n", count
      }
    ' "$SMAPS"
  else
    echo "Unavailable: DuckDetector not running or smaps unreadable."
    echo "Rerun with DuckDetector foregrounded and adequate permissions."
  fi
  echo
  echo "== Interpretation and safeguards =="
  echo "Shared_Dirty / Swap are accounting observations, not proof of instruction tampering."
  echo "Overlayfs alone is not evidence of root (AOSP supports remount overlayfs)."
  echo "No modules, kernel hooks, mount rules, SELinux policy or in-memory code were modified."
} > "$REPORT" 2>&1

printf 'BRENE diagnostic report: %s\n' "$REPORT"
