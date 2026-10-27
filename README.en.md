# SukiSU-Ultra + SUSFS Kernel for Redmi Turbo 3 / POCO F6 (peridot)

<div align="center">

[![Kernel](https://img.shields.io/badge/Kernel-6.1.138-blue.svg)](https://kernel.org)
[![Root](https://img.shields.io/badge/Root-SukiSU--Ultra%20builtin-6f42c1.svg)](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.3.0-red.svg)](https://github.com/simonpunk/susfs4ksu)
[![Device](https://img.shields.io/badge/Device-Redmi%20Turbo%203%20%2F%20POCO%20F6-orange.svg)](#)
[![Android](https://img.shields.io/badge/Tested%20on-Android%2017%20ported%20ROM-green.svg)](#)
[![Build](https://img.shields.io/badge/Build-GitHub%20Actions-2088ff.svg)](https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/actions)

**A fork of [Flavenz-Kernel-Peridot](https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot): KernelSU Next replaced with SukiSU-Ultra, keeping the ACK 6.1.138 base, peridot defconfig and SUSFS. Verified on a ported OS4 (Android 17) ROM.**

</div>

---

## What is this

A custom GKI kernel for the **Redmi Turbo 3 / POCO F6 (`peridot`, Snapdragon 8s Gen 3 / SM8635)**:

| Item | Value |
|---|---|
| Kernel base | ACK `android14-6.1-lts` @ `0c3d559bcd85` = `6.1.138-android14-11` |
| Device config | peridot defconfig from `Mohithash/kernel_xiaomi_sm8635`, branch `17` |
| Root | **SukiSU-Ultra `builtin` branch** (pinned `0b666ca`), built into the kernel (GKI mode); manager `41095-6` |
| Hiding | **SUSFS v2.3.0** (`gki-android14-6.1` patch from `ShirkNeko/susfs4ksu`, rebased onto ACK `0c3d559`) |
| Toolchain | Neutron Clang 30062026, ThinLTO, GitHub Actions |
| Extra | Flavenz's Droidspaces container-related kABI-safe configs kept (SYSVIPC / namespaces / MACVLAN / IPv6 NAT, etc.) |
| KPM | Not enabled — KernelPatch-patched images failed to boot on this device (see Known limitations) |

### Differences from upstream Flavenz

- KernelSU Next → **SukiSU-Ultra builtin** (use the SukiSU manager 41095+; the KSU Next manager is not compatible)
- SUSFS patch switched to ShirkNeko's SukiSU-compatible patch set, plus SukiSU hide hooks (`patches/sukisu/69_hide_stuff.patch`)
- `-Werror` disabled for SukiSU builtin code (`-Wno-error`), otherwise Clang fails on `-Wimplicit-fallthrough`
- KPM not enabled (KernelPatch-patched images failed to boot on this device)
- Verified booting/rooting/SUSFS on a **ported OS4 (Android 17)** ROM

---

## Verified on

| Item | Value |
|---|---|
| Device | Redmi Turbo 3 `24069RA21C` (peridot) |
| ROM | Ported OS4.0.25.0, Android 17 (SDK 37), `CP2A.260605.016`, fingerprint `Redmi/peridot/peridot:17/OS4.0.25.0.XEOCNXM` |
| Kernel | `6.1.138-android14-11-ga3b9c44908dd-ab13320413+` |
| Manager | SukiSU-Ultra **v4.2.1-r2 (41095-6)**, kernel full version `v4.2.1-r2-0b666cad@HEAD` |
| SUSFS | **v2.3.0**, `ksud susfs implementation = builtin`, `status = true` |
| Flashing | `fastboot boot` for a temporary test → `fastboot flash boot` to persist; `init_boot` kept stock |
| Hardware | root (`su`, `u:r:ksu`), modules, Zygisk Next/LSPosed, camera, Wi-Fi driver, charging, 5G all working |

> ⚠️ Personal, unofficial build. Back up first and prefer a temporary `fastboot boot` test on different ROM/firmware versions.

---

## Download

- Releases: <https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/releases>
- Each release contains a flashable AnyKernel3 zip and `SHA256SUMS.txt`

Requirement: **unlocked bootloader**. Back up your current `boot` / `init_boot` partitions before flashing.

---

## Flashing

### Option A: Custom recovery (TWRP / OrangeFox / NEBULA)

1. Download the AnyKernel3 zip.
2. Boot into your custom recovery.
3. (Recommended) Back up `boot` and `init_boot`.
4. Flash the zip → optionally wipe Dalvik/Cache → reboot.

> If you previously rooted via the LKM method (SukiSU/KernelSU/Magisk patched `init_boot`), **restore the stock `init_boot` first**, otherwise the LKM may conflict with the kernel-integrated SukiSU.

### Option B: Fastboot only (what the author used)

1. Extract `Image` from the release AnyKernel3 zip.
2. Get the stock `boot.img` of the **exact same ROM/firmware** (peridot boot partition uses Android boot header v4 with `ramdisk_size=0`).
3. Repack `Image` into a boot image with the included script:
   ```bash
   python scripts/repack_boot.py stock_boot.img Image new_boot.img
   ```
4. If `init_boot` was LKM-patched, restore the stock `init_boot`.
5. Test temporarily first (some Xiaomi devices may refuse `fastboot boot`):
   ```bash
   adb reboot bootloader
   fastboot boot new_boot.img
   ```
6. After confirming it boots and Wi-Fi/camera/charging work:
   ```bash
   fastboot flash boot new_boot.img
   fastboot reboot
   ```

### Rescue / rollback

Enter Fastboot (power off, hold Power + Volume Down; on some devices release Power on the vibration and keep holding Volume Down), then:

```bash
fastboot flash boot      /path/to/stock_boot.img
fastboot flash init_boot /path/to/stock_init_boot.img
fastboot reboot
```

If you only touched `boot`/`init_boot`, Fastboot recovery is usually enough. Do not touch `xbl/abl/tz/uefi` etc., and do not flash older firmware (anti-rollback).

---

## Build it yourself (GitHub Actions)

1. Fork this repository.
2. Actions → **Build Kernel - Peridot (SukiSU+SUSFS)** → Run workflow.
3. Set `rom_build_date` to your ROM's `ro.build.date` (or epoch / `ro.build.date.utc`) so the kernel build timestamp matches your ROM; leave the default if unsure.
4. Artifacts are uploaded to the workflow run and (on success) published as a GitHub Release.

Customization points:

| What | Where |
|---|---|
| SukiSU version | `SUKISU_COMMIT` / `SUKISU_VERSION` at the top of the workflow |
| SUSFS version/patch | `patches/susfs/` (patch already rebased onto ACK `0c3d559`) |
| SukiSU hide hooks | `patches/sukisu/69_hide_stuff.patch` |
| KSU/SUSFS kernel config | `configs/sukisu_susfs.config` |
| peridot defconfig source | cloned from `Mohithash/kernel_xiaomi_sm8635` in the workflow |
| KPM | not provided (KernelPatch-incompatible on this device) |

---

## Known limitations

- KPM is **not enabled**: KernelPatch-patched images (raw `Image`, boot image, and a patched stock kernel) all failed to boot on this device (peridot + ported OS4), so no KPM flavor is published. SUSFS/hiding is unaffected.
- SUSFS hides paths/mounts but **cannot hide the manager package name**; pair it with HMA (Hide My Applist) etc. to hide packages from target apps.
- LSPosed/Zygisk injection can be detected by some checker apps (e.g. ApplistDetector's "Xposed Modules"); this is inherent to the Xposed ecosystem, not the kernel.
- Play Integrity / GMS behavior depends on the ROM itself; no guarantee of passing Play Integrity on ported ROMs.

---

## Credits

- **Flavenz / ZxAlif-ID** — upstream kernel and GitHub Actions pipeline: <https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot>
- **SukiSU-Ultra** — <https://github.com/SukiSU-Ultra/SukiSU-Ultra>
- **simonpunk / susfs4ksu**, **ShirkNeko** — SUSFS patches and SukiSU integration: <https://github.com/ShirkNeko/susfs4ksu>, <https://github.com/SukiSU-Ultra/SukiSU_patch>
- **Mohithash** — peridot defconfig (`kernel_xiaomi_sm8635`)
- **Google ACK / Qualcomm / Xiaomi MiCode** — kernel sources
- **osm0sis / AnyKernel3** — flashing script
- **ravindu644 / Droidspaces** — container kABI patches

---

## License & Disclaimer

GPL-2.0 (see [LICENSE](LICENSE)). Kernel source copyright belongs to the respective upstream projects.

Personal, non-commercial project provided **AS-IS, without warranty of any kind**. Flashing, rooting and custom kernels carry risks (brick, data loss, security issues). Back up and proceed at your own risk.

---

**🌐 Language: [中文](README.md) | English**
