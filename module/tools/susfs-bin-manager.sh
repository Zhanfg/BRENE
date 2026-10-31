#!/system/bin/sh
# BRENE SuSFS binary manager: pinned upstream, SHA-256 and runtime ABI validation.
# Downloads never execute before their hash, ELF format and source are verified.
umask 077
MODE=$1
[ -n "$MODE" ] || MODE=status
BASE=/data/adb/brene
BIN=/data/adb/ksu/bin/susfs
BUNDLED=$2
[ -n "$BUNDLED" ] || BUNDLED=/data/adb/modules/brene/tools/susfs
REV=041f69d7fe23a7bd928f9bd90eb3535774d00456
PIN=8a626ce3bae27a7bcaa2e7f5f7b91e786ecc57f8e57d19c7856719a89b54b6fa
URL=https://raw.githubusercontent.com/sidex15/susfs4ksu-binaries/$REV/ksu_susfs_arm64
if [ "$BRENE_BIN_TEST" = 1 ]; then
 [ -z "$BRENE_BIN_BASE" ] || BASE=$BRENE_BIN_BASE
 [ -z "$BRENE_BIN_INSTALLED" ] || BIN=$BRENE_BIN_INSTALLED
 [ -z "$BRENE_BIN_PIN" ] || PIN=$BRENE_BIN_PIN
 [ -z "$BRENE_BIN_URL" ] || URL=$BRENE_BIN_URL
 [ -z "$BRENE_BIN_REV" ] || REV=$BRENE_BIN_REV
fi
STATUS=$BASE/binary-update.status
LOG=$BASE/binary-update.log
ROLLBACK=$BASE/susfs.rollback
CONFIG=$BASE/config.sh
mkdir -p "$BASE" || exit 1
chmod 700 "$BASE" 2>/dev/null || :
log(){ printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)" "$*" >> "$LOG"; }
state(){ printf '%s\n' "$*" > "$STATUS"; chmod 600 "$STATUS" 2>/dev/null || :; log "$*"; }
enabled(){
 [ -r "$CONFIG" ] || return 0
 value=$(awk -F= '$1=="config_susfs_binary_auto_update"{print $2;exit}' "$CONFIG" 2>/dev/null)
 [ "$value" != 0 ]
}
check_sha(){
 [ -f "$1" ] && [ ! -L "$1" ] || return 1
 [ "$(printf '%s' "$PIN" | wc -c | tr -d ' ')" -eq 64 ] || return 1
 sha=$(sha256sum "$1" 2>/dev/null | awk '{print $1}')
 [ "$sha" = "$PIN" ]
}
valid_arch(){
 [ "$BRENE_BIN_TEST" = 1 ] && return 0
 magic=$(dd if="$1" bs=1 count=5 2>/dev/null | od -An -tu1 | tr -s ' ' | sed 's/^ //;s/ $//')
 machine=$(dd if="$1" bs=1 skip=18 count=2 2>/dev/null | od -An -tu1 | tr -s ' ' | sed 's/^ //;s/ $//')
 [ "$magic" = "127 69 76 70 2" ] && [ "$machine" = "183 0" ]
}
details(){
 [ -x "$1" ] || return 1
 D_VERSION=$("$1" show version 2>/dev/null) || D_VERSION=
 D_VARIANT=$("$1" show variant 2>/dev/null) || D_VARIANT=
 D_FEATURES=$("$1" show enabled_features 2>/dev/null) || D_FEATURES=
 printf '%s\n' "$D_VERSION" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+' || return 1
 [ -n "$D_VARIANT" ] || return 1
 printf '%s\n' "$D_FEATURES" | grep -q 'CONFIG_KSU_SUSFS_' || return 1
}
compatible(){
 path=$1
 valid_arch "$path" || return 1
 details "$path" || return 1
 remote_version=$D_VERSION
 remote_variant=$D_VARIANT
 remote_features=$(printf '%s\n' "$D_FEATURES" | grep 'CONFIG_KSU_SUSFS_' | LC_ALL=C sort -u)
 if [ -x "$BIN" ] && [ "$path" != "$BIN" ] && details "$BIN"; then
  [ "$remote_version" = "$D_VERSION" ] || return 1
  [ "$remote_variant" = "$D_VARIANT" ] || return 1
  installed_features=$(printf '%s\n' "$D_FEATURES" | grep 'CONFIG_KSU_SUSFS_' | LC_ALL=C sort -u)
  [ "$remote_features" = "$installed_features" ] || return 1
 fi
 return 0
}
fetch(){
 dest=$1
 case "$URL" in
  https://raw.githubusercontent.com/sidex15/susfs4ksu-binaries/*) ;;
  *) [ "$BRENE_BIN_TEST" = 1 ] || return 1 ;;
 esac
 if [ "$BRENE_BIN_TEST" = 1 ] && [ -n "$BRENE_BIN_FIXTURE" ]; then
  cp "$BRENE_BIN_FIXTURE" "$dest" || return 1
 elif command -v curl >/dev/null 2>&1; then
  curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
    --connect-timeout 4 --max-time 18 --retry 1 "$URL" -o "$dest" >> "$LOG" 2>&1 || return 1
 else
  log 'No CA-verified HTTPS curl transport; retaining offline binary'
  return 1
 fi
 [ -f "$dest" ] && [ ! -L "$dest" ] || return 1
 size=$(wc -c < "$dest" 2>/dev/null)
 case "$size" in ''|*[!0-9]*) return 1;; esac
 [ "$size" -ge 4096 ] && [ "$size" -le 2097152 ] || return 1
 check_sha "$dest" || return 1
 chmod 700 "$dest" || return 1
 compatible "$dest" || return 1
 return 0
}
stage(){
 STAGED=$BASE/.brene-download.$$
 trap 'rm -f "$STAGED"' EXIT HUP INT TERM
 if fetch "$STAGED"; then return 0; fi
 rm -f "$STAGED"
 trap - EXIT HUP INT TERM
 return 1
}
atomic_copy(){
 src=$1
 dest=$2
 [ -f "$src" ] && [ ! -L "$src" ] || return 1
 target_dir=$(dirname "$dest")
 [ -d "$target_dir" ] || mkdir -p "$target_dir" || return 1
 tmp="$target_dir/.brene-susfs.$$"
 cp "$src" "$tmp" && chmod 755 "$tmp" && mv -f "$tmp" "$dest" || {
  rm -f "$tmp"; return 1
 }
}
case "$MODE" in
 status)
  [ -r "$STATUS" ] && cat "$STATUS" || printf '%s\n' '状态：未执行二进制检查'
  printf '信任源版本: %s\n' "$REV" ;;
 select)
  if enabled && stage; then
   atomic_copy "$STAGED" "$BASE/susfs.selected" || exit 1
   rm -f "$STAGED"; trap - EXIT HUP INT TERM
   state '状态：已验证上游固定提交和 SHA-256，安装将使用受信任版本'
   printf '%s\n' "$BASE/susfs.selected"
   exit 0
  fi
  if [ -x "$BIN" ] && compatible "$BIN"; then
   state '状态：在线更新不可用或已关闭，沿用当前兼容的二进制'
   printf '%s\n' "$BIN"; exit 0
  fi
  if [ -f "$BUNDLED" ] && compatible "$BUNDLED"; then
   state '状态：在线更新不可用或已关闭，采用内置二进制'
   printf '%s\n' "$BUNDLED"; exit 0
  fi
  state '状态：未找到兼容二进制，未替换共享文件'
  exit 1 ;;
 check)
  if stage; then
   rm -f "$STAGED"; trap - EXIT HUP INT TERM
   state '状态：受信任版本下载、SHA-256 和运行时 ABI 验证通过'
  else
   state '状态：在线检查未通过，当前二进制未更改'
   exit 1
  fi ;;
 update)
  enabled || { state '状态：用户关闭二进制自动更新'; exit 0; }
  if ! stage; then
   state '状态：下载、摘要或 ABI 验证未通过，现有二进制不变'
   exit 1
  fi
  if cmp -s "$STAGED" "$BIN" 2>/dev/null; then
   rm -f "$STAGED"; trap - EXIT HUP INT TERM
   state '状态：当前就是受信任版本，无需更新'
   exit 0
  fi
  if [ -f "$BIN" ] && [ ! -L "$BIN" ]; then
   atomic_copy "$BIN" "$ROLLBACK" || { state '状态：无法备份，取消更新'; exit 1; }
  fi
  if ! atomic_copy "$STAGED" "$BIN"; then
   [ ! -f "$ROLLBACK" ] || atomic_copy "$ROLLBACK" "$BIN"
   state '状态：写入失败，已尝试恢复旧二进制'
   exit 1
  fi
  if ! compatible "$BIN"; then
   [ ! -f "$ROLLBACK" ] || atomic_copy "$ROLLBACK" "$BIN"
   state '状态：更新后 ABI 复核失败，已尝试回滚'
   exit 1
  fi
  atomic_copy "$BIN" "$BASE/susfs" || log 'Warning: module cache sync failed'
  rm -f "$STAGED"; trap - EXIT HUP INT TERM
  state '状态：已在线更新并复核受信任二进制，建议重启' ;;
 rollback)
  [ -f "$ROLLBACK" ] && [ ! -L "$ROLLBACK" ] || { state '状态：无回退文件'; exit 1; }
  atomic_copy "$ROLLBACK" "$BIN" || { state '状态：回退失败'; exit 1; }
  atomic_copy "$BIN" "$BASE/susfs" || :
  state '状态：已恢复上一份二进制，建议重启' ;;
 *) printf '%s\n' 'Usage: susfs-bin-manager.sh status|select [bundled]|check|update|rollback' >&2; exit 2 ;;
esac
