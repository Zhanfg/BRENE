# Adreno v891.11.3 uploaded package: static audit (2026-10-25)

This review concerns the user-supplied `891._extracted18PM_4.0.27.0.zip` only. **Do not upload proprietary GPU payload binaries or private reports to this public repository.**

## Confirmed, from ZIP contents
- ZIP metadata: `id=adreno_gpu_driver`, `version=892`, `description=Adreno 8xx 891.11.3`; the previously installed package was `v3.0 / V@0891.7.1`. The versions are not identical.
- 73 archive members, of which 28 are **ELF64 AArch64** libraries. All `DT_NEEDED` lists were extracted; no dynamic `TEXTREL` tag found in any bundled `.so`.
- Bundles 13 firmware files, eight Vulkan/OpenGL permission XMLs, four GPU KBC resources, 27 libraries under `system/vendor/lib64`, and `system/lib64/libgpuwork.so`.
- The GLES2 binary contains the printable embedded tag `V@0891.11.3x` (build date 2026-10-06).

## Confirmed original installer issues
1. `customize.sh` recursively deletes files named `*shader*` under `/data`, regardless of which application owns them. `uninstall.sh` removes broad unrelated caches.
2. It applies `same_process_hal_file` to all `system/vendor` files, including permission XML and GPU firmware; these file classes generally require distinct SELinux labels.
3. It references `qgl_config.txt` although the file is missing in the package.
4. With a separate Magisk OverlayFS implementation, a conditional branch can execute `rm -rf "$MODPATH/system"`, removing its own driver payload.
5. It globally replaces a large set of user-mode graphics libraries and feature files; it provides no application-scoped profile or dependency-closure verification against the device's installed OEM system.

## Test package generated privately
A **local**, non-public ZIP was produced with all 53 original `system/*` payload files byte-for-byte unchanged. Only `module.prop`, `customize.sh`, and `uninstall.sh` were modified. It removes destructive deletion, missing-file copy, and indiscriminate vendor labels while retaining all GPU binaries. Shell syntax, ZIP CRC, and mock installer paths were checked locally.

**This is installer-safety hardening only.** The same user-mode graphics libraries will still be mounted globally and could still cause DuckDetector Mount/Memory differences. No KMI-specific `.ko` was built; there is no grounded evidence that a kernel module is necessary. A real PJZ110/ColorOS load test remains outstanding.

## Proposed actual graphics-stack remediation

First compare the installed V@0891.7.1 package with this v891.11.3 ZIP, inspect on-device vendor library dependencies and /proc target namespaces. For users who only need newer GPU functionality for games, prefer the coherent per-application v891 graphics stack: leave SurfaceFlinger, system_server, launcher, OEM overlays and other processes on the system driver and place the selected profile in application-private namespaces. Validate no driver-load race; compare original driver, globally updated driver, and app-scoped updated driver under matching workloads. Per-app mounting can be implemented by an appropriately licensed GPU driver management project only after full profile mapping; no unsupported auto-injection patch has been committed here.

## Local integrity
Original ZIP SHA256: `93f6d44313e5f84a00b2d3dbcbc2782627957b18943f4d188c8614e20ca761cf`
Hardened ZIP SHA256: `aa68c18fa79732a82f4dfeaf1736743a3458d8b344f29b563e0a9bd92546fcce`

TEE and direct security-detector output manipulation remain out of scope.
