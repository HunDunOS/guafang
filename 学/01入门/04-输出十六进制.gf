00 ══════════════════════════════════════════════════════
00  01 入门：输出十六进制
00 ══════════════════════════════════════════════════════
00
00  把一个 0~15 的数转成十六进制字符：0-9 加 48，A-F 加 55
00 ══════════════════════════════════════════════════════

tt hexch 01 val 02 08
    tz res a0 0
    tz big a0 0
    res a0 01 val 02 hs 15
    big a0 01 res 02 a3 10
    lr big 08
        res a0 01 res 02 ht 48
    09
    lr 01 big 02 a1 0 08
        res a0 01 res 02 ht 7
    09
    zz res
09

tt main 01 argv 02 08
    tz num a0 255
    tz nib a0 0
    tz out a0 0
    nib a0 01 num 02 dl 4
    nib a0 01 nib 02 hs 15
    out a0 zt hexch 01 nib 02
    st dt out
    st dt 10
    zz 0
09
