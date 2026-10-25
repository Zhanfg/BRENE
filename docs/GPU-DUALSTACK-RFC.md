# RFC: BRENE GPU DualStack — driver functionality without global graphics-stack replacement

**Status:** architecture proposal, not implemented; source data: user-supplied GPU module `891._extracted18PM_4.0.27.0.zip` (versionCode 892, V@0891.11.3). The package’s proprietary GPU binaries must **not** be committed to this public repository.

## Non-negotiable goals

- Retain actual **Adreno 830** hardware, ColorOS stock KGSL/GMU/firmware, SurfaceFlinger, camera and system processes.
- Let explicitly selected graphics applications use a coherent **891.11.3** replacement graphics driver **without global /vendor or /system overlays**.
- Observe real Vulkan/GLES capabilities of selected apps; do not forge kernel state, /proc/maps, mountinfo, statx, GPU vendor/version, Memory Shared_Dirty or detector results.
- Fail closed and roll back per-app to OEM driver on incompatibility; never auto-apply to system apps or banking/integrity apps.
- Runtime intent **isolation**, not a claim of universal nondetectability. An app that actually loads the updated driver can legitimately inspect its version, loaded libraries and memory statistics.

## Why the uploaded ZIP cannot simply be hidden

Its root tree is `system/vendor`, with **28 AArch64 shared libraries** including `hw/vulkan.adreno.so`, `egl/libGLESv2_adreno.so`, `libllvm-qgl.so`, `libgsl.so`, `libOpenCL.so`, plus **13 firmware** and **8 global package feature XMLs** including Vulkan 1.4. Applying that tree through a KernelSU module makes new files visible globally; GPU libraries can alter executable-map statistics.

Crucially, the XML declaration `android.hardware.vulkan.version=1.4` is system-global. Making it globally visible while keeping stock Vulkan active for most apps could misrepresent platform capabilities. **Do not globally mount any package feature XML for an app-scoped profile.** Treat Vulkan 1.4 support as a measured runtime result from `vkEnumeratePhysicalDevices` / `vkGetPhysicalDeviceProperties` for the application loading v891.

Packaged GMU/AQE/SQE firmware must not be globally overlaid just because the userland driver includes it. Existing hardware firmware + userspace driver ABI compatibility must be established separately.

## Four planes

1. **Immutable driver bank**: stock remains mounted by OEM; v891 files stored as versioned and SHA-256-addressed read-only payload outside the KernelSU `system/` magic-mount tree. Retain matched ELF `DT_NEEDED`, `SONAME`, ABI and SELinux requirements. Maintain independent profiles for Vulkan, EGL/GLES, LLVM/compiler, and helper libraries, but apply them as complete, dependency-compatible sets; no arbitrary partial mixes.
2. **Native GraphicsEnvironment selector (preferred)**: check that the actual PJZ110 ROM supplies an eligible updatable production graphics driver using `ro.gfx.driver.0` and the Android native GraphicsEnvironment plumbing. If supported, ship a compatible GPU-driver APK/driver-library package plus declared SP-HAL dependency list and use per-app settings. On unsupported ROMs, **do not** silently force `ro.*` system properties or patch system_server. AOSP explicitly protects privileged/unupdated system apps from updatable drivers. Reference: https://android.googlesource.com/platform/frameworks/base.git/+/master/core/java/android/os/GraphicsEnvironment.java
3. **App-controlled Vulkan selector (safe fallback)**: for games/emulators with native alternate-driver support (e.g. AdrenoTools in PPSSPP), deliver an application-selectable Vulkan-only driver ZIP with its dependency closure. GLES still uses OEM unless the application selects an independently tested ANGLE-on-Vulkan path. ANGLE alone cannot make it use v891 Vulkan by magic. Confirm actual runtime loading, not merely availability in settings. Reference: https://www.ppsspp.org/docs/reference/custom-drivers/
4. **Privileged per-app process namespace backend (experimental last resort)**: only if OEM platform lacks a functioning native driver chooser **and** a target requires GLES plus Vulkan outside cooperating apps. This backend must complete coherent file bindings **before** target graphics library initialization. A `logcat` after-process-start watcher is not timing-safe; if race-free early attachment cannot be verified, disable the backend for that app. Never bind into PID 1, Zygote, SurfaceFlinger, system_server or whole vendor directories. Restrict mounts to the selected process’ private namespace, verify namespace identity, file hash/inode, SELinux label and all required libraries. This is compatible-behavior engineering, **not** a stealth hook or inspection evasion.
   
## Runtime state machine

`STOCK → ELIGIBILITY → STAGED → VERIFIED → ACTIVE`

- `ELIGIBILITY`: installed driver matches SM8750/Adreno 830 + Android 17, AArch64, actual library dependency closure, loader support, SELinux access. Production APK backend is selected only if ROM supports it.
- `STAGED`: v891 driver files are stored in dedicated profile bank, no global `system/vendor` overlay. Payload must not be deleted when referenced by any active mount/process.
- `VERIFIED`: in a disposable graphics test app, confirm v891 driver identity, Vulkan version, extensions, GLES path, actual `maps`/inode and rendering surface. Validate initialization and process teardown.
- `ACTIVE`: apply only to explicitly allowlisted, user-installed graphics apps; maintain versioned per-app rollback records.
- On failure: `FALLBACK_STOCK` for next app launch, persist failure reason; after repeated failures (e.g. two crashes) auto-disable the profile. *Do not assume rollback changes already-mapped libraries in running processes*; restart the target app.

## Backend selection and capability guarantee matrix

| Mode | Global mount | Vulkan v891 | GLES v891 | Kernel/firmware modification |
|---|---:|---|---|---|
| OEM Stock | No | No | No | No |
| AOSP updatable driver package **if OEM enabled** | No system/vendor overlay | Candidate; verify runtime | Candidate; verify runtime | No |
| Cooperative app / AdrenoTools | No | Supported on app's own loader if compatible | Not via AdrenoTools alone | No |
| ANGLE configured per app | No | Uses whichever Vulkan driver was actually selected | OpenGL-to-Vulkan via ANGLE, not native v891 GLES | No |
| Private process mount namespace fallback | In selected PID only | Candidate; timing verification | Candidate; timing verification | No |
| Original global KernelSU `system/vendor` module | Yes | Device-wide | Device-wide | May include dangerous firmware overlays |

This design **cannot promise that a process running the upgraded GPU driver will appear identical to an OEM process** under a comprehensive memory/driver API inspection. It instead reduces unexplained global modifications and gives consumers honest capability selection.

## First practical build gates

**P0 — Platform probe (read-only)**: collect `ro.gfx.driver.0`, `ro.gfx.driver.1`, `ro.vulkan.apex`, `ro.hardware.vulkan`, driver package presence, installed vendor driver ABI/hash and available Vulkan/GLES rendering paths. Use existing private GPU audit rather than publish private logs.

**P1 — Payload splitter**: transform supplied ZIP into v891 driver bank and dependency manifest, explicitly exclude `system/vendor/firmware/*` and all `etc/permissions/*.xml` from app-scoped deployment; keep them in a **quarantined** reference directory only.

**P2 — Native loader prototype**: if P0 confirms valid GraphicsEnvironment route, build a signed test driver APK and test a dedicated renderer app. Otherwise first deliver Vulkan-only app-compatible driver ZIP to a known AdrenoTools-capable application; no global mount.

**P3 — Consistency test**: test stock, current global v891, and selected-app v891: compare both DuckDetector and selected game processes; in the selected game prove Vulkan/GLES features and stable shader compilation; in nonselected/system processes confirm only OEM graphics libs. Include reboot/camera/SurfaceFlinger stability checks.

**P4 — Release**: incorporate user-driven profile selection and per-app rollback in BRENE's Chinese WebUI. Keep the GPU driver binaries as a **separate, private payload** from BRENE's public source. Do not enable experimental private-namespace backend by default.

## What is deliberately not proposed

No custom `.ko` to intercept mountinfo, maps, smaps, inode data or DuckDetector; these only falsify observations and cannot repair broken graphics. No blanket SUS_MAP rule on Qualcomm libraries, no modification of TEE, no global tampering with system-app visibility, no claim that Vulkan feature declarations alone enable new hardware capabilities.
