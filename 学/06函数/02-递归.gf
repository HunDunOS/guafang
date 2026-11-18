00 ══════════════════════════════════════════════════════
00  06 函数：递归求阶乘
00 ══════════════════════════════════════════════════════
00
00  函数可以调自己。注意留出口，否则栈会爆。
00 ══════════════════════════════════════════════════════

tt fact 01 num 02 08
    tz res a0 0
    lr 01 num 02 a5 1 08
        res a0 1
        zz res
    09
    tz sub a0 0
    tz part a0 0
    sub a0 01 num 02 hz 1
    part a0 zt fact 01 sub 02
    res a0 01 num 02 hh part
    zz res
09

tt main 01 argv 02 08
    tz out a0 0
    out a0 zt fact 01 5 02
    st dt out
    st dt 10
    zz 0
09
