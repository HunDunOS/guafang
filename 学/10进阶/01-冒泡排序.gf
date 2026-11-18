00 ══════════════════════════════════════════════════════
00  10 进阶：冒泡排序
00 ══════════════════════════════════════════════════════
00
00  把数组从小到大排好，再打出来。
00 ══════════════════════════════════════════════════════

tf dat a7 6 a8

tt main 01 argv 02 08
    tz pos a0 0
    tz scan a0 0
    tz aval a0 0
    tz bval a0 0
    tz tmp a0 0

    dat a7 0 a8 a0 5
    dat a7 1 a8 a0 3
    dat a7 2 a8 a0 8
    dat a7 3 a8 a0 1
    dat a7 4 a8 a0 9
    dat a7 5 a8 a0 2

    pos a0 0
    ll 01 pos 02 a3 5 08
        scan a0 0
        ll 01 scan 02 a3 5 08
            aval a0 dat a7 scan a8
            bval a0 dat a7 01 scan 02 ht 1 a8
            lr 01 aval 02 a4 bval 08
                tmp a0 aval
                dat a7 scan a8 a0 bval
                dat a7 01 scan 02 ht 1 a8 a0 tmp
            09
            scan a0 01 scan 02 ht 1
        09
        pos a0 01 pos 02 ht 1
    09

    pos a0 0
    ll 01 pos 02 a3 6 08
        aval a0 dat a7 pos a8
        st dt aval
        st dt 32
        pos a0 01 pos 02 ht 1
    09
    st dt 10
    zz 0
09
