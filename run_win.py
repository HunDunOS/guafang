#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
run_win.py —— 卦方 stage1 的 Windows 宿主 + 加载器（不依赖 WSL / as / ld）

流程：
  gfx.exe bootstrap.gf -c -nx -obj -o gfx2.obj
      → gfx2.obj（text+rodata 字节）、.sym（符号表）、.reloc（重定位）、.sym.size（三段长度）
  本脚本把字节贴进低地址可执行内存、回填全部重定位、用 9 个 Python 回调实现宿主内建，
  然后调用 fn_主(输入文件路径)，让它自己生成 新清单999.txt。

约定（与 gfx.c / 宿主64.s 一致）：
  调用方 push 参数 → call → add rsp,8*n；被调方第一个参数在 [rbp+16+8*(np-1-i)]
  即栈上：第 1 个参数在最高地址 [rsp+8*n]，第 n 个在 [rsp+8]
"""
import ctypes
import os
import struct
import sys
from ctypes import wintypes

HERE = os.path.dirname(os.path.abspath(__file__))
OBJ = os.path.join(HERE, "gfx2.obj")
INPUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "bootstrap.gf")

MEM_COMMIT, MEM_RESERVE = 0x1000, 0x2000
PAGE_EXECUTE_READWRITE = 0x40
SLURP_SIZE = 1 << 20
BASES = (0x10000000, 0x20000000, 0x30000000, 0x40000000, 0x50000000, 0x60000000)

_k32 = ctypes.windll.kernel32
VirtualAlloc = _k32.VirtualAlloc
VirtualAlloc.restype = ctypes.c_void_p
VirtualAlloc.argtypes = [ctypes.c_void_p, ctypes.c_size_t, wintypes.DWORD, wintypes.DWORD]

CALLBACKS = []          # 必须保活，否则回调被 GC 后执行会崩
OUT = sys.stdout.buffer


def out(b):
    OUT.write(b)
    OUT.flush()


def cstr(addr):
    return ctypes.string_at(addr)


def align4(n):
    return (n + 3) & ~3


# ── 栈传参 → Win64 ABI 的机器码 shim ────────────────────────────────────
def mov_stack(reg, disp):
    """mov reg, [rsp+disp8]  reg: 0=rcx 1=rdx 2=r8 3=r9"""
    op = ((0x48, 0x8B, 0x4C, 0x24), (0x48, 0x8B, 0x54, 0x24),
          (0x4C, 0x8B, 0x44, 0x24), (0x4C, 0x8B, 0x4C, 0x24))[reg]
    return bytes(op) + bytes([disp])


def make_shim(nargs, cb_addr):
    b = bytearray()
    for k in range(min(nargs, 4)):
        b += mov_stack(k, 8 * (nargs - k))     # 第 k+1 个参数
    b += bytes([0x53])                         # push rbx（保活原 rsp）
    b += bytes([0x48, 0x89, 0xE3])             # mov rbx, rsp
    b += bytes([0x48, 0x83, 0xE4, 0xF0])      # and rsp, -16（不依赖调用方对齐）
    b += bytes([0x48, 0x83, 0xEC, 0x20])      # sub rsp,32（shadow space）
    b += bytes([0x48, 0xB8]) + struct.pack("<Q", cb_addr)
    b += bytes([0xFF, 0xD0])                   # call rax
    b += bytes([0x48, 0x89, 0xDC])             # mov rsp, rbx
    b += bytes([0x5B])                         # pop rbx
    b += bytes([0xC3])                         # ret（参数由调用方清理）
    return bytes(b)


def main():
    os.chdir(HERE)          # 让「新清单999.txt」等相对路径落在持久目录
    for p in (OBJ, OBJ + ".sym", OBJ + ".reloc", OBJ + ".sym.size", INPUT):
        if not os.path.exists(p):
            print("缺文件:", p)
            return 1

    text_len, rodata_len, bss_len = map(int, open(OBJ + ".sym.size").read().split())
    blob = bytearray(open(OBJ, "rb").read())
    rodata_base = align4(text_len)
    bss_base = align4(rodata_base + rodata_len)
    print(f"段长: text={text_len} rodata={rodata_len} bss={bss_len} 文件={len(blob)} "
          f"rodata@{rodata_base} bss@{bss_base}")

    syms = {}
    for line in open(OBJ + ".sym", encoding="utf-8"):
        p = line.split()
        if len(p) >= 3:
            syms[p[0]] = (int(p[1]), int(p[2]))
    relocs = []
    for line in open(OBJ + ".reloc", encoding="utf-8"):
        p = line.split()
        if len(p) >= 3:
            relocs.append((int(p[0]), int(p[1]), p[2]))
    print(f"符号={len(syms)} 重定位={len(relocs)}")

    # 内存布局：text+rodata（落盘字节）→ bss → 1MB 读文件缓冲 → 路径串 → shim/入口 stub
    slurp_off = bss_base + bss_len
    extra_off = slurp_off + SLURP_SIZE
    total = extra_off + 64 * 1024

    base = None
    for cand in BASES:
        a = VirtualAlloc(ctypes.c_void_p(cand), total, MEM_COMMIT | MEM_RESERVE,
                         PAGE_EXECUTE_READWRITE)
        if a:
            base = a
            break
    if not base:
        print("指定低地址分配失败（32 位绝对重定位需要 <4GB 基址）")
        return 1
    if base >= (1 << 32):
        print(f"警告: 基址 0x{base:x} 超过 4GB，绝对 32 位重定位会截断")
    print(f"装载基址: 0x{base:x}  提交 {total} 字节")

    sec_base = {0: base, 1: base + rodata_base, 2: base + bss_base}
    slurp_addr = base + slurp_off

    # ── 9 个宿主内建（参数一律 64 位整数，Win64 前 4 个走寄存器）────────
    CT = ctypes.CFUNCTYPE(ctypes.c_uint64, ctypes.c_uint64, ctypes.c_uint64,
                          ctypes.c_uint64, ctypes.c_uint64)

    def h_putc(a, _1, _2, _3):
        out(bytes([a & 255]))
        return 0

    def h_puts(a, _1, _2, _3):
        out(cstr(a))
        return 0

    def h_puti(n, _1, _2, _3):
        v = ctypes.c_int32(n & 0xffffffff).value
        out(str(v).encode())
        return 0

    def h_oob(_0, _1, _2, _3):
        out(b"\n[OOB] index out of range\n")
        return 0

    def h_sb(addr, byte, _2, _3):
        ctypes.memmove(addr, bytes([byte & 255]), 1)
        return 0

    def h_fsize(path, _1, _2, _3):
        try:
            return os.path.getsize(cstr(path).decode("utf-8"))
        except OSError:
            return 0

    def h_readfile(path, _1, _2, _3):
        try:
            data = open(cstr(path).decode("utf-8"), "rb").read()
        except OSError:
            return 0
        n = min(len(data), SLURP_SIZE)
        ctypes.memmove(slurp_addr, data[:n], n)
        return n

    def h_readbuf(_0, _1, _2, _3):
        return slurp_addr

    def h_write_file(path, content, length, _3):
        try:
            name = cstr(path).decode("utf-8")
            n = int(length)
            data = ctypes.string_at(content, n) if n > 0 else cstr(content)
            with open(name, "wb") as f:
                f.write(data)
            return 1
        except OSError as e:
            out(("写文件失败: %s\n" % e).encode())
            return 0

    # 名字 → (参数个数, 回调实现)。参数个数按 自举.gf / 宿主64.s 的栈序
    spec = [
        ("_rt_putc",      1, h_putc),
        ("_rt_puts",      1, h_puts),
        ("_rt_puti",      1, h_puti),
        ("_rt_oob",       0, h_oob),
        ("_rt_sb",        2, h_sb),
        ("_rt_fsize",     1, h_fsize),
        ("_rt_readfile",  1, h_readfile),
        ("_rt_readbuf",   0, h_readbuf),
        ("fn_write_file", 3, h_write_file),
    ]
    cb_addr = {}
    for name, n, fn in spec:
        cb = CT(fn)
        CALLBACKS.append(cb)
        cb_addr[name] = ctypes.cast(cb, ctypes.c_void_p).value

    # ── 贴入 shim 与路径串 ────────────────────────────────────────────
    cursor = extra_off
    shim_addr = {}
    for name, n, fn in spec:
        s = make_shim(n, cb_addr[name])
        ctypes.memmove(base + cursor, s, len(s))   # shim 在 extra 区，blob 只管落盘的 text+rodata
        shim_addr[name] = base + cursor
        cursor += (len(s) + 15) & ~15

    path_bytes = os.path.basename(INPUT).encode("ascii") + b"\0"
    ctypes.memmove(base + cursor, path_bytes, len(path_bytes))
    path_addr = base + cursor
    cursor += (len(path_bytes) + 15) & ~15

    # 入口 stub: push 路径地址 → call fn_main → 清栈 → ret
    # 函数名已改 ASCII 缩写（fn_main）；保留旧 mangle 名兼容
    entry_name = next((n for n in ("fn_main", "fn__e4_b8_bb") if n in syms), None)
    if entry_name is None:
        print("找不到入口符号 (fn_main / fn__e4_b8_bb)")
        return 1
    entry_fn = sec_base[syms[entry_name][0]] + syms[entry_name][1]
    stub = (bytes([0x68]) + struct.pack("<I", path_addr) +
            bytes([0x48, 0xB8]) + struct.pack("<Q", entry_fn) +
            bytes([0xFF, 0xD0, 0x48, 0x83, 0xC4, 0x08, 0xC3]))
    ctypes.memmove(base + cursor, stub, len(stub))
    entry_stub = base + cursor
    print(f"fn_主 @0x{entry_fn:x}  入口 stub @0x{entry_stub:x}")

    def sym_addr(name):
        if name.startswith("rip+"):
            name = name[4:]
        if name in syms:
            s, o = syms[name]
            return sec_base[s] + o
        if name in shim_addr:
            return shim_addr[name]
        raise KeyError("未解析符号 " + name)

    # ── 回填全部重定位（obj 模式下内部符号也留了占位）────────────────
    unresolved = []
    for pos, cls, name in relocs:
        try:
            target = sym_addr(name)
        except KeyError:
            unresolved.append(name)
            continue
        field = base + pos
        if cls == 0:
            v = target
            width = 4
        elif cls == 1:
            v = target - (field + 4)
            width = 4
        else:
            v = target - (field + 1)
            width = 1
        blob[pos:pos + width] = struct.pack("<I", v & 0xffffffff)[:width]
    if unresolved:
        print("未解析符号:", sorted(set(unresolved)))
        return 1
    print(f"回填 {len(relocs)} 笔完成")

    ctypes.memmove(base, bytes(blob), len(blob))     # text+rodata 落盘
    print("--- 开始执行 gfx2 ---")
    ctypes.CFUNCTYPE(ctypes.c_uint64)(entry_stub)()
    print("\n--- gfx2 返回 ---")
    return 0


if __name__ == "__main__":
    sys.exit(main())
