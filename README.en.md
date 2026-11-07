# SukiSU-Ultra + SUSFS Kernel for Redmi Turbo 3 / POCO F6 (peridot)

<div align="center">

[![Kernel](https://img.shields.io/badge/Kernel-6.1.138-blue.svg)](https://kernel.org)
[![Root](https://img.shields.io/badge/Root-SukiSU--Ultra%20builtin-6f42c1.svg)](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.3.0-red.svg)](https://github.com/ShirkNeko/susfs4ksu)
[![Device](https://img.shields.io/badge/Device-Redmi%20Turbo%203%20%2F%20POCO%20F6-orange.svg)](#)
[![Android](https://img.shields.io/badge/Tested%20on-Android%2017%20ported%20ROM-green.svg)](#)
[![Build](https://img.shields.io/badge/Build-GitHub%20Actions-2088ff.svg)](https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/actions)

**A fork of [Flavenz-Kernel-Peridot](https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot): KernelSU Next replaced with SukiSU-Ultra builtin, keeping the ACK 6.1.138 base, peridot defconfig and SUSFS. Boot-tested on a ported OS4 (Android 17) ROM.**

**🌐 Language: [中文](README.md) | English**

</div>

---

## What is this

A custom GKI kernel for the **Redmi Turbo 3 / POCO F6 (`peridot`, Snapdragon 8s Gen 3 / SM8635)**:

| Item | Value |
|---|---|
| Kernel base | ACK `android14-6.1-lts` @ `0c3d559bcd85c64dae9c9c9687abbe5347fff3ad` = `6.1.138-android14-11` |
| Device config | `Mohithash/kernel_xiaomi_sm8635`, branch `17` @ `690024ef343deb44b03fa8e83dea5d5312c27795` (3 files sha256-pinned; CI rejects branch HEAD) |
| Root | **SukiSU-Ultra `builtin`** @ `1cfa57340590971cba7521ed536da8ebbedc5f0a` (2026-11-01), compiled into the kernel (GKI builtin mode) |
| Hiding | **SUSFS v2.3.0** (`ShirkNeko/susfs4ksu` @ `05f201978bdbd5d08f842e0a2a6e0f2ff0912787`, vendored and exactly rebased onto ACK `0c3d559`) |
| Toolchain | Neutron Clang 30062026 (sha256-pinned), ThinLTO, GitHub Actions |
| Extra | Flavenz's Droidspaces container-related kABI-safe configs (SYSVIPC / namespaces / MACVLAN / IPv6 NAT, etc.) |
| KPM | Not enabled — KernelPatch-patched images failed to boot on this device (peridot + ported OS4) |
| Build inputs | Everything is pinned (commit + sha256) in [`configs/pins.env`](configs/pins.env); floating branches/tags are rejected by CI |

### Differences from upstream Flavenz

- KernelSU Next → **SukiSU-Ultra builtin** (use a SukiSU-family manager; the KSU Next manager is not compatible)
- SUSFS patch switched to ShirkNeko's SukiSU-compatible patch set, plus SukiSU hide hooks ([`patches/sukisu/69_hide_stuff.patch`](patches/sukisu/69_hide_stuff.patch), exactly rebased onto ACK 0c3d559 + SUSFS; **fuzz is no longer accepted by CI**)
- `-Werror` disabled for SukiSU builtin code (`-Wno-error`), otherwise Clang fails on `-Wimplicit-fallthrough`
- KPM not enabled (KernelPatch-patched images failed to boot on this device)
- **Honest versioning**: the vendor's `CONFIG_LOCALVERSION="-android14-11-ga3b9c44908dd-ab13320413"` and the `CONFIG_UNAME_OVERRIDE` / `com.google.android.gms` spoof are no longer shipped. CI forces `uname -r` to a traceable
  `6.1.138-flavenz-<build-date>-<flavor>-g<ack-short-sha>-<repo-short-sha>` and hard-gates the Image banner.
- **Release engineering hardening**: unique tags, drafts by default, exp builds always prereleases, least-privilege jobs, provenance, GPL source offer, explicit signing status (UNSIGNED is stated explicitly unless a key is configured — never faked).

---

## Verified on

> Two kinds of verification: **historically boot-tested builds** (real device) and the **current pin** (most recent boot test passed on a single peridot).
> CI only proves compilation. Every release records its `boot_test_status`; a build is never presented as verified when it was not boot-tested.

| Item | Stable b16e899 (historical) | Current pin (exp) |
|---|---|---|
| Device | Redmi Turbo 3 `24069RA21C` (peridot) | Same peridot (single-device test) |
| ROM | Ported OS4.0.25.0, Android 17 (SDK 37), `CP2A.260605.016`, fingerprint `Redmi/peridot/peridot:17/OS4.0.25.0.XEOCNXM`; vendor/ODM is an Android 14 base | Same |
| Kernel | Old vendor LOCALVERSION banner (`6.1.138-android14-11-ga3b9c44908dd-ab13320413+`) | `6.1.138-flavenz-…` (honest LOCALVERSION; date/flavor/SHA vary per build) |
| SukiSU | builtin `b16e899` | builtin `1cfa573` (2026-11-01) |
| Manager | SukiSU-Ultra **v4.2.1-r2 (41095-6)** (verified with that older kernel) | The official SukiSU-Ultra manager matching kernel UAPI (6); the repo does not pin an APK version |
| SUSFS | v2.3.0, `ksud susfs implementation = builtin`, `status = true` | v2.3.0 (same) |
| Flashing | Local repack of stock boot.img → `fastboot boot` test → `fastboot flash boot`; `init_boot` kept stock | Same path (**not** recovery, see below) |
| Hardware | root (`su`, `u:r:ksu`), modules, Zygisk Next/LSPosed, camera, Wi-Fi, charging, 5G | Boot/root/SUSFS/basic hardware spot check; no full regression |

> ⚠️ Personal, unofficial build. Back up everything first; cross-version flashing is at your own risk.

---

## Download & releases

- Releases: <https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/releases>
- Assets per release:
  - `Peridot-Kernel-ACK-SukiSU-…-droidspaces-<date>.zip` — AnyKernel3 installer (kernel `Image`, GPL-2.0 `LICENSE`, `PROVENANCE.txt`, `SOURCE-OFFER.txt`)
  - `SHA256SUMS.txt` — sha256 of every asset (verify with `sha256sum -c`)
  - `PROVENANCE.txt` — exact commits, input hashes, CI run URL, kernel release and `Image` sha256
  - `SOURCE-OFFER.txt` — GPL-2.0 written source offer
  - `SIGNING.txt` — explicitly says `SIGNED` or `UNSIGNED` (never pretends)
  - `Flavenz-Kernel-source-<sha>.tar.gz` — snapshot of this repository (workflow/configs/patches) at the release commit

Release policy (since 2026-11-07):

- Tags are unique: `Flavenz-<YYYYMMDD>-<flavor>-<repo-short-sha>-g<ack-short-sha>-r<run>`; CI **never** deletes or recreates a tag/release.
- `exp` builds are **always** GitHub prereleases; releases are created as **drafts** by default and publishing requires manual approval (protected `release` environment).
- `stable` can only be published when `boot_test_status=boot-tested` and after approval; otherwise the release stays a draft or the job fails.
- Repository settings recommended: **Immutable releases** + `Flavenz-*` tag protection. CI reports the actual state in the release notes.

---

## Flashing — read this first

### Prerequisites

- **Unlocked bootloader**; working `fastboot`.
- **Back up to a PC, not just `/sdcard`** (`/sdcard` may be unreadable when the system fails to boot):
  ```bash
  adb shell su -c 'ls -l /dev/block/by-name/ | grep -E "boot|init_boot|vendor_boot"'
  adb shell su -c 'dd if=/dev/block/by-name/boot of=/sdcard/boot.img'
  adb pull /sdcard/boot.img .
  # A/B device: back up both slots — boot_a/b, init_boot_a/b, vendor_boot_a/b
  ```
  Copy the files to your PC and verify their sha256.

### About recovery (important)

- **There is currently no working TWRP / OrangeFox / NEBULA for the peridot OS4 / Android 17 port** (as of 2026-11-07).
- The shipped AnyKernel3 zip still needs a custom recovery, so **the "flash the zip in recovery" path is not usable on this ROM right now**. Do not follow outdated recovery instructions.
- Use the fastboot path instead.

### Option A: Fastboot (what the author used)

1. Extract `Image` from the release AnyKernel3 zip.
2. Get the stock `boot.img` of the **exact same ROM/firmware** (peridot: Android boot header v4, `ramdisk_size=0`, 96 MiB boot partition).
3. Repack with the included script:
   ```bash
   python scripts/repack_boot.py stock_boot.img Image new_boot.img
   ```
4. If you previously rooted via the LKM method (patched `init_boot`), **restore the stock `init_boot` first**; LKM + builtin SukiSU may conflict.
5. Optional RAM-only test (some Xiaomi bootloaders reject `fastboot boot`):
   ```bash
   adb reboot bootloader
   fastboot boot new_boot.img
   ```
6. After confirming boot / Wi-Fi / camera / charging, persist it (A/B: current slot by default):
   ```bash
   fastboot flash boot new_boot.img
   # To write both slots explicitly:
   # fastboot flash boot_a new_boot.img
   # fastboot flash boot_b new_boot.img
   fastboot reboot
   ```

**Boot image hard limits (do not ignore):**

- CI **does not build or attach a boot image** to releases; the `new_boot.img` above is repacked by you.
- It is **unsigned and has no valid AVB footer** for peridot. It only boots with an unlocked bootloader and AVB/verity disabled (or a vbmeta policy that accepts it). On an AVB-enforcing setup verification can fail and bootloop.
- The 96 MiB size / zero padding comes from the stock boot partition layout (magiskboot preserves the stock header/size); it is not corruption.
- `fastboot boot` is **only** a RAM test, **not** a rollback.

### Option B: Custom recovery (currently unavailable on this device)

If a working peridot OS4 recovery appears later: download the matching AnyKernel3 zip → boot recovery → (recommended) back up boot/init_boot → flash the zip → optionally wipe Dalvik/Cache → reboot. **Do not attempt this on the current ROM: there is no custom recovery.**

### Rescue / rollback

Enter Fastboot (power off, hold Power + Volume Down; on some devices release Power on the vibration and keep holding Volume Down), then restore from the **backups on your PC**:

```bash
fastboot flash boot_a      stock_boot.img
fastboot flash boot_b      stock_boot.img
fastboot flash init_boot_a stock_init_boot.img   # only if init_boot was modified
fastboot flash init_boot_b stock_init_boot.img
fastboot reboot
```

- **Rollback = `fastboot flash` of the stock images**; `fastboot boot` is not a rollback.
- Do not touch `xbl/abl/tz/uefi`, and do not flash older firmware (anti-rollback).
- A `/sdcard`-only backup is not enough: it may be unreadable when the system cannot boot — copy it to a PC first.

---

## Release integrity / verification

```bash
# 1) Verify every asset
sha256sum -c SHA256SUMS.txt

# 2) If SIGNING.txt says SIGNED
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt

# 3) Read the exact provenance (commits, input sha256, CI run)
cat PROVENANCE.txt
```

- If `SIGNING.txt` says **UNSIGNED**, `SHA256SUMS.txt` only proves transport integrity, **not authorship**; rely on the CI run/commit recorded in `PROVENANCE.txt`.
- Immutable releases + tag protection (repo settings) are what give assets/tags tamper resistance; CI discloses the actual setting in the release notes.

---

## Build it yourself (GitHub Actions)

1. Fork this repository.
2. Actions → **Build Kernel - Peridot (SukiSU+SUSFS)** → Run workflow.
3. Inputs:
   - `release_channel`: `exp` (default) or `stable`;
   - `publish_release`: default `false` (creates a **draft** only); `true` publishes after approval in the protected `release` environment;
   - `boot_test_status`: `not-boot-tested` (default) or `boot-tested`; **stable + publish requires boot-tested**;
   - `rom_build_date`: **leave empty** to use the source commit date as the build timestamp (honest, reproducible); only if you fill in the ROM `ro.build.date` is the timestamp explicitly synced and **disclosed** in provenance/release notes;
   - `autofdo_profile_url` + `autofdo_profile_sha256`: optional AutoFDO path; sha256 is mandatory when a URL is provided.
4. Artifacts are uploaded to the workflow run; on success a **draft** release is created for review/publish.

Customization points:

| What | Where |
|---|---|
| All external inputs (ACK/SukiSU/defconfig/SUSFS/Droidspaces/toolchain commits + sha256) | [`configs/pins.env`](configs/pins.env) |
| SukiSU version | `SUKISU_COMMIT` / `SUKISU_SETUP_SHA256` in `configs/pins.env` |
| SUSFS version/patch | `patches/susfs/` (exactly rebased onto ACK `0c3d559`; `git apply --check` must pass) |
| SukiSU hide hooks | `patches/sukisu/69_hide_stuff.patch` (exact rebase, no fuzz) |
| KSU/SUSFS kernel config | [`configs/sukisu_susfs.config`](configs/sukisu_susfs.config) |
| Version string | CI generates `-flavenz-<date>-<flavor>-g<ack>-<repo>`; `CONFIG_LOCALVERSION_AUTO=n`, `CONFIG_UNAME_OVERRIDE` forbidden |
| KPM | not provided (KernelPatch-incompatible on this device) |

One-time repository settings for the release operator:

1. Create environment `release` with **required reviewers** (otherwise `publish_release=true` is rejected by CI).
2. Settings → General → Releases → enable **immutable releases**; add a tag protection rule for `Flavenz-*`.
3. Optional: configure `RELEASE_GPG_PRIVATE_KEY` / `RELEASE_GPG_PASSPHRASE` secrets to GPG-sign `SHA256SUMS.txt`.

---

## Known limitations

- KPM is **not enabled**: KernelPatch-patched images (raw `Image`, boot image, patched stock kernel) all failed to boot on this device, so no KPM flavor is published. SUSFS/hiding is unaffected.
- **No custom recovery exists for the current ROM**, so the AnyKernel3 zip cannot be flashed on-device for now (see Flashing).
- **Boot images are unsigned / no AVB footer**: unlocked bootloader + AVB/verity disabled required; see the hard limits above.
- SUSFS hides paths/mounts but **cannot hide the manager package name**; pair it with HMA etc.
- LSPosed/Zygisk injection can be detected by some checker apps (e.g. ApplistDetector's "Xposed Modules"); inherent to the Xposed ecosystem.
- Play Integrity / GMS behavior depends on the ported ROM itself.
- **No uname/build-time spoofing**: the old `CONFIG_UNAME_OVERRIDE`/GMS strings are removed; `uname -r` shows a real `-flavenz-...` version. This is deliberate (traceability over camouflage); please do not file issues asking to hide uname.

---

## Credits

- **Flavenz / ZxAlif-ID** — upstream kernel and GitHub Actions pipeline: <https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot>
- **SukiSU-Ultra** — <https://github.com/SukiSU-Ultra/SukiSU-Ultra>
- **ShirkNeko / simonpunk** — SUSFS patches and SukiSU integration: <https://github.com/ShirkNeko/susfs4ksu>, <https://github.com/SukiSU-Ultra/SukiSU_patch>
- **Mohithash** — peridot defconfig (`kernel_xiaomi_sm8635`)
- **Google ACK / Qualcomm / Xiaomi MiCode** — kernel sources
- **osm0sis / AnyKernel3** — flashing script
- **ravindu644 / Droidspaces** — container kABI patches

---

## License & Disclaimer

GPL-2.0 (see [LICENSE](LICENSE)). Kernel source copyright belongs to the respective upstream projects. The flashable zip keeps the GPL-2.0 text and the source offer (see [`docs/source-offer.md`](docs/source-offer.md)).

Personal, non-commercial project provided **AS-IS, without warranty of any kind**. Flashing, rooting and custom kernels carry risks (brick, data loss, security issues). Back up and proceed at your own risk.

---

**🌐 Language: [中文](README.md) | English**
