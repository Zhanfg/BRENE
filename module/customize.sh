#!/bin/bash
# shellcheck disable=SC2154
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin

# Load utils
[[ -e "${MODPATH}/utils.sh" ]] && source "${MODPATH}/utils.sh"

echo ""
echo "██████╗ ██████╗ ███████╗███╗   ██╗███████╗"
echo "██╔══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝"
echo "██████╔╝██████╔╝█████╗  ██╔██╗ ██║█████╗  "
echo "██╔══██╗██╔══██╗██╔══╝  ██║╚██╗██║██╔══╝  "
echo "██████╔╝██║  ██║███████╗██║ ╚████║███████╗"
echo "╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝"
echo ""

# Check Compatibility
if [[ -z "${KSU}" ]]; then
	abort '[❌] SuSFS is only for KernelSU or forks!'
fi

if [[ "${ARCH}" != "arm64" ]]; then
	abort '[❌] Only arm64 is supported!'
fi

if [[ "${KSU_KERNEL_VER_CODE}" -ge 32336 ]]; then
	echo "[✅] Detected KernelSU kernel version: ${KSU_KERNEL_VER_CODE}"
else
	abort "[❌] Unsupported KernelSU kernel version: ${KSU_KERNEL_VER_CODE}!"
fi

if [[ ! -d "${DEST_BIN_DIR}" ]]; then
	abort "[❌] '${DEST_BIN_DIR}' not existed, installation aborted!"
fi

# Select a pinned and validated online binary, or an offline compatible fallback.
chmod 755 "$MODPATH/tools/susfs"
mkdir -p "$PERSISTENT_DIR" || abort '[❌] Cannot prepare persistent directory'
chmod 700 "$PERSISTENT_DIR" 2>/dev/null || :
selected_bin=$(/system/bin/sh "$MODPATH/tools/susfs-bin-manager.sh" select "$MODPATH/tools/susfs") ||
    abort '[❌] No compatible SuSFS binary available, shared binary unchanged'
case "$selected_bin" in
    "$PERSISTENT_DIR/susfs.selected"|"$MODPATH/tools/susfs"|"$DEST_BIN_DIR/susfs") ;;
    *) abort '[❌] Invalid binary selector result' ;;
esac
[[ -f "$selected_bin" && ! -L "$selected_bin" ]] || abort '[❌] Selected binary unavailable'
susfs_version=$("$selected_bin" show version 2>/dev/null)
if [[ "$susfs_version" == "v2."* || "$susfs_version" == "v3."* ]]; then
    echo "[✅] Selected compatible SuSFS userspace tool: $susfs_version"
else
    abort "[❌] Selected tool cannot communicate with the kernel: $susfs_version"
fi
# Save first foreign binary for uninstall and the immediate predecessor for rollback.
if [[ -f "$DEST_BIN_DIR/susfs" && ! -f "$PERSISTENT_DIR/susfs.previous" ]]; then
    if [[ -f "$PERSISTENT_DIR/susfs" ]] && cmp -s "$DEST_BIN_DIR/susfs" "$PERSISTENT_DIR/susfs"; then
        echo '[ℹ️] Existing shared binary is managed by BRENE'
    else
        cp -pf "$DEST_BIN_DIR/susfs" "$PERSISTENT_DIR/susfs.previous" ||
            abort '[❌] Failed to preserve pre-existing shared binary'
    fi
fi
if [[ -f "$DEST_BIN_DIR/susfs" && ! -L "$DEST_BIN_DIR/susfs" ]] &&
   ! cmp -s "$DEST_BIN_DIR/susfs" "$selected_bin"; then
    cp -pf "$DEST_BIN_DIR/susfs" "$PERSISTENT_DIR/susfs.rollback" ||
        abort '[❌] Failed to preserve last-good binary'
fi
# Staging in each destination directory makes each individual replacement atomic.
cp -pf "$selected_bin" "$PERSISTENT_DIR/.susfs.new.$$" ||
    abort '[❌] Failed to stage binary cache'
chmod 755 "$PERSISTENT_DIR/.susfs.new.$$"
mv -f "$PERSISTENT_DIR/.susfs.new.$$" "$PERSISTENT_DIR/susfs" ||
    abort '[❌] Failed to cache BRENE selected binary'
cp -pf "$selected_bin" "$DEST_BIN_DIR/.susfs.new.$$" ||
    abort '[❌] Failed to stage shared SuSFS binary'
chmod 755 "$DEST_BIN_DIR/.susfs.new.$$"
mv -f "$DEST_BIN_DIR/.susfs.new.$$" "$DEST_BIN_DIR/susfs" ||
    abort '[❌] Failed to install shared SuSFS binary'
[[ "$("$DEST_BIN_DIR/susfs" show version 2>/dev/null)" == "$susfs_version" ]] || {
    [[ ! -f "$PERSISTENT_DIR/susfs.rollback" ]] || cp -pf "$PERSISTENT_DIR/susfs.rollback" "$DEST_BIN_DIR/susfs"
    abort '[❌] Installed binary validation failed, rollback attempted'
}
chmod +x "$MODPATH/inotify.sh" "$MODPATH/remove_ksu_directory.sh" "$MODPATH/kstat-rules.sh" "$MODPATH/autoshield.sh" "$MODPATH/mount-hide.sh" "$MODPATH/tools/susfs-auto.sh" "$MODPATH/tools/susfs-bin-manager.sh" "$MODPATH/post-mount.sh"
ln -sf "$DEST_BIN_DIR/susfs" "$DEST_BIN_DIR/sus"
ln -sf "$DEST_BIN_DIR/susfs" "$DEST_BIN_DIR/ksu_susfs"

# Reset module description
susfs_total_features="kernel-defined"
susfs_features_number=$(${SUSFS_BIN} show enabled_features | wc -l)
kernel_version=$(cat /proc/version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
description="KernelSU module with SuSFS support and more"
status="Waiting for reboot ⏱️"
${KSU_BIN} module config set override.description "[Status: ${status} | Kernel Version: ${kernel_version} | SuSFS: ${susfs_version} | SuSFS Kernel Features: ${susfs_features_number} enabled] ${description}"

# Disable other SuSFS modules
[[ -e "${KSU_MODULES_DIR}/susfs4ksu" ]] && {
	touch "${KSU_MODULES_DIR}/susfs4ksu/disable" && echo '[✅] Disabling other SuSFS module'
}
[[ -e "${KSU_MODULES_DIR}/susfs_manager" ]] && {
	touch "${KSU_MODULES_DIR}/susfs_manager/disable" && echo '[✅] Disabling other SuSFS module'
}

echo "[✅] Preparing brene persistent directory (${PERSISTENT_DIR})"
mkdir -p "${PERSISTENT_DIR}"

files="
custom_sus_map.txt
custom_kernel_umount.txt
custom_sus_path.txt
custom_sus_path_loop.txt
custom_open_redirect.txt
custom_sus_kstat.txt
custom_static_kstat.txt
custom_cmdline.txt
custom_bootconfig.txt
"
for file in ${files}; do
	if [[ ! -f "${PERSISTENT_DIR}/${file}" ]]; then
		touch "${PERSISTENT_DIR}/${file}" && echo "[✅] Added ${file}"
	fi
done

if [[ ! -f "${PERSISTENT_DIR}/config.sh" ]]; then
	cp "${MODPATH}/config.sh" "${PERSISTENT_DIR}" && echo '[✅] Added config.sh'
else
	while IFS='=' read -r key value || [[ -n "${key}" ]]; do

		# Skip empty lines or comments
		[[ -z "${key// /}" || "${key// /}" == "#"* ]] && continue

		if grep -q "^${key}=" "${PERSISTENT_DIR}/config.sh"; then
			:
		else
			echo "${key}=${value}" >> "${PERSISTENT_DIR}/config.sh"
			echo "[➕] Added missing key=value: ${key}=${value}"
		fi

	done < "${MODPATH}/config.sh"
fi

# Persist the capability profile during installation, before first reboot.
# Existing user configuration is not overwritten.
if BRENE_AUTO_INSTALL_BIN="${PERSISTENT_DIR}/susfs" /system/bin/sh "${MODPATH}/tools/susfs-auto.sh" install; then
    echo '[✅] SuSFS capability profile persisted; boot-time recheck enabled'
else
    echo '[⚠️] Auto-probe deferred to boot; user settings preserved'
fi

update_config_date

# Reset fake_files folder
[[ -d "${PERSISTENT_DIR}/fake_files" ]] && rm -rf "${PERSISTENT_DIR}/fake_files"
mkdir -p "${PERSISTENT_DIR}/fake_files"

# Hot install support
if [[ "${KSU_HAS_HOT_INSTALL}" == true ]]; then
	export MODULE_HOT_INSTALL_REQUEST=true
fi
