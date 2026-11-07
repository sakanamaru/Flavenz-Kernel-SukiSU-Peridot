# Changelog

All notable changes to this repository. Since 2026-11-07 release tags are
unique per run: `Flavenz-<YYYYMMDD>-<flavor>-<repo-short-sha>-g<ack-short-sha>-r<run>`
(older releases used `Flavenz-YYYYMMDD` / `Flavenz-YYYYMMDD-afdo`).
See [Releases](https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/releases).
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2026-11-07] — P0 release-engineering / supply-chain / version-honesty hardening
> No release was published for this change. All work is local/CI-code only.
> The SELinux fix module is owned by a separate effort and was **not touched**.

### Security / release integrity
- **Release tags are now unique and immutable in CI behaviour**: tag
  `Flavenz-<date>-<flavor>-<repo7>-g<ack12>-r<run>`. The release job **fails**
  if the tag/release already exists — CI never deletes or recreates a tag or
  release (`build-droidspaces.yml`, `build-patch.yml`, `build-autofdo.yml`).
- **Drafts by default**: the release job creates a GitHub **draft** unless
  `publish_release=true`; publishing requires the protected `release`
  environment (documented required-reviewer setup). `exp` channel releases are
  **always** `--prerelease` (never "Latest"); `stable` + publish additionally
  requires `boot_test_status=boot-tested`.
- **Least privilege**: workflow-level `contents: read`; the build job has no
  write permission; only the release job has `contents: write` and it runs in
  the `release` environment; all checkouts use `persist-credentials: false`;
  GitHub Actions are pinned by commit SHA.
- **Provenance and checksums**: the build job generates `PROVENANCE.txt` with
  every pinned commit/hash, kernel release, Image sha256, build timestamp and
  timestamp source; the release job generates `SHA256SUMS.txt` only after every
  asset is final, optionally GPG-signs it (`RELEASE_GPG_PRIVATE_KEY`), and
  writes `SIGNING.txt` (explicit `UNSIGNED` when no key — signatures are never
  faked). Uploaded assets are re-verified server-side via the GitHub asset
  digest (download fallback).
- Added `scripts/ci/verify-release.sh` (checksums, zip contents, Image vs
  provenance, GPL text, no boot images, signing-status consistency) with
  functional tests; boot images are never attached to a release; the actual
  immutable-releases setting is reported in the release notes.
- `build-patch.yml` release step is off by default and legacy-labelled;
  `build-autofdo.yml` prerelease is draft by default with a new
  `publish_prerelease` input; `compare-kernel-zips.yml` is read-only.
- All text artefacts are LF-enforced via a new `.gitattributes` (CRLF patches
  had silently broken `git apply`).

### Supply chain (pinned build inputs)
- New [`configs/pins.env`](configs/pins.env) is the single source of truth; CI
  verifies every value before use:
  - ACK full commit `0c3d559bcd85c64dae9c9c9687abbe5347fff3ad`;
  - peridot defconfig `Mohithash/kernel_xiaomi_sm8635` commit
    `690024ef343deb44b03fa8e83dea5d5312c27795` + sha256 for all 3 copied files
    — the `17`/`main`/`theettam-*` branch fallback is **removed** (branch HEAD
    rejected);
  - SukiSU-Ultra builtin `1cfa57340590971cba7521ed536da8ebbedc5f0a`;
    `kernel/setup.sh` is downloaded to a file, sha256-verified and executed
    with the full commit (no `curl ... | bash`), then `git rev-parse HEAD` and
    a clean worktree are verified;
  - Droidspaces kABI patch pinned to commit
    `cea978d58037568e7cba26c0c201b1de08f4b210` + sha256 (no `main` branch,
    no `|| echo` swallowing);
  - Neutron Clang `30062026` tarball sha256 + antman sha256 verified;
  - AutoFDO backport patch sha256 verified; a profile URL now requires
    `autofdo_profile_sha256`.
- **Patches apply exactly (zero fuzz)**: `patches/susfs/50_add_...` was
  re-rebased against ACK `0c3d559` and `patches/sukisu/69_hide_stuff.patch`
  against ACK+SUSFS; both now pass `git apply --check` and are applied with
  `git apply` only. The previous `patch --fuzz=3` / `-F 3` fuzz acceptance is
  gone. Note: fuzzy application of the 69 patch used to insert the dentry
  block inside the SUSFS open-redirect branch; the exact rebase puts it at the
  author-intended location (after `pgoff`, before the `bypass:` label).
- The local AutoFDO kbuild patch was normalized CRLF→LF so `git apply` works
  on Linux (it previously only worked with tools that strip CR).

### Version honesty (no spoofed uname/build time)
- `CONFIG_LOCALVERSION` is overridden to
  `-flavenz-<build-date>-<flavor>-g<ack12>-<repo7>`, `CONFIG_LOCALVERSION_AUTO=n`;
  vendor `CONFIG_UNAME_OVERRIDE` / `CONFIG_UNAME_OVERRIDE_TARGET` /
  `CONFIG_UNAME_OVERRIDE_STRING` (`com.google.android.gms`) are stripped from
  the defconfig fragments and forbidden by build gates.
- Build gates now hard-fail if `out/.config`, `kernel.release` or the Image
  banner do not match the expected honest version, or if old spoof strings are
  present.
- `KBUILD_BUILD_TIMESTAMP` is now the **source commit date** by default (does
  not masquerade as the ROM build date). Passing `rom_build_date` is optional
  and, when used, is explicitly disclosed as ROM-synced in `PROVENANCE.txt` and
  the release notes. `scripts/ci/build-boot-image.sh` now requires the honest
  `-flavenz-` banner.

### GPL / licensing
- The flashable AnyKernel3 zip now includes the **GPL-2.0 text (`LICENSE`)**,
  `PROVENANCE.txt` and `SOURCE-OFFER.txt`; the old packaging excluded
  `LICENSE.txt`.
- Releases attach `SOURCE-OFFER.txt` (GPL-2.0 written offer + exact source
  locations) and a `Flavenz-Kernel-source-<sha>.tar.gz` snapshot of this
  repository; added [`docs/source-offer.md`](docs/source-offer.md).

### Documentation
- `README.md` / `README.en.md` rewritten for the current reality: verified
  environment updated (SukiSU builtin `1cfa573`, SUSFS v2.3.0, honest uname);
  explicitly states that **no working TWRP/OrangeFox exists for the OS4 /
  Android 17 port**, so the AnyKernel3 zip cannot be flashed on this ROM yet;
  documents A/B slots, unsigned/no-AVB boot images, `fastboot boot` being a
  RAM-only test (not rollback and rejected by some bootloaders), PC backups
  (not `/sdcard`-only), LKM→builtin migration, release draft/approval flow,
  provenance/signature verification and GPL source offer.
- `README.id.md` (inherited upstream Indonesian doc) got an outdated-document
  banner and a corrected flashing section; `docs/kernel-context.md` /
  `.en.md` got a status banner plus current pipeline/version facts.
- Release notes generated by CI are rewritten to include provenance, GPL
  source offer, flashing/AVB limitations, boot-test status and signing status.

### Verification performed (no release published)
- YAML parse (`PyYAML`) + `bash -n` for every `run:` block of all workflows.
- Functional tests for `scripts/ci/verify-release.sh` (positive + tampered zip,
  boot-image attachment, fake signature claim, Image/provenance mismatch).
- Release-pipeline harness (`provenance → package → prepare assets → release
  body → gh create with stubbed gh`): asserts drafts/prerelease flags, unique
  tag, and that no `gh release delete` ever appears.
- Patch pipeline simulation against ACK `0c3d559` + SukiSU `1cfa573`: SUSFS,
  hide-hooks, Droidspaces kABI and AutoFDO patches all pass
  `git apply --check` / apply exactly; `fix_task_mmu.py` runs clean.

## [2026-09-15] — SUSFS actually enabled for the first time
### Fixed
- **SUSFS core was never compiled into any build**: the upstream
  `50_add_susfs_in_gki-android14-6.1.patch` did not apply against ACK
  `0c3d559bcd85` (include-context mismatch in `fs/exec.c`/`fs/proc/base.c`)
  and the workflow swallowed the failure (`|| echo`). `susfs` strings: 0 in
  every shipped Image; the `SUSFS v2.1.0` zip label was a pure mislabel
  (branch HEAD was already v2.3.0 since 2026-08-30).
- KernelSU Next tag `v3.3.0` lacks the SUSFS-integration symbols the patch
  expects (v3.x hook-manager refactor) → the correct pairing is pershoot
  `dev-susfs` HEAD `5dfc3359` (selinux glue pre-integrated).
### Changed
- `patches/susfs/` vendored + pinned: `susfs.c`/`susfs.h`/`susfs_def.h`
  (susfs4ksu `05f2019`, v2.3.0) + the 50_add patch rebased to ACK
  `0c3d559bcd85` (applies clean, verified via `git apply --check`).
- `build-droidspaces.yml` + `build-autofdo.yml`: KernelSU setup pinned to
  commit `5dfc3359`, SUSFS setup vendored + fail-hard (`git apply --check`,
  apply, `fs/Makefile` guard) — no more swallowed patch failures; labels
  truthful (`SUSFS-v2.3.0`, `KSUNext-5dfc3359`).
- First SUSFS-enabled build: prerelease `Flavenz-20260915-afdo`
  (run `34919940613`). Boot-test via `fla-boot.img` required before stable.

## [2026-09-13] — guidix-full flavor removed
### Removed
- **The `guidix-full` flavor (GuidixX 16.2 base) is gone**: the Guidix zip
  BOOTLOOPED on-device (user report, evidence: `logs/recovery_20260913.log`;
  device recovered by restoring boot/dtbo/init_boot/vendor_boot + re-flashing
  the NexiunOS ROM).
- Both `Peridot-Kernel-Guidix-…zip` assets deleted from Releases
  `Flavenz-20260908` and `Flavenz-20260910`.
### Changed
- `build-droidspaces.yml`: single-flavor matrix (`ack-full` only); release
  count guard 2 → 1; release notes updated.
- READMEs + `docs/kernel-context.md`/`.en.md` synced (bilingual policy).

## [2026-09-12] — Repository & docs
### Added
- Community standards files: CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CITATION.cff,
  CHANGELOG, issue templates (bug / feature), .gitignore.
- Benchmark documentation for the **ack-full** build (`docs/benchmark/`) with a
  live HTML report served via **GitHub Pages**.
- Bilingual docs policy: `docs/kernel-context.md` (ID, canonical) +
  `docs/kernel-context.en.md` (EN translation); `README.md` (EN) +
  `README.id.md` (ID).
### Changed
- `docs/kernel-context.md`: Kernel_F6 marked **deprecated** (AnyKernel3 fully
  vendored since `0af93dc`); flash-test verification recorded.
- README: language switcher, benchmark section, fixed device badge link.

## [Flavenz-20260910] — 2026-09-10 (run 34425680767)
### Fixed
- **Duck Detector "Build time drift"**: `KBUILD_BUILD_TIMESTAMP` is now derived
  from the ROM's `ro.build.date` via the `rom_build_date` workflow input
  (default `2026-07-01`) instead of a hardcoded CI timestamp — `uname -a`
  matches the system build date, integrity checkers no longer flag the kernel
  (commit `7e5880b`).
### Verified
- 3/3 jobs green; both flavors embed `#1 SMP PREEMPT Wed Jul  1 00:00:00 UTC 2026`
  (checked via `strings Image` on the downloaded release zips); `sha256sum -c` OK.

## [Flavenz-20260908] — 2026-09-08 (run 34283279734)
### Fixed
- **OrangeFox flash abort** (`Unable to determine active slot`): generated +
  vendored `anykernel.sh` use the proven `block=boot` + `is_slot_device=auto`
  header; `tools/ak3-core.sh` patched with `/system/bin/getprop` and
  `/proc/bootconfig` fallbacks (`a76a91b`).
- **Release job wrapper detection**: wrapper zips are detected by content
  (`anykernel.sh` presence), not by `unzip -l | grep '\.zip$'` — flashable zips
  are no longer deleted during unwrap (`d91e765`).
### Added
- Automated `release` job publishing raw flashable zips + `SHA256SUMS.txt` to
  GitHub Releases (no zip-in-zip).
- One-shot `compare-kernel-zips.yml` (template vs release vs upstream AK3).

## [2026-09-08] — Build pipeline stabilization
### Fixed
- AnyKernel3 **vendored** into `anykernel/` (`0af93dc`) — runner-side git clones
  died silently with exit 3 during packaging; vendoring removes the failure class.
- Packaging step wrote `ZIPPATH` via `GITHUB_ENV` but read it in the same step →
  empty path, hidden zip file (`e1d2a62`).
- ACK megarepo clone dropped mid-transfer → 3-attempt retry with backoff +
  `http.lowSpeedLimit` / `http.lowSpeedTime` (`6478ccd`).

## [2026-09-07] — Initial public build pipeline
### Added
- `build-droidspaces.yml`: 2-job matrix (`guidix-full`, `ack-full`), Neutron
  Clang 30062026 + antman, KernelSU Next v3.3.0 (pershoot/dev-susfs), SUSFS
  v2.1.0, Droidspaces container configs + SYSVIPC kABI relocation patch.
