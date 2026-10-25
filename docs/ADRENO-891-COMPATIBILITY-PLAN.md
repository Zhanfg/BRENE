# PJZ110 GPU v891 driver stack compatibility and remediation

## Confirmed

The user's physical GPU is Adreno 830 (SM8750). Their installed module ID is **adreno_gpu_driver**, module version **v3.0**, Qualcomm userspace driver release **V@0891.7.1**. Driver 891 does not mean the physical GPU has changed.

The original driver ZIP is not available in this repository. Consequently, this document cannot claim which files the module actually replaces or how its mounts are implemented. The observed OPlus-like /my_* and /mnt/opex overlays must not be assumed to come from the GPU module without mount-source evidence.

## Root cause hypothesis to test

- Mount: replacing vendor GPU libraries globally can introduce per-file bind or overlay filesystem entries. Determine the mount source and namespace for each target. Do not hide or unmount ColorOS OEM overlays.
- Memory: updated libraries may alter relocation, executable mapping, Shared_Dirty and swap behavior. Counters are not proof of Hook or modified instructions. Inspect file-backed mappings and ELF relocations before action.
- Hardware/kernel: stock Adreno 830 KGSL, GMU and firmware remain device-specific. A new .ko cannot be justified by a userspace driver release change alone.

## Preferred implementation: scoped v891 user libraries

Retain the native ColorOS EGL/Vulkan stack for system services; load v891 libraries only into explicitly selected application mount namespaces.

1. Extract and inventory the real driver ZIP. Preserve both ELF32 and ELF64 libraries, ELF DT_NEEDED/SONAME, Vulkan ICD, EGL/GLES, LLVM compiler, and auxiliary dependencies.
2. Form atomic dependency-compatible driver profiles. No blind mixing of OEM LLVM with v891 Vulkan, or replacing vendor/lib64 as an entire directory when per-file staging is possible.
3. For apps that need v891, apply only the selected coherent driver profile in their namespace and verify effective mapped inode, SELinux labels, permissions and driver identity. Preserve the original global driver.
4. A/B: stock globally vs global v891 vs scoped v891, compare the same workloads, graphics stability, mount namespace, and actual smaps of that process.
5. Failure rollback restores original per-app routing, without deleting staged files while mounted.

Potential implementation reference: https://github.com/insterbridge/live-gpu-driver (per-app mode). Its loader takes AdrenoToolsDrivers-format packages; a KernelSU Full ZIP is **not** automatically compatible and must be converted after the contents are inspected. Its logcat-based app watcher may race with early library loading.

## If global v891 is required

Modify the original GPU module rather than BRENE. Prefer precise per-file binds, ensure complete userspace library dependency closure, minimize whole-directory overlay staging, verify clean unmount and restore behavior. Do not overlay OPlus vendor partitions globally without an explicit lifecycle and baseline.

## Artifacts required

The original **adreno_gpu_driver v3.0 / V@0891.7.1** module ZIP (or a private read-only inventory of its contents). Without it we cannot build an evidence-based updated driver module or truthfully report the duck detector anomalies fixed.

TEE is intentionally out of scope. Do not claim detection success from a modified score or forged /proc output.
