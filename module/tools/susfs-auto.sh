#!/system/bin/sh
# BRENE automatic SuSFS capability negotiation.
# Persistent data files are NOT sourced/evaluated as shell code.
# Install -> early boot -> post-mount -> boot complete, with safe defaults.
umask 077
MODE=$1
BASE=/data/adb/brene
BIN=/data/adb/ksu/bin/susfs
KERNEL=/proc/sys/kernel/osrelease
if [ "$BRENE_AUTO_TEST" = 1 ]; then
 [ -n "$BRENE_AUTO_BASE" ] && BASE=$BRENE_AUTO_BASE
 [ -n "$BRENE_AUTO_BIN" ] && BIN=$BRENE_AUTO_BIN
 [ -n "$BRENE_AUTO_KERNEL" ] && KERNEL=$BRENE_AUTO_KERNEL
elif [ -n "$BRENE_AUTO_INSTALL_BIN" ] && [ "$MODE" = install ]; then
 BIN=$BRENE_AUTO_INSTALL_BIN
fi
PROFILE=$BASE/auto-profile.txt
FEATURES=$BASE/auto-features.list
SIGNATURE=$BASE/auto-signature.txt
STATUS=$BASE/auto-status.txt
LOG=$BASE/auto-events.log
mkdir -p "$BASE" || exit 1
chmod 700 "$BASE" 2>/dev/null || :
flag(){
 file=$BASE/config.sh
 key=$1
 default=$2
 value=
 if [ -f "$file" ] && [ ! -L "$file" ]; then
  value=$(awk -F= -v k="$key" '$1==k {print $2; exit}' "$file" 2>/dev/null)
 fi
 case "$value" in 0|1) printf '%s\n' "$value";; *) printf '%s\n' "$default";; esac
}
atomic(){
 dest=$1
 source=$2
 mv -f "$source" "$dest" || return 1
 chmod 600 "$dest" 2>/dev/null || :
}
note(){
 printf '%s: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)" "$*" >> "$LOG"
}
safestr(){
 # No user, serial, token or property data in the profile.
 printf '%s' "$1" | LC_ALL=C tr -cd 'a-zA-Z0-9._+:-' | cut -c1-120
}
feature(){
 [ -f "$FEATURES" ] && grep -Fxq "CONFIG_KSU_SUSFS_$1" "$FEATURES"
}
valid_version(){
 printf '%s\n' "$1" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+([+._-][A-Za-z0-9.+_-]*)?$'
}
probe(){
 tmp=$BASE/.auto-probe.$$
 feat=$BASE/.auto-feat.$$
 trap 'rm -f "$tmp" "$feat"' EXIT HUP INT TERM
 : > "$tmp" || return 1
 : > "$feat" || return 1
 kernel=$(cat "$KERNEL" 2>/dev/null)
 kernel=$(safestr "$kernel")
 [ -n "$kernel" ] || kernel=unknown
 if [ ! -x "$BIN" ]; then
  printf '%s\n' '状态：SuSFS CLI 不可执行，保留原有配置，不应用自动策略' > "$STATUS"
  note 'probe failed: executable unavailable'
  return 1
 fi
 version=$("$BIN" show version 2>/dev/null) || version=
 variant=$("$BIN" show variant 2>/dev/null) || variant=
 raw=$("$BIN" show enabled_features 2>/dev/null) || raw=
 version=$(safestr "$version")
 variant=$(safestr "$variant")
 if ! valid_version "$version"; then
  printf '%s\n' '状态：SuSFS 版本无法验证，跳过自动配置' > "$STATUS"
  note 'probe failed: unsupported version response'
  return 1
 fi
 [ -n "$variant" ] || variant=unknown
 printf '%s\n' "$raw" |
  sed -n 's/^\(CONFIG_KSU_SUSFS_[A-Z0-9_]*\)\(=y\)\{0,1\}$/\1/p' |
  LC_ALL=C sort -u > "$feat"
 count=$(wc -l < "$feat" | tr -d ' ')
 case "$count" in ''|*[!0-9]*) count=0;; esac
 if [ "$count" -eq 0 ]; then
  printf '%s\n' '状态：未得到可信的内核能力列表，跳过自动配置' > "$STATUS"
  note 'probe failed: feature enumeration empty'
  return 1
 fi
 digest=$( { printf '%s\n' "$kernel" "$version" "$variant"; cat "$feat"; } | cksum | awk '{print $1 ":" $2}')
 old=$(cat "$SIGNATURE" 2>/dev/null)
 changed=0
 [ "$old" = "$digest" ] || changed=1
 {
  printf '状态：内核能力已检测并持久化\n'
  printf 'SuSFS：%s (%s)\n' "$version" "$variant"
  printf '内核：%s\n' "$kernel"
  printf '已报告能力：%s 项\n' "$count"
  printf '自动适配：%s\n' "$( [ "$(flag config_susfs_auto_enable 1)" = 1 ] && printf 开启 || printf 关闭 )"
  if grep -Fxq 'CONFIG_KSU_SUSFS_SUS_MOUNT' "$feat"; then
    printf 'Mount 视图隐藏：可按原开关自动应用\n'
  else
    printf 'Mount 视图隐藏：未报告支持，不主动调用\n'
  fi
  if grep -Eq '^CONFIG_KSU_SUSFS_AUTO_ADD_.*MOUNT$' "$feat"; then
    printf 'Mount 自动标记：由内核编译能力负责（不执行全局卸载）\n'
  else
    printf 'Mount 自动标记：内核未报告对应能力\n'
  fi
  printf 'Kernel Umount：仅由用户现有开关决定，自动适配不会额外开启\n'
  printf '能力指纹：%s\n' "$digest"
  printf '更新依据：%s\n' "$( [ "$changed" = 1 ] && printf 新环境或能力变化 || printf 与上次检测一致 )"
 } > "$tmp" || return 1
 atomic "$FEATURES" "$feat" || return 1
 atomic "$PROFILE" "$tmp" || return 1
 printf '%s\n' "$digest" > "$SIGNATURE"
 chmod 600 "$SIGNATURE" 2>/dev/null || :
 printf '%s\n' "状态：检测完成；已持久化 $count 项能力；指纹变化=$changed" > "$STATUS"
 [ "$changed" = 0 ] || note "capability profile changed: $kernel $version $variant count=$count"
 trap - EXIT HUP INT TERM
 return 0
}
early(){
 if [ "$(flag config_susfs_auto_enable 1)" != 1 ]; then
  note 'early: automatic management disabled by user'
  return 0
 fi
 probe || return 0
 if [ "$(flag config_hide_sus_mnts_for_non_su_procs 1)" != 1 ]; then
  note 'early: mount view hiding disabled by user'
  return 0
 fi
 if ! feature SUS_MOUNT; then
  note 'early: SUS_MOUNT not reported, fail closed'
  return 0
 fi
 if "$BIN" hide_sus_mnts_for_non_su_procs 1 >> "$LOG" 2>&1; then
  printf '%s\n' '状态：已在早期启动应用 SuSFS 非 SU 挂载视图隐藏（依用户配置）' > "$STATUS"
  note 'early: mount view configured'
 else
  printf '%s\n' '状态：内核拒绝挂载视图隐藏命令，保留原有配置' > "$STATUS"
  note 'early: mount command rejected'
 fi
}
mounted(){
 # Mount table is checked after the metamodule has mounted all modules.
 probe || return 0
 if [ -r /proc/1/mountinfo ]; then
  root=/data/adb/modules/brene/mount-hide.sh
  if [ "$BRENE_AUTO_TEST" = 1 ] && [ -n "$BRENE_AUTO_MOUNT_HELPER" ]; then root=$BRENE_AUTO_MOUNT_HELPER; fi
  if [ -f "$root" ]; then
   sh "$root" preview 2>/dev/null | head -n 180 > "$BASE/auto-mount-preview.txt"
   chmod 600 "$BASE/auto-mount-preview.txt" 2>/dev/null || :
  fi
 fi
 note 'post-mount: capability checked and non-destructive mount inventory refreshed'
}
late(){
 probe || return 0
 note 'boot-completed: persisted capability profile checked'
}
case "$MODE" in
 install|probe) probe ;;
 early) early ;;
 mounted) mounted ;;
 late) late ;;
 status)
   # Show the latest runtime result before the cached fingerprint: stale profiles
   # must not disguise a failed probe or rejected kernel command.
   if [ -r "$STATUS" ]; then cat "$STATUS"
   else printf '%s\n' '状态：尚未执行自动内核适配'; fi
   [ ! -r "$PROFILE" ] || cat "$PROFILE"
   ;;
 *) printf '%s\n' 'Usage: susfs-auto.sh install|probe|early|mounted|late|status' >&2; exit 2 ;;
esac
