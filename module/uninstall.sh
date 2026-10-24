#!/bin/bash
# shellcheck disable=SC2154
# BRENE uninstallation is intentionally non-destructive.
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin
SUSFS_BIN=${DEST_BIN_DIR}/susfs
OUR_BIN=${PERSISTENT_DIR}/susfs
PREVIOUS_BIN=${PERSISTENT_DIR}/susfs.previous

# Do not remove a shared binary installed by another tool after BRENE.
removed_owned_tool=0
if [[ -f "${OUR_BIN}" && -f "${SUSFS_BIN}" ]] && cmp -s "${OUR_BIN}" "${SUSFS_BIN}"; then
    if [[ -f "${PREVIOUS_BIN}" ]]; then
        cp -pf "${PREVIOUS_BIN}" "${SUSFS_BIN}" &&
            echo '[BRENE] Restored the pre-existing shared susfs tool'
    else
        rm -f "${SUSFS_BIN}"
        removed_owned_tool=1
        echo '[BRENE] Removed BRENE-owned susfs tool'
    fi
else
    echo '[BRENE] Shared susfs tool changed externally; leaving it untouched'
fi

# Leave existing aliases in place if a previous or third-party tool is retained.
if [[ "${removed_owned_tool}" == 1 ]]; then
    for link in "${DEST_BIN_DIR}/sus" "${DEST_BIN_DIR}/ksu_susfs"; do
        if [[ -L "${link}" && "$(readlink "${link}")" == "${SUSFS_BIN}" ]]; then
            rm -f "${link}"
        fi
    done
fi
# Preserve the persistent configuration and backups on uninstall to avoid data loss.
echo '[BRENE] Persistent configuration was retained at /data/adb/brene'
