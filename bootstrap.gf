00 ══════════════════════════════════════════════════════
00  自举.gf —— 用卦方写的卦方编译器（stage1）
00 ══════════════════════════════════════════════════════
00
00  目标：gfx 编译它 → gfx2；gfx2 编译它 → gfx3；gfx2 == gfx3
00
00  语法子集（自举.gf 自己用到的）：
00    tt 定义函数   tz 局部变量   ts 全局变量   tf 全局数组
00    zz 返回       = 赋值        ht hz 加减
00    lr ll 条件循环  zt 调用      dd 字符串     dt 整数
00 ══════════════════════════════════════════════════════

ts buf a0 0
ts len a0 0
ts cnt a0 0
ts olen a0 0
ts slot a0 0
ts nname a0 0
ts idx a0 0
ts elno a0 0
ts pdepth a0 0
ts estop a0 0
00 查全用：命中索引+1（0 表示没找到）
ts allhit a0 0
ts allidx a0 0
00 命名铁律命中时置 1：不写产物文件
ts badname a0 0

tf bittab a7 30000 a8
tf lentab a7 30000 a8
tf outbuf a7 524288 a8
tf nmpos a7 2000 a8
tf nmlen a7 2000 a8
tf slotpos a7 2000 a8
tf argmark a7 2000 a8
tf elstack a7 512 a8
tf dstack a7 512 a8
tf tstack a7 512 a8
tf topstack a7 512 a8
00 dd 字符串表：串位=内容在缓冲的起点，串长=内容长度（去掉首尾03）
ts nstr a0 0
tf strpos a7 1024 a8
tf slen a7 1024 a8
00 ts 全局表：全位=名字token索引，全大=size*count
ts nglob a0 0
tf gpos a7 256 a8
tf gsize a7 256 a8
tf ginit a7 256 a8

00 ─────────────────────────────────────────
00  基础
00 ─────────────────────────────────────────

tt isws 01 c 02 08
    tz r a0 0
    tz q1 a0 0
    tz q2 a0 0
    tz t a0 0
    t a0 01 c 02 a1 32
    lr t 08 r a0 1 09
    t a0 01 c 02 a1 9
    lr t 08 r a0 1 09
    t a0 01 c 02 a1 10
    lr t 08 r a0 1 09
    t a0 01 c 02 a1 13
    lr t 08 r a0 1 09
    zz r
09

tt getb 01 i 02 08
    tz a a0 0
    a a0 buf ht i
    a a0 fh 01 a 02
    a a0 01 a 02 hs 255
    zz a
09

00 ─────────────────────────────────────────
00  输出区
00 ─────────────────────────────────────────

tt putb 01 c 02 08
    tz p a0 0
    p a0 outbuf ht olen
    putw 01 p a9 c 02
    olen a0 01 olen 02 ht 1
    zz 0
09

00 ══════ 表达式求值 ══════
00 求值(k)：求第 k 个记号的值，返回数值
00   纯数字   → 返回数字本身
00   纯变量   → 返回它槽位里存的值
00   找不到   → 返回 0
tt eval 01 k 02 08
    tz q1 a0 0
    tz t a0 0
    tz L1 a0 0
    tz p a0 0
    tz c a0 0
    tz d a0 0
    tz v a0 0
    tz r a0 0
    tz q2 a0 0
    tz slv a0 0
    tz i a0 0
    tz num a0 0

    00 第一个字节是数字（48~57）就是数字字面量
    c a0 head 01 k 02
    c a0 01 c 02 hs 255
    v a0 0
    t a0 01 c 02 a6 48
    lr t 08
        t a0 01 c 02 a5 57
        lr t 08
            00 逐位累加：数 = 数*10 + (c-48)
            L1 a0 getlen 01 k 02
            ll 08
                t a0 01 i 02 a1 L1
                lr t 08 ls 09
                q1 a0 01 p 02 ht i
                c a0 bytes 01 k a9 i 02
                c a0 01 c 02 hz 48
                num a0 01 num 02 hh 10
                num a0 01 num 02 ht c
                i a0 01 i 02 ht 1
            09
            zz num
        09
    09

    00 不是数字：当变量名，查槽位
    slot a0 lookup 01 k 02
    t a0 01 slot 02 a1 0
    lr t 08
        zz 0
    09
    00 跨帧读调用者(fn_主)槽位的值：
    00   求值栈帧 sub rsp,96 → rsp+96 = 本帧 rbp；[rbp] = 调用者 rbp
    00   [调用者rbp - 槽] = 目标变量
    p a0 fr
    p a0 01 p 02 ht 96
    v a0 fh 01 p 02
    p a0 01 v 02 hz slot
    v a0 fh 01 p 02
    zz v
09

00 取第 k 个记号的第 j 个字节
tt bytes 01 k a9 j 02 08
    tz p a0 0
    tz q a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    q a0 01 p 02 ht j
    q a0 fh 01 q 02
    q a0 01 q 02 hs 255
    zz q
09

00 取第 k 个记号的第一个字节
tt head 01 k 02 08
    tz p a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    p a0 fh 01 p 02
    zz p
09

00 ══════ 槽位表：名字 → rbp 偏移 ══════

00 登记一个名字（k=记号号，槽=rbp偏移）
tt defname 01 k a9 slv 02 08
    tz n a0 0
    n a0 nname
    nmpos a7 n a8 a0 gettok 01 k 02
    nmlen a7 n a8 a0 getlen 01 k 02
    slotpos a7 n a8 a0 slv
    argmark a7 n a8 a0 0
    nname a0 01 nname 02 ht 1
    zz 0
09

00 比两个名字是否相同：k=记号号，j=表中下标
tt smeq 01 k a9 j 02 08
    tz q1 a0 0
    tz q2 a0 0
    tz t a0 0
    tz p a0 0
    tz q a0 0
    tz i a0 0
    tz a a0 0
    tz b a0 0
    tz same a0 0
    tz L1 a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    q a0 nmpos a7 j a8
    q a0 01 buf 02 ht q
    L1 a0 nmlen a7 j a8
    same a0 0
    00 长度必须相等，否则 n3 会被误判成 n（只比首字节）
    q2 a0 getlen 01 k 02
    lr 01 q2 02 a1 01 L1 02 08
    same a0 1
    ll 08
        t a0 01 i 02 a1 L1
        lr t 08 ls 09
        q1 a0 01 q 02 ht i
        a a0 fh 01 q1 02
        a a0 01 a 02 hs 255
        q2 a0 01 p 02 ht i
        b a0 fh 01 q2 02
        b a0 01 b 02 hs 255
        lh a b 08 same a0 0 ls 09
        i a0 01 i 02 ht 1
    09
    09
    zz same
09

00 同tok：比较两个 token(k,j) 的内容（都按 token 索引取缓冲位置），用于查全
tt sametok 01 k a9 j 02 08
    tz p a0 0
    tz q a0 0
    tz L1 a0 0
    tz i a0 0
    tz a a0 0
    tz b a0 0
    tz t a0 0
    tz same a0 0
    L1 a0 getlen 01 k 02
    p a0 gettok 01 k 02
    q a0 gettok 01 j 02
    p a0 01 buf 02 ht p
    q a0 01 buf 02 ht q
    same a0 0
    00 长度必须相等：否则 t 会命中 tstack（只比到短的那个名字的长度就停）
    t a0 getlen 01 j 02
    lr 01 t 02 a1 01 L1 02 08
    same a0 1
    ll 08
        t a0 01 i 02 a1 L1
        lr t 08 ls 09
        a a0 fh 01 p 02
        a a0 01 a 02 hs 255
        b a0 fh 01 q 02
        b a0 01 b 02 hs 255
        lh a b 08 same a0 0 ls 09
        p a0 01 p 02 ht 1
        q a0 01 q 02 ht 1
        i a0 01 i 02 ht 1
    09
    09
    zz same
09

00 查名字：返回槽位（正数 8,16,...），找不到返回 0
00   注意：不能返回 -1 —— 无符号比较下 -1 恒大于任何正数，
00   且 wnum 不支持负数会把 -1 打成乱码（曾出现 [rbp-w51615]）
tt lookup 01 k 02 08
    tz j a0 0
    tz r a0 0
    tz q1 a0 0
    tz q2 a0 0
    tz f a0 0
    r a0 0
    ll 01 j 02 a3 01 nname 02 08
        f a0 smeq 01 k a9 j 02
        lr f 08
            r a0 slotpos a7 j a8
            idx a0 j
            ls
        09
        j a0 01 j 02 ht 1
    09
    zz r
09

00 ── 出数：把数字转成十进制输出（支持 0~999999）──
tt wnum 01 v 02 08
    tz d a0 0
    tz has a0 0
    tz t a0 0


    has a0 0

    00 十亿位
    t a0 01 v 02 a6 1000000000
    lr t 08
        d a0 01 v 02 hl 1000000000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 1000000000
        has a0 1
    09

    00 亿位
    t a0 01 v 02 a6 100000000
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 100000000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 100000000
        has a0 1
    09

    00 千万位
    t a0 01 v 02 a6 10000000
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 10000000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 10000000
        has a0 1
    09

    00 百万位
    t a0 01 v 02 a6 1000000
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 1000000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 1000000
        has a0 1
    09

    00 十万位
    t a0 01 v 02 a6 100000
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 100000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 100000
        has a0 1
    09

    00 万位
    t a0 01 v 02 a6 10000
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 10000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 10000
        has a0 1
    09

    00 千位
    t a0 01 v 02 a6 1000
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 1000
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 1000
        has a0 1
    09

    00 百位
    t a0 01 v 02 a6 100
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 100
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 100
        has a0 1
    09

    00 十位
    t a0 01 v 02 a6 10
    lr 01 t hr has 02 08
        d a0 01 v 02 hl 10
        d a0 01 d 02 ht 48
        putb 01 d 02
        v a0 01 v 02 hf 10
    09

    00 个位
    v a0 01 v 02 ht 48
        putb 01 v 02
    zz 0
09

tt wstr 01 s 02 08
    tz i a0 0
    tz c a0 0
    tz p a0 0
    tz t a0 0
    tz q a0 0
    p a0 s
    ll 08
        q a0 01 p 02 ht i
        c a0 fh 01 q 02
        c a0 01 c 02 hs 255
        t a0 01 c 02 a1 0
        lr t 08 ls 09
        putb 01 c 02
        i a0 01 i 02 ht 1
    09
    zz 0
09

00 ─────────────────────────────────────────
00  记号表：取位置、取长度、比字符串
00 ─────────────────────────────────────────

tt gettok 01 k 02 08
    tz t a0 0
    t a0 01 k 02 hh 8
    t a0 bittab ht t
    t a0 fh 01 t 02
    zz t
09

tt getlen 01 k 02 08
    tz t a0 0
    t a0 01 k 02 hh 8
    t a0 lentab ht t
    t a0 fh 01 t 02
    zz t
09

tt tokis 01 k a9 s 02 08
    tz t a0 0
    tz q1 a0 0
    tz q2 a0 0
    tz p a0 0
    tz i a0 0
    tz a a0 0
    tz b a0 0
    tz same a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    same a0 1
    ll 08
        q1 a0 01 p 02 ht i
        a a0 fh 01 q1 02
        a a0 01 a 02 hs 255
        q2 a0 01 s 02 ht i
        b a0 fh 01 q2 02
        b a0 01 b 02 hs 255
        t a0 01 b 02 a1 0
        lr t 08 ls 09
        lh a b 08 same a0 0 ls 09
        i a0 01 i 02 ht 1
    09
    00 长度必须相等：否则 zz 会命中 zzdone、ts 会命中 tstack
    t a0 getlen 01 k 02
    lh t i 08 same a0 0 09
    zz same
09

tt puttok 01 k 02 08
    tz p a0 0
    tz i a0 0
    tz c a0 0
    tz L a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    L a0 getlen 01 k 02
    i a0 0
    ll 01 i 02 a3 01 L 02 08
        c a0 fh 01 01 p ht i 02 02
        c a0 01 c 02 hs 255
        putb 01 c 02
        i a0 01 i 02 ht 1
    09
    zz 0
09

00 hex2：输出字节 v 的两位小写十六进制
tt hex2 01 v 02 08
    tz hi a0 0
    tz lo a0 0
    tz c2 a0 0
    hi a0 01 v 02 hl 16
    lo a0 01 v 02 hf 16
    00 高位
    c2 a0 01 hi 02 a3 10
    lr c2 08
        putb 01 01 hi 02 ht 48 02
    09
    c2 a0 01 hi 02 a6 10
    lr c2 08
        putb 01 01 hi 02 ht 87 02
    09
    00 低位
    c2 a0 01 lo 02 a3 10
    lr c2 08
        putb 01 01 lo 02 ht 48 02
    09
    c2 a0 01 lo 02 a6 10
    lr c2 08
        putb 01 01 lo 02 ht 87 02
    09
    zz 0
09

00 曼：mangle token k 的名字并输出到出区（g_ 由调用方加）
tt mgl 01 k 02 08
    tz p a0 0
    tz L a0 0
    tz i a0 0
    tz v a0 0
    tz t a0 0
    tz f a0 0
    tz done a0 0
    tz q2 a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    L a0 getlen 01 k 02
    i a0 0
    ll 01 i 02 a3 01 L 02 08
        done a0 0
        v a0 fh 01 01 p ht i 02 02
        v a0 01 v 02 hs 255
        t a0 01 v 02 a6 97
        lr t 08
            f a0 01 v 02 a5 122
            lr f 08
                putb 01 v 02
                done a0 1
            09
        09
        t a0 01 done 02 a1 0
        lr t 08
            f a0 01 v 02 a6 65
            lr f 08
                q2 a0 01 v 02 a5 90
                lr q2 08
                    putb 01 v 02
                    done a0 1
                09
            09
        09
        t a0 01 done 02 a1 0
        lr t 08
            f a0 01 v 02 a6 48
            lr f 08
                q2 a0 01 v 02 a5 57
                lr q2 08
                    putb 01 v 02
                    done a0 1
                09
            09
        09
        t a0 01 done 02 a1 0
        lr t 08
            f a0 01 v 02 a1 95
            lr f 08
                putb 01 v 02
                done a0 1
            09
        09
        t a0 01 done 02 a1 0
        lr t 08
            putb 01 95 02
            hex2 01 v 02
        09
        i a0 01 i 02 ht 1
    09
    zz 0
09
00 查全局表，命中返回 索引+1（>0），未命中返回 0
00   返回 索引+1 而非 索引：索引 0 是合法全局，用 0 表示“没找到”才能判断
tt findall 01 k 02 08
    tz j a0 0
    tz f2 a0 0
    tz n2 a0 0
    tz r a0 0
    ll 01 j 02 a3 01 nglob 02 08
        n2 a0 gpos a7 j a8
        f2 a0 sametok 01 k a9 n2 02
        lr f2 08
            allidx a0 j
            r a0 01 j 02 ht 1
            ls
        09
        j a0 01 j 02 ht 1
    09
    zz r
09

00 串转数：token k 的十进制文本转数值（0x/0X 开头按十六进制，strtol base 0 口径）
tt str2num 01 k 02 08
    tz p a0 0
    tz L a0 0
    tz i a0 0
    tz v a0 0
    tz c3 a0 0
    tz t a0 0
    tz f a0 0
    p a0 gettok 01 k 02
    p a0 01 buf 02 ht p
    L a0 getlen 01 k 02
    i a0 0
    00 0x / 0X 开头 → 十六进制，超过 2147483647 同样饱和成 2147483647
    c3 a0 fh 01 01 p ht 0 02 02
    c3 a0 01 c3 02 hs 255
    t a0 01 c3 02 a1 48
    lr t 08
        c3 a0 fh 01 01 p ht 1 02 02
        c3 a0 01 c3 02 hs 255
        t a0 01 c3 02 a1 120
        f a0 01 c3 02 a1 88
        t a0 01 t 02 hr 01 f 02
        lr t 08
            v a0 0
            i a0 2
            ll 01 i 02 a3 01 L 02 08
                c3 a0 fh 01 01 p ht i 02 02
                c3 a0 01 c3 02 hs 255
                t a0 01 c3 02 a6 48
                f a0 01 c3 02 a5 57
                t a0 01 t 02 hs 01 f 02
                lr t 08
                    c3 a0 01 c3 02 hz 48
                    v a0 01 v 02 hh 16
                    v a0 01 v 02 ht 01 c3 02
                09
                t a0 01 c3 02 a6 97
                f a0 01 c3 02 a5 102
                t a0 01 t 02 hs 01 f 02
                lr t 08
                    c3 a0 01 c3 02 hz 87
                    v a0 01 v 02 hh 16
                    v a0 01 v 02 ht 01 c3 02
                09
                t a0 01 c3 02 a6 65
                f a0 01 c3 02 a5 70
                t a0 01 t 02 hs 01 f 02
                lr t 08
                    c3 a0 01 c3 02 hz 55
                    v a0 01 v 02 hh 16
                    v a0 01 v 02 ht 01 c3 02
                09
                lr 01 v 02 a4 2147483647 08 v a0 2147483647 09
                i a0 01 i 02 ht 1
            09
            zz v
        09
    09
    ll 01 i 02 a3 01 L 02 08
        c3 a0 fh 01 01 p ht i 02 02
        c3 a0 01 c3 02 hs 255
        t a0 01 c3 02 a6 48
        lr t 08
            f a0 01 c3 02 a5 57
            lr f 08
                v a0 01 v 02 hh 10
                c3 a0 01 c3 02 hz 48
                v a0 01 v 02 ht 01 c3 02
                00 gfx 用 strtol：Windows 下 long 是 32 位，溢出一律饱和成 2147483647
                lr 01 v 02 a4 2147483647 08 v a0 2147483647 09
            09
        09
        i a0 01 i 02 ht 1
    09
    zz v
09

00 登全局：登记顶层 ts/tf 声明，k=名字token，sz=size*count
tt regglob 01 k a9 s2 02 08
    gpos a7 nglob a8 a0 k
    gsize a7 nglob a8 a0 s2
    nglob a0 01 nglob 02 ht 1
    zz 0
09

00 登串：把 token k（形如 03内容03）登记进串表，返回串号
tt regstr 01 k 02 08
    tz p a0 0
    tz L a0 0
    tz d a0 0
    tz c a0 0
    tz q1 a0 0
    p a0 gettok 01 k 02
    L a0 getlen 01 k 02
    00 两端定界符共占几字节：03…03 → 4；双引号 … → 2
    d a0 4
    c a0 bytes 01 k a9 0 02
    lr 01 c 02 a1 34 08 d a0 2 09
    q1 a0 01 d 02 hl 2
    q1 a0 01 p 02 ht q1
    q1 a0 01 buf 02 ht q1
    strpos a7 nstr a8 a0 q1
    q1 a0 01 L 02 hz 01 d 02
    slen a7 nstr a8 a0 q1
    nstr a0 01 nstr 02 ht 1
    zz 01 nstr 02 hz 1
09

00 是名：这个字节是否可作为标识符首字节（小写/大写/_/中文）
tt isname 01 c 02 08
    tz t a0 0
    tz f a0 0
    t a0 01 c 02 a6 97
    f a0 01 c 02 a5 122
    t a0 01 t 02 hs 01 f 02
    f a0 01 c 02 a6 65
    lr f 08
        f a0 01 c 02 a5 90
        t a0 01 t 02 hr 01 f 02
    09
    f a0 01 c 02 a1 95
    t a0 01 t 02 hr 01 f 02
    f a0 01 c 02 a6 128
    t a0 01 t 02 hr 01 f 02
    zz t
09

00 isnum(k)：token 全是十进制数字（不含空；01..09 编码记号由调用处排除）
tt isnum 01 k 02 08
    tz i a0 0
    tz L a0 0
    tz p a0 0
    tz q a0 0
    tz c a0 0
    L a0 getlen 01 k 02
    p a0 gettok 01 k 02
    ll 01 i 02 a3 01 L 02 08
        q a0 01 p 02 ht i
        q a0 01 buf 02 ht q
        c a0 fh 01 q 02
        c a0 01 c 02 hs 255
        lr 01 c 02 a3 48 08 zz 0 09
        lr 01 c 02 a4 57 08 zz 0 09
        i a0 01 i 02 ht 1
    09
    zz 1
09

00 putnumtok：数字 token 按 gfx 口径输出解析值（strtol 32 位饱和，超过 2147483647 一律 2147483647）
00   非数字 token（名字、编码记号）原样输出，行为与 puttok 相同
tt putnumtok 01 k 02 08
    tz v a0 0
    tz t a0 0
    tz L a0 0
    tz c a0 0
    L a0 getlen 01 k 02
    00 十六进制字面量 0x / 0X：解析成十进制输出（strtol base 0 口径）
    t a0 01 L 02 a4 2
    lr t 08
        c a0 head 01 k 02
        c a0 01 c 02 hs 255
        t a0 01 c 02 a1 48
        lr t 08
            c a0 bytes 01 k a9 1 02
            t a0 01 c 02 a1 120
            v a0 01 c 02 a1 88
            t a0 01 t 02 hr 01 v 02
            lr t 08
                v a0 str2num 01 k 02
                wnum 01 v 02
                zz 0
            09
        09
    09
    t a0 01 L 02 a4 0
    lr t 08
        t a0 isnum 01 k 02
        lr t 08
            00 首字节是 0 且长度 2 的是编码记号，不是数字，原样输出
            c a0 head 01 k 02
            c a0 01 c 02 hs 255
            t a0 01 c 02 a1 48
            v a0 01 L 02 a1 2
            t a0 01 t 02 hs 01 v 02
            t a0 01 t 02 a1 0
            lr t 08
                v a0 str2num 01 k 02
                wnum 01 v 02
                zz 0
            09
        09
    09
    puttok 01 k 02
    zz 0
09

00 istype(k)：token 是不是类型名（对齐 gfx 的 TYPES 表）
00   u8/u16/u32/u64/i8/i16/i32/i64/z 单字；J M S H T 单字与其两位组合
tt istype 01 k 02 08
    tz L a0 0
    tz c a0 0
    tz c2 a0 0
    tz c3 a0 0
    tz t a0 0
    tz f a0 0
    tz f2 a0 0
    tz g a0 0
    L a0 getlen 01 k 02
    00 超过 3 个字符的不是类型
    lr 01 L 02 a4 3 08 zz 0 09
    c a0 head 01 k 02
    c a0 01 c 02 hs 255
    00 单字符：z(122) J(74) M(77) S(83) H(72) T(84)
    lr 01 L 02 a1 1 08
        lr 01 c 02 a1 122 08 zz 1 09
        lr 01 c 02 a1 74 08 zz 1 09
        lr 01 c 02 a1 77 08 zz 1 09
        lr 01 c 02 a1 83 08 zz 1 09
        lr 01 c 02 a1 72 08 zz 1 09
        lr 01 c 02 a1 84 08 zz 1 09
        zz 0
    09
    c2 a0 bytes 01 k a9 1 02
    00 双字符：u8 i8 或 J M S H T 两两组合
    lr 01 L 02 a1 2 08
        lr 01 c 02 a1 117 08
            lr 01 c2 02 a1 56 08 zz 1 09
        09
        lr 01 c 02 a1 105 08
            lr 01 c2 02 a1 56 08 zz 1 09
        09
        f a0 01 c 02 a1 74
        g a0 01 c 02 a1 77
        f a0 01 f 02 hr 01 g 02
        g a0 01 c 02 a1 83
        f a0 01 f 02 hr 01 g 02
        g a0 01 c 02 a1 72
        f a0 01 f 02 hr 01 g 02
        g a0 01 c 02 a1 84
        f a0 01 f 02 hr 01 g 02
        g a0 01 c2 02 a1 74
        t a0 01 c2 02 a1 77
        g a0 01 g 02 hr 01 t 02
        t a0 01 c2 02 a1 83
        g a0 01 g 02 hr 01 t 02
        t a0 01 c2 02 a1 72
        g a0 01 g 02 hr 01 t 02
        t a0 01 c2 02 a1 84
        g a0 01 g 02 hr 01 t 02
        t a0 01 f 02 hs 01 g 02
        lr t 08 zz 1 09
        zz 0
    09
    00 三字符：u16 u32 u64 i16 i32 i64
    c3 a0 bytes 01 k a9 2 02
    f a0 01 c 02 a1 117
    g a0 01 c 02 a1 105
    f a0 01 f 02 hr 01 g 02
    g a0 01 c2 02 a1 49
    t a0 01 c3 02 a1 54
    g a0 01 g 02 hs 01 t 02
    t a0 01 c2 02 a1 51
    f2 a0 01 c3 02 a1 50
    t a0 01 t 02 hs 01 f2 02
    g a0 01 g 02 hr 01 t 02
    t a0 01 c2 02 a1 54
    f2 a0 01 c3 02 a1 52
    t a0 01 t 02 hs 01 f2 02
    g a0 01 g 02 hr 01 t 02
    t a0 01 f 02 hs 01 g 02
    lr t 08 zz 1 09
    zz 0
09

00 载荷：把一个记号当值载入 rax（数字 / 局部 / 参数 / 全局标量）
tt pl 01 n3 02 08
    tz c a0 0
    tz t a0 0
    tz q1 a0 0
    tz f a0 0
    c a0 head 01 n3 02
    c a0 01 c 02 hs 255
    t a0 01 c 02 a6 48
    q1 a0 01 c 02 a5 57
    t a0 01 t 02 hs 01 q1 02
    lr t 08
        putb 01 9 02
        wstr 01 03mov rax, 03 02
        putnumtok 01 n3 02
        putb 01 10 02
        zz 0
    09
    q1 a0 lookup 01 n3 02
    00 lookup: 0=not found(global), >0=param slot, <0=local slot
    t a0 01 q1 02 a2 0
    lr t 08

        f a0 argmark a7 idx a8
        lr f 08
            putb 01 9 02
            wstr 01 03lea rax, [rbp+03 02
            wnum 01 q1 02
            wstr 01 03]03 02
            putb 01 10 02
        09
        f a0 01 f 02 a1 0
        lr f 08
            putb 01 9 02
            wstr 01 03lea rax, [rbp-03 02
            wnum 01 q1 02
            wstr 01 03]03 02
            putb 01 10 02
        09
        putb 01 9 02
        wstr 01 03mov rax, [rax]03 02
        putb 01 10 02
        zz 0
    09
    putb 01 9 02
    wstr 01 03mov rax, offset g_03 02
    mgl 01 n3 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03mov rax, [rax]03 02
    putb 01 10 02
    zz 0
09

00 二元运算：约定 rax=右值、栈顶=左值；按 op token 输出指令，结果留在 rax
00   op 首字节 61('=') → cmp+sete；60/62/33 → cmp+setb/setbe/seta/setae/setne
00   op 首字节 104('h') → ht/hz/hh/hl/hf/hs/hr/hd 算术与位运算
tt twoop 01 op 02 08
    tz c a0 0
    tz q2 a0 0
    tz t a0 0
    tz f a0 0
    c a0 head 01 op 02
    c a0 01 c 02 hs 255
    q2 a0 bytes 01 op a9 1 02
    00 all operators: move right to rcx, pop left into rax
    putb 01 9 02
    wstr 01 03mov rcx, rax03 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03pop rax03 02
    putb 01 10 02
    00 a1~a6 comparison ops: emit cmp + setcc + movzx directly
    t a0 01 c 02 a1 97
    lr t 08
        00 c == 97 means a0-a9 family
        t a0 01 q2 02 a6 48
        f a0 01 q2 02 a5 55
        t a0 01 t 02 hs 01 f 02
        lr t 08
            putb 01 9 02
            wstr 01 03cmp rax, rcx03 02
            putb 01 10 02
            00 a1=49 sete  a2=50 setne  a3=51 setb  a4=52 seta  a5=53 setbe  a6=54 setae
            lr 01 q2 02 a1 49 08
                putb 01 9 02
                wstr 01 03sete al03 02
                putb 01 10 02
            09
            lr 01 q2 02 a1 50 08
                putb 01 9 02
                wstr 01 03setne al03 02
                putb 01 10 02
            09
            lr 01 q2 02 a1 51 08
                putb 01 9 02
                wstr 01 03setb al03 02
                putb 01 10 02
            09
            lr 01 q2 02 a1 52 08
                putb 01 9 02
                wstr 01 03seta al03 02
                putb 01 10 02
            09
            lr 01 q2 02 a1 53 08
                putb 01 9 02
                wstr 01 03setbe al03 02
                putb 01 10 02
            09
            lr 01 q2 02 a1 54 08
                putb 01 9 02
                wstr 01 03setae al03 02
                putb 01 10 02
            09
            putb 01 9 02
            wstr 01 03movzx rax, al03 02
            putb 01 10 02
            zz 0
        09
    09
    00 算术与位运算
    t a0 01 c 02 a1 104
    lr t 08
        lr 01 q2 02 a1 116 08
            putb 01 9 02
            wstr 01 03add rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 a1 122 08
            putb 01 9 02
            wstr 01 03sub rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 a1 104 08
            putb 01 9 02
            wstr 01 03imul rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 a1 115 08
            putb 01 9 02
            wstr 01 03and rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 a1 114 08
            putb 01 9 02
            wstr 01 03or rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 a1 100 08
            putb 01 9 02
            wstr 01 03xor rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        00 hl 除法 / hf 取模：xor rdx,rdx; div rcx
        f a0 01 q2 02 a1 108
        lr f 08
            putb 01 9 02
            wstr 01 03xor rdx, rdx03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03div rcx03 02
            putb 01 10 02
            zz 0
        09
        f a0 01 q2 02 a1 102
        lr f 08
            putb 01 9 02
            wstr 01 03xor rdx, rdx03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03div rcx03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03mov rax, rdx03 02
            putb 01 10 02
            zz 0
        09
    09
    00 dh 左移 / dl 右移：量在 cl（gfx binop_emit 口径）
    t a0 01 c 02 a1 100
    lr t 08
        lr 01 q2 02 a1 104 08
            putb 01 9 02
            wstr 01 03shl rax, cl03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 a1 108 08
            putb 01 9 02
            wstr 01 03shr rax, cl03 02
            putb 01 10 02
            zz 0
        09
    09
    00 兜底：什么都不是，当加法（不静默吞掉）
    putb 01 9 02
    wstr 01 03add rax, rcx03 02
    putb 01 10 02
    zz 0
09

00 ─────────────────────────────────────────
00  命名铁律：命令与名字不许含中文 / 非 ASCII
00  放行的三处：00 注释（切词阶段整行跳过）、03…03 字符串（是输出内容）、文件名
00 ─────────────────────────────────────────

00 haszh(k)：token k 里有没有 >= 0x80 的字节
tt haszh 01 k 02 08
    tz i a0 0
    tz L a0 0
    tz p a0 0
    tz q a0 0
    tz c a0 0
    L a0 getlen 01 k 02
    p a0 gettok 01 k 02
    ll 01 i 02 a3 01 L 02 08
        q a0 01 p 02 ht i
        q a0 01 buf 02 ht q
        c a0 fh 01 q 02
        c a0 01 c 02 hs 255
        lr 01 c 02 a6 128 08 zz 1 09
        i a0 01 i 02 ht 1
    09
    zz 0
09

00 lineof(k)：token k 在源码第几行（从 1 数）
tt lineof 01 k 02 08
    tz i a0 0
    tz e a0 0
    tz c a0 0
    tz n a0 0
    e a0 gettok 01 k 02
    ll 01 i 02 a3 01 e 02 08
        c a0 getb 01 i 02
        lr 01 c 02 a1 10 08 n a0 01 n 02 ht 1 09
        i a0 01 i 02 ht 1
    09
    n a0 01 n 02 ht 1
    zz n
09

00 outtok(k)：把 token 原文写到 stdout（报错用，可以含中文）
tt outtok 01 k 02 08
    tz i a0 0
    tz L a0 0
    tz p a0 0
    tz q a0 0
    tz c a0 0
    L a0 getlen 01 k 02
    p a0 gettok 01 k 02
    ll 01 i 02 a3 01 L 02 08
        q a0 01 p 02 ht i
        q a0 01 buf 02 ht q
        c a0 fh 01 q 02
        c a0 01 c 02 hs 255
        putc 01 c 02
        i a0 01 i 02 ht 1
    09
    zz 0
09

00 ─────────────────────────────────────────
00  语句切分：算出一条语句的结束位置
00  〖与 outputs/ly2gf/refparse.py 逐条对应，改一处必须同步另一处〗
00  主循环尾部统一用 i = stmtend(k)，各分支不再各写各的推进
00  注：判 token 一律用 is1/is2 比字节，不用字符串字面量
00      因为 gfx 预处理里 03 后紧跟 01/02 会被当成标点而报错
00 ─────────────────────────────────────────

00 is1(k,b)：token 恰好一个字节且等于 b
tt is1 01 k a9 b 02 08
    tz L a0 0
    tz c a0 0
    L a0 getlen 01 k 02
    lr 01 L 02 a1 1 08
        c a0 bytes 01 k a9 0 02
        lr 01 c 02 a1 b 08
            zz 1
        09
    09
    zz 0
09

00 is2(k,b0,b1)：token 恰好两个字节且等于 b0b1
tt is2 01 k a9 bb0 a9 bb1 02 08
    tz L a0 0
    tz c a0 0
    L a0 getlen 01 k 02
    lr 01 L 02 a1 2 08
        c a0 bytes 01 k a9 0 02
        lr 01 c 02 a1 bb0 08
            c a0 bytes 01 k a9 1 02
            lr 01 c 02 a1 bb1 08
                zz 1
            09
        09
    09
    zz 0
09

00 ggap(a,b)：源缓冲里 [a,b) 之间有几个换行（zs 内联块还原行用）
tt ggap 01 a a9 b 02 08
    tz i a0 0
    tz c a0 0
    tz n a0 0
    i a0 01 a 02
    ll 01 i 02 a3 01 b 02 08
        c a0 getb 01 i 02
        lr 01 c 02 a1 10 08 n a0 01 n 02 ht 1 09
        i a0 01 i 02 ht 1
    09
    zz n
09

00 mp(k)：k 指 01，返回配对 02 之后的下标
tt mp 01 k 02 08
    tz d a0 0
    tz e a0 0
    tz t a0 0
    e a0 01 k 02
    d a0 0
    ll 01 e 02 a3 01 cnt 02 08
        t a0 is2 01 e a9 48 a9 49 02
        lr t 08 d a0 01 d 02 ht 1 09
        t a0 is2 01 e a9 48 a9 50 02
        lr t 08
            d a0 01 d 02 hz 1
            lr 01 d 02 a1 0 08
                e a0 01 e 02 ht 1
                ls
            09
        09
        e a0 01 e 02 ht 1
    09
    zz e
09

00 mb(k)：k 指 [，返回配对 ] 之后的下标
tt mb 01 k 02 08
    tz d a0 0
    tz e a0 0
    tz t a0 0
    e a0 01 k 02
    d a0 0
    ll 01 e 02 a3 01 cnt 02 08
        t a0 is2 01 e a9 97 a9 55 02
        lr t 08 d a0 01 d 02 ht 1 09
        t a0 is2 01 e a9 97 a9 56 02
        lr t 08
            d a0 01 d 02 hz 1
            lr 01 d 02 a1 0 08
                e a0 01 e 02 ht 1
                ls
            09
        09
        e a0 01 e 02 ht 1
    09
    zz e
09

00 u08(k)：找同层的 08（跳过括号内），返回它之后的下标
tt u08 01 k 02 08
    tz e a0 0
    tz t a0 0
    e a0 01 k 02
    ll 01 e 02 a3 01 cnt 02 08
        t a0 is2 01 e a9 48 a9 49 02
        lr t 08
            e a0 mp 01 e 02
            Zn
        09
        t a0 is2 01 e a9 97 a9 55 02
        lr t 08
            e a0 mb 01 e 02
            Zn
        09
        t a0 is2 01 e a9 48 a9 56 02
        lr t 08
            e a0 01 e 02 ht 1
            zz e
        09
        e a0 01 e 02 ht 1
    09
    zz e
09

00 aend(k)：一个原子的结束位置（数字 / 括号 / fr / 名 01…02 / 名[下标]）
tt aend 01 k 02 08
    tz e a0 0
    tz t a0 0
    e a0 01 k 02 ht 1
    t a0 is2 01 k a9 48 a9 49 02
    lr t 08
        e a0 mp 01 k 02
        zz e
    09
    t a0 is2 01 k a9 102 a9 114 02
    lr t 08 zz e 09
    t a0 is2 01 e a9 48 a9 49 02
    lr t 08
        e a0 mp 01 e 02
        zz e
    09
    t a0 is2 01 e a9 97 a9 55 02
    lr t 08
        e a0 mb 01 e 02
        ll 08
            t a0 is2 01 e a9 97 a9 55 02
            lr 01 t 02 a1 0 08 ls 09
            e a0 mb 01 e 02
        09
        zz e
    09
    zz e
09

00 isop(k)：token k 是不是二元运算符
tt isop 01 k 02 08
    tz q a0 0
    tz t a0 0
    t a0 is2 01 k a9 104 a9 116 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 122 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 104 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 108 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 102 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 115 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 114 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 104 a9 100 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 100 a9 104 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 100 a9 108 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 97 a9 49 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 97 a9 50 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 97 a9 53 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 97 a9 54 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 97 a9 51 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 97 a9 52 02
    lr t 08 q a0 1 09
    t a0 is1 01 k a9 38 02
    lr t 08 q a0 1 09
    t a0 is1 01 k a9 124 02
    lr t 08 q a0 1 09
    t a0 is1 01 k a9 94 02
    lr t 08 q a0 1 09
    zz q
09

00 xend(k)：表达式 = 原子（运算符 原子）*
tt xend 01 k 02 08
    tz e a0 0
    tz q a0 0
    e a0 aend 01 k 02
    ll 08
        q a0 isop 01 e 02
        lr 01 q 02 a1 0 08 ls 09
        e a0 01 e 02 ht 1
        e a0 aend 01 e 02
    09
    zz e
09

00 stmtend(k)：一条顶层语句的结束位置（开区间）
tt stmtend 01 k 02 08
    tz r a0 0
    tz t a0 0
    tz e a0 0
    tz q a0 0
    r a0 0
    00 ts 名 = 表达式  /  ts 名（无初值，只有两个 token）
    t a0 is2 01 k a9 116 a9 115 02
    lr t 08
        e a0 01 k 02 ht 2
        t a0 is2 01 e a9 97 a9 48 02
        lr 01 t 02 a1 0 08 r a0 01 e 02 09
        lr t 08
            e a0 01 e 02 ht 1
            r a0 xend 01 e 02
        09
    09
    t a0 is2 01 k a9 116 a9 122 02
    lr t 08
        e a0 01 k 02 ht 3
        r a0 xend 01 e 02
    09
    00 th name a0 number  (same shape as tz)
    t a0 is2 01 k a9 116 a9 104 02
    lr t 08
        e a0 01 k 02 ht 3
        r a0 xend 01 e 02
    09
    00 td name a0 value  (bool, same shape as tz)
    t a0 is2 01 k a9 116 a9 100 02
    lr t 08
        e a0 01 k 02 ht 3
        r a0 xend 01 e 02
    09
    00 tr name 08 ... 09  (enum)
    t a0 is2 01 k a9 116 a9 114 02
    lr t 08
        e a0 01 k 02 ht 2
        r a0 u08 01 e 02
        r a0 01 r 02 hz 1
    09
    00 tl name 08 ... 09  (struct)
    t a0 is2 01 k a9 116 a9 108 02
    lr t 08
        e a0 01 k 02 ht 2
        r a0 u08 01 e 02
        r a0 01 r 02 hz 1
    09
    00 tf 名 [ n ]
    t a0 is2 01 k a9 116 a9 102 02
    lr t 08
        e a0 01 k 02 ht 2
        r a0 mb 01 e 02
    09
    00 tt 名 01 参数… 02 08（参数表里没有括号，直接扫 02）
    t a0 is2 01 k a9 116 a9 116 02
    lr t 08
        e a0 01 k 02 ht 1
        ll 01 e 02 a3 01 cnt 02 08
            t a0 is2 01 e a9 48 a9 50 02
            lr t 08 ls 09
            e a0 01 e 02 ht 1
        09
        00 02 之后可能有 -> 返回类型，一路扫到 08 为止
        e a0 01 e 02 ht 1
        ll 01 e 02 a3 01 cnt 02 08
            t a0 is2 01 e a9 48 a9 56 02
            lr t 08 ls 09
            e a0 01 e 02 ht 1
        09
        r a0 01 e 02
    09
    00 ll / lr / lh / lz → 吃到同层 08
    q a0 0
    t a0 is2 01 k a9 108 a9 108 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 108 a9 114 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 108 a9 104 02
    lr t 08 q a0 1 09
    t a0 is2 01 k a9 108 a9 122 02
    lr t 08 q a0 1 09
    lr q 08
        e a0 01 k 02 ht 1
        r a0 u08 01 e 02
        r a0 01 r 02 hz 1
    09
    00 zz 表达式
    t a0 is2 01 k a9 122 a9 122 02
    lr t 08
        e a0 01 k 02 ht 1
        r a0 01 k 02 ht 1
        q a0 0
        t a0 is2 01 e a9 48 a9 57 02
        lr t 08 q a0 1 09
        t a0 is2 01 e a9 48 a9 56 02
        lr t 08 q a0 1 09
        lr 01 q 02 a1 0 08
            r a0 xend 01 e 02
        09
    09
    00 其余：名字打头（ls / Zn / Zb / 08 / 09 也走这里，落到 r = k+1）
    lr 01 r 02 a1 0 08
        e a0 01 k 02 ht 1
        t a0 is2 01 e a9 97 a9 48 02
        lr t 08
            e a0 01 e 02 ht 1
            r a0 xend 01 e 02
        09
        lr 01 r 02 a1 0 08
            00 名 [ 下标 ] = 表达式  或  名 [ 下标 ]
            t a0 is2 01 e a9 97 a9 55 02
            lr t 08
                e a0 mb 01 e 02
                t a0 is2 01 e a9 97 a9 48 02
                lr t 08
                    e a0 01 e 02 ht 1
                    r a0 xend 01 e 02
                09
                lr 01 r 02 a1 0 08
                    r a0 01 e 02
                09
            09
            lr 01 r 02 a1 0 08
                00 名 01 参数… 02（调用）
                t a0 is2 01 e a9 48 a9 49 02
                lr t 08
                    r a0 mp 01 e 02
                09
                lr 01 t 02 a1 0 08
                    r a0 01 e 02
                09
            09
        09
    09
    zz r
09

00 ─────────────────────────────────────────
00  主
00 ─────────────────────────────────────────

tt main 01 argv 02 08
    tz chrv a0 0
    tz idxv a0 0
    tz tmpv a0 0
    tz cond a0 0
    tz cond2 a0 0
    tz zzdone a0 0
    tz argdone a0 0
    tz skip a0 0
    tz num a0 0
    tz start a0 0
    tz hasfn a0 0
    tz ktok a0 0
    tz nv2 a0 0
    tz nv3 a0 0
    tz retv a0 0
    tz qv1 a0 0
    tz qv2 a0 0
    tz vv2 a0 0
    tz noload a0 0
    tz bname a0 0
    tz incdone a0 0
    tz sv2 a0 0
    tz endp a0 0
    tz apos a0 0
    tz fp a0 0
    tz skip2 a0 0
    tz cmp a0 0
    tz numleft a0 0
    tz rpv a0 0
    tz send a0 0

    tmpv a0 rdfile 01 argv 02
    len a0 fsize 01 argv 02
    buf a0 rdbuf 01 02
    olen a0 0

    00 ── 切词 ──
    idxv a0 0
    num a0 0
    ll 01 idxv 02 a3 01 len 02 08
        00 跳空白
        ll 01 idxv 02 a3 01 len 02 08
            chrv a0 getb 01 idxv 02
            cond a0 isws 01 chrv 02
            lr cond 08 idxv a0 01 idxv 02 ht 1 09
            lh cond 1 08 ls 09
        09

        00 到末尾就收工
        tmpv a0 01 idxv 02 a6 01 len 02
        lr tmpv 08 ls 09

        00 是 00 开头的注释行吗：第一个字节是 0，第二个是 0
        chrv a0 getb 01 idxv 02
        cond a0 01 chrv 02 a1 48
        lr cond 08
            nv3 a0 01 idxv 02 ht 1
            chrv a0 getb 01 nv3 02
            cond a0 01 chrv 02 a1 48
            lr cond 08
                00 注释：跳到行尾，然后重来
                ll 01 idxv 02 a3 01 len 02 08
                    chrv a0 getb 01 idxv 02
                    tmpv a0 01 chrv 02 a1 10
                    lr tmpv 08 ls 09
                    idxv a0 01 idxv 02 ht 1
                09
                Zn
            09
        09
        tmpv a0 01 idxv 02 a6 01 len 02
        lr tmpv 08 ls 09

        00 03 字符串：整段（含两端 03）作为一个 token，串内空格不切
        00   例 wstr 01 03mov rax, 003 02 → token 是 03mov rax, 003
        00   不这么切，收尾 03 紧跟内容末尾的 0 会拼出 003 被当注释整行丢掉
        chrv a0 getb 01 idxv 02
        cond a0 01 chrv 02 a1 48
        lr cond 08
            nv3 a0 01 idxv 02 ht 1
            qv2 a0 getb 01 nv3 02
            cond a0 01 qv2 02 a1 51
            lr cond 08
                bittab a7 num a8 a0 idxv
                start a0 idxv
                idxv a0 01 idxv 02 ht 2
                ll 01 idxv 02 a3 01 len 02 08
                    chrv a0 getb 01 idxv 02
                    tmpv a0 01 chrv 02 a1 48
                    lr tmpv 08
                        nv3 a0 01 idxv 02 ht 1
                        qv2 a0 getb 01 nv3 02
                        cond a0 01 qv2 02 a1 51
                        lr cond 08
                            idxv a0 01 idxv 02 ht 2
                            ls
                        09
                    09
                    idxv a0 01 idxv 02 ht 1
                09
                lentab a7 num a8 a0 01 idxv 02 hz 01 start 02
                num a0 01 num 02 ht 1
                Zn
            09
        09

        00 双引号字符串（学/ 里的写法）：整段（含两端双引号）作为一个 token，跨行扫到闭引号为止（对齐 stage0 词法）
        chrv a0 getb 01 idxv 02
        cond a0 01 chrv 02 a1 34
        lr cond 08
            bittab a7 num a8 a0 idxv
            start a0 idxv
            idxv a0 01 idxv 02 ht 1
            ll 01 idxv 02 a3 01 len 02 08
                chrv a0 getb 01 idxv 02
                cond a0 01 chrv 02 a1 34
                lr cond 08
                    idxv a0 01 idxv 02 ht 1
                    ls
                09
                idxv a0 01 idxv 02 ht 1
            09
            lentab a7 num a8 a0 01 idxv 02 hz 01 start 02
            num a0 01 num 02 ht 1
            Zn
        09

        bittab a7 num a8 a0 idxv
        start a0 idxv
        ll 01 idxv 02 a3 01 len 02 08
            chrv a0 getb 01 idxv 02
            cond a0 isws 01 chrv 02
            tmpv a0 01 cond 02 a1 1
            lr tmpv 08 ls 09
            00 [ ] , 单独切 token（C版词法把它们都切 TK_P）
            cond a0 01 chrv 02 a1 91
            qv2 a0 01 chrv 02 a1 93
            cond a0 01 cond 02 hr 01 qv2 02
            qv2 a0 01 chrv 02 a1 44
            cond a0 01 cond 02 hr 01 qv2 02
            lr cond 08
                tmpv a0 01 idxv 02 a1 01 start 02
                lr tmpv 08
                    idxv a0 01 idxv 02 ht 1
                09
                ls
            09
            idxv a0 01 idxv 02 ht 1
        09
        lentab a7 num a8 a0 01 idxv 02 hz 01 start 02
        num a0 01 num 02 ht 1
    09
    cnt a0 num

    00 ── 命名铁律：命令与名字不许含中文 / 非 ASCII ──
    00   放行 03…03 字符串（首两字节 0,3）—— 那是输出内容，可以有中文
    00   00 注释在切词阶段已整行跳过，不在 token 表里
    idxv a0 0
    ll 01 idxv 02 a3 01 cnt 02 08
        nv2 a0 0
        nv3 a0 getlen 01 idxv 02
        chrv a0 bytes 01 idxv a9 0 02
        lr 01 chrv 02 a1 34 08 nv2 a0 1 09
        lr 01 nv3 02 a6 2 08
            chrv a0 bytes 01 idxv a9 0 02
            lr 01 chrv 02 a1 48 08
                chrv a0 bytes 01 idxv a9 1 02
                lr 01 chrv 02 a1 51 08 nv2 a0 1 09
            09
        09
        lr 01 nv2 02 a1 0 08
            nv2 a0 haszh 01 idxv 02
            lr nv2 08
                puts 01 03命名铁律：第 03 02
                nv2 a0 lineof 01 idxv 02
                puti 01 nv2 02
                puts 01 03 行的名字『03 02
                outtok 01 idxv 02
                puts 01 03』里有中文或非 ASCII 字符03 02
                putc 01 10 02
                puts 01 03        中文只能写在注释、字符串和文件名里；命令与名字只能用英文字母 数字 下划线03 02
                putc 01 10 02
                badname a0 1
                cnt a0 0
                ls
            09
        09
        idxv a0 01 idxv 02 ht 1
    09

    00 ══ 生成汇编 ══
    wstr 01 03# 由 卦方(Guafang) 编译器 gfx 生成03 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03.intel_syntax noprefix03 02
    putb 01 10 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03.section .text03 02
    putb 01 10 02

    idxv a0 0
    ll 01 idxv 02 a3 01 cnt 02 08
        ktok a0 idxv
        incdone a0 0
        cmp a0 0
        bname a0 0
        send a0 stmtend 01 ktok 02


        00 ── 括号深度跟踪 + lr 的 else 标签闭合 ──
        00 记号 09 = 字节 48,57；记号 08 = 字节 48,56
        nv2 a0 getlen 01 ktok 02
        nv3 a0 bytes 01 ktok a9 0 02
        qv1 a0 bytes 01 ktok a9 1 02
        cond a0 01 nv2 02 a1 2
        lr cond 08
            cond a0 01 nv3 02 a1 48
            lr cond 08
                00 遇 09：若栈顶深度 == 当前深度-1，则这是个 lr 块的收尾
                cond a0 01 qv1 02 a1 57
                lr cond 08
                    cond a0 01 estop 02 a4 0
                    lr cond 08
                        nv2 a0 01 pdepth 02 hz 1
                        nv3 a0 dstack a7 estop a8
                        cond a0 01 nv2 02 hz 01 nv3 02
                        cond a0 01 cond 02 a1 0
                        lr cond 08
                            nv3 a0 tstack a7 estop a8
                            00 型1=lr：输出 .LelseN:
                            cond a0 01 nv3 02 a1 1
                            lr cond 08
                                00 如果后面紧跟 ld（else），先跳过一个结束标签
                                nv2 a0 01 ktok 02 ht 1
                                cond a0 is2 01 nv2 a9 108 a9 100 02
                                lr cond 08
                                    putb 01 9 02
                                    wstr 01 03jmp .Lendif03 02
                                    qv1 a0 elstack a7 estop a8
                                    wnum 01 qv1 02
                                    putb 01 10 02
                                09
                                wstr 01 03.Lelse03 02
                                nv2 a0 elstack a7 estop a8
                                wnum 01 nv2 02
                                wstr 01 03:03 02
                                putb 01 10 02
                            09
                            00 型4=ld 块收尾：只出 .LendifN:
                            cond a0 01 nv3 02 a1 4
                            lr cond 08
                                wstr 01 03.Lendif03 02
                                nv2 a0 elstack a7 estop a8
                                wnum 01 nv2 02
                                wstr 01 03:03 02
                                putb 01 10 02
                            09
                            00 型2=ll无限：jmp .LltopT + .LlendN:
                            cond a0 01 nv3 02 a1 2
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03jmp .Lltop03 02
                                nv2 a0 topstack a7 estop a8
                                wnum 01 nv2 02
                                putb 01 10 02
                                wstr 01 03.Llend03 02
                                nv2 a0 elstack a7 estop a8
                                wnum 01 nv2 02
                                wstr 01 03:03 02
                                putb 01 10 02
                            09
                            00 型3=ll条件：jmp .LwtopT + .LwendN:
                            cond a0 01 nv3 02 a1 3
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03jmp .Lwtop03 02
                                nv2 a0 topstack a7 estop a8
                                wnum 01 nv2 02
                                putb 01 10 02
                                wstr 01 03.Lwend03 02
                                nv2 a0 elstack a7 estop a8
                                wnum 01 nv2 02
                                wstr 01 03:03 02
                                putb 01 10 02
                            09
                            estop a0 01 estop 02 hz 1
                        09
                    09
                    pdepth a0 01 pdepth 02 hz 1
                09
                00 遇 08：深度+1
                cond a0 01 qv1 02 a1 56
                lr cond 08
                    pdepth a0 01 pdepth 02 ht 1
                09
            09
        09

        00 ls：跳出当前循环 → jmp .LlendN / .LwendN（从栈顶往下找最近循环层）
        cond a0 tokis 01 ktok a9 03ls03 02
        lr cond 08
            sv2 a0 estop
            vv2 a0 0
            ll 08
                cond a0 01 sv2 02 a5 0
                lr cond 08 ls 09
                nv2 a0 tstack a7 sv2 a8
                cond a0 01 nv2 02 a1 2
                qv1 a0 01 nv2 02 a1 3
                cond a0 01 cond 02 hr 01 qv1 02
                lr cond 08
                    vv2 a0 sv2
                    ls
                09
                sv2 a0 01 sv2 02 hz 1
            09
            lr vv2 08
                nv2 a0 tstack a7 vv2 a8
                qv1 a0 elstack a7 vv2 a8
                cond a0 01 nv2 02 a1 2
                lr cond 08
                    putb 01 9 02
                    wstr 01 03jmp .Llend03 02
                    wnum 01 qv1 02
                    putb 01 10 02
                09
                cond a0 01 nv2 02 a1 3
                lr cond 08
                    putb 01 9 02
                    wstr 01 03jmp .Lwend03 02
                    wnum 01 qv1 02
                    putb 01 10 02
                09
            09
        09

        00 Zn：continue —— 跳回最近循环头（型2 → .Lltop，型3 → .Lwtop）
        cond a0 tokis 01 ktok a9 03Zn03 02
        lr cond 08
            sv2 a0 estop
            vv2 a0 0
            ll 08
                cond a0 01 sv2 02 a5 0
                lr cond 08 ls 09
                nv2 a0 tstack a7 sv2 a8
                cond a0 01 nv2 02 a1 2
                qv1 a0 01 nv2 02 a1 3
                cond a0 01 cond 02 hr 01 qv1 02
                lr cond 08
                    vv2 a0 sv2
                    ls
                09
                sv2 a0 01 sv2 02 hz 1
            09
            lr vv2 08
                nv2 a0 tstack a7 vv2 a8
                qv1 a0 topstack a7 vv2 a8
                cond a0 01 nv2 02 a1 2
                lr cond 08
                    putb 01 9 02
                    wstr 01 03jmp .Lltop03 02
                    wnum 01 qv1 02
                    putb 01 10 02
                09
                cond a0 01 nv2 02 a1 3
                lr cond 08
                    putb 01 9 02
                    wstr 01 03jmp .Lwtop03 02
                    wnum 01 qv1 02
                    putb 01 10 02
                09
            09
        09

        00 tt 名字 → 补上函数尾声 + .globl + 序言
        cond a0 tokis 01 ktok a9 03tt03 02
        lr cond 08
            00 第二个函数起，先补上一个函数的尾声（有函=已见函数数，非0则补）
            lr hasfn 08
                wstr 01 03.Lret_03 02
                nv3 a0 01 retv 02
                mgl 01 nv3 02
                wstr 01 03:03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03mov rsp, rbp03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03pop rbp03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03ret03 02
                putb 01 10 02
                putb 01 10 02
            09
            retv a0 01 ktok 02 ht 1
            hasfn a0 01 hasfn 02 ht 1
            putb 01 9 02
            wstr 01 03.globl fn_03 02
            nv3 a0 01 ktok 02 ht 1
            mgl 01 nv3 02
            putb 01 10 02
            wstr 01 03fn_03 02
            mgl 01 nv3 02
            wstr 01 03:03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03push rbp03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03mov rbp, rsp03 02
            putb 01 10 02
            00 预扫描本函数 tz 数量 → 16 对齐帧大小
            nv2 a0 01 ktok 02 ht 1
            qv1 a0 0
            ll 01 nv2 02 a3 01 cnt 02 08
                tmpv a0 tokis 01 nv2 a9 03tt03 02
                lr tmpv 08 ls 09
                tmpv a0 tokis 01 nv2 a9 03tz03 02
                lr tmpv 08 qv1 a0 01 qv1 02 ht 1 09
                tmpv a0 tokis 01 nv2 a9 03th03 02
                lr tmpv 08 qv1 a0 01 qv1 02 ht 1 09
                nv2 a0 01 nv2 02 ht 1
            09
            qv2 a0 01 qv1 02 hh 8
            qv2 a0 01 qv2 02 ht 15
            nv2 a0 01 qv2 02 hf 16
            qv2 a0 01 qv2 02 hz 01 nv2 02
            00 帧大小为0时不输出 sub rsp（对齐 C 版 if(framesz)）
            lr qv2 08
                putb 01 9 02
                wstr 01 03sub rsp, 03 02
                wnum 01 qv2 02
                putb 01 10 02
            09
            putb 01 9 02
            wstr 01 03mov rax, 003 02
            putb 01 10 02
            00 函数开始重置局部名字表（C版 nvars=0），在登记参数之前
            nname a0 0
            slot a0 0
            00 登记参数：扫描 01 名1 , 名2 02，槽=16+8*(np-1-j)（正数），参标=1
            nv3 a0 01 ktok 02 ht 2
            qv1 a0 0
            ll 01 nv3 02 a3 01 cnt 02 08
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                tmpv a0 01 chrv 02 a1 48
                lr tmpv 08
                    chrv a0 bytes 01 nv3 a9 1 02
                    tmpv a0 01 chrv 02 a1 50
                    lr tmpv 08 ls 09
                09
                tmpv a0 isname 01 chrv 02
                00 exclude a0-a9 encoded tokens
                cond2 a0 getlen 01 nv3 02
                cond2 a0 01 cond2 02 a1 2
                lr cond2 08
                    cond2 a0 01 chrv 02 a1 97
                    lr cond2 08
                        cond2 a0 bytes 01 nv3 a9 1 02
                        lr 01 cond2 02 a6 47 08
                            lr 01 cond2 02 a5 58 08
                                tmpv a0 0
                            09
                        09
                    09
                09
                cond2 a0 istype 01 nv3 02
                cond2 a0 01 cond2 02 a1 0
                tmpv a0 01 tmpv 02 hs 01 cond2 02
                lr tmpv 08
                    qv1 a0 01 qv1 02 ht 1
                09
                nv3 a0 01 nv3 02 ht 1
            09
            nv3 a0 01 ktok 02 ht 2
            qv2 a0 0
            ll 01 nv3 02 a3 01 cnt 02 08
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                tmpv a0 01 chrv 02 a1 48
                lr tmpv 08
                    chrv a0 bytes 01 nv3 a9 1 02
                    tmpv a0 01 chrv 02 a1 50
                    lr tmpv 08 ls 09
                09
                tmpv a0 isname 01 chrv 02
                00 exclude a9 (comma) and other a0-a9 encoded tokens
                cond2 a0 getlen 01 nv3 02
                cond2 a0 01 cond2 02 a1 2
                lr cond2 08
                    cond2 a0 01 chrv 02 a1 97
                    lr cond2 08
                        cond2 a0 bytes 01 nv3 a9 1 02
                        lr 01 cond2 02 a6 47 08
                            lr 01 cond2 02 a5 58 08
                                tmpv a0 0
                            09
                        09
                    09
                09
                cond2 a0 istype 01 nv3 02
                cond2 a0 01 cond2 02 a1 0
                tmpv a0 01 tmpv 02 hs 01 cond2 02
                lr tmpv 08
                    num a0 01 qv1 02 hz 01 qv2 02
                    num a0 01 num 02 hz 1
                    num a0 01 num 02 hh 8
                    num a0 01 num 02 ht 16
                    defname 01 nv3 a9 num 02
                    cond a0 01 nname 02 hz 1
                    argmark a7 cond a8 a0 1
                    qv2 a0 01 qv2 02 ht 1
                09
                nv3 a0 01 nv3 02 ht 1
            09
            00 跳过整个声明头：tt 名字 01 参数… 02 08（n3 停在 02 上）
            idxv a0 01 nv3 02 ht 1
        09

        00 tz 名字 = 数字 / tz 名字 = fh 另一个名字 / tz 名字 = zt 调用
        cond a0 tokis 01 ktok a9 03tz03 02
        00 th/td only when inside a function (top-level th/td are global consts)
        qv1 a0 tokis 01 ktok a9 03th03 02
        qv2 a0 01 hasfn 02 a4 0
        qv1 a0 01 qv1 02 hs 01 qv2 02
        cond a0 01 cond 02 hr 01 qv1 02
        qv1 a0 tokis 01 ktok a9 03td03 02
        qv1 a0 01 qv1 02 hs 01 qv2 02
        cond a0 01 cond 02 hr 01 qv1 02
        lr cond 08
            slot a0 01 slot 02 ht 8
            nv3 a0 01 ktok 02 ht 1
            defname 01 nv3 a9 slot 02
            nv2 a0 01 ktok 02 ht 3
            00 右值是 zt 调用：只登记槽位不生成代码，主循环落到 = 上，由调用段存回
            qv1 a0 is2 01 nv2 a9 122 a9 116 02
            00 右值是 fh 名（不带括号）：先取地址再解引用
            tmpv a0 is2 01 nv2 a9 102 a9 104 02
            lr tmpv 08
                nv3 a0 01 ktok 02 ht 4
                pl 01 nv3 02
                putb 01 9 02
                wstr 01 03mov rax, [rax]03 02
                putb 01 10 02
            09
            cond a0 01 tmpv 02 a1 0
            lr cond 08
                lr 01 qv1 02 a1 0 08
                    putb 01 9 02
                    wstr 01 03mov rax, 03 02
                    nv3 a0 01 ktok 02 ht 3
                    putnumtok 01 nv3 02
                    putb 01 10 02
                09
            09
            lr 01 qv1 02 a1 0 08
                putb 01 9 02
                wstr 01 03mov [rbp-03 02
                wnum 01 slot 02
                wstr 01 03], rax03 02
                putb 01 10 02
            09
            idxv a0 01 idxv 02 ht 3
        09

        00 target = fr -> mov rax,rsp / mov [rbp-slot],rax
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            cond a0 tokis 01 nv3 a9 03fr03 02
            lr cond 08
                nv2 a0 lookup 01 ktok 02
                cond a0 01 nv2 02 a6 8
                qv1 a0 01 nv2 02 a5 512
                cond a0 01 cond 02 hs 01 qv1 02
                lr cond 08
                    putb 01 9 02
                    wstr 01 03mov rax, rsp03 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03mov [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                    idxv a0 01 idxv 02 ht 2
                    incdone a0 1
                09
            09
        09

        00 ── 赋值：名 = 字符串（"…" 或 03…03）→ regstr + mov rax, offset .LstrN + 存回 ──
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        qv1 a0 01 incdone 02 a1 0
        cond a0 01 cond 02 hs 01 qv1 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            qv1 a0 getlen 01 nv3 02
            qv1 a0 01 qv1 02 a4 1
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            cond a0 01 chrv 02 a1 34
            qv2 a0 is2 01 nv3 a9 48 a9 51 02
            cond a0 01 cond 02 hr 01 qv2 02
            cond a0 01 cond 02 hs 01 qv1 02
            lr cond 08
                nv2 a0 regstr 01 nv3 02
                putb 01 9 02
                wstr 01 03mov rax, offset .Lstr03 02
                wnum 01 nv2 02
                putb 01 10 02
                nv2 a0 lookup 01 ktok 02
                tmpv a0 01 nv2 02 a6 8
                qv1 a0 01 nv2 02 a5 512
                tmpv a0 01 tmpv 02 hs 01 qv1 02
                lr tmpv 08
                    qv2 a0 argmark a7 idx a8
                    lr qv2 08
                        putb 01 9 02
                        wstr 01 03mov [rbp+03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                    09
                    qv2 a0 01 qv2 02 a1 0
                    lr qv2 08
                        putb 01 9 02
                        wstr 01 03mov [rbp-03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                    09
                09
                qv2 a0 01 tmpv 02 a1 0
                lr qv2 08
                    qv1 a0 findall 01 ktok 02
                    lr qv1 08
                        qv1 a0 gsize a7 allidx a8
                        tmpv a0 01 qv1 02 a1 8
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            mgl 01 ktok 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov [rax], rcx03 02
                            putb 01 10 02
                        09
                    09
                09
                incdone a0 1
            09
        09

        00 ── 赋值：名 = zf 名（取地址：局部 lea / 参数 lea+ / 全局 offset，不解引用）──
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        qv1 a0 01 incdone 02 a1 0
        qv1 a0 01 incdone 02 a1 0
        cond a0 01 cond 02 hs 01 qv1 02
        nv3 a0 01 ktok 02 ht 2
        qv1 a0 is2 01 nv3 a9 122 a9 102 02
        cond a0 01 cond 02 hs 01 qv1 02
        nv3 a0 01 ktok 02 ht 3
        chrv a0 head 01 nv3 02
        chrv a0 01 chrv 02 hs 255
        qv1 a0 isname 01 chrv 02
        cond a0 01 cond 02 hs 01 qv1 02
        lr cond 08
            00 取地址方：局部/参数 lea，全局 offset g_
            nv2 a0 lookup 01 nv3 02
            tmpv a0 01 nv2 02 a6 8
            qv1 a0 01 nv2 02 a5 512
            tmpv a0 01 tmpv 02 hs 01 qv1 02
            lr tmpv 08
                qv2 a0 argmark a7 idx a8
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03lea rax, [rbp+03 02
                    wnum 01 nv2 02
                    wstr 01 03]03 02
                    putb 01 10 02
                09
                qv2 a0 01 qv2 02 a1 0
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03lea rax, [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03]03 02
                    putb 01 10 02
                09
            09
            qv2 a0 01 tmpv 02 a1 0
            lr qv2 08
                qv1 a0 findall 01 nv3 02
                lr qv1 08
                    putb 01 9 02
                    wstr 01 03mov rax, offset g_03 02
                    mgl 01 nv3 02
                    putb 01 10 02
                09
            09
            00 存回目标：局部 mov [rbp-slot],rax；全局 push/offset/pop/mov
            nv2 a0 lookup 01 ktok 02
            tmpv a0 01 nv2 02 a6 8
            qv1 a0 01 nv2 02 a5 512
            tmpv a0 01 tmpv 02 hs 01 qv1 02
            lr tmpv 08
                qv2 a0 argmark a7 idx a8
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03mov [rbp+03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
                qv2 a0 01 qv2 02 a1 0
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03mov [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
            09
            qv2 a0 01 tmpv 02 a1 0
            lr qv2 08
                qv1 a0 findall 01 ktok 02
                lr qv1 08
                    qv1 a0 gsize a7 allidx a8
                    tmpv a0 01 qv1 02 a1 8
                    lr tmpv 08
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        mgl 01 ktok 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03pop rcx03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov [rax], rcx03 02
                        putb 01 10 02
                    09
                09
            09
            incdone a0 1
        09

        00 ── 赋值：名 = fh 名（解引用读内存：载荷 + mov rax,[rax]，再存回）──
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        qv1 a0 01 incdone 02 a1 0
        cond a0 01 cond 02 hs 01 qv1 02
        nv3 a0 01 ktok 02 ht 2
        qv1 a0 is2 01 nv3 a9 102 a9 104 02
        cond a0 01 cond 02 hs 01 qv1 02
        nv3 a0 01 ktok 02 ht 3
        chrv a0 head 01 nv3 02
        chrv a0 01 chrv 02 hs 255
        qv1 a0 isname 01 chrv 02
        cond a0 01 cond 02 hs 01 qv1 02
        lr cond 08
            pl 01 nv3 02
            putb 01 9 02
            wstr 01 03mov rax, [rax]03 02
            putb 01 10 02
            nv2 a0 lookup 01 ktok 02
            tmpv a0 01 nv2 02 a6 8
            qv1 a0 01 nv2 02 a5 512
            tmpv a0 01 tmpv 02 hs 01 qv1 02
            lr tmpv 08
                qv2 a0 argmark a7 idx a8
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03mov [rbp+03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
                qv2 a0 01 qv2 02 a1 0
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03mov [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
            09
            qv2 a0 01 tmpv 02 a1 0
            lr qv2 08
                qv1 a0 findall 01 ktok 02
                lr qv1 08
                    qv1 a0 gsize a7 allidx a8
                    tmpv a0 01 qv1 02 a1 8
                    lr tmpv 08
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        mgl 01 ktok 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03pop rcx03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov [rax], rcx03 02
                        putb 01 10 02
                    09
                09
            09
            incdone a0 1
        09

        00 ── sh 名 , 值：写内存（gfx：载荷(名)/push/载荷(值)/mov rcx,rcx/pop/mov [rax],rcx）──
        tmpv a0 is2 01 ktok a9 115 a9 104 02
        cond a0 01 incdone 02 a1 0
        tmpv a0 01 tmpv 02 hs 01 cond 02
        lr tmpv 08
            nv3 a0 01 ktok 02 ht 1
            pl 01 nv3 02
            putb 01 9 02
            wstr 01 03push rax03 02
            putb 01 10 02
            nv3 a0 01 ktok 02 ht 3
            pl 01 nv3 02
            putb 01 9 02
            wstr 01 03mov rcx, rax03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03pop rax03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03mov [rax], rcx03 02
            putb 01 10 02
            incdone a0 1
        09

        00 ── 赋值右值是 zt 调用：名 = zt 函数 01 参数 02 → 只吃 名 和 =，主循环落到 zt/addv 上，由调用段存回 ──
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        qv1 a0 01 incdone 02 a1 0
        cond a0 01 cond 02 hs 01 qv1 02
        nv3 a0 01 ktok 02 ht 2
        qv1 a0 is2 01 nv3 a9 122 a9 116 02
        cond a0 01 cond 02 hs 01 qv1 02
        lr cond 08
            idxv a0 01 idxv 02 ht 2
            incdone a0 1
        09

        00 ── 赋值：目标 = 变量（局部/参数/全局 四种互赋）──
        00 判据：k+1是=，k+2是标识符，k+3 不是运算符/括号/编码
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        qv1 a0 01 incdone 02 a1 0
        cond a0 01 cond 02 hs 01 qv1 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 3
            fp a0 0
            fp a0 getlen 01 nv3 02
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            skip2 a0 0
            cond a0 01 fp 02 a1 2
            lr cond 08
                qv1 a0 01 chrv 02 a1 104
                qv2 a0 01 chrv 02 a1 100
                qv1 a0 01 qv1 02 hr 01 qv2 02
                qv2 a0 01 chrv 02 a1 48
                qv1 a0 01 qv1 02 hr 01 qv2 02
                skip2 a0 01 qv1 02
            09
            00 any a0-a9 encoded token (first byte 97) is an operator, not a name
            qv1 a0 01 chrv 02 a1 97
            skip2 a0 01 skip2 02 hr 01 qv1 02
            00 整句正好 3 个 token（名 = 名）时，k+3 已是下一条语句，不能拿它判算子
            cond a0 01 send 02 hz 01 ktok 02
            qv1 a0 01 cond 02 a1 3
            lr qv1 08 skip2 a0 0 09
            cond a0 01 skip2 02 a1 0
            lr cond 08
                nv3 a0 01 ktok 02 ht 2
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                tmpv a0 isname 01 chrv 02
                lr tmpv 08
                    nv2 a0 lookup 01 ktok 02
                    qv2 a0 argmark a7 idx a8
                    cond a0 01 nv2 02 a6 8
                    qv1 a0 01 nv2 02 a5 512
                    cond a0 01 cond 02 hs 01 qv1 02
                    pl 01 nv3 02
                    lr cond 08
                        lr qv2 08
                            putb 01 9 02
                            wstr 01 03mov [rbp+03 02
                            wnum 01 nv2 02
                            wstr 01 03], rax03 02
                            putb 01 10 02
                        09
                        qv1 a0 01 qv2 02 a1 0
                        lr qv1 08
                            putb 01 9 02
                            wstr 01 03mov [rbp-03 02
                            wnum 01 nv2 02
                            wstr 01 03], rax03 02
                            putb 01 10 02
                        09
                    09
                    qv1 a0 01 cond 02 a1 0
                    lr qv1 08
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        nv3 a0 01 ktok 02
                        mgl 01 nv3 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03pop rcx03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov [rax], rcx03 02
                        putb 01 10 02
                    09
                    idxv a0 01 idxv 02 ht 2
                    incdone a0 1
                09
            09
        09

        00 裸二元表达式：局部 = A op B（5 token k..k+4），A/B 为数字或变量，op 为 h* / dh / dl
        00 必须放在"名字=单个数字"之前，否则只剩 A 被存回
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv2 a0 lookup 01 ktok 02
            cond a0 01 nv2 02 a6 8
            qv1 a0 01 nv2 02 a5 512
            cond a0 01 cond 02 hs 01 qv1 02
            lr cond 08
                00 判 k+3 是合法二元算子：ht hz hh hl hf hs hr hd / dh dl（hi 之类不算）
                nv3 a0 01 ktok 02 ht 3
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                qv2 a0 bytes 01 nv3 a9 1 02
                cond2 a0 0
                tmpv a0 01 chrv 02 a1 104
                lr tmpv 08
                    cond a0 01 qv2 02 a1 116
                    qv1 a0 01 qv2 02 a1 122
                    cond a0 01 cond 02 hr 01 qv1 02
                    qv1 a0 01 qv2 02 a1 104
                    cond a0 01 cond 02 hr 01 qv1 02
                    qv1 a0 01 qv2 02 a1 108
                    cond a0 01 cond 02 hr 01 qv1 02
                    qv1 a0 01 qv2 02 a1 102
                    cond a0 01 cond 02 hr 01 qv1 02
                    qv1 a0 01 qv2 02 a1 115
                    cond a0 01 cond 02 hr 01 qv1 02
                    qv1 a0 01 qv2 02 a1 114
                    cond a0 01 cond 02 hr 01 qv1 02
                    qv1 a0 01 qv2 02 a1 100
                    cond a0 01 cond 02 hr 01 qv1 02
                    cond2 a0 cond
                09
                tmpv a0 01 chrv 02 a1 100
                lr tmpv 08
                    cond a0 01 qv2 02 a1 104
                    qv1 a0 01 qv2 02 a1 108
                    cond a0 01 cond 02 hr 01 qv1 02
                    cond2 a0 cond
                09
                qv1 a0 getlen 01 nv3 02
                tmpv a0 01 qv1 02 a1 2
                tmpv a0 01 tmpv 02 hs 01 cond2 02
                00 左操作数：数字放行；是名字则必须是局部/参数（全局交给专用块）
                nv3 a0 01 ktok 02 ht 2
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                cond2 a0 01 chrv 02 a6 48
                qv2 a0 01 chrv 02 a5 57
                cond2 a0 01 cond2 02 hs 01 qv2 02
                lr cond2 08
                    cond2 a0 1
                09
                qv2 a0 01 cond2 02 a1 0
                lr qv2 08
                    qv2 a0 lookup 01 nv3 02
                    cond a0 01 qv2 02 a6 8
                    qv1 a0 01 qv2 02 a5 512
                    cond2 a0 01 cond 02 hs 01 qv1 02
                09
                tmpv a0 01 tmpv 02 hs 01 cond2 02
                lr tmpv 08
                    00 右值先求（载荷 直接产出 mov rax），左值 push 后再 二op
                    nv3 a0 01 ktok 02 ht 2
                    pl 01 nv3 02
                    putb 01 9 02
                    wstr 01 03push rax03 02
                    putb 01 10 02
                    00 右值 k+4；若是 01 X 02 则取 k+5，i 多进 2
                    nv3 a0 01 ktok 02 ht 4
                    rpv a0 0
                    chrv a0 head 01 nv3 02
                    chrv a0 01 chrv 02 hs 255
                    cond2 a0 01 chrv 02 a1 48
                    lr cond2 08
                        qv2 a0 bytes 01 nv3 a9 1 02
                        cond2 a0 01 qv2 02 a1 49
                        lr cond2 08
                            nv3 a0 01 ktok 02 ht 6
                            qv2 a0 head 01 nv3 02
                            qv2 a0 01 qv2 02 hs 255
                            cond a0 01 qv2 02 a1 48
                            lr cond 08
                                qv2 a0 bytes 01 nv3 a9 1 02
                                cond a0 01 qv2 02 a1 50
                                lr cond 08
                                    nv3 a0 01 ktok 02 ht 5
                                    rpv a0 2
                                09
                            09
                        09
                    09
                    pl 01 nv3 02
                    nv3 a0 01 ktok 02 ht 3
                    twoop 01 nv3 02
                    00 载荷 会改 找索引，这里必须重新 lookup 左值
                    nv2 a0 lookup 01 ktok 02
                    cond a0 argmark a7 idx a8
                    lr cond 08
                        putb 01 9 02
                        wstr 01 03mov [rbp+03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                    09
                    cond a0 01 cond 02 a1 0
                    lr cond 08
                        putb 01 9 02
                        wstr 01 03mov [rbp-03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                    09
                    idxv a0 01 idxv 02 ht 4
                    idxv a0 idxv ht rpv
                    incdone a0 1
                09
            09
        09

        00 ── 名字 = 01 A 02（括号里只有一个原子）──
        00 C版就是 expr()：取 A 的值 → 存回槽位
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            tmpv a0 is2 01 nv3 a9 48 a9 49 02
            rpv a0 0
            lr tmpv 08 rpv a0 1 09
            nv3 a0 01 ktok 02 ht 4
            tmpv a0 is2 01 nv3 a9 48 a9 50 02
            rpv a0 01 rpv 02 hs 01 tmpv 02
            nv2 a0 01 send 02 hz 01 ktok 02
            tmpv a0 01 nv2 02 a1 5
            rpv a0 01 rpv 02 hs 01 tmpv 02
            lr rpv 08
                nv3 a0 01 ktok 02 ht 3
                pl 01 nv3 02
                nv2 a0 lookup 01 ktok 02
                tmpv a0 01 nv2 02 a6 8
                qv2 a0 01 nv2 02 a5 512
                tmpv a0 01 tmpv 02 hs 01 qv2 02
                lr tmpv 08
                    cond2 a0 argmark a7 idx a8
                    lr cond2 08
                        putb 01 9 02
                        wstr 01 03mov [rbp+03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                    09
                    cond2 a0 01 cond2 02 a1 0
                    lr cond2 08
                        putb 01 9 02
                        wstr 01 03mov [rbp-03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                    09
                    incdone a0 1
                09
            09
        09

        00 赋值：名字 = 单个数字（三个记号 r = 1）
        00 守卫：左值须是局部槽[8,512]，右值须长度1且首字节数字
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv2 a0 lookup 01 ktok 02
            nv3 a0 01 ktok 02 ht 2
            qv1 a0 getlen 01 nv3 02
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            tmpv a0 01 nv2 02 a6 8
            cond a0 01 nv2 02 a5 512
            tmpv a0 01 tmpv 02 hs 01 cond 02
            00 右值必须是纯十进制数字；01..09 这种两位编码记号要排除
            qv2 a0 isnum 01 nv3 02
            lr 01 qv1 02 a1 2 08
                chrv a0 bytes 01 nv3 a9 0 02
                lr 01 chrv 02 a1 48 08 qv2 a0 0 09
            09
            tmpv a0 01 tmpv 02 hs 01 qv2 02
            qv2 a0 01 incdone 02 a1 0
            tmpv a0 01 tmpv 02 hs 01 qv2 02
            lr tmpv 08
                putb 01 9 02
                wstr 01 03mov rax, 03 02
                nv3 a0 01 ktok 02 ht 2
                putnumtok 01 nv3 02
                putb 01 10 02
                00 参数(参标=1)存 [rbp+N]，局部(参标=0)存 [rbp-N]
                cond a0 argmark a7 idx a8
                lr cond 08
                    putb 01 9 02
                    wstr 01 03mov [rbp+03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
                cond a0 01 cond 02 a1 0
                lr cond 08
                    putb 01 9 02
                    wstr 01 03mov [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
                idxv a0 01 idxv 02 ht 2
            09
            00 全局标量赋值：全名 = 数字（3 token，左值不是局部）
            nv3 a0 01 ktok 02 ht 1
            cond a0 is2 01 nv3 a9 97 a9 48 02
            lr cond 08
                qv1 a0 lookup 01 ktok 02
                cond a0 01 qv1 02 a1 0
                lr cond 08
                    tmpv a0 findall 01 ktok 02
                    lr tmpv 08
                        vv2 a0 gsize a7 allidx a8
                        tmpv a0 01 vv2 02 a1 8
                        nv3 a0 01 ktok 02 ht 2
                        chrv a0 head 01 nv3 02
                        chrv a0 01 chrv 02 hs 255
                        cond2 a0 01 chrv 02 a6 48
                        qv2 a0 01 chrv 02 a5 57
                        cond2 a0 01 cond2 02 hs 01 qv2 02
                        00 排除 01..09 编码记号：首字节 '0' 且长度 2
                        qv2 a0 01 chrv 02 a1 48
                        qv1 a0 getlen 01 nv3 02
                        tmpv a0 01 qv1 02 a1 2
                        qv2 a0 01 qv2 02 hs 01 tmpv 02
                        tmpv a0 01 qv2 02 a1 0
                        cond2 a0 01 cond2 02 hs 01 tmpv 02
                        tmpv a0 01 vv2 02 a1 8
                        tmpv a0 01 tmpv 02 hs 01 cond2 02
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03mov rax, 03 02
                            nv3 a0 01 ktok 02 ht 2
                            putnumtok 01 nv3 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            nv3 a0 01 ktok 02
                            mgl 01 nv3 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov [rax], rcx03 02
                            putb 01 10 02
                            idxv a0 01 idxv 02 ht 2
                            incdone a0 1
                        09
                    09
                09
            09
            00 全局自增/减：全局名 = 01 全局名 op 数字（k..k+6）
            qv1 a0 findall 01 ktok 02
            lr qv1 08
                nv3 a0 01 ktok 02 ht 2
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                tmpv a0 01 chrv 02 a1 48
                lr tmpv 08
                    nv3 a0 01 ktok 02 ht 5
                    chrv a0 head 01 nv3 02
                    chrv a0 01 chrv 02 hs 255
                    cond a0 01 chrv 02 a1 104
                    lr cond 08
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        nv3 a0 01 ktok 02
                        mgl 01 nv3 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, [rax]03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        nv3 a0 01 ktok 02 ht 6
                        putb 01 9 02
                        wstr 01 03mov rax, 03 02
                        putnumtok 01 nv3 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rcx, rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03pop rax03 02
                        putb 01 10 02
                        nv3 a0 01 ktok 02 ht 5
                        qv2 a0 bytes 01 nv3 a9 1 02
                        cond a0 01 qv2 02 a1 116
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03add rax, rcx03 02
                            putb 01 10 02
                        09
                        cond a0 01 qv2 02 a1 122
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03sub rax, rcx03 02
                            putb 01 10 02
                        09
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        nv3 a0 01 ktok 02
                        mgl 01 nv3 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03pop rcx03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov [rax], rcx03 02
                        putb 01 10 02
                        idxv a0 01 idxv 02 ht 6
                        incdone a0 1
                    09
                09
            09
            00 局部守卫失败 → 查全局：mov rax,值 / push / mov rax,offset g_名 / pop rcx / mov [rax],rcx
            cond a0 01 incdone 02 a1 0
            00 整句必须只有 3 个 token：名 = 值。名 = 函数(…) 是调用，交给调用段
            tmpv a0 01 send 02 hz 01 ktok 02
            qv2 a0 01 tmpv 02 a1 3
            cond a0 01 cond 02 hs 01 qv2 02
            lr cond 08
            tmpv a0 01 nv2 02 a6 8
            cond a0 01 nv2 02 a5 512
            tmpv a0 01 tmpv 02 hs 01 cond 02
            cond a0 01 tmpv 02 a1 0
            lr cond 08
                qv2 a0 findall 01 ktok 02
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03mov rax, 03 02
                    nv3 a0 01 ktok 02 ht 2
                    putnumtok 01 nv3 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03push rax03 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03mov rax, offset g_03 02
                    nv3 a0 01 ktok 02
                    mgl 01 nv3 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03pop rcx03 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03mov [rax], rcx03 02
                    putb 01 10 02
                    idxv a0 01 idxv 02 ht 2
                09
            09
            09
        09

        00 ── 名字 = 01 A op B 02（两个操作数同在一个括号里）──
        00   与下面那个 01 A 02 op B 形态互补，靠 k+4 是否运算符区分
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            tmpv a0 is2 01 nv3 a9 48 a9 49 02
            cond a0 01 cond 02 hs 01 tmpv 02
            qv1 a0 01 ktok 02 ht 4
            tmpv a0 isop 01 qv1 02
            cond a0 01 cond 02 hs 01 tmpv 02
            nv3 a0 01 ktok 02 ht 6
            tmpv a0 is2 01 nv3 a9 48 a9 50 02
            cond a0 01 cond 02 hs 01 tmpv 02
            nv2 a0 lookup 01 ktok 02
            tmpv a0 01 nv2 02 a6 8
            qv2 a0 01 nv2 02 a5 512
            tmpv a0 01 tmpv 02 hs 01 qv2 02
            cond a0 01 cond 02 hs 01 tmpv 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 3
                pl 01 nv3 02
                putb 01 9 02
                wstr 01 03push rax03 02
                putb 01 10 02
                nv3 a0 01 ktok 02 ht 5
                pl 01 nv3 02
                nv3 a0 01 ktok 02 ht 4
                twoop 01 nv3 02
                nv2 a0 lookup 01 ktok 02
                cond2 a0 argmark a7 idx a8
                lr cond2 08
                    putb 01 9 02
                    wstr 01 03mov [rbp+03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
                cond2 a0 01 cond2 02 a1 0
                lr cond2 08
                    putb 01 9 02
                    wstr 01 03mov [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                09
                incdone a0 1
            09
        09

        00 ── 全局：名 = 01 A op B 02 → pl(A)/push/pl(B)/twoop/push/offset g_名/pop rcx/mov [rax],rcx ──
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            tmpv a0 is2 01 nv3 a9 48 a9 49 02
            cond a0 01 cond 02 hs 01 tmpv 02
            qv1 a0 01 ktok 02 ht 4
            tmpv a0 isop 01 qv1 02
            cond a0 01 cond 02 hs 01 tmpv 02
            nv3 a0 01 ktok 02 ht 6
            tmpv a0 is2 01 nv3 a9 48 a9 50 02
            cond a0 01 cond 02 hs 01 tmpv 02
            qv1 a0 findall 01 ktok 02
            cond a0 01 cond 02 hs 01 qv1 02
            nv2 a0 lookup 01 ktok 02
            tmpv a0 01 nv2 02 a1 0
            cond a0 01 cond 02 hs 01 tmpv 02
            nv2 a0 gsize a7 allidx a8
            tmpv a0 01 nv2 02 a1 8
            cond a0 01 cond 02 hs 01 tmpv 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 3
                pl 01 nv3 02
                putb 01 9 02
                wstr 01 03push rax03 02
                putb 01 10 02
                nv3 a0 01 ktok 02 ht 5
                pl 01 nv3 02
                nv3 a0 01 ktok 02 ht 4
                twoop 01 nv3 02
                putb 01 9 02
                wstr 01 03push rax03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03mov rax, offset g_03 02
                nv3 a0 01 ktok 02
                mgl 01 nv3 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03pop rcx03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03mov [rax], rcx03 02
                putb 01 10 02
                incdone a0 1
            09
        09

        00 表达式：名字 = (左 op 右)，左=局部变量，右=数字，op 先做 ==
        00 形态：t = 01 b 02 == 32 （k..k+6）
        00 k+2 首字节是 0 且第二字节是 1 → 是 01 括号记号
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            tmpv a0 01 chrv 02 a1 48
            lr tmpv 08
                chrv a0 bytes 01 nv3 a9 1 02
                tmpv a0 01 chrv 02 a1 49
                lr tmpv 08
                    nv2 a0 lookup 01 ktok 02
                    00 accept any slot: cond=1 if lookup found (normalize to boolean)
                    cond a0 0
                    lr 01 nv2 02 a2 0 08
                        cond a0 1
                    09
                    00 必须真是 01 A 02 op B：k+4 是 02 且 k+5 是运算符
                    00 否则 e = 01 k 02 这种单原子括号会被误吃，op 越界读到下一句
                    qv1 a0 01 ktok 02 ht 4
                    tmpv a0 is2 01 qv1 a9 48 a9 50 02
                    cond a0 01 cond 02 hs 01 tmpv 02
                    qv1 a0 01 ktok 02 ht 5
                    tmpv a0 isop 01 qv1 02
                    cond a0 01 cond 02 hs 01 tmpv 02
                    lr cond 08
                        00 左值 b=k+3：数字→mov rax,N；否则 lea/mov
                        nv3 a0 01 ktok 02 ht 3
                        chrv a0 head 01 nv3 02
                        chrv a0 01 chrv 02 hs 255
                        numleft a0 0
                        cond a0 01 chrv 02 a6 48
                        qv2 a0 01 chrv 02 a5 57
                        cond a0 01 cond 02 hs 01 qv2 02
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03mov rax, 03 02
                            putnumtok 01 nv3 02
                            putb 01 10 02
                            numleft a0 1
                        09
                        qv2 a0 01 numleft 02 a1 0
                        lr qv2 08
                        nv2 a0 lookup 01 nv3 02
                        tmpv a0 01 nv2 02 a6 8
                        qv2 a0 01 nv2 02 a5 512
                        tmpv a0 01 tmpv 02 hs 01 qv2 02
                        noload a0 0
                        lr tmpv 08
                            00 局部/参数：f=参标判正负
                            cond a0 argmark a7 idx a8
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03lea rax, [rbp+03 02
                                wnum 01 nv2 02
                                wstr 01 03]03 02
                                putb 01 10 02
                            09
                            qv2 a0 01 cond 02 a1 0
                            lr qv2 08
                                putb 01 9 02
                                wstr 01 03lea rax, [rbp-03 02
                                wnum 01 nv2 02
                                wstr 01 03]03 02
                                putb 01 10 02
                            09
                        09
                        qv2 a0 01 tmpv 02 a1 0
                        lr qv2 08
                            00 全局：mov rax,offset g_X；标量(全大==8)再 load
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            mgl 01 nv3 02
                            putb 01 10 02
                            nv2 a0 findall 01 nv3 02
                            vv2 a0 gsize a7 allidx a8
                            cond a0 01 vv2 02 a1 8
                            qv2 a0 01 cond 02 a1 0
                            lr qv2 08
                                noload a0 1
                            09
                        09
                        qv2 a0 01 noload 02 a1 0
                        lr qv2 08
                            putb 01 9 02
                            wstr 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        09
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        00 右值 = k+6；若是 01 X 02（k+6='01' 且 k+8='02'）则取 k+7，右括=2
                        nv3 a0 01 ktok 02 ht 6
                        chrv a0 head 01 nv3 02
                        chrv a0 01 chrv 02 hs 255
                        rpv a0 0
                        cond a0 01 chrv 02 a1 48
                        lr cond 08
                            qv2 a0 bytes 01 nv3 a9 1 02
                            cond a0 01 qv2 02 a1 49
                            lr cond 08
                                nv3 a0 01 ktok 02 ht 8
                                qv2 a0 head 01 nv3 02
                                qv2 a0 01 qv2 02 hs 255
                                cond2 a0 01 qv2 02 a1 48
                                lr cond2 08
                                    qv2 a0 bytes 01 nv3 a9 1 02
                                    cond2 a0 01 qv2 02 a1 50
                                    lr cond2 08
                                        nv3 a0 01 ktok 02 ht 7
                                        rpv a0 2
                                    09
                                09
                            09
                        09
                        chrv a0 head 01 nv3 02
                        chrv a0 01 chrv 02 hs 255
                        tmpv a0 01 chrv 02 a6 48
                        qv2 a0 01 chrv 02 a5 57
                        tmpv a0 01 tmpv 02 hs 01 qv2 02
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03mov rax, 03 02
                            putnumtok 01 nv3 02
                            putb 01 10 02
                        09
                        qv2 a0 01 tmpv 02 a1 0
                        lr qv2 08
                            qv1 a0 lookup 01 nv3 02
                            tmpv a0 01 qv1 02 a6 8
                            qv2 a0 01 qv1 02 a5 512
                            tmpv a0 01 tmpv 02 hs 01 qv2 02
                            qv2 a0 01 tmpv 02 a1 0
                            lr qv2 08
                                qv2 a0 findall 01 nv3 02
                            09
                            lr qv2 08
                                putb 01 9 02
                                wstr 01 03mov rax, offset g_03 02
                                mgl 01 nv3 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03mov rax, [rax]03 02
                                putb 01 10 02
                            09
                            00 t 只表示「是局部」；不要并上 q2，否则全局也会再发一次 [rbp-0]
                            lr tmpv 08
                                cond a0 argmark a7 idx a8
                                lr cond 08
                                    putb 01 9 02
                                    wstr 01 03lea rax, [rbp+03 02
                                    wnum 01 qv1 02
                                    wstr 01 03]03 02
                                    putb 01 10 02
                                09
                                tmpv a0 01 cond 02 a1 0
                                lr tmpv 08
                                    putb 01 9 02
                                    wstr 01 03lea rax, [rbp-03 02
                                    wnum 01 qv1 02
                                    wstr 01 03]03 02
                                    putb 01 10 02
                                09
                                putb 01 9 02
                                wstr 01 03mov rax, [rax]03 02
                                putb 01 10 02
                            09
                        09
                        00 op=k+5 == 判断（首字节=）
                        nv3 a0 01 ktok 02 ht 5
                        chrv a0 head 01 nv3 02
                        chrv a0 01 chrv 02 hs 255
                        00 a1~a6: two-byte op, decode by second byte
                        tmpv a0 01 chrv 02 a1 97
                        lr tmpv 08
                            nv3 a0 01 ktok 02 ht 5
                            vv2 a0 bytes 01 nv3 a9 1 02
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03cmp rax, rcx03 02
                            putb 01 10 02
                            00 a1=49 sete  a2=50 setne  a3=51 setb  a4=52 seta  a5=53 setbe  a6=54 setae
                            lr 01 vv2 02 a1 49 08
                                putb 01 9 02
                                wstr 01 03sete al03 02
                                putb 01 10 02
                            09
                            lr 01 vv2 02 a1 50 08
                                putb 01 9 02
                                wstr 01 03setne al03 02
                                putb 01 10 02
                            09
                            lr 01 vv2 02 a1 51 08
                                putb 01 9 02
                                wstr 01 03setb al03 02
                                putb 01 10 02
                            09
                            lr 01 vv2 02 a1 52 08
                                putb 01 9 02
                                wstr 01 03seta al03 02
                                putb 01 10 02
                            09
                            lr 01 vv2 02 a1 53 08
                                putb 01 9 02
                                wstr 01 03setbe al03 02
                                putb 01 10 02
                            09
                            lr 01 vv2 02 a1 54 08
                                putb 01 9 02
                                wstr 01 03setae al03 02
                                putb 01 10 02
                            09
                            putb 01 9 02
                            wstr 01 03movzx rax, al03 02
                            putb 01 10 02
                        09
                        tmpv a0 01 chrv 02 a1 61
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03cmp rax, rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03sete al03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03movzx rax, al03 02
                            putb 01 10 02
                        09
                        00 其余比较：< > <= >= != → cmp + setcc + movzx
                        00 判据 op token 首字节：60(<) 62(>) 33(!)；第二字节61(=)区分单双
                        nv3 a0 01 ktok 02 ht 5
                        qv2 a0 head 01 nv3 02
                        qv2 a0 01 qv2 02 hs 255
                        cond a0 01 chrv 02 a1 60
                        tmpv a0 01 chrv 02 a1 62
                        cond a0 01 cond 02 hr 01 tmpv 02
                        tmpv a0 01 chrv 02 a1 33
                        cond a0 01 cond 02 hr 01 tmpv 02
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03cmp rax, rcx03 02
                            putb 01 10 02
                            00 判第二字节是否 61(=)
                            nv3 a0 01 ktok 02 ht 5
                            vv2 a0 bytes 01 nv3 a9 1 02
                            cond2 a0 01 vv2 02 a1 61
                            00 c==60: < → b / <= → be
                            tmpv a0 01 chrv 02 a1 60
                            lr tmpv 08
                                lr cond2 08
                                    putb 01 9 02
                                    wstr 01 03setbe al03 02
                                    putb 01 10 02
                                09
                                qv1 a0 01 cond2 02 a1 0
                                lr qv1 08
                                    putb 01 9 02
                                    wstr 01 03setb al03 02
                                    putb 01 10 02
                                09
                            09
                            00 c==62: > → a / >= → ae
                            tmpv a0 01 chrv 02 a1 62
                            lr tmpv 08
                                lr cond2 08
                                    putb 01 9 02
                                    wstr 01 03setae al03 02
                                    putb 01 10 02
                                09
                                qv1 a0 01 cond2 02 a1 0
                                lr qv1 08
                                    putb 01 9 02
                                    wstr 01 03seta al03 02
                                    putb 01 10 02
                                09
                            09
                            00 c==33: != → setne
                            tmpv a0 01 chrv 02 a1 33
                            lr tmpv 08
                                putb 01 9 02
                                wstr 01 03setne al03 02
                                putb 01 10 02
                            09
                            putb 01 9 02
                            wstr 01 03movzx rax, al03 02
                            putb 01 10 02
                        09
                        00 算术运算：op token 首字节 h(104) → ht加/hz减/hh乘 等
                        tmpv a0 01 chrv 02 a1 104
                        lr tmpv 08
                            nv3 a0 01 ktok 02 ht 5
                            qv2 a0 bytes 01 nv3 a9 1 02
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            00 ht → add
                            cond a0 01 qv2 02 a1 116
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03add rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hz → sub
                            cond a0 01 qv2 02 a1 122
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03sub rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hh → imul
                            cond a0 01 qv2 02 a1 104
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03imul rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hs → and
                            cond a0 01 qv2 02 a1 115
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03and rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hr → or
                            cond a0 01 qv2 02 a1 114
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03or rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hd → xor
                            cond a0 01 qv2 02 a1 100
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03xor rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hl → div (rdx清零)
                            cond a0 01 qv2 02 a1 108
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03xor rdx, rdx03 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03div rcx03 02
                                putb 01 10 02
                            09
                            00 hf → mod (rdx清零, div, 取rdx)
                            cond a0 01 qv2 02 a1 102
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03xor rdx, rdx03 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03div rcx03 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03mov rax, rdx03 02
                                putb 01 10 02
                            09
                        09
                        00 位移运算：op 首字节 d(100) → dh=shl rax,cl / dl=shr rax,cl
                        tmpv a0 01 chrv 02 a1 100
                        lr tmpv 08
                            nv3 a0 01 ktok 02 ht 5
                            qv2 a0 bytes 01 nv3 a9 1 02
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            00 dh → shl
                            cond a0 01 qv2 02 a1 104
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03shl rax, cl03 02
                                putb 01 10 02
                            09
                            00 dl → shr
                            cond a0 01 qv2 02 a1 108
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03shr rax, cl03 02
                                putb 01 10 02
                            09
                        09
                        00 存回左值 = k：参数用 [rbp+N]，局部用 [rbp-N]
                        nv2 a0 lookup 01 ktok 02
                        cond a0 argmark a7 idx a8
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03mov [rbp+03 02
                            wnum 01 nv2 02
                            wstr 01 03], rax03 02
                            putb 01 10 02
                        09
                        cond a0 01 cond 02 a1 0
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03mov [rbp-03 02
                            wnum 01 nv2 02
                            wstr 01 03], rax03 02
                            putb 01 10 02
                        09
                        idxv a0 01 idxv 02 ht 6
                        idxv a0 idxv ht rpv
                        incdone a0 1
                    09
                09
            09
        09

        00 裸左值表达式：目标 = 全局 ht 右值（5 token: k..k+4）
        00 C版 lvalue_full：全局 offset+load → push，右值 load → add → 存回局部
        00 判据：k+1 是 =，k 是局部[8,512]，k+2 查全命中(全局)，k+3 是 ht
        00 注意：通用裸二元块已覆盖本形态，靠 自增已 闸门避免重复触发
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        qv2 a0 01 incdone 02 a1 0
        cond a0 01 cond 02 hs 01 qv2 02
        lr cond 08
            nv2 a0 lookup 01 ktok 02
            cond a0 01 nv2 02 a6 8
            qv1 a0 01 nv2 02 a5 512
            cond a0 01 cond 02 hs 01 qv1 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 2
                qv2 a0 findall 01 nv3 02
                lr qv2 08
                    nv3 a0 01 ktok 02 ht 3
                    tmpv a0 tokis 01 nv3 a9 03ht03 02
                    lr tmpv 08
                        00 左值全局：offset g_X；标量(全大==8)再 load，数组名仅取地址
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        nv3 a0 01 ktok 02 ht 2
                        mgl 01 nv3 02
                        putb 01 10 02
                        qv2 a0 gsize a7 allidx a8
                        cond a0 01 qv2 02 a1 8
                        lr cond 08
                            putb 01 9 02
                            wstr 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        00 右值 k+4：全局→offset+load；否则局部/参数→lea+load
                        nv3 a0 01 ktok 02 ht 4
                        qv1 a0 lookup 01 nv3 02
                        tmpv a0 01 qv1 02 a6 8
                        qv2 a0 01 qv1 02 a5 512
                        tmpv a0 01 tmpv 02 hs 01 qv2 02
                        qv2 a0 01 tmpv 02 a1 0
                        lr qv2 08
                            qv2 a0 findall 01 nv3 02
                        09
                        lr qv2 08
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            nv3 a0 01 ktok 02 ht 4
                            mgl 01 nv3 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        lr tmpv 08
                            nv3 a0 01 ktok 02 ht 4
                            qv1 a0 lookup 01 nv3 02
                            cond a0 argmark a7 idx a8
                            lr cond 08
                                putb 01 9 02
                                wstr 01 03lea rax, [rbp+03 02
                                wnum 01 qv1 02
                                wstr 01 03]03 02
                                putb 01 10 02
                            09
                            tmpv a0 01 cond 02 a1 0
                            lr tmpv 08
                                putb 01 9 02
                                wstr 01 03lea rax, [rbp-03 02
                                wnum 01 qv1 02
                                wstr 01 03]03 02
                                putb 01 10 02
                            09
                            putb 01 9 02
                            wstr 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        00 op: mov rcx,rax / pop rax / add rax,rcx
                        putb 01 9 02
                        wstr 01 03mov rcx, rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03pop rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03add rax, rcx03 02
                        putb 01 10 02
                        00 存回目标：mov [rbp-slot], rax
                        nv2 a0 lookup 01 ktok 02
                        putb 01 9 02
                        wstr 01 03mov [rbp-03 02
                        wnum 01 nv2 02
                        wstr 01 03], rax03 02
                        putb 01 10 02
                        idxv a0 01 idxv 02 ht 4
                    09
                09
            09
        09

        00 ── 数组写：数组名 [ 下标 ] = 右值 ──
        00 C版：基址offset → 下标load → cmp count/jb .Lbok/call _rt_oob/.Lbok:
        00       → imul 8 → push → 基址 → rcx → pop/add → push → 右值 → rcx/pop/mov [rax]
        00 判据：k+1是'['(91)，k+3是']'(93)，k+4是=，k查全命中且全大>8
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 55 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 3
            cond a0 is2 01 nv3 a9 97 a9 56 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 4
                cond a0 is2 01 nv3 a9 97 a9 48 02
                lr cond 08
                    qv2 a0 findall 01 ktok 02
                    lr qv2 08
                        vv2 a0 gsize a7 allidx a8
                        tmpv a0 01 vv2 02 a6 8
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            nv3 a0 01 ktok 02
                            mgl 01 nv3 02
                            putb 01 10 02
                            00 下标 k+2
                            nv3 a0 01 ktok 02 ht 2
                            pl 01 nv3 02
                            00 越界检查
                            putb 01 9 02
                            wstr 01 03cmp rax, 03 02
                            qv1 a0 01 vv2 02 hl 8
                            wnum 01 qv1 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03jb .Lbok03 02
                            elno a0 01 elno 02 ht 1
                            qv1 a0 elno
                            wnum 01 qv1 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03call _rt_oob03 02
                            putb 01 10 02
                            wstr 01 03.Lbok03 02
                            wnum 01 qv1 02
                            wstr 01 03:03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03imul rax, 803 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            nv3 a0 01 ktok 02
                            mgl 01 nv3 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03add rax, rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03push rax03 02
                            putb 01 10 02
                            00 右值 k+5：字母→调用或变量；否则载荷
                            endp a0 0
                            nv3 a0 01 ktok 02 ht 5
                            chrv a0 head 01 nv3 02
                            chrv a0 01 chrv 02 hs 255
                            00 括号表达式右值：01 A 02 op 01 B op2 C 02 / 01 A 02 op B
                            cond2 a0 01 chrv 02 a1 48
                            lr cond2 08
                                qv1 a0 bytes 01 nv3 a9 1 02
                                cond2 a0 01 qv1 02 a1 49
                                lr cond2 08
                                    nv3 a0 01 ktok 02 ht 6
                                    pl 01 nv3 02
                                    putb 01 9 02
                                    wstr 01 03push rax03 02
                                    putb 01 10 02
                                    00 B 侧是否也是 01 ... 02
                                    nv2 a0 01 ktok 02 ht 9
                                    qv2 a0 head 01 nv2 02
                                    qv2 a0 01 qv2 02 hs 255
                                    cond a0 01 qv2 02 a1 48
                                    lr cond 08
                                        qv1 a0 bytes 01 nv2 a9 1 02
                                        cond a0 01 qv1 02 a1 49
                                    09
                                    lr cond 08
                                        nv3 a0 01 ktok 02 ht 10
                                        pl 01 nv3 02
                                        00 k+11 是 02 → 简单形态 01 A 02 op 01 B 02
                                        nv2 a0 01 ktok 02 ht 11
                                        qv1 a0 is2 01 nv2 a9 48 a9 50 02
                                        lr qv1 08
                                            nv3 a0 01 ktok 02 ht 8
                                            twoop 01 nv3 02
                                            endp a0 01 ktok 02 ht 12
                                        09
                                        lr 01 qv1 02 a1 0 08
                                            00 链式形态 01 A 02 op 01 B op2 C 02
                                            putb 01 9 02
                                            wstr 01 03push rax03 02
                                            putb 01 10 02
                                            nv3 a0 01 ktok 02 ht 12
                                            pl 01 nv3 02
                                            nv3 a0 01 ktok 02 ht 11
                                            twoop 01 nv3 02
                                            nv3 a0 01 ktok 02 ht 8
                                            twoop 01 nv3 02
                                            endp a0 01 ktok 02 ht 13
                                        09
                                    09
                                    cond2 a0 01 endp 02 a1 0
                                    lr cond2 08
                                        nv3 a0 01 ktok 02 ht 9
                                        pl 01 nv3 02
                                        nv3 a0 01 ktok 02 ht 8
                                        twoop 01 nv3 02
                                        endp a0 01 ktok 02 ht 9
                                    09
                                09
                            09
                            tmpv a0 isname 01 chrv 02
                            lr tmpv 08
                                nv2 a0 01 ktok 02 ht 6
                                00 判断 k+6 是不是 01（括号开）：长度2且字节 48/49
                                cond a0 getlen 01 nv2 02
                                tmpv a0 01 cond 02 a1 2
                                cond2 a0 0
                                lr tmpv 08
                                    chrv a0 head 01 nv2 02
                                    chrv a0 01 chrv 02 hs 255
                                    cond2 a0 01 chrv 02 a1 48
                                    lr cond2 08
                                        chrv a0 bytes 01 nv2 a9 1 02
                                        cond2 a0 01 chrv 02 a1 49
                                    09
                                09
                                lr cond2 08
                                    num a0 0
                                    apos a0 01 ktok 02 ht 7
                                    ll 08
                                        nv3 a0 apos
                                        cond a0 getlen 01 nv3 02
                                        tmpv a0 01 cond 02 a1 2
                                        cond a0 0
                                        lr tmpv 08
                                            chrv a0 head 01 nv3 02
                                            chrv a0 01 chrv 02 hs 255
                                            qv1 a0 01 chrv 02 a1 48
                                            lr qv1 08
                                                chrv a0 bytes 01 nv3 a9 1 02
                                                cond a0 01 chrv 02 a1 50
                                            09
                                        09
                                        lr cond 08 ls 09
                                        cond a0 is2 01 nv3 a9 97 a9 57 02
                                        lr cond 08
                                            apos a0 01 apos 02 ht 1
                                        09
                                        nv3 a0 apos
                                        pl 01 nv3 02
                                        putb 01 9 02
                                        wstr 01 03push rax03 02
                                        putb 01 10 02
                                        num a0 01 num 02 ht 1
                                        apos a0 01 apos 02 ht 1
                                    09
                                    putb 01 9 02
                                    wstr 01 03call fn_03 02
                                    nv3 a0 01 ktok 02 ht 5
                                    mgl 01 nv3 02
                                    putb 01 10 02
                                    tmpv a0 01 num 02 a4 0
                                    lr tmpv 08
                                        putb 01 9 02
                                        wstr 01 03add rsp, 03 02
                                        qv1 a0 01 num 02 hh 8
                                        wnum 01 qv1 02
                                        putb 01 10 02
                                    09
                                    endp a0 apos
                                09
                            09
                            00 还没发右值（末==0）→ 当变量载荷一次
                            cond2 a0 01 endp 02 a1 0
                            lr cond2 08
                                pl 01 nv3 02
                                endp a0 01 ktok 02 ht 5
                            09
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov [rax], rcx03 02
                            putb 01 10 02
                            idxv a0 01 endp 02
                        09
                    09
                09
            09
        09

        00 ── 数组读：目标 = 全局数组名[下标]（6 token: k..k+5）──
        00 C版：基址offset → 下标load → cmp count/jb .Lbok/call _rt_oob/.Lbok:
        00       → imul 8 → push → 基址 → rcx → pop/add → mov [rax] → 存回目标
        00 判据：k+1是=，k局部，k+2查全命中，k+3首字节'['(91)，k+4下标，k+5']'
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv2 a0 lookup 01 ktok 02
            00 any local/param slot (nonzero) accepted
            cond a0 01 nv2 02 a2 0
            00 结尾判定：6 记号要 k+5 是 a8；10 记号（表达式下标）k+9 是 a8
            start a0 01 send 02 hz ktok
            tmpv a0 01 start 02 a1 6
            lr tmpv 08
                nv3 a0 01 ktok 02 ht 5
                tmpv a0 is2 01 nv3 a9 97 a9 56 02
            09
            lr 01 start 02 a1 10 08
                nv3 a0 01 ktok 02 ht 9
                tmpv a0 is2 01 nv3 a9 97 a9 56 02
            09
            cond a0 01 cond 02 hs 01 tmpv 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 3
                cond a0 is2 01 nv3 a9 97 a9 55 02
                lr cond 08
                    nv3 a0 01 ktok 02 ht 2
                    qv2 a0 findall 01 nv3 02
                    lr qv2 08
                        vv2 a0 gsize a7 allidx a8
                        tmpv a0 01 vv2 02 a6 8
                        lr tmpv 08
                            00 基址 offset（先输出）
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            nv3 a0 01 ktok 02 ht 2
                            mgl 01 nv3 02
                            putb 01 10 02
                            00 先判表达式下标：01 A op B 02（如 缓冲[ 01 p 02 ht i 02 ]）
                            nv3 a0 01 ktok 02 ht 4
                            chrv a0 head 01 nv3 02
                            chrv a0 01 chrv 02 hs 255
                            qv1 a0 01 chrv 02 a1 48
                            tmpv a0 bytes 01 nv3 a9 1 02
                            cond2 a0 01 tmpv 02 a1 49
                            qv1 a0 01 qv1 02 hs 01 cond2 02
                            lr qv1 08
                                00 表达式下标 01 A 02 op B：A=k+5 / B=k+8 / op=k+7
                                nv3 a0 01 ktok 02 ht 5
                                pl 01 nv3 02
                                putb 01 9 02
                                wstr 01 03push rax03 02
                                putb 01 10 02
                                nv3 a0 01 ktok 02 ht 8
                                pl 01 nv3 02
                                nv3 a0 01 ktok 02 ht 7
                                twoop 01 nv3 02
                                idxv a0 01 idxv 02 ht 2
                            09
                            lr 01 qv1 02 a1 0 08
                            00 下标 k+4：数字→mov rax,N；变量→lea+load
                            nv3 a0 01 ktok 02 ht 4
                            chrv a0 head 01 nv3 02
                            chrv a0 01 chrv 02 hs 255
                            tmpv a0 01 chrv 02 a6 48
                            qv2 a0 01 chrv 02 a5 57
                            tmpv a0 01 tmpv 02 hs 01 qv2 02
                            lr tmpv 08
                                putb 01 9 02
                                wstr 01 03mov rax, 03 02
                                putnumtok 01 nv3 02
                                putb 01 10 02
                            09
                            qv2 a0 01 tmpv 02 a1 0
                            lr qv2 08
                                qv1 a0 lookup 01 nv3 02
                                tmpv a0 01 qv1 02 a6 8
                                cond2 a0 01 qv1 02 a5 512
                                tmpv a0 01 tmpv 02 hs 01 cond2 02
                                lr tmpv 08
                                    cond2 a0 argmark a7 idx a8
                                    lr cond2 08
                                        putb 01 9 02
                                        wstr 01 03lea rax, [rbp+03 02
                                        wnum 01 qv1 02
                                        wstr 01 03]03 02
                                        putb 01 10 02
                                    09
                                    qv2 a0 01 cond2 02 a1 0
                                    lr qv2 08
                                        putb 01 9 02
                                        wstr 01 03lea rax, [rbp-03 02
                                        wnum 01 qv1 02
                                        wstr 01 03]03 02
                                        putb 01 10 02
                                    09
                                    putb 01 9 02
                                    wstr 01 03mov rax, [rax]03 02
                                    putb 01 10 02
                                09
                                00 下标是全局（如 idx）：offset g_ + load
                                lr 01 tmpv 02 a1 0 08
                                    rpv a0 findall 01 nv3 02
                                    lr rpv 08
                                        putb 01 9 02
                                        wstr 01 03mov rax, offset g_03 02
                                        mgl 01 nv3 02
                                        putb 01 10 02
                                        putb 01 9 02
                                        wstr 01 03mov rax, [rax]03 02
                                        putb 01 10 02
                                    09
                                09
                            09
                            09
                            00 越界检查：cmp rax,count / jb .LbokN / call _rt_oob / .LbokN:
                            putb 01 9 02
                            wstr 01 03cmp rax, 03 02
                            qv1 a0 01 vv2 02 hl 8
                            wnum 01 qv1 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03jb .Lbok03 02
                            elno a0 01 elno 02 ht 1
                            qv1 a0 elno
                            wnum 01 qv1 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03call _rt_oob03 02
                            putb 01 10 02
                            wstr 01 03.Lbok03 02
                            wnum 01 qv1 02
                            wstr 01 03:03 02
                            putb 01 10 02
                            00 imul 8 / push / 基址 / rcx / pop / add / load / 存回
                            putb 01 9 02
                            wstr 01 03imul rax, 803 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rax, offset g_03 02
                            nv3 a0 01 ktok 02 ht 2
                            mgl 01 nv3 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03add rax, rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            wstr 01 03mov rax, [rax]03 02
                            putb 01 10 02
                            nv2 a0 lookup 01 ktok 02
                            putb 01 9 02
                            wstr 01 03mov [rbp-03 02
                            wnum 01 nv2 02
                            wstr 01 03], rax03 02
                            putb 01 10 02
                            idxv a0 01 idxv 02 ht 5
                        09
                    09
                09
            09
        09

        00 zz 值 → 求值进 rax，再 jmp .Lret_
        cond a0 tokis 01 ktok a9 03zz03 02
        lr cond 08
            zzdone a0 0
            nv3 a0 01 ktok 02 ht 1
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            qv1 a0 getlen 01 nv3 02
            00 字符串 token 03..03：首字节48('0') 且 第二字节51('3') 且 长度>1
            00 必须查第二字节，否则两位数字常量 10/08 会被误判成字符串
            00 用 q2 存第二字节，不覆盖 c（c 后面数字判据还要用）
            qv2 a0 bytes 01 nv3 a9 1 02
            tmpv a0 01 chrv 02 a1 48
            lr tmpv 08
                cond a0 01 qv2 02 a1 51
                lr cond 08
                    tmpv a0 01 qv1 02 a4 4
                    lr tmpv 08
                        zzdone a0 1
                        nv2 a0 regstr 01 nv3 02
                        putb 01 9 02
                        wstr 01 03mov rax, offset .Lstr03 02
                        wnum 01 nv2 02
                        putb 01 10 02
                    09
                09
            09
            00 数字 token：长度==1 且首字节 48..57
            cond a0 01 qv1 02 a1 1
            qv2 a0 01 chrv 02 a6 48
            qv1 a0 01 chrv 02 a5 57
            qv2 a0 01 qv2 02 hs 01 qv1 02
            cond a0 01 cond 02 hs 01 qv2 02
            lr cond 08
                00 数字：mov rax, 值
                zzdone a0 1
                putb 01 9 02
                wstr 01 03mov rax, 03 02
                nv3 a0 01 ktok 02 ht 1
                putnumtok 01 nv3 02
                putb 01 10 02
            09
            00 括号表达式：zz 01 A 02 op B 或 zz 01 A op B 02（返回前求值）
            tmpv a0 is2 01 nv3 a9 48 a9 49 02
            lr tmpv 08
                zzdone a0 1
                nv2 a0 01 ktok 02 ht 2
                pl 01 nv2 02
                putb 01 9 02
                wstr 01 03push rax03 02
                putb 01 10 02
                nv2 a0 01 ktok 02 ht 3
                cond2 a0 isop 01 nv2 02
                lr cond2 08
                    00 形2：01 A op B 02 → 运算符在括号里，B=k+4，op=k+3
                    nv2 a0 01 ktok 02 ht 4
                    pl 01 nv2 02
                    nv2 a0 01 ktok 02 ht 3
                    twoop 01 nv2 02
                09
                cond2 a0 01 cond2 02 a1 0
                lr cond2 08
                    00 形1：01 A 02 op B → 运算符在括号外，B=k+5，op=k+4
                    nv2 a0 01 ktok 02 ht 5
                    pl 01 nv2 02
                    nv2 a0 01 ktok 02 ht 4
                    twoop 01 nv2 02
                09
            09
            00 其余按变量：全局查全命中走 offset g_，否则局部/参数（原样）
            qv1 a0 01 zzdone 02 a1 0
            lr qv1 08
                nv2 a0 lookup 01 nv3 02
                qv2 a0 01 nv2 02 a6 8
                cond2 a0 01 nv2 02 a5 512
                qv2 a0 01 qv2 02 hs 01 cond2 02
                cond2 a0 01 qv2 02 a1 0
                qv2 a0 0
                lr cond2 08
                    qv2 a0 findall 01 nv3 02
                09
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03mov rax, offset g_03 02
                    nv2 a0 01 ktok 02 ht 1
                    mgl 01 nv2 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03mov rax, [rax]03 02
                    putb 01 10 02
                09
                qv2 a0 01 cond2 02 a1 0
                lr qv2 08
                    cond a0 argmark a7 idx a8
                    lr cond 08
                        putb 01 9 02
                        wstr 01 03lea rax, [rbp+03 02
                        wnum 01 nv2 02
                        wstr 01 03]03 02
                        putb 01 10 02
                    09
                    tmpv a0 01 cond 02 a1 0
                    lr tmpv 08
                        putb 01 9 02
                        wstr 01 03lea rax, [rbp-03 02
                        wnum 01 nv2 02
                        wstr 01 03]03 02
                        putb 01 10 02
                    09
                    putb 01 9 02
                    wstr 01 03mov rax, [rax]03 02
                    putb 01 10 02
                09
            09
            putb 01 9 02
            wstr 01 03jmp .Lret_03 02
            nv3 a0 01 retv 02
            mgl 01 nv3 02
            putb 01 10 02
        09

        00 lr 条件：k=lr，两种形态
        00   形1 变量：lr 变量 08          → load / test / jz .LelseN
        00   形2 比较：lr 01 A 02 op 01 B 02 08 → 载荷A/push/载荷B/rcx/cmp/setX/movzx/test/jz
        cond a0 tokis 01 ktok a9 03lr03 02
        lr cond 08
            nv2 a0 01 ktok 02 ht 1
            chrv a0 head 01 nv2 02
            chrv a0 01 chrv 02 hs 255
            cmp a0 0
            lr 01 chrv 02 a1 48 08 cmp a0 1 09
            lr 01 cmp 02 a1 1 08
                00 条件表达式：lr 01 A op B 02 08  或  lr 01 A 02 op 01 B 02 08
                nv3 a0 01 ktok 02 ht 2
                pl 01 nv3 02
                putb 01 9 02
                wstr 01 03push rax03 02
                putb 01 10 02
                00 判 k+3 是否为 02 编码 → 决定形态
                nv3 a0 01 ktok 02 ht 3
                chrv a0 head 01 nv3 02
                chrv a0 01 chrv 02 hs 255
                tmpv a0 01 chrv 02 a1 48
                qv2 a0 bytes 01 nv3 a9 1 02
                cond2 a0 01 qv2 02 a1 50
                tmpv a0 01 tmpv 02 hs 01 cond2 02
                qv1 a0 01 ktok 02 ht 3
                nv3 a0 01 ktok 02 ht 4
                lr tmpv 08
                    00 形2：A 02 op ?  → op=k+4；右值可能是 01 B 02（B=k+6）也可能裸 B（k+5）
                    qv1 a0 01 ktok 02 ht 4
                    nv3 a0 01 ktok 02 ht 6
                    cond2 a0 01 ktok 02 ht 5
                    cond a0 is2 01 cond2 a9 48 a9 49 02
                    lr 01 cond 02 a1 0 08
                        nv3 a0 01 ktok 02 ht 5
                    09
                    idxv a0 01 idxv 02 ht 7
                09
                lr 01 tmpv 02 a1 0 08
                    00 形1：A op B 02 → op=k+3, B=k+4
                    idxv a0 01 idxv 02 ht 5
                09
                pl 01 nv3 02
                twoop 01 qv1 02
                putb 01 9 02
                wstr 01 03test rax, rax03 02
                putb 01 10 02
            09
            lr 01 cmp 02 a1 0 08
                00 也可能是 lr 变量 op 值（不带括号）：载荷 / push / 载荷 / 比较
                nv3 a0 01 ktok 02 ht 2
                cond2 a0 isop 01 nv3 02
                lr cond2 08
                    nv3 a0 01 ktok 02 ht 1
                    pl 01 nv3 02
                    putb 01 9 02
                    wstr 01 03push rax03 02
                    putb 01 10 02
                    nv3 a0 01 ktok 02 ht 3
                    pl 01 nv3 02
                    nv3 a0 01 ktok 02 ht 2
                    twoop 01 nv3 02
                09
                lr 01 cond2 02 a1 0 08
                00 变量形态：局部/参数 → lea+load；全局 → offset g_+load
                nv3 a0 lookup 01 nv2 02
                qv2 a0 01 nv3 02 a6 8
                cond2 a0 01 nv3 02 a5 512
                qv2 a0 01 qv2 02 hs 01 cond2 02
                lr qv2 08
                    putb 01 9 02
                    wstr 01 03lea rax, [rbp-03 02
                    wnum 01 nv3 02
                    wstr 01 03]03 02
                    putb 01 10 02
                    putb 01 9 02
                    wstr 01 03mov rax, [rax]03 02
                    putb 01 10 02
                09
                lr 01 qv2 02 a1 0 08
                    cond2 a0 findall 01 nv2 02
                    lr cond2 08
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        mgl 01 nv2 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, [rax]03 02
                        putb 01 10 02
                    09
                09
                09
                putb 01 9 02
                wstr 01 03test rax, rax03 02
                putb 01 10 02
                idxv a0 01 ktok 02 ht 1
            09
            cmp a0 0
            elno a0 01 elno 02 ht 1
            putb 01 9 02
            wstr 01 03jz .Lelse03 02
            wnum 01 elno 02
            putb 01 10 02
            estop a0 01 estop 02 ht 1
            elstack a7 estop a8 a0 elno
            dstack a7 estop a8 a0 pdepth
            tstack a7 estop a8 a0 1
        09

        00 lh/lz A B：比较跳转（lh 不等 / lz 相等）→ 载荷A/push/载荷B/rcx/cmp/je|jne .LelseN
        cond a0 tokis 01 ktok a9 03lh03 02
        lr cond 08 cmp a0 1 09
        cond a0 tokis 01 ktok a9 03lz03 02
        lr cond 08 cmp a0 2 09
        lr cmp 08
            nv2 a0 01 ktok 02 ht 1
            pl 01 nv2 02
            putb 01 9 02
            wstr 01 03push rax03 02
            putb 01 10 02
            nv2 a0 01 ktok 02 ht 2
            pl 01 nv2 02
            putb 01 9 02
            wstr 01 03mov rcx, rax03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03pop rax03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03cmp rax, rcx03 02
            putb 01 10 02
            elno a0 01 elno 02 ht 1
            putb 01 9 02
            cond a0 01 cmp 02 a1 1
            lr cond 08
                wstr 01 03je .Lelse03 02
            09
            cond a0 01 cmp 02 a1 2
            lr cond 08
                wstr 01 03jne .Lelse03 02
            09
            wnum 01 elno 02
            putb 01 10 02
            estop a0 01 estop 02 ht 1
            elstack a7 estop a8 a0 elno
            dstack a7 estop a8 a0 pdepth
            tstack a7 estop a8 a0 1
            cmp a0 0
            idxv a0 01 ktok 02 ht 2
        09

        00 ll 循环：k=ll，k+1 记号首字节48('0')，第二字节56('8')→无限循环，49('1')→条件循环
        00 连续分配两个编号：top=N，end=N+1（与 C 版 newlab 顺序一致）
        cond a0 tokis 01 ktok a9 03ll03 02
        lr cond 08
            nv2 a0 01 ktok 02 ht 1
            chrv a0 head 01 nv2 02
            chrv a0 01 chrv 02 hs 255
            cond a0 01 chrv 02 a1 48
            lr cond 08
                qv2 a0 bytes 01 nv2 a9 1 02
                00 无限循环：bytes1==56('8')
                cond a0 01 qv2 02 a1 56
                lr cond 08
                    elno a0 01 elno 02 ht 1
                    qv1 a0 elno
                    elno a0 01 elno 02 ht 1
                    wstr 01 03.Lltop03 02
                    wnum 01 qv1 02
                    wstr 01 03:03 02
                    putb 01 10 02
                    estop a0 01 estop 02 ht 1
                    elstack a7 estop a8 a0 elno
                    topstack a7 estop a8 a0 qv1
                    dstack a7 estop a8 a0 pdepth
                    tstack a7 estop a8 a0 2
                09
                00 条件循环：bytes1==49('1')，条件 01 变量 02 取 k+2 变量名
                cond a0 01 qv2 02 a1 49
                lr cond 08
                    elno a0 01 elno 02 ht 1
                    qv1 a0 elno
                    elno a0 01 elno 02 ht 1
                    wstr 01 03.Lwtop03 02
                    wnum 01 qv1 02
                    wstr 01 03:03 02
                    putb 01 10 02
                    00 条件：ll 01 A 02 < 01 B 02 08 → 载荷A/push/载荷B/rcx/cmp/setb/movzx/test/jz
                    nv3 a0 01 ktok 02 ht 2
                    pl 01 nv3 02
                    00 判 k+4 是否 08：是则单条件 ll 01 A 02 08，否则比较序列
                    nv3 a0 01 ktok 02 ht 4
                    chrv a0 head 01 nv3 02
                    chrv a0 01 chrv 02 hs 255
                    cond2 a0 01 chrv 02 a1 48
                    qv2 a0 bytes 01 nv3 a9 1 02
                    tmpv a0 01 qv2 02 a1 56
                    cond2 a0 01 cond2 02 hs 01 tmpv 02
                    lr cond2 08
                        putb 01 9 02
                        wstr 01 03test rax, rax03 02
                        putb 01 10 02
                    09
                    lr 01 cond2 02 a1 0 08
                    putb 01 9 02
                    wstr 01 03push rax03 02
                    putb 01 10 02
                    00 右值：k+5 是 01 则 B=k+6（括号形态），否则 B=k+5（裸）
                    nv2 a0 01 ktok 02 ht 5
                    tmpv a0 is2 01 nv2 a9 48 a9 49 02
                    lr tmpv 08 nv2 a0 01 ktok 02 ht 6 09
                    pl 01 nv2 02
                    00 比较指令由运算符决定：< setb / > seta / <= setbe / >= setae / == sete / != setne
                    nv3 a0 01 ktok 02 ht 4
                    twoop 01 nv3 02
                    putb 01 9 02
                    wstr 01 03test rax, rax03 02
                    putb 01 10 02
                    09
                    putb 01 9 02
                    wstr 01 03jz .Lwend03 02
                    wnum 01 elno 02
                    putb 01 10 02
                    estop a0 01 estop 02 ht 1
                    elstack a7 estop a8 a0 elno
                    topstack a7 estop a8 a0 qv1
                    dstack a7 estop a8 a0 pdepth
                    tstack a7 estop a8 a0 3
                09
            09
        09

        00 ── 顶层全局声明 ts 名 = 值 / tf 名[N]（有函==0 时才处理）──
        tmpv a0 01 hasfn 02 a1 0
        lr tmpv 08
            nv3 a0 tokis 01 ktok a9 03ts03 02
            lr nv3 08
                nv2 a0 01 ktok 02 ht 1
                qv1 a0 8
                regglob 01 nv2 a9 qv1 02
                idxv a0 01 ktok 02 ht 1
                00 可选初值：ts 名 = 数字
                nv3 a0 01 ktok 02 ht 2
                cond a0 is2 01 nv3 a9 97 a9 48 02
                lr cond 08
                    nv3 a0 01 ktok 02 ht 3
                    qv1 a0 str2num 01 nv3 02
                    nv2 a0 01 nglob 02 hz 1
                    ginit a7 nv2 a8 a0 qv1
                    idxv a0 01 ktok 02 ht 3
                09
            09
            nv3 a0 tokis 01 ktok a9 03tf03 02
            lr nv3 08
                nv2 a0 01 ktok 02 ht 1
                qv1 a0 01 ktok 02 ht 3
                qv1 a0 str2num 01 qv1 02
                qv1 a0 01 qv1 02 hh 8
                regglob 01 nv2 a9 qv1 02
                idxv a0 01 ktok 02 ht 4
            09
            00 th 名字 a0 数值：只读常量，和 ts 一样进全局表
            nv3 a0 tokis 01 ktok a9 03th03 02
            lr nv3 08
                nv2 a0 01 ktok 02 ht 1
                qv1 a0 8
                regglob 01 nv2 a9 qv1 02
                idxv a0 01 ktok 02 ht 1
                nv3 a0 01 ktok 02 ht 2
                cond a0 is2 01 nv3 a9 97 a9 48 02
                lr cond 08
                    nv3 a0 01 ktok 02 ht 3
                    qv1 a0 str2num 01 nv3 02
                    nv2 a0 01 nglob 02 hz 1
                    ginit a7 nv2 a8 a0 qv1
                    idxv a0 01 ktok 02 ht 3
                09
            nv3 a0 tokis 01 ktok a9 03td03 02
            lr nv3 08
                nv2 a0 01 ktok 02 ht 1
                qv1 a0 8
                regglob 01 nv2 a9 qv1 02
                idxv a0 01 ktok 02 ht 1
                nv3 a0 01 ktok 02 ht 2
                cond a0 is2 01 nv3 a9 97 a9 48 02
                lr cond 08
                    nv3 a0 01 ktok 02 ht 3
                    qv1 a0 str2num 01 nv3 02
                    nv2 a0 01 nglob 02 hz 1
                    ginit a7 nv2 a8 a0 qv1
                    idxv a0 01 ktok 02 ht 3
                09
            09
            09
        09

        00 ── zh 标签名 → 名字: ──
        tmpv a0 is2 01 ktok a9 122 a9 104 02
        lr tmpv 08
            nv3 a0 01 ktok 02 ht 1
            mgl 01 nv3 02
            wstr 01 03:03 02
            putb 01 10 02
            incdone a0 1
        09

        00 ── lt 标签名 → jmp 名字 ──
        tmpv a0 is2 01 ktok a9 108 a9 116 02
        lr tmpv 08
            putb 01 9 02
            wstr 01 03jmp 03 02
            nv3 a0 01 ktok 02 ht 1
            mgl 01 nv3 02
            putb 01 10 02
            incdone a0 1
        09

        00 ── ld 08 … 09（else 块）：只出 .LendifN: 标签收尾 ──
        00 jmp .LendifN 已在前面 lr 的 09 处出过，这里只需标签
        tmpv a0 01 incdone 02 a1 0
        nv3 a0 is2 01 ktok a9 108 a9 100 02
        tmpv a0 01 tmpv 02 hs 01 nv3 02
        lr tmpv 08
            nv3 a0 01 ktok 02 ht 1
            cond a0 is2 01 nv3 a9 48 a9 56 02
            lr cond 08
                00 ld 08 … 09：整块原文跳过（块内代码前面已处理），末尾出 .LendifN:
                wstr 01 03.Lendif03 02
                qv1 a0 01 estop 02 ht 1
                nv2 a0 elstack a7 qv1 a8
                wnum 01 nv2 02
                wstr 01 03:03 02
                putb 01 10 02
                incdone a0 1
            09
        09

        00 ── zs 08 … 09：内联汇编，块内原文照抄 ──
        00 C版：token 之间补一个空格，原行尾换行，块末再加一个换行
        tmpv a0 is2 01 ktok a9 122 a9 115 02
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 48 a9 56 02
        tmpv a0 01 tmpv 02 hs 01 cond 02
        lr tmpv 08
            00 找匹配的 09（08/09 成对，要计深度）
            fp a0 1
            apos a0 01 ktok 02 ht 2
            endp a0 01 ktok 02 ht 2
            ll 01 apos 02 a3 01 cnt 02 08
                tmpv a0 is2 01 apos a9 48 a9 56 02
                lr tmpv 08 fp a0 01 fp 02 ht 1 09
                tmpv a0 is2 01 apos a9 48 a9 57 02
                lr tmpv 08
                    fp a0 01 fp 02 hz 1
                    lr 01 fp 02 a1 0 08 endp a0 01 apos 02 ls 09
                09
                apos a0 01 apos 02 ht 1
            09
            00 从 08 的末尾开始：先补换行，再吐 token + 空格
            nv2 a0 01 ktok 02 ht 1
            qv1 a0 gettok 01 nv2 02
            rpv a0 01 qv1 02 ht 2
            apos a0 01 ktok 02 ht 2
            ll 01 apos 02 a3 01 endp 02 08
                qv1 a0 gettok 01 apos 02
                numleft a0 ggap 01 rpv a9 qv1 02
                ll 01 numleft 02 a4 0 08
                    putb 01 10 02
                    numleft a0 01 numleft 02 hz 1
                09
                puttok 01 apos 02
                putb 01 32 02
                nv2 a0 getlen 01 apos 02
                rpv a0 01 qv1 02 ht 01 nv2 02
                apos a0 01 apos 02 ht 1
            09
            qv1 a0 gettok 01 endp 02
            numleft a0 ggap 01 rpv a9 qv1 02
            ll 01 numleft 02 a4 0 08
                putb 01 10 02
                numleft a0 01 numleft 02 hz 1
            09
            putb 01 10 02
            incdone a0 1
        09

        00 ── st dt 值：写屏幕一个整数 ──
        tmpv a0 is2 01 ktok a9 115 a9 116 02
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 100 a9 116 02
        tmpv a0 01 tmpv 02 hs 01 cond 02
        lr tmpv 08
            nv3 a0 01 ktok 02 ht 2
            pl 01 nv3 02
            putb 01 9 02
            wstr 01 03push rax03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03call _rt_puti03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03add rsp, 803 02
            putb 01 10 02
            incdone a0 1
        09

        00 ── st dd "…"：写屏幕一个字符串常量 ──
        00 C版：push offset .LstrN / call _rt_puts / add rsp, 8
        tmpv a0 is2 01 ktok a9 115 a9 116 02
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 100 a9 100 02
        tmpv a0 01 tmpv 02 hs 01 cond 02
        lr tmpv 08
            nv3 a0 01 ktok 02 ht 2
            nv2 a0 regstr 01 nv3 02
            putb 01 9 02
            wstr 01 03push offset .Lstr03 02
            wnum 01 nv2 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03call _rt_puts03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03add rsp, 803 02
            putb 01 10 02
            incdone a0 1
        09

        00 ── st 裸值：st 变量 / st 数字 → pl + puti（gfx：st 后面 NUM/ID 直接 expr+puti）──
        tmpv a0 is2 01 ktok a9 115 a9 116 02
        cond a0 01 incdone 02 a1 0
        tmpv a0 01 tmpv 02 hs 01 cond 02
        lr tmpv 08
            nv3 a0 01 ktok 02 ht 1
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            cond a0 isnum 01 nv3 02
            qv1 a0 01 chrv 02 a1 48
            qv2 a0 getlen 01 nv3 02
            qv2 a0 01 qv2 02 a1 2
            qv1 a0 01 qv1 02 hs 01 qv2 02
            qv1 a0 01 qv1 02 a1 0
            cond a0 01 cond 02 hs 01 qv1 02
            qv2 a0 isname 01 chrv 02
            cond a0 01 cond 02 hr 01 qv2 02
            00 排除字符串 token：03…03（48,51）或 "（34）
            qv2 a0 is2 01 nv3 a9 48 a9 51 02
            cond2 a0 01 chrv 02 a1 34
            qv2 a0 01 qv2 02 hr 01 cond2 02
            qv2 a0 01 qv2 02 a1 0
            cond a0 01 cond 02 hs 01 qv2 02
            lr cond 08
                pl 01 nv3 02
                putb 01 9 02
                wstr 01 03push rax03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03call _rt_puti03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03add rsp, 803 02
                putb 01 10 02
                incdone a0 1
            09
        09

        00 ── 赋值+内建 fh：目标 = fh 01 addr 02（6 token: k..k+5）──
        00 C版：expr(addr)→mov rax,[rax](解引用)→mov [rbp-slot],rax
        00 判据：k 局部[8,512]，k+1 是 =，k+2 是 fh，k+3 必须是 01（无括号形态交给前面的 名 = fh 名 段）
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv2 a0 lookup 01 ktok 02
            cond a0 01 nv2 02 a6 8
            qv1 a0 01 nv2 02 a5 512
            cond a0 01 cond 02 hs 01 qv1 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 2
                tmpv a0 tokis 01 nv3 a9 03fh03 02
                nv3 a0 01 ktok 02 ht 3
                cond a0 is2 01 nv3 a9 48 a9 49 02
                tmpv a0 01 tmpv 02 hs 01 cond 02
                lr tmpv 08
                    00 addr 若是 01 A op B 02 形态 → 表达式地址
                    nv2 a0 01 ktok 02 ht 4
                    chrv a0 head 01 nv2 02
                    chrv a0 01 chrv 02 hs 255
                    tmpv a0 01 chrv 02 a1 48
                    qv2 a0 bytes 01 nv2 a9 1 02
                    cond a0 01 qv2 02 a1 49
                    tmpv a0 01 tmpv 02 hs 01 cond 02
                    lr tmpv 08
                        00 表达式地址：载荷 A=k+5 / push / 载荷 B=k+7 / 二op(k+6)
                        nv2 a0 01 ktok 02 ht 5
                        pl 01 nv2 02
                        putb 01 9 02
                        wstr 01 03push rax03 02
                        putb 01 10 02
                        nv2 a0 01 ktok 02 ht 7
                        pl 01 nv2 02
                        nv2 a0 01 ktok 02 ht 6
                        twoop 01 nv2 02
                        idxv a0 01 idxv 02 ht 3
                    09
                    lr 01 tmpv 02 a1 0 08
                    00 addr = k+4，先查局部（否则查全全局）
                    nv2 a0 01 ktok 02 ht 4
                    qv1 a0 lookup 01 nv2 02
                    tmpv a0 01 qv1 02 a6 8
                    qv2 a0 01 qv1 02 a5 512
                    tmpv a0 01 tmpv 02 hs 01 qv2 02
                    qv2 a0 01 tmpv 02 a1 0
                    lr qv2 08
                        qv2 a0 findall 01 nv2 02
                    09
                    lr qv2 08
                        putb 01 9 02
                        wstr 01 03mov rax, offset g_03 02
                        nv3 a0 01 ktok 02 ht 4
                        mgl 01 nv3 02
                        putb 01 10 02
                        putb 01 9 02
                        wstr 01 03mov rax, [rax]03 02
                        putb 01 10 02
                    09
                    00 t 只表示「是局部」；不要把 q2 并进来
                    lr tmpv 08
                        cond2 a0 argmark a7 idx a8
                        lr cond2 08
                            putb 01 9 02
                            wstr 01 03lea rax, [rbp+03 02
                            wnum 01 qv1 02
                            wstr 01 03]03 02
                            putb 01 10 02
                        09
                        tmpv a0 01 cond2 02 a1 0
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03lea rax, [rbp-03 02
                            wnum 01 qv1 02
                            wstr 01 03]03 02
                            putb 01 10 02
                        09
                        putb 01 9 02
                        wstr 01 03mov rax, [rax]03 02
                        putb 01 10 02
                    09
                    09
                    00 fh 核心：再解引用一次
                    putb 01 9 02
                    wstr 01 03mov rax, [rax]03 02
                    putb 01 10 02
                    00 存回目标
                    nv2 a0 lookup 01 ktok 02
                    putb 01 9 02
                    wstr 01 03mov [rbp-03 02
                    wnum 01 nv2 02
                    wstr 01 03], rax03 02
                    putb 01 10 02
                    idxv a0 01 idxv 02 ht 5
                09
            09
        09

        00 ── 赋值右值是调用：名 = 函数 01 参数 02 ──
        00   把 k 前移到函数名，直接交给下面的调用段生成
        00   （stmend 对移位后的 k 给出的末尾与移位前一致，所以推进不受影响）
        nv3 a0 01 ktok 02 ht 1
        cond a0 is2 01 nv3 a9 97 a9 48 02
        lr cond 08
            nv3 a0 01 ktok 02 ht 2
            qv1 a0 head 01 nv3 02
            qv1 a0 01 qv1 02 hs 255
            cond a0 isname 01 qv1 02
            lr cond 08
                nv3 a0 01 ktok 02 ht 3
                cond a0 is2 01 nv3 a9 48 a9 49 02
                lr cond 08
                    ktok a0 01 ktok 02 ht 2
                09
            09
        09

        00 ── 函数调用：标识符 + 01( 参数 02 → eval/push + call fn_名 + add rsp ──
        00 排除 ll/lz/lh/fh/fr/lr（它们是"关键字+01括号"形态，会被误认成调用）
        skip a0 0
        nv3 a0 tokis 01 ktok a9 03ll03 02
        lr nv3 08 skip a0 1 09
        nv3 a0 tokis 01 ktok a9 03lr03 02
        lr nv3 08 skip a0 1 09
        nv3 a0 tokis 01 ktok a9 03lz03 02
        lr nv3 08 skip a0 1 09
        nv3 a0 tokis 01 ktok a9 03lh03 02
        lr nv3 08 skip a0 1 09
        nv3 a0 tokis 01 ktok a9 03fh03 02
        lr nv3 08 skip a0 1 09
        nv3 a0 tokis 01 ktok a9 03fr03 02
        lr nv3 08 skip a0 1 09
        00 zz 是返回语句，不是调用 fn_zz
        nv3 a0 tokis 01 ktok a9 03zz03 02
        lr nv3 08 skip a0 1 09
        nv3 a0 01 skip 02 a1 0
        lr nv3 08
            00 宿主内建名识别：写字→_rt_sb / 写字节→_rt_putc / 写串→_rt_puts / 写数→_rt_puti
            bname a0 0
            cond a0 tokis 01 ktok a9 03putw03 02
            lr cond 08 bname a0 1 09
            cond a0 tokis 01 ktok a9 03putc03 02
            lr cond 08 bname a0 2 09
            cond a0 tokis 01 ktok a9 03puts03 02
            lr cond 08 bname a0 3 09
            cond a0 tokis 01 ktok a9 03puti03 02
            lr cond 08 bname a0 4 09
            cond a0 tokis 01 ktok a9 03rdfile03 02
            lr cond 08 bname a0 5 09
            cond a0 tokis 01 ktok a9 03rdbuf03 02
            lr cond 08 bname a0 6 09
            cond a0 tokis 01 ktok a9 03fsize03 02
            lr cond 08 bname a0 7 09
            cond a0 tokis 01 ktok a9 03wrfile03 02
            lr cond 08 bname a0 8 09
            cond a0 tokis 01 ktok a9 03slurp03 02
            lr cond 08 bname a0 9 09
            nv3 a0 01 ktok 02
            chrv a0 head 01 nv3 02
            chrv a0 01 chrv 02 hs 255
            tmpv a0 isname 01 chrv 02
            cond a0 01 bname 02 a4 0
            tmpv a0 01 tmpv 02 hr 01 cond 02
            lr tmpv 08
                cond a0 1
                qv2 a0 01 bname 02 a4 0
                cond a0 01 cond 02 hr 01 qv2 02
                lr cond 08
                nv2 a0 01 ktok 02 ht 1
                chrv a0 head 01 nv2 02
                chrv a0 01 chrv 02 hs 255
                cond a0 01 chrv 02 a1 48
                lr cond 08
                    chrv a0 bytes 01 nv2 a9 1 02
                    cond a0 01 chrv 02 a1 49
                    lr cond 08
                        00 确认 k+1 是 01 左括号 → 是函数调用
                        num a0 0
                        00 fp/skip2 借作内层 zt 调用状态：进循环前必须清零（别的段会写脏它们）
                        fp a0 0
                        skip2 a0 0
                        qv1 a0 01 ktok 02 ht 2
                        ll 01 qv1 02 a3 01 cnt 02 08
                            argdone a0 0
                            00 右括号 02 → break；若正处于内层 zt 调用里则收口内层调用
                            nv3 a0 head 01 qv1 02
                            nv3 a0 01 nv3 02 hs 255
                            cond a0 01 nv3 02 a1 48
                            lr cond 08
                                tmpv a0 bytes 01 qv1 a9 1 02
                                cond a0 01 tmpv 02 a1 50
                                lr cond 08
                                    lr 01 fp 02 a4 0 08
                                        00 内层 zt 调用收口：call fn_名 / add rsp, 8*(内层参数数) / push rax
                                        putb 01 9 02
                                        wstr 01 03call fn_03 02
                                        mgl 01 fp 02
                                        putb 01 10 02
                                        nv2 a0 01 num 02 hz 01 skip2 02
                                        tmpv a0 01 nv2 02 a4 0
                                        lr tmpv 08
                                            putb 01 9 02
                                            wstr 01 03add rsp, 03 02
                                            nv3 a0 01 nv2 02 hh 8
                                            wnum 01 nv3 02
                                            putb 01 10 02
                                        09
                                        putb 01 9 02
                                        wstr 01 03push rax03 02
                                        putb 01 10 02
                                        num a0 01 skip2 02 ht 1
                                        fp a0 0
                                        argdone a0 1
                                        qv1 a0 01 qv1 02 ht 1
                                        Zn
                                    09
                                    ls
                                09
                            09
                            00 zt 调用作为实参：zt 名 01 参数 02 → 记下函数名，参数由后续分支照常 push，02 收口
                            qv2 a0 is2 01 qv1 a9 122 a9 116 02
                            tmpv a0 01 argdone 02 a1 0
                            qv2 a0 01 qv2 02 hs 01 tmpv 02
                            lr qv2 08
                                nv3 a0 01 qv1 02 ht 1
                                chrv a0 head 01 nv3 02
                                chrv a0 01 chrv 02 hs 255
                                tmpv a0 isname 01 chrv 02
                                nv2 a0 01 qv1 02 ht 2
                                cond a0 is2 01 nv2 a9 48 a9 49 02
                                tmpv a0 01 tmpv 02 hs 01 cond 02
                                lr tmpv 08
                                    fp a0 01 qv1 02 ht 1
                                    skip2 a0 num
                                    qv1 a0 01 qv1 02 ht 3
                                    Zn
                                09
                            09
                            00 编码左括号 01 → 参数是表达式 01 A op B 02
                            chrv a0 head 01 qv1 02
                            chrv a0 01 chrv 02 hs 255
                            cond a0 01 chrv 02 a1 48
                            lr cond 08
                                tmpv a0 bytes 01 qv1 a9 1 02
                                cond2 a0 01 tmpv 02 a1 49
                                lr cond2 08
                                    00 q1 本身是 01 → 形A：01 01 A 02 op B 02
                                    00 否则形B：01 A op B 02（q1=A）
                                    nv3 a0 01 qv1 02
                                    chrv a0 head 01 nv3 02
                                    chrv a0 01 chrv 02 hs 255
                                    qv2 a0 bytes 01 nv3 a9 1 02
                                    tmpv a0 01 chrv 02 a1 48
                                    cond a0 01 qv2 02 a1 49
                                    tmpv a0 01 tmpv 02 hs 01 cond 02
                                    qv2 a0 01 qv1 02
                                    nv3 a0 01 qv1 02 ht 1
                                    cond a0 01 qv1 02 ht 2
                                    lr tmpv 08
                                        00 形A 两种：01 A 02 op B（op 在 02 后，hex2 用）/ 01 A op B 02（op 在括号里，递归用）
                                        qv2 a0 01 qv1 02 ht 1
                                        nv2 a0 01 qv1 02 ht 2
                                        cond2 a0 is2 01 nv2 a9 48 a9 50 02
                                        lr cond2 08
                                            00 01 A 02 op B：op=q1+3 B=q1+4
                                            nv3 a0 01 qv1 02 ht 4
                                            cond a0 01 qv1 02 ht 3
                                            qv1 a0 01 qv1 02 ht 5
                                        09
                                        cond2 a0 01 cond2 02 a1 0
                                        lr cond2 08
                                            00 01 A op B 02：op=q1+2 B=q1+3
                                            nv3 a0 01 qv1 02 ht 3
                                            cond a0 01 qv1 02 ht 2
                                            qv1 a0 01 qv1 02 ht 5
                                        09
                                    09
                                    lr 01 tmpv 02 a1 0 08
                                        00 形B：A=q1 op=q1+1 B=q1+2
                                        qv1 a0 01 qv1 02 ht 3
                                    09
                                    pl 01 qv2 02
                                    putb 01 9 02
                                    wstr 01 03push rax03 02
                                    putb 01 10 02
                                    pl 01 nv3 02
                                    twoop 01 cond 02
                                    putb 01 9 02
                                    wstr 01 03push rax03 02
                                    putb 01 10 02
                                    num a0 01 num 02 ht 1
                                    argdone a0 1
                                    Zn
                                09
                            09
                            00 字符串：03..03（首字节48 第二字节51）或 ".."（首字节34）
                            chrv a0 head 01 qv1 02
                            chrv a0 01 chrv 02 hs 255
                            cond a0 01 chrv 02 a1 48
                            lr cond 08
                                qv2 a0 bytes 01 qv1 a9 1 02
                                cond a0 01 qv2 02 a1 51
                            09
                            lr 01 chrv 02 a1 34 08 cond a0 1 09
                            lr cond 08
                                tmpv a0 getlen 01 qv1 02
                                qv2 a0 01 tmpv 02 a4 4
                                lr 01 chrv 02 a1 34 08 qv2 a0 1 09
                                    lr qv2 08
                                        nv2 a0 regstr 01 qv1 02
                                        putb 01 9 02
                                        wstr 01 03mov rax, offset .Lstr03 02
                                        wnum 01 nv2 02
                                        putb 01 10 02
                                        putb 01 9 02
                                        wstr 01 03push rax03 02
                                        putb 01 10 02
                                        num a0 01 num 02 ht 1
                                        argdone a0 1
                                    09
                                09
                            00 数字参数：c 是首字节，重新取（字符串分支没改 c 本身）
                            chrv a0 head 01 qv1 02
                            chrv a0 01 chrv 02 hs 255
                            qv2 a0 01 chrv 02 a6 48
                            cond a0 01 chrv 02 a5 57
                            qv2 a0 01 qv2 02 hs 01 cond 02
                            tmpv a0 01 argdone 02 a1 0
                            qv2 a0 01 qv2 02 hs 01 tmpv 02
                            tmpv a0 01 qv2 02 a1 1
                            lr tmpv 08
                                putb 01 9 02
                                wstr 01 03mov rax, 03 02
                                putnumtok 01 qv1 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03push rax03 02
                                putb 01 10 02
                                num a0 01 num 02 ht 1
                                argdone a0 1
                            09
                            00 zf 参数：取地址，不解引用（局部 lea / 全局 offset g_）
                            qv2 a0 is2 01 qv1 a9 122 a9 102 02
                            tmpv a0 01 argdone 02 a1 0
                            qv2 a0 01 qv2 02 hs 01 tmpv 02
                            lr qv2 08
                                nv3 a0 01 qv1 02 ht 1
                                nv2 a0 lookup 01 nv3 02
                                tmpv a0 01 nv2 02 a6 8
                                cond a0 01 nv2 02 a5 512
                                tmpv a0 01 tmpv 02 hs 01 cond 02
                                lr tmpv 08
                                    cond a0 argmark a7 idx a8
                                    lr cond 08
                                        putb 01 9 02
                                        wstr 01 03lea rax, [rbp+03 02
                                        wnum 01 nv2 02
                                        wstr 01 03]03 02
                                        putb 01 10 02
                                    09
                                    cond a0 01 cond 02 a1 0
                                    lr cond 08
                                        putb 01 9 02
                                        wstr 01 03lea rax, [rbp-03 02
                                        wnum 01 nv2 02
                                        wstr 01 03]03 02
                                        putb 01 10 02
                                    09
                                09
                                lr 01 tmpv 02 a1 0 08
                                    cond a0 findall 01 nv3 02
                                    lr cond 08
                                        putb 01 9 02
                                        wstr 01 03mov rax, offset g_03 02
                                        mgl 01 nv3 02
                                        putb 01 10 02
                                    09
                                09
                                putb 01 9 02
                                wstr 01 03push rax03 02
                                putb 01 10 02
                                num a0 01 num 02 ht 1
                                00 吃掉 zf 和名字两个 token（Zn 跳过尾部 q1+1，这里要 +2）
                                qv1 a0 01 qv1 02 ht 2
                                Zn
                            09
                            00 fd 参数：逻辑非 → pl + test/sete/movzx + push（gfx fd 口径）
                            qv2 a0 is2 01 qv1 a9 102 a9 100 02
                            tmpv a0 01 argdone 02 a1 0
                            qv2 a0 01 qv2 02 hs 01 tmpv 02
                            lr qv2 08
                                nv3 a0 01 qv1 02 ht 1
                                pl 01 nv3 02
                                putb 01 9 02
                                wstr 01 03test rax, rax03 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03sete al03 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03movzx rax, al03 02
                                putb 01 10 02
                                putb 01 9 02
                                wstr 01 03push rax03 02
                                putb 01 10 02
                                num a0 01 num 02 ht 1
                                00 吃掉 fd 和操作数两个 token
                                qv1 a0 01 qv1 02 ht 2
                                Zn
                            09
                            00 变量参数：首字节 97..122
                            chrv a0 head 01 qv1 02
                            chrv a0 01 chrv 02 hs 255
                            tmpv a0 isname 01 chrv 02
                            00 exclude a0~a9 encoded tokens (they are operators, not names)
                            qv2 a0 getlen 01 qv1 02
                            cond a0 01 qv2 02 a1 2
                            lr cond 08
                                cond a0 01 chrv 02 a1 97
                                lr cond 08
                                    qv2 a0 bytes 01 qv1 a9 1 02
                                    cond a0 01 qv2 02 a6 47
                                    cond2 a0 01 qv2 02 a5 58
                                    cond a0 01 cond 02 hs 01 cond2 02
                                    lr cond 08
                                        tmpv a0 0
                                    09
                                09
                            09
                            qv2 a0 01 argdone 02 a1 0
                            tmpv a0 01 tmpv 02 hs 01 qv2 02
                            lr tmpv 08
                                nv2 a0 lookup 01 qv1 02
                                tmpv a0 01 nv2 02 a6 8
                                qv2 a0 01 nv2 02 a5 512
                                tmpv a0 01 tmpv 02 hs 01 qv2 02
                                lr tmpv 08
                                    cond a0 argmark a7 idx a8
                                    lr cond 08
                                        putb 01 9 02
                                        wstr 01 03lea rax, [rbp+03 02
                                        wnum 01 nv2 02
                                        wstr 01 03]03 02
                                        putb 01 10 02
                                    09
                                    qv2 a0 01 cond 02 a1 0
                                    lr qv2 08
                                        putb 01 9 02
                                        wstr 01 03lea rax, [rbp-03 02
                                        wnum 01 nv2 02
                                        wstr 01 03]03 02
                                        putb 01 10 02
                                    09
                                    putb 01 9 02
                                    wstr 01 03mov rax, [rax]03 02
                                    putb 01 10 02
                                09
                                00 参数是全局（如 slot / cnt / outbuf）：offset g_；标量才 load
                                lr 01 tmpv 02 a1 0 08
                                    qv2 a0 findall 01 qv1 02
                                    lr qv2 08
                                        putb 01 9 02
                                        wstr 01 03mov rax, offset g_03 02
                                        mgl 01 qv1 02
                                        putb 01 10 02
                                        00 数组名只取地址，不能解引用
                                        tmpv a0 gsize a7 allidx a8
                                        lr 01 tmpv 02 a1 8 08
                                            putb 01 9 02
                                            wstr 01 03mov rax, [rax]03 02
                                            putb 01 10 02
                                        09
                                    09
                                09
                                putb 01 9 02
                                wstr 01 03push rax03 02
                                putb 01 10 02
                                num a0 01 num 02 ht 1
                                argdone a0 1
                            09
                            qv1 a0 01 qv1 02 ht 1
                        09
                        00 右括号 02 时停（上面循环碰到 02 时三个判据都不满足会 continue，需显式 break）
                        putb 01 9 02
                        cond a0 01 bname 02 a1 0
                        lr cond 08
                            wstr 01 03call fn_03 02
                            nv2 a0 01 ktok 02
                            mgl 01 nv2 02
                        09
                        cond a0 01 bname 02 a1 1
                        lr cond 08
                            wstr 01 03call _rt_sb03 02
                        09
                        cond a0 01 bname 02 a1 2
                        lr cond 08
                            wstr 01 03call _rt_putc03 02
                        09
                        cond a0 01 bname 02 a1 3
                        lr cond 08
                            wstr 01 03call _rt_puts03 02
                        09
                        cond a0 01 bname 02 a1 4
                        lr cond 08
                            wstr 01 03call _rt_puti03 02
                        09
                        cond a0 01 bname 02 a1 5
                        lr cond 08
                            wstr 01 03call _rt_readfile03 02
                        09
                        cond a0 01 bname 02 a1 6
                        lr cond 08
                            wstr 01 03call _rt_readbuf03 02
                        09
                        cond a0 01 bname 02 a1 7
                        lr cond 08
                            wstr 01 03call _rt_fsize03 02
                        09
                        cond a0 01 bname 02 a1 8
                        lr cond 08
                            wstr 01 03call fn_write_file03 02
                        09
                        cond a0 01 bname 02 a1 9
                        lr cond 08
                            wstr 01 03call _rt_slurp03 02
                        09
                        putb 01 10 02
                        tmpv a0 01 num 02 a4 0
                        lr tmpv 08
                            putb 01 9 02
                            wstr 01 03add rsp, 03 02
                            qv1 a0 01 num 02 hh 8
                            wnum 01 qv1 02
                            putb 01 10 02
                        09
                        00 调用结果存回：k-1 是 = 且 k-2 是局部槽，补 mov [rbp-slot],rax
                        00   或 k-1 是 zt 且 k-2 是 = 且 k-3 是局部槽（tz 名 = zt 调用）
                        nv2 a0 0
                        nv3 a0 01 ktok 02 hz 1
                        cond a0 is2 01 nv3 a9 97 a9 48 02
                        lr cond 08
                            nv2 a0 01 ktok 02 hz 2
                        09
                        nv3 a0 01 ktok 02 hz 1
                        cond a0 tokis 01 nv3 a9 03zt03 02
                        lr cond 08
                            nv3 a0 01 ktok 02 hz 2
                            cond a0 is2 01 nv3 a9 97 a9 48 02
                            lr cond 08
                                nv2 a0 01 ktok 02 hz 3
                            09
                        09
                        cond a0 01 nv2 02 a4 0
                        lr cond 08
                            qv1 a0 lookup 01 nv2 02
                            tmpv a0 01 qv1 02 a6 8
                            qv2 a0 01 qv1 02 a5 512
                            tmpv a0 01 tmpv 02 hs 01 qv2 02
                            lr tmpv 08
                                putb 01 9 02
                                wstr 01 03mov [rbp-03 02
                                wnum 01 qv1 02
                                wstr 01 03], rax03 02
                                putb 01 10 02
                            09
                            00 全局左值：push 值 / offset g_名 / pop rcx / mov [rax],rcx
                            lr 01 tmpv 02 a1 0 08
                                qv2 a0 findall 01 nv2 02
                                lr cond 08
                                    qv1 a0 gsize a7 allidx a8
                                    cond a0 01 qv1 02 a1 8
                                    lr cond 08
                                        putb 01 9 02
                                        wstr 01 03push rax03 02
                                        putb 01 10 02
                                        putb 01 9 02
                                        wstr 01 03mov rax, offset g_03 02
                                        mgl 01 nv2 02
                                        putb 01 10 02
                                        putb 01 9 02
                                        wstr 01 03pop rcx03 02
                                        putb 01 10 02
                                        putb 01 9 02
                                        wstr 01 03mov [rax], rcx03 02
                                        putb 01 10 02
                                    09
                                09
                            09
                        09
                        00 跳过整个调用到匹配的 02
                        qv1 a0 01 ktok 02 ht 2
                        ll 08
                            chrv a0 head 01 qv1 02
                            chrv a0 01 chrv 02 hs 255
                            cond a0 01 chrv 02 a1 48
                            lr cond 08
                                chrv a0 bytes 01 qv1 a9 1 02
                                cond a0 01 chrv 02 a1 50
                                lr cond 08 ls 09
                            09
                            idxv a0 qv1
                            qv1 a0 01 qv1 02 ht 1
                        09
                    09
                09
            09
        09
        09

        idxv a0 send
    09
    00 收尾：补最后一个函数的尾声
    wstr 01 03.Lret_03 02
    nv3 a0 01 retv 02
    mgl 01 nv3 02
    wstr 01 03:03 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03mov rsp, rbp03 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03pop rbp03 02
    putb 01 10 02
    putb 01 9 02
    wstr 01 03ret03 02
    putb 01 10 02

    00 ── ts 全局表：输出 .bss/.comm + .data ──
    lr nglob 08
        putb 01 10 02
        putb 01 9 02
        wstr 01 03.section .bss03 02
        putb 01 10 02
        putb 01 9 02
        wstr 01 03.align 403 02
        putb 01 10 02
        idxv a0 0
        ll 01 idxv 02 a3 01 nglob 02 08
            cond a0 ginit a7 idxv a8
            qv2 a0 01 cond 02 a1 0
            lr qv2 08
                putb 01 9 02
                wstr 01 03.comm g_03 02
                nv2 a0 gpos a7 idxv a8
                mgl 01 nv2 02
                wstr 01 03, 03 02
                qv1 a0 gsize a7 idxv a8
                wnum 01 qv1 02
                wstr 01 03, 403 02
                putb 01 10 02
            09
            idxv a0 01 idxv 02 ht 1
        09
        putb 01 10 02
        putb 01 9 02
        wstr 01 03.section .data03 02
        putb 01 10 02
        putb 01 9 02
        wstr 01 03.align 803 02
        putb 01 10 02
        idxv a0 0
        ll 01 idxv 02 a3 01 nglob 02 08
            cond a0 ginit a7 idxv a8
            lr cond 08
                wstr 01 03g_03 02
                nv2 a0 gpos a7 idxv a8
                mgl 01 nv2 02
                wstr 01 03:03 02
                putb 01 10 02
                putb 01 9 02
                wstr 01 03.quad 03 02
                qv1 a0 ginit a7 idxv a8
                wnum 01 qv1 02
                putb 01 10 02
            09
            idxv a0 01 idxv 02 ht 1
        09
    09

    00 ── dd 字符串表：输出 .section .rodata ──
    lr nstr 08
        putb 01 10 02
        putb 01 9 02
        wstr 01 03.section .rodata03 02
        putb 01 10 02
        idxv a0 0
        ll 01 idxv 02 a3 01 nstr 02 08
            wstr 01 03.Lstr03 02
            wnum 01 idxv 02
            wstr 01 03:03 02
            putb 01 10 02
            putb 01 9 02
            wstr 01 03.asciz 03 02
            putb 01 34 02
            nv2 a0 strpos a7 idxv a8
            nv3 a0 slen a7 idxv a8
            qv1 a0 0
            ll 01 qv1 02 a3 01 nv3 02 08
                chrv a0 fh 01 01 nv2 ht qv1 02 02
                chrv a0 01 chrv 02 hs 255
                putb 01 chrv 02
                qv1 a0 01 qv1 02 ht 1
            09
            putb 01 34 02
            putb 01 10 02
            idxv a0 01 idxv 02 ht 1
        09
        putb 01 9 02
        wstr 01 03.section .text03 02
        putb 01 10 02
    09

    puti 01 len 02
    putc 01 32 02
    puti 01 cnt 02
    putc 01 32 02
    qv1 a0 01 8 02
    qv2 a0 eval 01 qv1 02
    puti 01 qv2 02
    putc 01 32 02
    puti 01 olen 02
    putc 01 10 02
    lr 01 badname 02 a1 0 08
        wrfile 01 03新清单999.txt03 a9 outbuf a9 olen 02
    09
    zz 0
09
