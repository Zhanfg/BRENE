# BRENE fork: SuSFS 2.3.0 development notes

This fork extends BRENE's WebUI and userspace control layer; it does **not** patch or build an Android kernel. The running kernel must already support SuSFS and each requested feature.

## Architecture and feature matrix

WebUI: `module/webroot/`, persistence: `/data/adb/brene/`, userspace binary: `/data/adb/ksu/bin/susfs`.

The feature matrix in the SuSFS tab reads `susfs show enabled_features`, `show version` and `show variant` at runtime. Compiled features are **not** guaranteed to work on a specific device, and the compilation status of `HIDE_KSU_SUSFS_SYMBOLS` cannot be toggled from userspace.

The additional KSTAT and custom Cmdline/Bootconfig paths are empty by default. Saving a rule writes a file; actual application requires reboot. This is an experimental development build; take a module backup before installing.

## Dynamic KSTAT rules

File: `/data/adb/brene/custom_sus_kstat.txt`; max 200 rules and 32 KiB.

Example:
```text
/system/etc/hosts|update
/system/framework/services.jar|clone
```

`pre` calls `add_sus_kstat` from `post-fs-data.sh`; `post` calls `update_sus_kstat` or `update_sus_kstat_full_clone` from `boot-completed.sh`. **These two hooks do not bracket every third-party module mount operation.** Only use for a verified compatible mount lifecycle.

## Static KSTAT rules

File: `/data/adb/brene/custom_static_kstat.txt`; max 200 rules and 32 KiB.

Each line contains a path followed by **12** values (pipe-delimited):

```text
/absolute/path|ino|dev|nlink|size|atime|atime_nsec|mtime|mtime_nsec|ctime|ctime_nsec|blocks|blksize
```

Each numeric field can be the literal `default` or a non-negative decimal number of up to 20 digits. Static rules are attempted at `boot-completed.sh` after the dynamic KSTAT update, and failures are logged to `/data/adb/brene/kstat.log`. Many types of files are unsuitable for metadata spoofing; verify each target.

## Custom Cmdline / Bootconfig

Saved files:
- GKI: `/data/adb/brene/custom_bootconfig.txt`
- non-GKI: `/data/adb/brene/custom_cmdline.txt`

The module selects a file based on the kernel-reported `susfs show variant`, and imposes an 8 KiB limit. A user override applies **only when both** `config_spoof_cmdline_or_bootconfig=1` and `config_use_custom_cmdline_or_bootconfig=1`. Both default to off. When the custom file is empty, the original BRENE preset is used.

**Do not paste an incomplete kernel command line:** custom content replaces the entire displayed file, not individual keys. The source content is always passed as file data, never `source`d or `eval`ed.

## Installation and recovery

- Installer tests the bundled SuSFS executable against the live kernel **before** installing it to a shared location.
- The existing shared `susfs` is preserved at `/data/adb/brene/susfs.previous` on first install when it is not already BRENE-managed.
- Uninstaller restores the previous binary only when the shared copy still matches BRENE's own program.
- User configuration is preserved after uninstall by default, to avoid irreversible loss.
- Older BRENE installations may have already overwritten their previous `susfs` executable. This fork cannot reconstruct a binary that was never backed up.

## Validation and release gates

GitHub Actions validates Shell/JavaScript syntax, WebUI wiring, mocks the KSTAT `susfs` program for early, late and unsupported cases, packages a ZIP and uploads it as a workflow artifact. These are **host-only tests**, not real kernel validation.

Before marking PR ready, test at minimum:
1. installation, reboot and uninstall restoration using a non-primary device;
2. both SuSFS GKI and non-GKI variants if supported hardware is available;
3. stale/missing/unsupported kernel features, custom rule malformed data;
4. full source-to-binary tool compatibility;
5. application and rollback of each custom KSTAT and boot argument rule.

See upstream patch branches at https://gitlab.com/simonpunk/susfs4ksu . The upstream default/master branch is intentionally not the newest SuSFS implementation.

License obligations inherited from BRENE remain applicable.
