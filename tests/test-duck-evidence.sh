#!/bin/sh
set -eu
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT HUP INT TERM
cat > "$T/smaps" <<'EOF'
70000000-70100000 r-xp 00000000 00:10 111 /vendor/lib64/libllvm-qgl.so
Size:              16384 kB
Shared_Dirty:      12944 kB
Swap:              27536 kB
70000000-70020000 r--p 00000000 00:10 111 /vendor/lib64/libllvm-qgl.so
Shared_Dirty:      900 kB
Swap:              100 kB
72000000-72010000 r-xp 00000000 00:20 222 /vendor/lib64/egl/libGLESv2_adreno.so
Shared_Dirty:       2120 kB
Swap:                  0 kB
73000000-73010000 r-xp 00000000 00:30 333 /data/local/tmp/injected.so
Shared_Dirty:         80 kB
Swap:                  0 kB
EOF
cat > "$T/mountinfo" <<'EOF'
123 11 0:1 / /system ro - overlay overlay rw
124 11 0:2 / /vendor ro - erofs /dev/block/dm-1 ro
125 11 0:3 / /product/app ro - overlay overlay ro,lowerdir=/my_region/app:/my_product/app:/product/app
126 11 0:4 / /system_ext/framework/oplusex/com.oplus.Test ro - overlay overlay ro,lowerdir=/mnt/opex/com.oplus.Test/javalib:/system_ext/framework/oplusex/com.oplus.Test
EOF
BRENE_AUDIT_OUTPUT_DIR="$T" \
BRENE_AUDIT_SMAPS="$T/smaps" \
BRENE_AUDIT_MOUNTINFO="$T/mountinfo" \
sh module/tools/duck-evidence-audit.sh
REPORT=$(find "$T" -maxdepth 1 -name 'BRENE_Duck_Evidence_*.txt' | head -n 1)
test -n "$REPORT"
cat "$REPORT"
grep -q '12944 KiB Swap=27536 KiB' "$REPORT"
grep -q '2120 KiB Swap=0 KiB' "$REPORT"
if grep -q '900 KiB' "$REPORT"; then
 echo "Non-executable mapping should be excluded"; exit 1
fi
if grep -q 'injected.so' "$REPORT"; then
 echo "Non-system path should be excluded"; exit 1
fi
grep -q 'overlay overlay rw' "$REPORT"
grep -q 'Overlays total=3 OPlus-like=2 unclassified=1' "$REPORT"
grep -q 'Exact /system mount type=overlay /vendor mount type=erofs' "$REPORT"
grep -q 'Mountinfo source: explicit diagnostic fixture' "$REPORT"
grep -q 'OPlus-like candidate (NOT VERIFIED)' "$REPORT"
grep -q 'Unclassified candidate (REVIEW)' "$REPORT"
grep -q 'No modules, kernel hooks, mount rules' "$REPORT"
echo 'Duck evidence audit fixture checks passed'
