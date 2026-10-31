#!/system/bin/sh
# BRENE Mount visibility rules — non-destructive scanner + opt-in per-fork KSU rules.
# Never unmount anything from the active init/global namespace.
umask 077
BASE=/data/adb/brene
KSU=/data/adb/ksud
MOUNTINFO=/proc/1/mountinfo
# Overrides exist only for isolated host tests.
if [ "${BRENE_TESTING:-0}" = 1 ]; then
  [ -n "${BRENE_TEST_BASE:-}" ] && BASE=$BRENE_TEST_BASE
  [ -n "${BRENE_TEST_KSU:-}" ] && KSU=$BRENE_TEST_KSU
  [ -n "${BRENE_TEST_MOUNTINFO:-}" ] && MOUNTINFO=$BRENE_TEST_MOUNTINFO
fi
[ -r "$BASE/config.sh" ] && . "$BASE/config.sh"
: "${config_kernel_umount:=1}"
: "${config_mount_hide_auto_bind:=0}"
: "${config_mount_hide_sysfs:=0}"
: "${config_mount_hide_max_rules:=512}"
EXCLUDES="$BASE/mount-hide-exclude.txt"
# Allow exact paths and literal directory prefixes ending in '/'.
excluded() {
  target=$1
  [ -f "$EXCLUDES" ] && [ ! -L "$EXCLUDES" ] || return 1
  while IFS= read -r entry || [ -n "$entry" ]; do
    case "$entry" in
      ''|\#*) continue ;;
      /*) ;;
      *) continue ;;
    esac
    if [ "$entry" = "$target" ]; then return 0; fi
    case "$entry" in
      */) case "$target" in "$entry"*) return 0;; esac ;;
    esac
  done < "$EXCLUDES"
  return 1
}
STATUS="$BASE/mount-hide.status"
LOG="$BASE/mount-hide.log"
APPLIED="$BASE/mount-hide.applied"
log() { printf '%s\n' "$*" >> "$LOG"; }
status() { printf '%s\n' "$*" > "$STATUS"; }
collect(){
  [ -r "$MOUNTINFO" ] || return 1
  # Mountinfo fourth column (root) identifies module-owned bind source.
  # Deliberately scope the report's Lucky_Control only, excluding GPU modules.
  awk '
    $4 ~ /^\/(data\/)?adb\/modules\/Lucky_Control\// {
      p=$5
      if(p ~ /\\[0-7][0-7][0-7]/) next
      if(p ~ /^\/(system|system_ext|vendor|odm|product|my_product|oem|system_dlkm|vendor_dlkm|odm_dlkm)\//) print p "|system"
      else if(p ~ /^\/sys\/devices\/virtual\/thermal\/thermal_zone[0-9]+\/temp$/) print p "|thermal"
    }
  ' "$MOUNTINFO" | LC_ALL=C sort -u
}
case "${1:-report}" in
  collect) collect ;;
  preview)
    collect | while IFS='|' read -r path category; do
      if excluded "$path"; then printf '[排除] %s\n' "$path"
      elif [ "$category" = thermal ] && [ "$config_mount_hide_sysfs" != 1 ]; then
        printf '[温控保护] %s\n' "$path"
      else printf '[候选] %s\n' "$path"; fi
    done
    ;;
  report)
    [ -r "$STATUS" ] && cat "$STATUS" || printf '%s\n' '尚未执行'
    printf '自动规则=%s 温控路径=%s 内核卸载=%s\n' "$config_mount_hide_auto_bind" "$config_mount_hide_sysfs" "$config_kernel_umount"
    ;;
  apply)
    mkdir -p "$BASE" || exit 1
    : > "$LOG"
    if [ "$config_kernel_umount" != 1 ] || [ "$config_mount_hide_auto_bind" != 1 ]; then
      status '未启用：保持全局模块挂载不变'
      exit 0
    fi
    [ -x "$KSU" ] || { status '无法执行 ksud'; exit 1; }
    [ -r "$MOUNTINFO" ] || { status '无法读取 mountinfo'; exit 1; }
    case "$config_mount_hide_max_rules" in ''|*[!0-9]*) config_mount_hide_max_rules=512;; esac
    [ "$config_mount_hide_max_rules" -gt 0 ] 2>/dev/null || config_mount_hide_max_rules=512
    [ "$config_mount_hide_max_rules" -le 512 ] 2>/dev/null || config_mount_hide_max_rules=512
    temp="$BASE/.mount-hide.$$"
    trap 'rm -f "$temp"' EXIT HUP INT TERM
    collect > "$temp" || { status '扫描失败'; exit 1; }
    boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)
    [ -n "$boot_id" ] || boot_id=unknown
    if [ ! -f "$APPLIED" ] || [ "$(sed -n '1p' "$APPLIED")" != "# $boot_id" ]; then
      printf '# %s\n' "$boot_id" > "$APPLIED"
    fi
    count=0; registered=0; existing=0; skipped=0; failed=0
    while IFS='|' read -r path category; do
      [ -n "$path" ] || continue
      count=$((count+1))
      if [ "$count" -gt "$config_mount_hide_max_rules" ]; then skipped=$((skipped+1)); continue; fi
      if [ "$category" = thermal ] && [ "$config_mount_hide_sysfs" != 1 ]; then skipped=$((skipped+1)); continue; fi
      if excluded "$path"; then skipped=$((skipped+1)); log "EXCLUDED: $path"; continue; fi
      case "$path" in
        /*) ;;
        *) skipped=$((skipped+1)); continue;;
      esac
      case "$path" in
        *[!a-zA-Z0-9_./:+@=-]*) skipped=$((skipped+1)); continue;;
      esac
      if grep -Fqx -- "$path" "$APPLIED"; then existing=$((existing+1)); continue; fi
      if "$KSU" kernel umount add -f 2 "$path" >> "$LOG" 2>&1; then
        registered=$((registered+1)); printf '%s\n' "$path" >> "$APPLIED"
      else
        failed=$((failed+1)); log "FAILED: $path"
      fi
    done < "$temp"
    status "候选=$count 新注册=$registered 已有=$existing 排除=$skipped 失败=$failed（仅影响后续标记卸载的进程）"
    [ "$failed" -eq 0 ]
    ;;
  *) echo 'Usage: mount-hide.sh collect|preview|report|apply' >&2; exit 2;;
esac
