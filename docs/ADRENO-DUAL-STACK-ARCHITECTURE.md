# Adreno 830 + GPU V@0891.11.3: GPU Dual-Stack Architecture v0.1

**Design only: this is NOT a functioning scoped GPU driver module.** Keep this PR draft and do not merge with main until device testing. Proprietary GPU binaries remain private.

## The real constraint

Globally replacing /vendor GPU libraries introduces observable library maps, driver state and potential mount effects. SuSFS can reduce some path exposures but cannot make a legitimately loaded new GPU binary identical to the original in both behavior and memory accounting. We must distinguish avoiding unrelated global changes from claiming bypass of a detection tool. TEE is out of scope.

## Verified from uploaded ZIP

- `adreno_gpu_driver` module versionCode=892; user-mode driver V@0891.11.3, **not** previously installed v3.0 / V@0891.7.1.
- 28 native ELF64 AArch64 libraries; **no 32-bit GPU libraries** in this package.
- Static DT_NEEDED closure from `vulkan.adreno.so`: 8 bundled libraries, approx. 11.44 MB.
- Static EGL/GLES closure: 11 bundled libraries, approx. 9.99 MB.
- Additional 13 GPU firmware, four KBC resources and eight graphics feature XML; these are not automatically safe per-app.
- External dependencies (display mapper and graphics allocator variants) and dlopen resources must be verified on ColorOS.

## Layers

1. **OEM_NATIVE (default)**: original ColorOS EGL/GLES/Vulkan for SurfaceFlinger, SystemUI, camera and normal apps; stock kernel KGSL, GMU and firmware. The v891 package is stored privately rather than KSU-global system/vendor overlays. KernelSU skip_mount alone does not make libraries executable from arbitrary app namespaces.
2. **GPU891_VK_SCOPED (opt-in)**: for apps which support an explicit driver-selection API, install one coherent v891 Vulkan + library closure. Use a supported Android updatable graphics-driver route, when actually available on the specific ROM, or an app's built-in libadrenotools interface. libadrenotools does not automatically modify every app.
3. **GPU891_GLES_SCOPED (conditional)**: validate Android graphics driver opt-in for EGL/GLES. ANGLE can redirect supported GLES clients through Vulkan, but choosing ANGLE does not by itself select a v891 Vulkan driver. Direct GLES route is unsupported until a coherent, correctly loaded private driver is proved.
4. **STOCK_FIRMWARE (fixed initially)**: the device-level GPU firmware, KBC and KGSL remain OEM. Driver improvements that depend on newer global firmware cannot be promised in the isolated mode.
5. **Legacy global profile (research only)**: permits a broader GPU upgrade after boot, UI, camera and rendering checks, but it is inherently more observable and has a greater compatibility cost; not an invisibility solution.

## Control plane

- **Profile Validator:** SHA256, ELF architecture, DT_NEEDED/SONAME, runtime dlopen dependencies, external SP-HAL/VNDK mapper/allocator requirements, SELinux access and driver capabilities. Missing evidence => do not auto-select.
- **Profile Router:** route by actual supported loader and configured application needs; never use security-checker identity as a special case. Profile change before driver load, not via late logcat race.
- **Capability Probe:** independently confirm Vulkan driverVersion and extensions; EGL/GLES info; mapped library inode and hash. Do not publish unsupported Vulkan 1.4 feature XML globally.
- **Recovery:** atomic profile changes, immutable OEM fallback, recovery boot disabling, no deleting mounted staging paths.
- **BRENE Adapter:** show profile status and validation only. BRENE AutoShield remains unchanged, and SuSFS has no automatic authority to hide GPU vendor libraries.

## Acceptance tests

1. Compare actual installed OEM graphics blobs/dependencies and uploaded v891; verify which files, contexts and resources really load.
2. Install a private Vulkan profile into one app that explicitly supports alternate Adreno drivers; prove v891 actually loads and renders. Stock system processes must continue using OEM.
3. Validate GLES separately; do not infer GLES v891 works from Vulkan-only success. 32-bit apps should remain on OEM.
4. A/B test stock global, original global v891, and scoped v891 with identical workloads; compare performance, camera/UI stability, real mounts and private memory metrics. Do not modify DuckDetector verdicts.
5. Only after successful full-stack compatibility, build an installable GPU-profile package. **No KO is justified by this user's current purely user-mode driver file inventory.**

## Sources

- ZIP uploaded by user; static derived dependency manifest is available privately in the chat; no proprietary .so uploaded to GitHub.
- AOSP GraphicsEnv: https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/libs/graphicsenv/GraphicsEnv.cpp
- Android Vulkan HAL: https://source.android.com/docs/core/graphics/implement-vulkan
- Android GL driver loader: https://source.android.com/docs/core/graphics/implement-opengl-es
- ANGLE opt-in: https://android.googlesource.com/platform/external/angle/+/refs/heads/main/doc/DevSetupAndroid.md
- libadrenotools: https://github.com/bylaws/libadrenotools
- KernelSU mounting: https://kernelsu.org/guide/module.html
