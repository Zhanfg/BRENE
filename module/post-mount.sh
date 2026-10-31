#!/system/bin/sh
# Called after KernelSU/MetaModule mounts but before normal app startup.
MODDIR=${0%/*}
BASE=/data/adb/brene
[ -d "$BASE" ] || mkdir -p "$BASE"
if [ -f "$MODDIR/tools/susfs-auto.sh" ]; then
 /system/bin/sh "$MODDIR/tools/susfs-auto.sh" mounted >> "$BASE/auto-boot.log" 2>&1
fi
# KernelSU per-process unmount remains subject to user opt-in.
if [ -f "$MODDIR/mount-hide.sh" ]; then
 /system/bin/sh "$MODDIR/mount-hide.sh" apply >> "$BASE/mount-hide-boot.log" 2>&1
fi
