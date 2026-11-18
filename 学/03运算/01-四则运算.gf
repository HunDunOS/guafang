00 ══════════════════════════════════════════════════════
00  03 运算：加减乘除取余
00 ══════════════════════════════════════════════════════
00
00  二元运算写在括号里：01 甲 ht 乙 02
00  读作：左 操作 右
00
00  ht  火天  加
00  hz  火泽  减
00  hh  离离  乘
00  hl  火雷  除
00  hf  火风  取余
00
00  所有数字都是 64 位整数，没有小数。
00  除法是整除，除不尽的直接丢掉。
00 ══════════════════════════════════════════════════════

tt main 01 argv 02 08
    tz aval a0 100
    tz bval a0 7
    tz res a0 0

    res a0 01 aval 02 ht bval
    st dt res
    st dt 32

    res a0 01 aval 02 hz bval
    st dt res
    st dt 32

    res a0 01 aval 02 hh bval
    st dt res
    st dt 32

    res a0 01 aval 02 hl bval
    st dt res
    st dt 32

    res a0 01 aval 02 hf bval
    st dt res
    st dt 10

    zz 0
09
