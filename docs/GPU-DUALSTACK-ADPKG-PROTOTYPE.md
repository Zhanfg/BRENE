# GPU DualStack — Vulkan ADPKG prototype (2026-10-25)

**State:** two ZIPs generated privately from the user-provided Adreno 830 driver V@0891.11.3, with 8/9 ELF64 AArch64 libraries. Both pass local ZIP/ELF tests but **neither has been loaded on-device**. These are user-application custom Vulkan drivers, **NOT KernelSU/SukiSU flashable modules**. Proprietary blobs remain private; do not commit to this public repository.

## Build artifacts in the ChatGPT conversation

- **CORE**: `Adreno_89111_Vulkan_ADPKG_CORE_EXPERIMENTAL.zip`, 4,840,054 bytes, SHA256 `16f379f73bab03dd8c6f70cf17fefe81e09a46aaa93551d64ae53b49e0cc7427`, 8 libraries.
- **Extended**: `Adreno_89111_Vulkan_ADPKG_EXPERIMENTAL.zip`, 31,107,338 bytes, SHA256 `a3c8c97f422685ac55f07dd7b189fae3652c6eb967ada6272195756a27227d13`, adds optional LLVM qgl shader compiler library, 9 libraries.
- Unmodified source ZIP SHA256 `93f6d44313e5f84a00b2d3dbcbc2782627957b18943f4d188c8614e20ca761cf`.
- Source converter `Build_Adreno891_ADPKG.py`, accompanying per-file validation JSONs and `GPU_DualStack_Preflight.sh` are conversation artifacts, not published GPU files.

## What the converter actually does

1. Detects `system/vendor/lib64/hw/vulkan.adreno.so` and reads ELF64/AArch64 `PT_DYNAMIC`, `DT_NEEDED`, `DT_SONAME` and dynamic string tables.
2. Computes the closure of bundled directly-required .so libraries, includes *optional* `libllvm-qgl.so` only in Extended variant.
3. Renames the private libraries with same-length aliases (e.g. `libgsl.so` to `v89gsl.so`, `vulkan.adreno.so` to `vulkan.ad0891.so`) and patches **only referenced `DT_SONAME` / `DT_NEEDED` dynamic strings**. No program instruction bytes are intentionally modified. Reverse substitution of all 9 files re-created the original bytes **exactly**.
4. Produces ADPKG v1 `meta.json` plus shared libraries at archive root; excludes all `system/vendor/etc/permissions`, `firmware`, `gpu/kbc`, global GLES binaries and install scripts.
5. Verifies no global-boot files, all file lengths, CRC, SHA256 and ELF reference chains.

## Warnings / release blockers

- **29 externally needed SONAME names** remain unresolved against the user's live ColorOS linker namespace. Checking presence on disk is necessary but **not sufficient** to establish loader access; QTI Mapper, Allocator and Gralloc versions are particularly sensitive.
- Static `DT_NEEDED` closure cannot identify arbitrary `dlopen` libraries. A namespaced library may not satisfy a runtime lookup using its old SONAME. This is an **experimental package**.
- Source input is **64-bit-only**. GLES/OpenGL remains OEM stock for an app using this Vulkan profile; no guarantee that v891's complete userspace stack, new firmware functions, or Vulkan 1.4 is available.
- An app must explicitly integrate `libadrenotools` (e.g. a supported emulator); it cannot be forced to load the driver using this ZIP.
- If original global `adreno_gpu_driver` is still active, a per-app test cannot establish OEM-vs-v891 isolation. Do not automatically disable users' existing driver modules.
- New driver loading changes the real process environment. This is **not** a claim that DuckDetector will find every surface clean; no kernel interceptions or output forgery.

## PJZ110 gate

Run bundled `module/tools/gpu-dualstack-preflight.sh` using `sh` without arguments, collect its local Download report privately; verify external library presence, `ro.gfx.driver.0/.1`, module activation, then run CORE in an explicitly compatible application. If the runtime probe fails, revert the app's driver selection to OEM. Do not flash any ADPKG as a KernelSU module.

### Sources

- ADPKG specification: https://github.com/bylaws/libadrenotools/blob/master/tools/ADPKG.md
- App opt-in requirement: https://github.com/bylaws/libadrenotools
- PPSSPP driver manager: https://www.ppsspp.org/docs/reference/custom-drivers/
- Android GraphicsEnvironment restrictions: https://android.googlesource.com/platform/frameworks/base/+/HEAD/core/java/android/os/GraphicsEnvironment.java
