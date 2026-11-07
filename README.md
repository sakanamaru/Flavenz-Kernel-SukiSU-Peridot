# SukiSU-Ultra + SUSFS Kernel for Redmi Turbo 3 / POCO F6 (peridot)

<div align="center">

[![Kernel](https://img.shields.io/badge/Kernel-6.1.138-blue.svg)](https://kernel.org)
[![Root](https://img.shields.io/badge/Root-SukiSU--Ultra%20builtin-6f42c1.svg)](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.3.0-red.svg)](https://github.com/ShirkNeko/susfs4ksu)
[![Device](https://img.shields.io/badge/Device-Redmi%20Turbo%203%20%2F%20POCO%20F6-orange.svg)](#)
[![Android](https://img.shields.io/badge/Tested%20on-Android%2017%20ported%20ROM-green.svg)](#)
[![Build](https://img.shields.io/badge/Build-GitHub%20Actions-2088ff.svg)](https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/actions)

**基于 [Flavenz-Kernel-Peridot](https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot) 改造：KernelSU Next → SukiSU-Ultra builtin，保留 ACK 6.1.138 / peridot defconfig / SUSFS；实测可在移植的 OS4（Android 17）上开机使用。**

**🌐 语言: 中文 | [English](README.en.md)**

</div>

---

## 这是什么

给 **Redmi Turbo 3 / POCO F6（`peridot`，骁龙 8s Gen 3 / SM8635）** 用的自编 GKI 内核：

| 项目 | 内容 |
|---|---|
| 内核基线 | ACK `android14-6.1-lts` @ `0c3d559bcd85c64dae9c9c9687abbe5347fff3ad` = `6.1.138-android14-11` |
| 设备配置 | `Mohithash/kernel_xiaomi_sm8635` 分支 `17` @ `690024ef343deb44b03fa8e83dea5d5312c27795`（3 个文件 sha256 固定，CI 拒绝分支 HEAD） |
| Root | **SukiSU-Ultra `builtin` 分支** @ `1cfa57340590971cba7521ed536da8ebbedc5f0a`（2026-11-01），内核内置（GKI builtin 模式） |
| 隐藏 | **SUSFS v2.3.0**（`ShirkNeko/susfs4ksu` @ `05f201978bdbd5d08f842e0a2a6e0f2ff0912787`，vendored 并按 ACK `0c3d559` 精确 rebase） |
| 编译 | Neutron Clang 30062026（sha256 固定）、ThinLTO、GitHub Actions |
| 额外配置 | Flavenz 的 Droidspaces 容器 kABI-safe 配置（SYSVIPC / namespaces / MACVLAN / IPv6 NAT 等） |
| KPM | 未启用：KernelPatch 打补丁后的镜像在本机（peridot + 移植 OS4）实测无法启动，因此不提供 KPM flavor |
| 构建输入 | 全部 pin 在 [`configs/pins.env`](configs/pins.env)（commit + sha256，CI 拒绝浮动分支/tag） |

和上游 Flavenz 的差异：

- KernelSU Next → **SukiSU-Ultra builtin**（管理器也要换成 SukiSU 系，KSU Next 管理器不兼容）
- SUSFS 补丁换成 ShirkNeko 的 SukiSU 兼容版本，并额外加入 SukiSU hide hooks（[`patches/sukisu/69_hide_stuff.patch`](patches/sukisu/69_hide_stuff.patch)，已按 ACK 0c3d559+SUSFS 精确 rebase，**CI 不再允许 fuzz**）
- 构建时对 SukiSU 代码关闭 `-Werror`（否则 Clang 会因 `-Wimplicit-fallthrough` 直接失败）
- KPM 未启用（KernelPatch 在本机实测无法启动；SUSFS 不需要 KPM）
- **版本诚实化**：不再携带厂商的 `CONFIG_LOCALVERSION="-android14-11-ga3b9c44908dd-ab13320413"` 与 `CONFIG_UNAME_OVERRIDE`/`com.google.android.gms` 伪装；CI 强制 `uname -r` 为可追溯的
  `6.1.138-flavenz-<构建日期>-<flavor>-g<ACK短SHA>-<仓库短SHA>`，并硬校验 Image banner
- **发布工程加固**：唯一 release tag、默认 draft、exp 必为 prerelease、最小权限、provenance、GPL 源码提供、显式签名状态（未配置密钥时明确写 UNSIGNED，绝不伪装已签名）

## 已验证环境

> 验证分两类：**历史 boot-tested 构建**（真实设备）与**当前 pin**（最近一次 boot test 在单台 peridot 上通过）。
> CI 只做编译验证；任何 release 的 `boot_test_status` 都会写进 release notes，未通过 boot test 的构建不会伪装成“已验证”。

| 项目 | 稳定构建 b16e899（历史） | 当前 pin（exp） |
|---|---|---|
| 设备 | Redmi Turbo 3 `24069RA21C`（peridot） | 同一台 peridot（单机验证） |
| ROM | 移植 OS4.0.25.0，Android 17（SDK 37），`CP2A.260605.016`，指纹 `Redmi/peridot/peridot:17/OS4.0.25.0.XEOCNXM`；vendor/ODM 为 Android 14 旧底座 | 同上 |
| 内核 | 旧版 vendor LOCALVERSION（`6.1.138-android14-11-ga3b9c44908dd-ab13320413+`） | `6.1.138-flavenz-…`（honest LOCALVERSION，随构建日期/flavor/SHA 变化） |
| SukiSU | builtin `b16e899` | builtin `1cfa573`（2026-11-01） |
| 管理器 | SukiSU-Ultra **v4.2.1-r2 (41095-6)**（与该旧内核配对验证） | 需与内核 UAPI（6）匹配的官方 SukiSU-Ultra 管理器；仓库不固定 APK 版本 |
| SUSFS | v2.3.0，`ksud susfs implementation = builtin`、`status = true` | v2.3.0（同上） |
| 刷入方式 | 本地 repack stock boot.img → `fastboot boot` 临时测试 → `fastboot flash boot` 持久化；`init_boot` 保持原厂 | 同路径（**不是** recovery，见下） |
| 功能抽检 | root（`su`/`u:r:ksu`）、模块加载、Zygisk Next/LSPosed、相机、Wi-Fi、充电、5G 正常 | 开机/root/SUSFS/基础硬件抽检；未做全量回归 |

> ⚠️ 个人自编内核，**不是官方产物**。不同 ROM/固件请先完整备份；跨版本刷入风险自负。

---

## 下载与发布

- Releases：<https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/releases>
- 每个 release 的资产：
  - `Peridot-Kernel-ACK-SukiSU-…-droidspaces-<date>.zip` — AnyKernel3 刷机包（内含内核 `Image`、GPL-2.0 文本 `LICENSE`、`PROVENANCE.txt`、`SOURCE-OFFER.txt`）
  - `SHA256SUMS.txt` — 所有资产的 sha256（可用 `sha256sum -c` 校验）
  - `PROVENANCE.txt` — 精确 commit、输入 sha256、CI run URL、内核版本与 `Image` sha256
  - `SOURCE-OFFER.txt` — GPL-2.0 书面源码提供
  - `SIGNING.txt` — 明确写 `SIGNED` 或 `UNSIGNED`（未配置密钥时绝不伪装签名）
  - `Flavenz-Kernel-source-<sha>.tar.gz` — 本仓库（workflow/configs/patches）在发布 commit 的快照

发布规则（自 2026-11-07 起）：

- tag 唯一：`Flavenz-<YYYYMMDD>-<flavor>-<repo短SHA>-g<ACK短SHA>-r<run号>`；CI **永不删除/重建** tag 或 release。
- `exp` 渠道**永远**是 GitHub prerelease；默认发布为 **draft**，公开需要人工审批（protected `release` environment）。
- `stable` 只有在 `boot_test_status=boot-tested` 且人工审批后才可能发布；不满足则保持 draft/失败。
- 仓库侧建议启用 **Immutable releases** + `Flavenz-*` tag protection；CI 会读取并披露实际状态。

---

## 刷入（务必先读）

### 前置

- **Bootloader 已解锁**；`fastboot` 可用。
- **备份到电脑，不要只放 `/sdcard`**（系统起不来时 `/sdcard` 可能读不到）：
  ```bash
  adb shell su -c 'ls -l /dev/block/by-name/ | grep -E "boot|init_boot|vendor_boot"'
  adb shell su -c 'dd if=/dev/block/by-name/boot of=/sdcard/boot.img'
  adb pull /sdcard/boot.img .
  # A/B 设备建议同时备份两个槽：boot_a / boot_b、init_boot_a / init_boot_b、vendor_boot_a / vendor_boot_b
  ```
  把备份文件复制到电脑并核对 sha256。

### 关于 Recovery（重要）

- **当前 peridot 的 OS4 / Android 17 移植包没有可用的 TWRP / OrangeFox / NEBULA**（截至 2026-11-07）。
- 本仓库提供的 AnyKernel3 zip **仍然需要自定义 recovery 才能刷入**，所以在当前 ROM 上**“进 recovery 刷 zip”这条路不可用**；不要再按旧教程去 recovery 刷。
- 没有 recovery 的机型请走下面的 Fastboot 方式。

### 方式 A：Fastboot（作者使用的方式）

1. 从 release 的 AnyKernel3 zip 里取出 `Image`。
2. 从**你当前 ROM 同版本**的线刷包/固件中取原厂 `boot.img`（peridot：Android boot header v4，`ramdisk_size=0`，boot 分区 96 MiB）。
3. 用仓库脚本重打包：
   ```bash
   python scripts/repack_boot.py stock_boot.img Image new_boot.img
   ```
4. 若之前用 LKM 方式（SukiSU/KernelSU/Magisk 修补 `init_boot`）root 过，**先恢复原厂 `init_boot`**，否则 LKM 与内核内置 SukiSU 可能冲突。
5. 可选：临时 RAM 测试（部分 Xiaomi bootloader 会拒绝 `fastboot boot`）：
   ```bash
   adb reboot bootloader
   fastboot boot new_boot.img
   ```
6. 确认能开机、Wi-Fi/相机/充电正常后持久化（A/B 设备默认写当前活动槽）：
   ```bash
   fastboot flash boot new_boot.img
   # 若要显式写两个槽：
   # fastboot flash boot_a new_boot.img
   # fastboot flash boot_b new_boot.img
   fastboot reboot
   ```

**关于 boot 镜像的硬限制（不要忽略）：**

- CI **不构建、也不在 release 中附带 boot 镜像**；上面的 `new_boot.img` 是你本地 repack 的。
- 该镜像**未签名，且没有 peridot 有效的 AVB footer**。只有在 bootloader 已解锁、AVB/verity 已禁用（或 vbmeta 策略允许）的设备上才能启动；AVB enforcing 环境下会校验失败并可能 bootloop。
- repack 后保持 96 MiB 大小/零填充是原厂 boot 分区布局（magiskboot 保留 stock header/尺寸），不是损坏。
- `fastboot boot` 只是 RAM 测试，**不是回滚手段**。

### 方式 B：自定义 Recovery（当前设备暂不可用）

如果将来出现可用的 peridot OS4 recovery：下载对应日期的 AnyKernel3 zip → 进 recovery →（建议）先备份 boot/init_boot → 刷 zip → 可选 Wipe Dalvik/Cache → 重启。**在当前没有 recovery 的 ROM 上不要尝试。**

### 救砖 / 回滚

进入 Fastboot（关机后按住电源键+音量减；部分机型震动后松开电源键、继续按音量减），从**电脑上的原厂备份**恢复：

```bash
fastboot flash boot_a     stock_boot.img
fastboot flash boot_b     stock_boot.img
fastboot flash init_boot_a stock_init_boot.img   # 仅在 init_boot 被改过时
fastboot flash init_boot_b stock_init_boot.img
fastboot reboot
```

- **回滚 = `fastboot flash` 原厂镜像**；`fastboot boot` 不是回滚。
- 不要动 `xbl/abl/tz/uefi` 等 bootloader 分区，不要刷更旧的固件（防回滚）。
- 备份只在 `/sdcard` 不够：系统起不来时可能无法读取，务必先复制到电脑。

---

## 发布完整性 / 验证

```bash
# 1) 校验所有资产
sha256sum -c SHA256SUMS.txt

# 2) 如果有 GPG 签名（SIGNING.txt 写 SIGNED）
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt

# 3) 查看精确来源（commit、输入 sha256、CI run）
cat PROVENANCE.txt
```

- 若 `SIGNING.txt` 写 **UNSIGNED**：`SHA256SUMS.txt` 只能证明传输完整性，**不证明作者身份**；请以 `PROVENANCE.txt` 中记录的 CI run/commit 为准。
- 仓库侧启用 immutable releases + tag protection 后，release 资产和 tag 才具备防篡改语义；CI 会在 release notes 中披露该设置的实际状态。

---

## 自己构建（GitHub Actions）

1. Fork 本仓库。
2. Actions → **Build Kernel - Peridot (SukiSU+SUSFS)** → Run workflow。
3. 输入：
   - `release_channel`：`exp`（默认）或 `stable`；
   - `publish_release`：默认 `false`（只创建 **draft**）；`true` 需在受保护的 `release` environment 审批后才公开；
   - `boot_test_status`：`not-boot-tested`（默认）或 `boot-tested`；**stable + publish 必须 boot-tested**；
   - `rom_build_date`：**留空**即使用源码 commit 日期作为构建时间（诚实、可复现）；只有显式填写 ROM `ro.build.date` 时才会同步并在 provenance/release notes **明确披露**；
   - `autofdo_profile_url` + `autofdo_profile_sha256`：可选 AutoFDO 路径，提供 URL 时必须同时提供 sha256。
4. 构建产物在 Actions artifacts；成功后在 Releases 生成 **draft**，由维护者审核后再发布。

可调位置：

| 想改什么 | 改哪里 |
|---|---|
| 所有外部构建输入（ACK/SukiSU/defconfig/SUSFS/Droidspaces/工具链的 commit 与 sha256） | [`configs/pins.env`](configs/pins.env) |
| SukiSU 版本 | `configs/pins.env` 的 `SUKISU_COMMIT` / `SUKISU_SETUP_SHA256` |
| SUSFS 版本/补丁 | `patches/susfs/`（补丁已精确 rebase 到 ACK `0c3d559`，`git apply --check` 必须通过） |
| SukiSU 隐藏 hooks | `patches/sukisu/69_hide_stuff.patch`（精确 rebase，CI 禁止 fuzz） |
| KSU/SUSFS 内核配置 | [`configs/sukisu_susfs.config`](configs/sukisu_susfs.config) |
| 版本字符串 | CI 自动生成 `-flavenz-<date>-<flavor>-g<ack>-<repo>`；`CONFIG_LOCALVERSION_AUTO=n`、`CONFIG_UNAME_OVERRIDE` 禁止 |
| KPM | 未提供（KernelPatch 在本机不兼容，见“已知限制”） |

发布机需要的一次性仓库设置：

1. 创建 environment `release` 并配置 **required reviewers**（否则 `publish_release=true` 会被 CI 拒绝）。
2. Settings → General → Releases → 启用 **immutable releases**；为 `Flavenz-*` 添加 tag protection。
3. 可选：配置 `RELEASE_GPG_PRIVATE_KEY` / `RELEASE_GPG_PASSPHRASE` secrets 对 `SHA256SUMS.txt` 做 GPG 签名。

---

## 已知限制

- **KPM 未启用**：KernelPatch 打补丁的镜像（raw Image / boot image / 原厂内核三种方式）在本机（peridot + 移植 OS4）均无法启动，因此不提供 KPM flavor；SUSFS / 隐藏不受影响。
- **当前 ROM 无自定义 recovery**：AnyKernel3 zip 暂时无法在设备上刷入（见“刷入”）。
- **boot 镜像未签名/无 AVB footer**：需要解锁并关闭 AVB/verity；见“刷入”的硬限制。
- SUSFS 能隐藏路径/挂载，但**不能隐藏管理器包名**；需要配合 HMA（Hide My Applist）等。
- LSPosed 注入可能被部分检测 App 识别（如 ApplistDetector 的 "Xposed Modules"）；这是 Zygisk/Xposed 生态固有问题，与内核无关。
- 移植 ROM 的 GMS / Play Integrity 表现取决于 ROM 自身，不保证通过 Play Integrity。
- **不做 uname/构建时间伪装**：旧厂商 defconfig 的 `CONFIG_UNAME_OVERRIDE`/GMS 覆盖字符串已移除，`uname -r` 会显示真实 `-flavenz-...` 版本；这是刻意选择（可追溯优先），不要在 Issue 里要求“隐藏 uname”。

---

## Credits

- **Flavenz / ZxAlif-ID** — 上游内核与 GitHub Actions 构建流程：<https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot>
- **SukiSU-Ultra** — <https://github.com/SukiSU-Ultra/SukiSU-Ultra>
- **ShirkNeko / simonpunk** — SUSFS 补丁与 SukiSU 适配：<https://github.com/ShirkNeko/susfs4ksu>、<https://github.com/SukiSU-Ultra/SukiSU_patch>
- **Mohithash** — `kernel_xiaomi_sm8635` peridot defconfig
- **Google ACK / Qualcomm / Xiaomi MiCode** — 内核源码
- **osm0sis / AnyKernel3** — 刷写脚本
- **ravindu644 / Droidspaces** — 容器相关 kABI 补丁

---

## License & Disclaimer

GPL-2.0（见 [LICENSE](LICENSE)）。内核源码版权归各上游项目所有。刷机包内保留 GPL-2.0 文本与源码提供说明（[`docs/source-offer.md`](docs/source-offer.md)）。

本项目为个人、非商业项目，**AS-IS 无任何保证**。刷机、root、自编内核均有风险（变砖、数据丢失、安全问题等），请自行备份并承担后果。

---

## English summary

Custom GKI kernel for **Redmi Turbo 3 / POCO F6 (`peridot`)** based on ACK `android14-6.1-lts` @ `0c3d559bcd85` (6.1.138), with **SukiSU-Ultra builtin `1cfa573`** and **SUSFS v2.3.0** compiled in; KPM is not enabled. All build inputs are pinned (commit + sha256) in [`configs/pins.env`](configs/pins.env); patches apply exactly (no fuzz) and CI hard-gates an honest `-flavenz-…` kernel version. Releases are drafts by default, exp builds are always prereleases, tags are never deleted/recreated, and the release assets include GPL text, provenance and a source offer (UNSIGNED is stated explicitly unless a GPG key is configured).

**Flashing reality check:** there is currently **no working TWRP/OrangeFox for the OS4 / Android 17 port**, so the AnyKernel3 zip cannot be flashed on this ROM right now. The supported path is backing up `boot`/`init_boot`/`vendor_boot` to a PC, repacking the `Image` into the stock `boot.img` and using fastboot. Repacked boot images are **unsigned and have no valid AVB footer**, so they only work on an unlocked bootloader with AVB/verity disabled; `fastboot boot` is a RAM-only test (some Xiaomi bootloaders reject it) and is **not** a rollback. Roll back with `fastboot flash boot_a/b <stock.img>`. See [README.en.md](README.en.md) for the full English documentation.
