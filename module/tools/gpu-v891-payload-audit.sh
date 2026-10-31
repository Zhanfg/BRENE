#!/system/bin/sh
# PJZ110 / Adreno 830, Qualcomm v891 userspace driver audit.
# Run with sh and NO arguments. No changes to mounts or processes.
set -u
MOD=/data/adb/modules/adreno_gpu_driver
DEST=/sdcard/Download
mkdir -p "$DEST" 2>/dev/null || DEST=/data/local/tmp
mkdir -p "$DEST" 2>/dev/null || exit 1
OUT="$DEST/BRENE_GPU_v891_$(date +%Y%m%d_%H%M%S).txt"
{
  echo 'BRENE GPU v891 driver inventory — read-only'
  date 2>/dev/null
  echo "Device: $(getprop ro.product.model 2>/dev/null)"
  echo "Kernel: $(uname -r)"
  echo "EGL: $(getprop ro.hardware.egl 2>/dev/null)"
  echo "Vulkan: $(getprop ro.hardware.vulkan 2>/dev/null)"
  echo '=== Installed GPU module ==='
  if [ -d "$MOD" ]; then
    [ -r "$MOD/module.prop" ] && cat "$MOD/module.prop"
    [ -f "$MOD/disable" ] && echo 'disabled' || echo 'enabled/present'
    echo '=== Deployment hooks ==='
    for hook in post-fs-data.sh post-mount.sh service.sh customize.sh; do
      [ -r "$MOD/$hook" ] || continue
      echo "HOOK $hook"
      grep -nE 'overlay|mount |bind |nsenter|chcon|restorecon|insmod' "$MOD/$hook" 2>/dev/null | head -n 16 || true
    done
    echo '=== New driver payload file paths ==='
    for base in "$MOD/system/vendor" "$MOD/system/product" "$MOD/system/system_ext" "$MOD/vendor"; do
      [ -d "$base" ] || continue
      find "$base" -type f \( -name '*.so' -o -name '*.ko' -o -name '*.mbn' \) 2>/dev/null |
        head -n 200 | while IFS= read -r file; do
          echo "$file"
          stat -c 'size=%s mode=%a' "$file" 2>/dev/null || true
        done
    done
  else
    echo 'GPU module not found — upload the original v891 ZIP for an accurate inventory'
  fi
  echo '=== Running GPU library mapping (SurfaceFlinger) ==='
  for pid in $(pidof surfaceflinger 2>/dev/null); do
    case "$pid" in ''|*[!0-9]*) continue ;; esac
    if [ -r "/proc/$pid/maps" ]; then
      grep -E '(/vendor/|/system/).*(libllvm|vulkan|libGLES|libEGL|libgsl)' "/proc/$pid/maps" | head -n 40 || true
    fi
  done
  echo '=== Driver module mount source / overlay ==='
  if [ -r /proc/1/mountinfo ]; then
    grep -E 'adreno_gpu_driver| - overlay | /vendor ' /proc/1/mountinfo 2>/dev/null | head -n 65 || true
  else
    echo 'mountinfo unavailable'
  fi
  echo 'This report cannot prove the original OEM library baseline.'
  echo 'No mounted filesystems, driver libraries, kernel interfaces, or SELinux settings were changed.'
} > "$OUT" 2>&1
echo "GPU v891 report: $OUT"
