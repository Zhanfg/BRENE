# Adreno 830 V@0891.11.3 — GLOBAL GPU mount architecture (v0.2.0 experimental)

## Correct requirement

The user explicitly requires the updated GPU **globally** available to all applications, SystemUI, SurfaceFlinger, and system services. **Do not substitute per-app driver selection**, AdrenoTools-only loading or the skip-mount-only DualStack data bank for this goal. Minimize mount-visible changes where possible, but never claim invisibility by changing detector scores or falsifying `/proc`, `smaps`, `mountinfo` or `statx`.

## Actual uploaded source

The uploaded `891._extracted18PM_4.0.27.0.zip` (42 MiB) is `adreno_gpu_driver` version 892, V@0891.11.3; it differs from the user's previously installed V@0891.7.1. It has 53 files in `system/`, including **28 AArch64 user-mode .so libraries**, 13 GPU firmware files, 4 GPU KBC assets and 8 graphics feature permission XMLs. The raw proprietary Qualcomm bytes are NOT published to this public repository.

The user's earlier DuckDetector scan has 13 Memory findings, prominently executable `Shared_Dirty` and Swap in `/vendor/lib64/libllvm-qgl.so`, `/vendor/lib64/egl/libGLESv2_adreno.so`, and `/vendor/lib64/hw/vulkan.adreno.so`. Mount warnings report overlayfs on /system and /vendor, but an independent report identified native ColorOS /my_* and /mnt/opex overlays as well. Neither is by itself proof of module stealth or GPU code modification.

## Prototype: **full-system visibility**, guarded file binds

A chat-local (private) KernelSU module `brene_gpu_global891` v0.2.0-beta was built from this exact payload, retaining all 53 original system files in `payload/`. The module has `skip_mount` to bypass automatic entire-tree KernelSU overlay, but **does not disable global mounting**. Its `post-mount.sh` runs a separate mount engine:

1. Reject an enabled legacy `adreno_gpu_driver` to prevent conflicting layers; never disable it silently.
2. Ensure the kernel module is in normal early boot, not late-load mode; reject if Zygote or SurfaceFlinger already started.
3. Check all 28 vendor/system native-library targets already exist, and all payload libraries are present; **reject partial installs**.
4. Enter PID 1's mount namespace via `nsenter -t 1 -m`.
5. Clone the expected SELinux context from each existing stock target onto the module source.
6. Bind the new v891.11.3 library file over the existing system or vendor path. Check that target and payload resolve to the exact same device/inode after binding.
7. On any error, undo newly registered bind mounts in reverse order; never delete shader caches.
8. On boot completed, sample visibility of key driver libraries from Zygote and SurfaceFlinger proc-root views.
9. If a previous boot never reached boot-completed, automatically suppress further mounts and disable the module on the next boot.

**Key limitation:** this strict implementation is compatible only when all 28 replaced .so names already exist on stock ColorOS; a missing new filename requires a properly designed *new-file injection* backend (scoped overlayfs/hybrid or an OEM-updatable graphics package), not silent omission. The 13 firmware, four KBC files and eight XMLs are **preserved but not yet actively mounted** in this file-bind prototype, so this is **not yet a full 53-file GPU update**. GPU firmware may load before KernelSU post-mount and cannot be assumed updated by a later file bind.

## Why it cannot promise zero detection

Every genuine system-wide replacement changes observable state, at minimum the loaded user-space GPU libraries, driver version/capabilities, shared-dirty memory pages or the filesystem/mount topology. Overlayfs usually leaves overlayfs signals; per-file bind mounts avoid whole-directory overlays but leave per-file mount records/backing filesystem identity. If a detector runs in a process that uses v891, it can legitimately see v891. This architecture reduces unnecessary replacement breadth but is not a **detector-evasion guarantee**.

## Validation already done

- All 53 source payload files were compared byte-for-byte to the uploaded ZIP.
- All 28 native-library entries are in the exact-name strict manifest.
- ZIP CRC and shell syntax checks passed.
- Mocked global mount test: 28 bind attempts succeeded in simulated target filesystem.
- Injected failure at the fifth bind caused reversal of the four already registered binds.
- Removing a required OEM target prevented any mounting.
- **No real PJZ110 bind, EGL/GLES rendering, Vulkan physical device enumeration, GPU firmware compatibility or DuckDetector score improvement has been verified.**

A no-argument private read-only `BRENE_GPU_Global891_Preflight.sh` reports actual availability of all 28 OEM target files. Use it before considering any flash, and keep recovery access to revert GPU modules.

## Further engineering to reach production

- From actual device preflight, identify new ELF names requiring insertion and implement an atomic hybrid mount plan for those directories while preserving complete `DT_NEEDED` and vendor linker namespace behavior.
- Distinguish stock /my_* /mnt/opex factory overlays from the GPU module's mounts, without falsifying scan data.
- Validate GPU firmware/KBC version compatibility independently; do not install firmware updates that require reloading the GPU after the kernel has started.
- Stress test SurfaceFlinger, hardware composer, camera, video, games, GLSL/Vulkan shader compilation, suspend/resume, thermal throttling, crash recovery and reboot.
- Compare original global module, safe-installer module and true GlobalMount on identical firmware. Check both Vulkan/GLES features and DuckDetector results. No need for a separate KGSL .ko without kernel ABI evidence.

The `main` branch should remain untouched; stage through Draft PR until physical device verification.
