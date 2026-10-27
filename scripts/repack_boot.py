#!/usr/bin/env python3
"""Repack a peridot boot.img (Android boot header v4, ramdisk_size=0) with a new kernel Image.

Usage:
    python repack_boot.py <stock_boot.img> <Image> <out_boot.img>

Layout (observed on the stock 6.1.138 boot_a.img):
    [0, 4096)                 header (header_size=1584, page padded)
    [4096, 4096+kpad)         kernel, padded to PAGE_SIZE
    [4096+kpad, +4096)        AVB boot signature (optional, preserved when present)
"""
import struct
import sys
from pathlib import Path

PAGE = 4096
HDR_OFF_KERNEL_SIZE = 8
HDR_OFF_RAMDISK_SIZE = 12
HDR_OFF_HEADER_SIZE = 20
HDR_OFF_HEADER_VERSION = 40


def align(n: int, page: int = PAGE) -> int:
    return (n + page - 1) // page * page


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__)
        return 2
    stock = Path(sys.argv[1])
    image = Path(sys.argv[2])
    out = Path(sys.argv[3])

    boot = stock.read_bytes()
    kernel = image.read_bytes()

    if boot[:8] != b"ANDROID!":
        print("stock boot: not an Android boot image")
        return 1
    v = struct.unpack_from("<I", boot, HDR_OFF_HEADER_VERSION)[0]
    header_size = struct.unpack_from("<I", boot, HDR_OFF_HEADER_SIZE)[0]
    old_kernel = struct.unpack_from("<I", boot, HDR_OFF_KERNEL_SIZE)[0]
    old_ramdisk = struct.unpack_from("<I", boot, HDR_OFF_RAMDISK_SIZE)[0]
    if v != 4:
        print(f"expected header v4, got v{v}")
        return 1
    if old_ramdisk != 0:
        print(f"expected ramdisk_size=0 (init_boot device), got {old_ramdisk}")
        return 1

    old_kpad = align(old_kernel)
    sig_off = PAGE + old_kpad
    sig = boot[sig_off:sig_off + PAGE] if boot[sig_off:sig_off + 4] == b"AVB0" else b""

    new_header = bytearray(boot[:PAGE])
    struct.pack_into("<I", new_header, HDR_OFF_KERNEL_SIZE, len(kernel))
    struct.pack_into("<I", new_header, HDR_OFF_RAMDISK_SIZE, 0)

    parts = [bytes(new_header), kernel, b"\x00" * (align(len(kernel)) - len(kernel))]
    if sig:
        parts.append(sig)
    new_boot = b"".join(parts)

    out.write_bytes(new_boot)
    print(
        f"stock kernel={old_kernel} ({old_kernel/1048576:.1f}MB) "
        f"new kernel={len(kernel)} ({len(kernel)/1048576:.1f}MB) "
        f"signature={'kept' if sig else 'none'} "
        f"out={len(new_boot)} ({len(new_boot)/1048576:.1f}MB)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
