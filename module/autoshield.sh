#!/system/bin/sh
# AutoShield: opt-in discovery of module Zygisk native-library mappings.
# No deletion, no remount, no eval, no recursive filesystem scan.
set -u
BASE=${BRENE_AUTO_BASE:-/data/adb/brene}
MODULES=${BRENE_AUTO_MODULES:-/data/adb/modules}
BIN=${BRENE_AUTO_BIN:-/data/adb/ksu/bin/susfs}
BOOT_ID=${BRENE_AUTO_BOOT_ID:-}
CANDIDATES=$BASE/autoshield.candidates
APPLIED=$BASE/autoshield.applied
STATE=$BASE/autoshield.boot
LOG=$BASE/autoshield.log
MAX=64

mkdir -p "$BASE" 2>/dev/null || exit 1
log() { printf '%s\n' "$*" >> "$LOG"; }
enabled() {
  [ -f "$BASE/config.sh" ] && grep -qx 'config_auto_hide=1' "$BASE/config.sh"
}
has_map() {
  [ -x "$BIN" ] && "$BIN" show enabled_features 2>/dev/null |
    grep -Eq '(^|[^[:alnum:]_])(CONFIG_KSU_SUSFS_)?SUS_MAP([^[:alnum:]_]|$)'
}
valid_candidate() {
  file=$1
  [ -f "$file" ] && [ ! -L "$file" ] || return 1
  [ "${#file}" -le 240 ] || return 1
  case "$file" in *'
'*|*'|'*) return 1 ;; esac
  case "$file" in "$MODULES"/*/zygisk/*.so|"$MODULES"/*/zygisk/*/*.so) ;;
    *) return 1 ;; esac
  mod=${file%%/zygisk/*}
  id=${mod##*/}
  case "$id" in ''|*[!a-zA-Z0-9._-]*|brene) return 1 ;; esac
  [ -d "$mod" ] && [ ! -L "$mod" ] &&
    [ ! -f "$mod/disable" ] && [ ! -f "$mod/remove" ] || return 1
  return 0
}
scan() {
  tmp=$BASE/.autoshield.candidates.$$
  : > "$tmp" || return 1
  count=0
  for file in "$MODULES"/*/zygisk/*.so "$MODULES"/*/zygisk/*/*.so; do
    valid_candidate "$file" || continue
    grep -Fxq "$file" "$tmp" && continue
    printf '%s\n' "$file" >> "$tmp" || { rm -f "$tmp"; return 1; }
    count=$((count + 1))
    [ "$count" -lt "$MAX" ] || break
  done
  mv -f "$tmp" "$CANDIDATES" || return 1
  printf '发现 %s 个候选映射路径（尚未隐藏）\n' "$count"
}
apply() {
  enabled || { echo '自动应用已关闭'; return 0; }
  scan || { log '扫描失败'; return 1; }
  if ! has_map; then
    log '内核未报告 SUS_MAP，未应用规则'
    echo '当前内核未报告 SUS_MAP；已保留候选清单'
    return 0
  fi
  [ -n "$BOOT_ID" ] || BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)
  [ -n "$BOOT_ID" ] || BOOT_ID=unknown
  previous=$(cat "$STATE" 2>/dev/null)
  if [ "$previous" != "$BOOT_ID" ]; then
    : > "$APPLIED" || return 1
    printf '%s\n' "$BOOT_ID" > "$STATE" || return 1
  fi
  [ -f "$APPLIED" ] || : > "$APPLIED"
  added=0
  failed=0
  while IFS= read -r file || [ -n "$file" ]; do
    valid_candidate "$file" || continue
    grep -Fxq "$file" "$APPLIED" && continue
    if "$BIN" add_sus_map "$file" >> "$LOG" 2>&1; then
      printf '%s\n' "$file" >> "$APPLIED"
      added=$((added + 1))
    else
      failed=$((failed + 1))
    fi
  done < "$CANDIDATES"
  log "AutoShield 本次新增 $added 条，失败 $failed 条（只记录命令结果，不等于应用检测验证）"
  printf '成功提交 %s 条 SUS_MAP 规则，失败 %s 条；停用后重启才能撤销内核规则\n' "$added" "$failed"
  [ "$failed" -eq 0 ]
}
status() {
  if enabled; then echo '自动应用：已启用'; else echo '自动应用：已关闭'; fi
  if has_map; then echo 'SUS_MAP：内核已报告支持'; else echo 'SUS_MAP：未报告支持'; fi
  if [ -f "$CANDIDATES" ]; then
    echo "候选：$(wc -l < "$CANDIDATES" | tr -d ' ')"
  else
    echo '候选：未扫描'
  fi
  if [ -f "$APPLIED" ]; then
    echo "本次记录的提交数：$(wc -l < "$APPLIED" | tr -d ' ')"
  fi
  echo '停用仅阻止后续应用，已提交内核规则需重启才能撤销。'
}
case "${1:-}" in
  scan) scan ;;
  apply) apply ;;
  status) status ;;
  *) echo '用法：sh autoshield.sh scan|apply|status' >&2; exit 2 ;;
esac
