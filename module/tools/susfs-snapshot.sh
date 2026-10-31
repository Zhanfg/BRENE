#!/system/bin/sh
# BRENE local, whitelist-only config snapshots; never extract untrusted archives.
umask 077
BASE=/data/adb/brene
if [ "${BRENE_TESTING:-0}" = 1 ] && [ -n "${BRENE_TEST_BASE:-}" ]; then BASE=$BRENE_TEST_BASE; fi
ROOT="$BASE/snapshots"
FILES='config.sh custom_sus_map.txt custom_sus_path.txt custom_sus_path_loop.txt custom_open_redirect.txt custom_kernel_umount.txt custom_static_kstat.txt custom_sus_kstat.txt custom_cmdline.txt custom_bootconfig.txt mount-hide-exclude.txt'
valid_id() {
 case "$1" in
   [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]*) ;;
   *) return 1 ;;
 esac
 case "$1" in *[!0-9_]*) return 1;; esac
}
make_snapshot() {
 mkdir -p "$ROOT" || return 1
 id=$(date '+%Y%m%d_%H%M%S') || return 1
 seq=0
 while [ -e "$ROOT/$id" ]; do seq=$((seq+1)); id="$(date '+%Y%m%d_%H%M%S')_$seq"; done
 mkdir -m 700 "$ROOT/$id" || return 1
 copied=0
 for filename in $FILES; do
   src="$BASE/$filename"
   if [ -f "$src" ] && [ ! -L "$src" ]; then
     size=$(wc -c < "$src" 2>/dev/null) || size=999999
     [ "$size" -le 65536 ] 2>/dev/null || continue
     cp -p "$src" "$ROOT/$id/$filename" || return 1
     copied=$((copied+1))
   fi
 done
 [ "$copied" -gt 0 ] || { rmdir "$ROOT/$id" 2>/dev/null; echo '没有可备份的配置' >&2; return 1; }
 chmod 700 "$ROOT/$id" || return 1
 printf '%s\n' "$id"
}
case "${1:-}" in
 backup)
   make_snapshot ;;
 list)
   [ -d "$ROOT" ] || exit 0
   for p in "$ROOT"/*; do
     [ -d "$p" ] && [ ! -L "$p" ] || continue
     id=${p##*/}
     valid_id "$id" && printf '%s\n' "$id"
   done | LC_ALL=C sort -r ;;
 restore)
   id=${2:-}
   valid_id "$id" || { echo '无效快照标识' >&2; exit 2; }
   [ -d "$ROOT/$id" ] && [ ! -L "$ROOT/$id" ] || { echo '找不到快照' >&2; exit 1; }
   echo '恢复前备份：'
   make_snapshot || exit 1
   copied=0
   for filename in $FILES; do
     src="$ROOT/$id/$filename"
     [ -f "$src" ] && [ ! -L "$src" ] || continue
     size=$(wc -c < "$src" 2>/dev/null) || size=999999
     [ "$size" -le 65536 ] 2>/dev/null || continue
     [ ! -L "$BASE/$filename" ] || { echo "跳过符号链接: $filename" >&2; continue; }
     cp -p "$src" "$BASE/$filename" || exit 1
     copied=$((copied+1))
   done
   printf '已恢复 %s 个文件；请重启以重新应用规则\n' "$copied" ;;
 *) echo '用法: susfs-snapshot.sh backup|list|restore <快照ID>' >&2; exit 2 ;;
esac
