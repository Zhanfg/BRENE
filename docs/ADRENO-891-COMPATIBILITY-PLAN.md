# Adreno 830 / Qualcomm userspace GPU driver 891.11.3 — actual uploaded ZIP audit

## Confirmed exact source
Uploaded `891._extracted18PM_4.0.27.0.zip` (SHA-256 `93f6d44313e5f84a00b2d3dbcbc2782627957b18943f4d188c8614e20ca761cf`). This exact archive declares `id=adreno_gpu_driver`, **`version=892`** and **`description=Adreno 8xx 891.11.3`**. This is *not* the same metadata as the previously inventoried installed `v3.0 / 891.7.1`. GPU remains hardware Adreno 830.

73 ZIP entries, 28 AArch64 ELF shared objects, 13 firmware, 4 GPU KBC entries and 8 Vulkan/OpenGL permission XML. No standalone `.ko`. `libllvm-qgl.so`, `egl/libGLESv2_adreno.so`, and `hw/vulkan.adreno.so` are included. Readelf dynamic tags of the 28 ELFs showed no `TEXTREL`; this does not prove runtime memory pages have not been modified.

## Issues confirmed in installer, not hypothetical
- Original installer recursively deletes arbitrary `*shader*` files under `/data`; uninstaller removes shaders, graphite caches and GPU caches across application data.
- Copies `qgl_config.txt` although that file is **absent** from supplied ZIP.
- If `magisk_overlayfs` is present, explicitly invokes OverlayFS integration and then deletes the module `system/` payload.
- Ships a legacy `META-INF` updater requiring Magisk; it is not necessary for a dedicated KernelSU/SukiSU module.

## Local safe-repackage artifact
A **KernelSU/SukiSU-specific** ZIP was produced locally from the user-uploaded archive:

`Adreno_v89111_V892_KSU_Safe_v1.zip`

SHA-256: `9ca850e0a8394f2cd737db75e957732ac9f8ddecd6dc2874fca7eeba7985db59`.

The repack preserves the bytes of **48** executable/firmware/GPU KBC payload entries, all original GPUs/feature XML, core module ID, and the upstream SELinux labeling rules. Only installer/uninstaller scripts, module metadata, the legacy Magisk-only installer and a short safety README were changed. It does **not** change the GPU loader, memory-mapping behavior, OEM overlayfs, running applications or the kernel.

Local QA: ZIP CRC, module.prop root, shell syntax and payload SHA-256 comparison passed. This ZIP is a **test build**, not validated on Android. Binary payload cannot be committed to this repository through the UTF-8-only GitHub contents editor; use the sandbox attachment from the conversation.

## Real fix track — scoped driver loading
1. Collect stock ColorOS firmware's matching Vulkan/EGL/LLVM userspace libraries and identify how the installed GPU driver currently replaces them.
2. Evaluate source [live-gpu-driver](https://github.com/insterbridge/live-gpu-driver) as a starting point for a per-app v891 dependency-consistent profile, rather than modifying BRENE's unrelated SUSFS concealment layer.
3. Preserve critical OEM services (SurfaceFlinger, camera, SystemUI) on stock libraries; scope replacement to selected game processes. Validate each namespace actually loads the new .so bytes before accepting success.
4. Measure Mount and Memory from the **same process** in stock and v891 states with comparable workloads, avoiding false cause assignment to the many OPlus-native `/my_*` and `/mnt/opex` mounts.
5. Keep V@891 Vulkan/GLES compiler dependencies together; ensure ABI, SELinux and driver firmware compatibility before release.

**Limit:** A safer installer does not resolve DuckDetector Mount and Memory findings. No new kernel `.ko` has been justified or compiled. TEE remains out of scope.
