#!/bin/sh
set -eu
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/state"
cat > "$work/mountinfo" <<'EOF'
201 200 253:44 /adb/modules/Lucky_Control/system_ext/etc/horae/horae.conf /system_ext/etc/horae/horae.conf rw - f2fs /dev/block/dm-44 rw
202 200 253:44 /adb/modules/Lucky_Control/sys/class/thermal/thermal_zone36/temp /sys/devices/virtual/thermal/thermal_zone36/temp rw - f2fs /dev/block/dm-44 rw
203 200 253:45 /adb/modules/adreno_gpu_driver/vendor/lib64/egl/eglSubDriver.so /vendor/lib64/egl/eglSubDriver.so rw - f2fs /dev/block/dm-45 rw
204 200 253:44 /adb/modules/Lucky_Control/system_ext/etc/horae/horae.conf /system_ext/etc/horae/horae.conf rw - f2fs /dev/block/dm-44 rw
EOF
cat > "$work/ksud" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$work/calls"
exit 0
EOF
chmod 755 "$work/ksud"
env BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" BRENE_TEST_KSU="$work/ksud" BRENE_TEST_MOUNTINFO="$work/mountinfo" sh module/mount-hide.sh collect > "$work/candidates"
grep -qx '/system_ext/etc/horae/horae.conf|system' "$work/candidates"
grep -qx '/sys/devices/virtual/thermal/thermal_zone36/temp|thermal' "$work/candidates"
[ "$(wc -l < "$work/candidates")" -eq 2 ]
printf '%s\n' 'config_mount_hide_auto_bind=0' 'config_kernel_umount=1' 'config_mount_hide_sysfs=0' > "$work/state/config.sh"
env BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" BRENE_TEST_KSU="$work/ksud" BRENE_TEST_MOUNTINFO="$work/mountinfo" sh module/mount-hide.sh apply
[ ! -f "$work/calls" ]
sed -i 's/config_mount_hide_auto_bind=0/config_mount_hide_auto_bind=1/' "$work/state/config.sh"
env BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" BRENE_TEST_KSU="$work/ksud" BRENE_TEST_MOUNTINFO="$work/mountinfo" sh module/mount-hide.sh apply
grep -q 'kernel umount add -f 2 /system_ext/etc/horae/horae.conf' "$work/calls"
! grep -q 'thermal_zone36' "$work/calls"
! grep -q 'eglSubDriver' "$work/calls"
env BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" BRENE_TEST_KSU="$work/ksud" BRENE_TEST_MOUNTINFO="$work/mountinfo" sh module/mount-hide.sh apply
[ "$(grep -c 'kernel umount add' "$work/calls")" -eq 1 ]
# User allowlist: exact path must be excluded even when auto-unmount is enabled.
printf '%s\n' '/system_ext/etc/horae/horae.conf' > "$work/state/mount-hide-exclude.txt"
rm -f "$work/state/mount-hide.applied" "$work/calls"
env BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" BRENE_TEST_KSU="$work/ksud" BRENE_TEST_MOUNTINFO="$work/mountinfo" sh module/mount-hide.sh preview > "$work/preview"
grep -q '^\[排除\] /system_ext/etc/horae/horae.conf
 "$work/preview"
env BRENE_TESTING=1 BRENE_TEST_BASE="$work/state" BRENE_TEST_KSU="$work/ksud" BRENE_TEST_MOUNTINFO="$work/mountinfo" sh module/mount-hide.sh apply
if [ -f "$work/calls" ] && grep -q 'kernel umount add' "$work/calls"; then
 echo 'excluded mount was registered' >&2; exit 1
fi
echo 'PASS: scoped mounts, default safety, dedup and thermal exclusion'
