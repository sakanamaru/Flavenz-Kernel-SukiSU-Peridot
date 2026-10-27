#!/usr/bin/env python3
"""ACK 6.1 compatibility fixes required by the SUSFS patch.

Applied to fs/proc/task_mmu.c after the SUSFS patch:
  * define VMA_PAD_START when the patched code uses it but ACK does not define it
  * initialise struct dentry *dentry (SUSFS patch reworks show_map_vma)
"""
import pathlib
import sys


def main() -> int:
    path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "fs/proc/task_mmu.c")
    if not path.exists():
        print(f"[fix_task_mmu] {path} not found", file=sys.stderr)
        return 1
    src = path.read_text()
    changed = False

    if "VMA_PAD_START" in src and "#define VMA_PAD_START" not in src:
        if "#include <linux/pkeys.h>" in src:
            src = src.replace(
                "#include <linux/pkeys.h>",
                "#include <linux/pkeys.h>\n\n"
                "#ifndef VMA_PAD_START\n#define VMA_PAD_START(vma) ((vma)->vm_end)\n#endif",
                1,
            )
        else:
            lines = src.split("\n")
            idx = max(i for i, line in enumerate(lines) if line.startswith("#include"))
            lines.insert(
                idx + 1,
                "\n#ifndef VMA_PAD_START\n#define VMA_PAD_START(vma) ((vma)->vm_end)\n#endif",
            )
            src = "\n".join(lines)
        changed = True

    if "struct dentry *dentry;" in src:
        src = src.replace("struct dentry *dentry;", "struct dentry *dentry = NULL;")
        changed = True

    path.write_text(src)
    print(f"[fix_task_mmu] fixes applied: {changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
