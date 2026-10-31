#!/system/bin/sh
# PJZ110 DualStack GPU eligibility / external ABI preflight. No arguments.
# READ-ONLY. Does not mount, unload or alter any driver or app.
set -u
DIR=/sdcard/Download
mkdir -p "$DIR" 2>/dev/null || DIR=/data/local/tmp
mkdir -p "$DIR" 2>/dev/null || exit 1
STAMP=$(date +%Y%m%d_%H%M%S 2>/dev/null || echo unknown)
OUT="$DIR/BRENE_GPU_DualStack_Preflight_$STAMP.txt"
TEMP="$DIR/.brene_gpu_liblist_$$"
trap 'rm -f "$TEMP"' EXIT HUP INT TERM
{
  echo 'BRENE DualStack GPU v891.11.3 read-only preflight'
  date 2>/dev/null || true
  echo '--- Android platform graphics selection ---'
  for key in ro.product.device ro.board.platform ro.soc.model ro.build.version.sdk ro.hardware.egl ro.hardware.vulkan ro.gfx.driver.0 ro.gfx.driver.1 ro.gfx.driver_build_time; do
    printf '%s = %s\n' "$key" "$(getprop "$key" 2>/dev/null)"
  done
  g0=$(getprop ro.gfx.driver.0 2>/dev/null)
  g1=$(getprop ro.gfx.driver.1 2>/dev/null)
  for g in "$g0" "$g1"; do
    [ -n "$g" ] || continue
    echo "Declared graphics driver package: $g"
    pm path "$g" 2>/dev/null || echo 'Package not found by pm'
  done
  if [ -z "$g0$g1" ]; then
    echo 'OEM GraphicsEnvironment updatable driver package not declared.'
  else
    echo 'Driver property declared; package eligibility and signing still unverified.'
  fi
  echo '--- Existing root GPU driver module ---'
  if [ -d /data/adb/modules/adreno_gpu_driver ]; then
    if [ -f /data/adb/modules/adreno_gpu_driver/disable ]; then
      echo 'GPU root module DISABLED'
    else
      echo 'GPU root module ENABLED or state unknown'
      echo 'WARNING: global v891 may still be mounted; app-only test cannot prove OEM isolation.'
    fi
    sed -n '1,12p' /data/adb/modules/adreno_gpu_driver/module.prop 2>/dev/null
  else
    echo 'No adreno_gpu_driver installed at /data/adb/modules/'
  fi
  echo '--- Required native external library names ---'
  find /vendor/lib64 /odm/lib64 /system/lib64 /system_ext/lib64 /product/lib64 /apex -type f -name '*.so' 2>/dev/null |
      sed 's|.*/||' | sort -u > "$TEMP"
  if [ ! -s "$TEMP" ]; then
    echo 'Cannot inventory system/vendor libraries: result UNKNOWN.'
  else
    printf 'Unique SONAME-compatible file names visible: %s\n' "$(wc -l < "$TEMP")"
    while IFS= read -r lib; do
      [ -n "$lib" ] || continue
      if grep -Fqx "$lib" "$TEMP"; then
        printf 'PRESENT_NAME %s\n' "$lib"
      else
        printf 'NOT_FOUND_NAME %s\n' "$lib"
      fi
    done <<'LIST'
android.hardware.common-V2-ndk.so
android.hardware.graphics.allocator-V2-ndk.so
android.hardware.graphics.common@1.2.so
android.hardware.graphics.mapper@2.0.so
android.hardware.graphics.mapper@3.0.so
android.hardware.graphics.mapper@4.0.so
libbase.so
libbinder_ndk.so
libc++.so
libc.so
libcutils.so
libdl.so
libgralloc.qti.so
libgralloctypes.so
libgrallocutils.so
libhardware.so
libhidlbase.so
liblog.so
libm.so
libnativewindow.so
libsync.so
libutils.so
libutilscallstack.so
libvndksupport.so
libz.so
vendor.qti.hardware.display.mapper@2.0.so
vendor.qti.hardware.display.mapper@3.0.so
vendor.qti.hardware.display.mapper@4.0.so
vendor.qti.hardware.display.mapperextensions@1.1.so
LIST
  fi
  echo '--- Current init mount sources ---'
  if [ -r /proc/1/mountinfo ]; then
    grep -E 'adreno_gpu_driver| /vendor | - overlay ' /proc/1/mountinfo 2>/dev/null | head -n 25 || true
  else
    echo 'init mountinfo unreadable'
  fi
  echo '--- Interpretation ---'
  echo 'PRESENT_NAME does not verify linker namespace, ABI or loader compatibility.'
  echo 'Application-scoped Vulkan profiles work only in cooperating apps.'
  echo 'This check has not changed mounted drivers or security state.'
} > "$OUT" 2>&1
printf 'DualStack preflight report: %s\n' "$OUT"
