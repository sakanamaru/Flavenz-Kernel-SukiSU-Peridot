# GPL-2.0 Source Offer — Flavenz Kernel for peridot

> This file is the repository copy of the written offer. The release job
> generates a per-release `SOURCE-OFFER.txt` with the exact commits/hashes and
> attaches it to every GitHub Release. Both satisfy the GPL-2.0 requirement to
> provide the complete corresponding source for the distributed kernel
> binaries.

## What is distributed

Every Flavenz kernel release ships **Linux kernel binaries** (a `Image` payload
inside an AnyKernel3 zip) built from free software, mainly:

- Android Common Kernel (ACK) `android14-6.1-lts`, GPL-2.0;
- SukiSU-Ultra builtin driver, GPL-2.0;
- SUSFS patches and the vendored SUSFS sources;
- this repository's build logic, patches and configs, GPL-2.0-compatible.

The kernel binaries are therefore distributed under **GPL-2.0**. The flashable
zip contains the full GPL-2.0 text as `LICENSE`.

## Complete corresponding source

The complete corresponding source for a release is:

1. **ACK** — <https://android.googlesource.com/kernel/common> at the exact
   commit recorded in that release's `PROVENANCE.txt` (`ack_commit`), e.g.
   `0c3d559bcd85c64dae9c9c9687abbe5347fff3ad` for the current pin.
2. **This repository** — <https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot>
   at the exact `repo_commit` recorded in `PROVENANCE.txt`. It contains the
   build workflow, `configs/`, and every patch used:
   - `patches/susfs/50_add_susfs_in_gki-android14-6.1-ack-0c3d559.patch`
     (exact rebase, sha256 in `PROVENANCE.txt`);
   - `patches/sukisu/69_hide_stuff.patch` (exact rebase, sha256 in
     `PROVENANCE.txt`);
   - `patches/0001-kbuild-Add-AutoFDO-support-for-Clang-build-ACK-6.1.patch`;
   - the vendored SUSFS sources under `patches/susfs/`.
3. **SukiSU-Ultra** — <https://github.com/SukiSU-Ultra/SukiSU-Ultra> at the
   `sukisu_commit` recorded in `PROVENANCE.txt` (plus `kernel/setup.sh` with
   the sha256 recorded there).
4. **peridot defconfig** — <https://github.com/Mohithash/kernel_xiaomi_sm8635>
   at the `defconfig_commit` recorded in `PROVENANCE.txt` (branch-17 commit;
   the workflow refuses branch HEAD).
5. **Droidspaces kABI patch** — <https://github.com/ravindu644/Droidspaces-OSS>
   at the `droidspaces_commit` recorded in `PROVENANCE.txt`, file
   `Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kabi_6_7_8.patch`.
6. **Toolchain** (build-only, not linked into the kernel) — Neutron Clang
   catalogue `30062026`, sha256 recorded in `PROVENANCE.txt`.

Any release `.tar.gz` asset named `Flavenz-Kernel-source-<sha>.tar.gz` is a
snapshot of this repository at the release commit (workflow + configs +
patches), not the upstream trees themselves.

## Written offer

For at least **three years** from the date of a given release, the maintainer
will provide the complete corresponding source code on request. Requests can
be made through the repository's issue tracker:

<https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/issues>

Please include the release tag from `PROVENANCE.txt`. The source is also
publicly available at the URLs/commits above; the written offer is a fallback
required by GPL-2.0 §3.

## Non-GPL components

The AnyKernel3 installer keeps its own license, included in the flashable zip
as `LICENSE.txt` (AnyKernel3 / osm0sis). It is not covered by the kernel
GPL-2.0 licensing.
