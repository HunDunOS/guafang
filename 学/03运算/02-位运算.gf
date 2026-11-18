00 ══════════════════════════════════════════════════════
00  03 运算：位运算
00 ══════════════════════════════════════════════════════
00
00  hs  位与     hr  位或     hd  位异或
00  dh  左移     dl  右移     dr  按位取反
00 ══════════════════════════════════════════════════════

tt main 01 argv 02 08
    tz aval a0 12
    tz bval a0 10
    tz res a0 0

    res a0 01 aval 02 hs bval
    st dt res
    st dt 32

    res a0 01 aval 02 hr bval
    st dt res
    st dt 32

    res a0 01 aval 02 hd bval
    st dt res
    st dt 32

    res a0 01 aval 02 dh 2
    st dt res
    st dt 10
    zz 0
09
