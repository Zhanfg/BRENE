# BRENE GPU DualStack module MVP — v0.1.0-beta

This is a **separate KernelSU/SukiSU module**, not a modification to the existing BRENE root module or a new kernel KO. It is distributed privately from the chat artifact so the user's uploaded Qualcomm binary driver archives are not published to GitHub.

## What actually works

- `module.prop`, `skip_mount`, `action.sh`, lightweight `webroot/index.html`, and read-only profile metadata.
- The original full V@0891.11.3 archive and the derived Vulkan-only AdrenoTools driver archive are preserved byte-for-byte as a **nested, inert payload bank**.
- `skip_mount` means KernelSU's automatic system overlay is disabled. There is no top-level `system/` tree and no boot hook, global bind mount, SELinux or firmware modification.
- WebUI or KernelSU Action exports the Vulkan driver ZIP to `/sdcard/Download/BRENE_Adreno_Vulkan_89111.zip`. This allows an **already compatible** app (e.g. with AdrenoTools) to use the driver in its own Vulkan loading path.
- On-device tool checks both embedded SHA-256 values before exporting. It warns if the original globally mounted `adreno_gpu_driver` module remains enabled, but does **not** change that module.

## Test evidence

- Original source archive: SHA-256 `93f6d44313e5f84a00b2d3dbcbc2782627957b18943f4d188c8614e20ca761cf`
- Vulkan AdrenoTools archive: SHA-256 `a3c8c97f422685ac55f07dd7b189fae3652c6eb967ada6272195756a27227d13`
- Module build: `BRENE_GPU_DualStack_v0.1.0-PJZ110.zip`; SHA-256 `5eebf4b6cb6d5324879da5c1fd85123328df8b7b26a69adc1cfa61c34afdd560`.
- ZIP CRC, nested-archive byte equality, no global `system/` mounts, Shell parse, tool `verify`, on-demand `export`, exported-driver byte equality passed.
- Chromium WebUI mock interactions, nonoverflowing layout at 320, 393 and 768 px passed; screenshot available as conversation artifact, not checked into this repository.

## What is not complete

- Does **not** provide v891 OpenGL ES system-wide. PPSSPP-style custom AdrenoTools loading supports Vulkan, not OpenGL ES.
- Does **not** transparently inject drivers into arbitrary games or claim a race-free app-private mount backend. Generic app-process mount hooks can run after graphics libraries are already loaded. That is unsuitable for a production graphics stack.
- Is **not** tested for real-device Vulkan initialization, Adreno 830 ELF/mapper HAL compatibility, frame rendering or crashes.
- Does **not** guarantee immunity to detection; an app using v891 can legitimately observe its mapped driver or Vulkan version. The intent is to reduce unnecessary **global** modifications, not fabricate /proc or Memory results.
- Original global `adreno_gpu_driver` is **not disabled automatically**. To evaluate stock versus selective v891, the user should back up and then disable the original global module in KernelSU, reboot, verify system graphics, and use a compatible application to load v891.

## Next generation

1. Add a non-disruptive PJZ110 runtime eligibility gate: native `GraphicsEnvironment` / `ro.gfx.driver.0` support, linker/SPHAL and Vulkan/EGL ABI compatibility, surfaceflinger stability.
2. Build a **real per-app graphics-loader integration** only when the platform/target application has a defined pre-library-load attachment point. Late logcat watchers are not sufficient for a guaranteed first launch.
3. GLES enhancement requires a separate verified loader (updatable Android graphics driver package or an application integration), not a Vulkan-only driver archive.
4. Require actual game runtime Vulkan extension/version checks; compare stock, global v891 and selective v891 in the same firmware without falsifying memory or mount observables.

Sources:
- https://kernelsu.org/guide/module.html
- https://www.ppsspp.org/docs/reference/custom-drivers/
- https://android.googlesource.com/platform/frameworks/base/+/HEAD/core/java/android/os/GraphicsEnvironment.java
