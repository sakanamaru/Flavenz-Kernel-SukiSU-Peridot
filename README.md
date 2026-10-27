# SukiSU-Ultra + SUSFS Kernel for Redmi Turbo 3 / POCO F6 (peridot)

<div align="center">

[![Kernel](https://img.shields.io/badge/Kernel-6.1.138-blue.svg)](https://kernel.org)
[![Root](https://img.shields.io/badge/Root-SukiSU--Ultra%20builtin-6f42c1.svg)](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.3.0-red.svg)](https://github.com/simonpunk/susfs4ksu)
[![Device](https://img.shields.io/badge/Device-Redmi%20Turbo%203%20%2F%20POCO%20F6-orange.svg)](#)
[![Android](https://img.shields.io/badge/Tested%20on-Android%2017%20ported%20ROM-green.svg)](#)
[![Build](https://img.shields.io/badge/Build-GitHub%20Actions-2088ff.svg)](https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/actions)

**在 [Flavenz-Kernel-Peridot](https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot) 基础上改造：把 KernelSU Next 换成 SukiSU-Ultra，保留 ACK 6.1.138 / peridot defconfig / SUSFS，并实测可在移植的 OS4（Android 17）上正常使用。**

</div>

---

## 这是什么

给 **Redmi Turbo 3 / POCO F6（`peridot`，骁龙 8s Gen 3 / SM8635）** 用的自编 GKI 内核：

| 项目 | 内容 |
|---|---|
| 内核基线 | ACK `android14-6.1-lts` @ `0c3d559bcd85` = `6.1.138-android14-11` |
| 设备配置 | `Mohithash/kernel_xiaomi_sm8635` 分支 `17` 的 peridot defconfig |
| Root | **SukiSU-Ultra `builtin` 分支**（pin `0b666ca`），内核内置（GKI 模式），配套管理器 `41095-6` |
| 隐藏 | **SUSFS v2.3.0**（`ShirkNeko/susfs4ksu` 的 `gki-android14-6.1` 补丁，重基准到 ACK `0c3d559`） |
| 编译 | Neutron Clang 30062026、ThinLTO、GitHub Actions |
| 额外配置 | 保留 Flavenz 的 droidspaces 容器相关 kABI-safe 配置（SYSVIPC / 命名空间 / MACVLAN / IPv6 NAT 等） |
| KPM | **默认未开启**（`CONFIG_KPM` 关闭）；需要的话自行打开并打 KPM image patch |

和上游 Flavenz 的差异：

- KernelSU Next → **SukiSU-Ultra builtin**（管理器也需要换成 SukiSU 41095+，不能再用 KSU Next 管理器）
- SUSFS 补丁换成 ShirkNeko 的 SukiSU 兼容版本，并额外加入 SukiSU hide hooks（`patches/sukisu/69_hide_stuff.patch`）
- 构建时对 SukiSU 代码关闭 `-Werror`（`-Wno-error`），否则 Clang 会因 `-Wimplicit-fallthrough` 直接失败
- KPM 关闭（降低首次构建/开机风险，SUSFS 不需要 KPM）
- 在**移植 OS4（Android 17）** 上实测开机、root、SUSFS 均正常（见下）

---

## 已验证环境

| 项目 | 值 |
|---|---|
| 设备 | Redmi Turbo 3 `24069RA21C`（peridot） |
| ROM | 移植 OS4.0.25.0，Android 17（SDK 37），`CP2A.260605.016`，指纹 `Redmi/peridot/peridot:17/OS4.0.25.0.XEOCNXM` |
| 内核 | `6.1.138-android14-11-ga3b9c44908dd-ab13320413+` |
| 管理器 | SukiSU-Ultra **v4.2.1-r2 (41095-6)**，内核完整版本 `v4.2.1-r2-0b666cad@HEAD` |
| SUSFS | **v2.3.0**，`ksud susfs implementation = builtin`、`status = true` |
| 刷入方式 | `fastboot boot` 临时测试 → `fastboot flash boot` 持久化；`init_boot` 保持原厂 |
| 功能抽检 | root（`su`/u:r:ksu）、模块加载、Zygisk Next/LSPosed、相机、Wi-Fi 驱动、充电、5G 均正常 |

> ⚠️ 这是个人自编内核，**不是官方产物**。不同 ROM/固件版本请先备份，并优先用 `fastboot boot` 临时测试。

---

## 下载

- Releases：<https://github.com/sakanamaru/Flavenz-Kernel-SukiSU-Peridot/releases>
- 每个 Release 包含可直接刷写的 AnyKernel3 zip 和 `SHA256SUMS.txt`

前置条件：**Bootloader 已解锁**；刷入前备份当前 `boot` / `init_boot` 分区。

---

## 刷入

### 方式 A：自定义 Recovery（TWRP / OrangeFox / NEBULA）

1. 下载 Release 里对应日期的 AnyKernel3 zip。
2. 进入自定义 Recovery。
3. （建议）先备份 `boot`、`init_boot`。
4. 刷入 zip → 可选 Wipe Dalvik/Cache → 重启。

> 如果之前用 LKM 方式（SukiSU/KernelSU/Magisk 修补 init_boot）root 过，**先用原厂 init_boot 恢复**，否则 LKM 与内核内置的 SukiSU 可能冲突。

### 方式 B：只有 Fastboot（本仓库作者实测方式）

1. 从 Release 的 AnyKernel3 zip 里取出 `Image`。
2. 从**你当前 ROM 同版本**的线刷包/固件中取原厂 `boot.img`（peridot 的 boot 分区为 Android boot header v4、`ramdisk_size=0`）。
3. 用仓库里的 [`scripts/repack_boot.py`](scripts/repack_boot.py) 把 `Image` 重打包成 boot 镜像：
   ```bash
   python scripts/repack_boot.py stock_boot.img Image new_boot.img
   ```
4. 若 `init_boot` 被 LKM 方式修补过，先恢复原厂 `init_boot`。
5. 先临时测试（部分 Xiaomi 机型可能不支持 `fastboot boot`）：
   ```bash
   adb reboot bootloader
   fastboot boot new_boot.img
   ```
6. 确认能开机、Wi-Fi/相机/充电正常后持久化：
   ```bash
   fastboot flash boot new_boot.img
   fastboot reboot
   ```

### 救砖 / 回滚

进入 Fastboot（关机后按住电源键+音量减，部分机型出现震动后松开电源键、继续按音量减），然后：

```bash
fastboot flash boot   你的原厂boot.img
fastboot flash init_boot 你的原厂init_boot.img
fastboot reboot
```

只改 `boot`/`init_boot` 的情况下，一般都能通过 Fastboot 恢复；不要动 `xbl/abl/tz/uefi` 等 bootloader 分区，也不要刷入更旧版本的固件（防回滚）。

---

## 自己构建（GitHub Actions）

1. Fork 本仓库。
2. Actions → **Build Kernel - Peridot (SukiSU+SUSFS)** → Run workflow。
3. `rom_build_date` 填你 ROM 的 `ro.build.date`（或 epoch / `ro.build.date.utc`），用于对齐内核 build timestamp；不知道就留默认。
4. 构建完成后产物在 Actions artifacts / Releases 中。

可调位置：

| 想改什么 | 改哪里 |
|---|---|
| SukiSU 版本 | workflow 顶部的 `SUKISU_COMMIT`、`SUKISU_VERSION` |
| SUSFS 版本/补丁 | `patches/susfs/`（补丁已重基准到 ACK `0c3d559`） |
| SukiSU 隐藏 hooks | `patches/sukisu/69_hide_stuff.patch` |
| KSU/SUSFS 内核配置 | `configs/sukisu_susfs.config` |
| peridot defconfig | workflow 中从 `Mohithash/kernel_xiaomi_sm8635` 拷贝 |
| KPM | 在 `configs/sukisu_susfs.config` 加 `CONFIG_KPM=y`，并自行处理 KPM image patch |

---

## 已知限制

- **KPM 未启用**：SUSFS / 隐藏不受影响；需要 KPM 的模块请自行重编。
- SUSFS 能隐藏路径/挂载，但**不能隐藏管理器包名**；需要配合 HMA（Hide My Applist）等对目标 App 隐藏包名。
- LSPosed 注入可能被部分检测 App 识别（如 ApplistDetector 的 "Xposed Modules"）；这是 Zygisk/Xposed 生态的固有问题，与内核无关。
- 移植 ROM 的 GMS / Play Integrity 表现取决于 ROM 自身，不保证通过 Play Integrity。

---

## Credits

- **Flavenz / ZxAlif-ID** — 上游内核与 GitHub Actions 构建流程：<https://github.com/ZxAlif-ID/Flavenz-Kernel-Peridot>
- **SukiSU-Ultra** — <https://github.com/SukiSU-Ultra/SukiSU-Ultra>
- **simonpunk / susfs4ksu**、**ShirkNeko** — SUSFS 补丁与 SukiSU 适配：<https://github.com/ShirkNeko/susfs4ksu>、<https://github.com/SukiSU-Ultra/SukiSU_patch>
- **Mohithash** — `kernel_xiaomi_sm8635` peridot defconfig
- **Google ACK / Qualcomm / Xiaomi MiCode** — 内核源码
- **osm0sis / AnyKernel3** — 刷写脚本
- **ravindu644 / Droidspaces** — 容器相关 kABI 补丁

---

## License & Disclaimer

GPL-2.0（见 [LICENSE](LICENSE)）。内核源码版权归各上游项目所有。

本项目为个人、非商业项目，**AS-IS 无任何保证**。刷机、root、自编内核均有风险（变砖、数据丢失、安全问题等），请自行备份并承担后果。

---

## English summary

Custom GKI kernel for **Redmi Turbo 3 / POCO F6 (`peridot`)** based on ACK `android14-6.1-lts` @ `0c3d559` (6.1.138), with **SukiSU-Ultra builtin (`0b666ca`)** and **SUSFS v2.3.0** compiled in. Built with GitHub Actions + Neutron Clang; peridot defconfig from `Mohithash/kernel_xiaomi_sm8635`. Tested on a ported Android 17 (OS4) ROM: boots, root works, SUSFS reports `builtin`, and hardware (Wi-Fi/camera/charging) is functional. Flash via AnyKernel3 in a custom recovery, or repack the provided `Image` into your stock `boot.img` and use fastboot (keep `init_boot` stock). Use at your own risk; back up `boot`/`init_boot` first.
