00 ══════════════════════════════════════════════════════
00  01 排序：冒泡法
00 ══════════════════════════════════════════════════════
00
00  两个循环套在一起。
00  外圈管「还要排几轮」，内圈管「这一轮从头比到尾」。
00
00  每次比较相邻两个，顺序反了就换过来。
00  一轮下来，最大的就浮到最后面了。
00 ══════════════════════════════════════════════════════

tf num[10] = 0

tt swap 01 A , B 02 -> u64  08
    tz mid = 0
    mid = ff num , A
    sf num , A , ff num , B
    sf num , B , mid
    zz 0
 09

tt zhu 01 02 -> u64  08
    tz i = 0
    tz nei = 0
    tz n = 10
    tz zhi = 0
    tz A = 0
    tz B = 0
    tz yaddr = 0

    00 填一批乱序的数
    sf num , 0 , 64
    sf num , 1 , 25
    sf num , 2 , 12
    sf num , 3 , 22
    sf num , 4 , 11
    sf num , 5 , 90
    sf num , 6 , 45
    sf num , 7 , 33
    sf num , 8 , 5
    sf num , 9 , 77

    puts 01 "排序前 " 02
    i = 0
    ll  08
        lz i n  08 ls 09
        puti 01 ff num , i 02
        putc 01 32 02
        i = 01 i ht 1 02
     09
    putc 01 10 02

    00 冒泡
    i = 0
    ll  08
        lz i n  08 ls 09
        nei = 0
        ll  08
            zhi = 01 n hz 1 02
            lz nei zhi  08 ls 09
            A = ff num , nei
            yaddr = 01 nei ht 1 02
            B = ff num , yaddr
            lr A > B  08
                zt swap 01 nei , yaddr 02
             09
            nei = 01 nei ht 1 02
         09
        i = 01 i ht 1 02
     09

    puts 01 "排序后 " 02
    i = 0
    ll  08
        lz i n  08 ls 09
        puti 01 ff num , i 02
        putc 01 32 02
        i = 01 i ht 1 02
     09
    putc 01 10 02

    zz 0
 09
