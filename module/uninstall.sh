#!/bin/bash
# shellcheck disable=SC2154
# BRENE uninstallation is intentionally non-destructive.
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin
SUSFS_BIN=${DEST_BIN_DIR}/susfs
OUR_BIN=${PERSISTENT_DIR}/susfs
PREVIOUS_BIN=${PERSISTENT_DIR}/susfs.previous

# Do not remove a shared binary installed by another tool after BRENE.
if [[ -f "${OUR_BIN}" && -f "${SUSFS_BIN}" ]] && cmp -s "${OUR_BIN}" "${SUSFS_BIN}"; then
    if [[ -f "${PREVIOUS_BIN}" ]]; then
        cp -pf "${PREVIOUS_BIN}" "${SUSFS_BIN}" &&
            echo '[BRENE] Restored the pre-existing shared susfs tool'
    else
        rm -f "${SUSFS_BIN}"
        echo '[BRENE] Removed BRENE-owned susfs tool'
    fi
else
    echo '[BRENE] Shared susfs tool changed externally; leaving it untouched'
fi

for link in "${DEST_BIN_DIR}/sus" "${DEST_BIN_DIR}/ksu_susfs"; do
    if [[ -L "${link}" && "$(readlink "${link}")" == "${SUSFS_BIN}" ]]; then
        rm -f "${link}"
    fi
done
# Preserve the persistent configuration and backups on uninstall to avoid data loss.
echo '[BRENE] Persistent configuration was retained at /data/adb/brene'
