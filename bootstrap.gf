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

ts 缓冲 = 0
ts 长 = 0
ts 记数 = 0
ts 出长 = 0
ts 槽 = 0
ts 名数 = 0
ts 找索引 = 0
ts else号 = 0
ts 括号深 = 0
ts else栈顶 = 0

tf 位表[20000]
tf 长表[20000]
tf 出区[524288]
tf 名位[2000]
tf 名长[2000]
tf 槽位[2000]
tf 参标[2000]
tf else栈[512]
tf 深栈[512]
tf 型栈[512]
tf 顶栈[512]
00 dd 字符串表：串位=内容在缓冲的起点，串长=内容长度（去掉首尾03）
ts 串数 = 0
tf 串位[1024]
tf 串长[1024]
00 ts 全局表：全位=名字token索引，全大=size*count
ts 全局数 = 0
tf 全位表[256]
tf 全大表[256]
tf 全初[256]

00 ─────────────────────────────────────────
00  基础
00 ─────────────────────────────────────────

tt isws 01 c 02 08
    tz r = 0
    tz q1 = 0
    tz q2 = 0
    tz t = 0
    t = 01 c 02 == 32
    lr t 08 r = 1 09
    t = 01 c 02 == 9
    lr t 08 r = 1 09
    t = 01 c 02 == 10
    lr t 08 r = 1 09
    t = 01 c 02 == 13
    lr t 08 r = 1 09
    zz r
09

tt getb 01 i 02 08
    tz a = 0
    a = 缓冲 ht i
    a = fh 01 a 02
    a = 01 a 02 hs 255
    zz a
09

00 ─────────────────────────────────────────
00  输出区
00 ─────────────────────────────────────────

tt putb 01 c 02 08
    tz p = 0
    p = 出区 ht 出长
    写字 01 p , c 02
    出长 = 01 出长 02 ht 1
    zz 0
09

00 ══════ 表达式求值 ══════
00 求值(k)：求第 k 个记号的值，返回数值
00   纯数字   → 返回数字本身
00   纯变量   → 返回它槽位里存的值
00   找不到   → 返回 0
tt eval 01 k 02 08
    tz q1 = 0
    tz t = 0
    tz L1 = 0
    tz p = 0
    tz c = 0
    tz d = 0
    tz v = 0
    tz r = 0
    tz q2 = 0
    tz 槽 = 0
    tz i = 0
    tz 数 = 0

    00 第一个字节是数字（48~57）就是数字字面量
    c = head 01 k 02
    c = 01 c 02 hs 255
    v = 0
    t = 01 c 02 >= 48
    lr t 08
        t = 01 c 02 <= 57
        lr t 08
            00 逐位累加：数 = 数*10 + (c-48)
            L1 = getlen 01 k 02
            ll 08
                t = 01 i 02 == L1
                lr t 08 ls 09
                q1 = 01 p 02 ht i
                c = bytes 01 k , i 02
                c = 01 c 02 hz 48
                数 = 01 数 02 hh 10
                数 = 01 数 02 ht c
                i = 01 i 02 ht 1
            09
            zz 数
        09
    09

    00 不是数字：当变量名，查槽位
    槽 = lookup 01 k 02
    t = 01 槽 02 == 0
    lr t 08
        zz 0
    09
    00 跨帧读调用者(fn_主)槽位的值：
    00   求值栈帧 sub rsp,96 → rsp+96 = 本帧 rbp；[rbp] = 调用者 rbp
    00   [调用者rbp - 槽] = 目标变量
    p = fr
    p = 01 p 02 ht 96
    v = fh 01 p 02
    p = 01 v 02 hz 槽
    v = fh 01 p 02
    zz v
09

00 取第 k 个记号的第 j 个字节
tt bytes 01 k , j 02 08
    tz p = 0
    tz q = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    q = 01 p 02 ht j
    q = fh 01 q 02
    q = 01 q 02 hs 255
    zz q
09

00 取第 k 个记号的第一个字节
tt head 01 k 02 08
    tz p = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    p = fh 01 p 02
    zz p
09

00 ══════ 槽位表：名字 → rbp 偏移 ══════

00 登记一个名字（k=记号号，槽=rbp偏移）
tt defname 01 k , 槽 02 08
    tz n = 0
    n = 名数
    名位[n] = gettok 01 k 02
    名长[n] = getlen 01 k 02
    槽位[n] = 槽
    参标[n] = 0
    名数 = 01 名数 02 ht 1
    zz 0
09

00 比两个名字是否相同：k=记号号，j=表中下标
tt same 01 k , j 02 08
    tz q1 = 0
    tz q2 = 0
    tz t = 0
    tz p = 0
    tz q = 0
    tz i = 0
    tz a = 0
    tz b = 0
    tz 同 = 0
    tz L1 = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    q = 名位[j]
    q = 01 缓冲 02 ht q
    L1 = 名长[j]
    同 = 0
    00 长度必须相等，否则 n3 会被误判成 n（只比首字节）
    q2 = getlen 01 k 02
    lr 01 q2 02 == 01 L1 02 08
    同 = 1
    ll 08
        t = 01 i 02 == L1
        lr t 08 ls 09
        q1 = 01 q 02 ht i
        a = fh 01 q1 02
        a = 01 a 02 hs 255
        q2 = 01 p 02 ht i
        b = fh 01 q2 02
        b = 01 b 02 hs 255
        lh a b 08 同 = 0 ls 09
        i = 01 i 02 ht 1
    09
    09
    zz 同
09

00 同tok：比较两个 token(k,j) 的内容（都按 token 索引取缓冲位置），用于查全
tt 同tok 01 k , j 02 08
    tz p = 0
    tz q = 0
    tz L1 = 0
    tz i = 0
    tz a = 0
    tz b = 0
    tz t = 0
    tz 同 = 0
    L1 = getlen 01 k 02
    p = gettok 01 k 02
    q = gettok 01 j 02
    p = 01 缓冲 02 ht p
    q = 01 缓冲 02 ht q
    同 = 1
    ll 08
        t = 01 i 02 == L1
        lr t 08 ls 09
        a = fh 01 p 02
        a = 01 a 02 hs 255
        b = fh 01 q 02
        b = 01 b 02 hs 255
        lh a b 08 同 = 0 ls 09
        p = 01 p 02 ht 1
        q = 01 q 02 ht 1
        i = 01 i 02 ht 1
    09
    zz 同
09

00 查名字：返回槽位（正数 8,16,...），找不到返回 0
00   注意：不能返回 -1 —— 无符号比较下 -1 恒大于任何正数，
00   且 puti 不支持负数会把 -1 打成乱码（曾出现 [rbp-w51615]）
tt lookup 01 k 02 08
    tz j = 0
    tz r = 0
    tz q1 = 0
    tz q2 = 0
    tz f = 0
    r = 0
    ll 01 j 02 < 01 名数 02 08
        f = same 01 k , j 02
        lr f 08
            r = 槽位[j]
            找索引 = j
            ls
        09
        j = 01 j 02 ht 1
    09
    zz r
09

00 ── 出数：把数字转成十进制输出（支持 0~999999）──
tt puti 01 v 02 08
    tz d = 0
    tz 有 = 0
    tz t = 0


    有 = 0

    00 十万位
    t = 01 v 02 >= 100000
    lr t 08
        d = 01 v 02 hl 100000
        d = 01 d 02 ht 48
        putb 01 d 02
        v = 01 v 02 hf 100000
        有 = 1
    09

    00 万位
    t = 01 v 02 >= 10000
    lr 01 t hr 有 02 08
        d = 01 v 02 hl 10000
        d = 01 d 02 ht 48
        putb 01 d 02
        v = 01 v 02 hf 10000
        有 = 1
    09

    00 千位
    t = 01 v 02 >= 1000
    lr 01 t hr 有 02 08
        d = 01 v 02 hl 1000
        d = 01 d 02 ht 48
        putb 01 d 02
        v = 01 v 02 hf 1000
        有 = 1
    09

    00 百位
    t = 01 v 02 >= 100
    lr 01 t hr 有 02 08
        d = 01 v 02 hl 100
        d = 01 d 02 ht 48
        putb 01 d 02
        v = 01 v 02 hf 100
        有 = 1
    09

    00 十位
    t = 01 v 02 >= 10
    lr 01 t hr 有 02 08
        d = 01 v 02 hl 10
        d = 01 d 02 ht 48
        putb 01 d 02
        v = 01 v 02 hf 10
    09

    00 个位
    v = 01 v 02 ht 48
        putb 01 v 02
    zz 0
09

tt puts 01 s 02 08
    tz i = 0
    tz c = 0
    tz p = 0
    tz t = 0
    tz q = 0
    p = s
    ll 08
        q = 01 p 02 ht i
        c = fh 01 q 02
        c = 01 c 02 hs 255
        t = 01 c 02 == 0
        lr t 08 ls 09
        putb 01 c 02
        i = 01 i 02 ht 1
    09
    zz 0
09

00 ─────────────────────────────────────────
00  记号表：取位置、取长度、比字符串
00 ─────────────────────────────────────────

tt gettok 01 k 02 08
    tz t = 0
    t = 01 k 02 hh 8
    t = 位表 ht t
    t = fh 01 t 02
    zz t
09

tt getlen 01 k 02 08
    tz t = 0
    t = 01 k 02 hh 8
    t = 长表 ht t
    t = fh 01 t 02
    zz t
09

tt tokis 01 k , s 02 08
    tz t = 0
    tz q1 = 0
    tz q2 = 0
    tz p = 0
    tz i = 0
    tz a = 0
    tz b = 0
    tz 同 = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    同 = 1
    ll 08
        q1 = 01 p 02 ht i
        a = fh 01 q1 02
        a = 01 a 02 hs 255
        q2 = 01 s 02 ht i
        b = fh 01 q2 02
        b = 01 b 02 hs 255
        t = 01 b 02 == 0
        lr t 08 ls 09
        lh a b 08 同 = 0 ls 09
        i = 01 i 02 ht 1
    09
    zz 同
09

tt puttok 01 k 02 08
    tz p = 0
    tz i = 0
    tz c = 0
    tz L = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    L = getlen 01 k 02
    i = 0
    ll 01 i 02 < 01 L 02 08
        c = fh 01 01 p ht i 02 02
        c = 01 c 02 hs 255
        putb 01 c 02
        i = 01 i 02 ht 1
    09
    zz 0
09

00 hex2：输出字节 v 的两位小写十六进制
tt hex2 01 v 02 08
    tz hi = 0
    tz lo = 0
    tz c2 = 0
    hi = 01 v 02 hl 16
    lo = 01 v 02 hf 16
    00 高位
    c2 = 01 hi 02 < 10
    lr c2 08
        putb 01 01 hi 02 ht 48 02
    09
    c2 = 01 hi 02 >= 10
    lr c2 08
        putb 01 01 hi 02 ht 87 02
    09
    00 低位
    c2 = 01 lo 02 < 10
    lr c2 08
        putb 01 01 lo 02 ht 48 02
    09
    c2 = 01 lo 02 >= 10
    lr c2 08
        putb 01 01 lo 02 ht 87 02
    09
    zz 0
09

00 曼：mangle token k 的名字并输出到出区（g_ 由调用方加）
tt 曼 01 k 02 08
    tz p = 0
    tz L = 0
    tz i = 0
    tz v = 0
    tz t = 0
    tz f = 0
    tz 已 = 0
    tz q2 = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    L = getlen 01 k 02
    i = 0
    ll 01 i 02 < 01 L 02 08
        已 = 0
        v = fh 01 01 p ht i 02 02
        v = 01 v 02 hs 255
        t = 01 v 02 >= 97
        lr t 08
            f = 01 v 02 <= 122
            lr f 08
                putb 01 v 02
                已 = 1
            09
        09
        t = 01 已 02 == 0
        lr t 08
            f = 01 v 02 >= 65
            lr f 08
                q2 = 01 v 02 <= 90
                lr q2 08
                    putb 01 v 02
                    已 = 1
                09
            09
        09
        t = 01 已 02 == 0
        lr t 08
            f = 01 v 02 >= 48
            lr f 08
                q2 = 01 v 02 <= 57
                lr q2 08
                    putb 01 v 02
                    已 = 1
                09
            09
        09
        t = 01 已 02 == 0
        lr t 08
            f = 01 v 02 == 95
            lr f 08
                putb 01 v 02
                已 = 1
            09
        09
        t = 01 已 02 == 0
        lr t 08
            putb 01 95 02
            hex2 01 v 02
        09
        i = 01 i 02 ht 1
    09
    zz 0
09
00 查全：查全局表，命中返回 索引+1（>0），未命中返回 0
00   返回 索引+1 而非 索引：索引 0 是合法全局，用 0 表示“没找到”才能判断
ts 全命中 = 0
ts 全索引 = 0
tt 查全 01 k 02 08
    tz j = 0
    tz f2 = 0
    tz n2 = 0
    tz r = 0
    ll 01 j 02 < 01 全局数 02 08
        n2 = 全位表[ j ]
        f2 = 同tok 01 k , n2 02
        lr f2 08
            全索引 = j
            r = 01 j 02 ht 1
            ls
        09
        j = 01 j 02 ht 1
    09
    zz r
09

00 串转数：token k 的十进制文本转数值
tt 串转数 01 k 02 08
    tz p = 0
    tz L = 0
    tz i = 0
    tz v = 0
    tz c3 = 0
    tz t = 0
    tz f = 0
    p = gettok 01 k 02
    p = 01 缓冲 02 ht p
    L = getlen 01 k 02
    i = 0
    ll 01 i 02 < 01 L 02 08
        c3 = fh 01 01 p ht i 02 02
        c3 = 01 c3 02 hs 255
        t = 01 c3 02 >= 48
        lr t 08
            f = 01 c3 02 <= 57
            lr f 08
                v = 01 v 02 hh 10
                c3 = 01 c3 02 hz 48
                v = 01 v 02 ht 01 c3 02
            09
        09
        i = 01 i 02 ht 1
    09
    zz v
09

00 登全局：登记顶层 ts/tf 声明，k=名字token，sz=size*count
tt 登全局 01 k , s2 02 08
    全位表[全局数] = k
    全大表[全局数] = s2
    全局数 = 01 全局数 02 ht 1
    zz 0
09

00 登串：把 token k（形如 03内容03）登记进串表，返回串号
tt 登串 01 k 02 08
    tz p = 0
    tz L = 0
    p = gettok 01 k 02
    L = getlen 01 k 02
    串位[串数] = 01 缓冲 02 ht 01 p ht 2 02
    串长[串数] = 01 L 02 hz 4
    串数 = 01 串数 02 ht 1
    zz 01 串数 02 hz 1
09

00 是名：这个字节是否可作为标识符首字节（小写/大写/_/中文）
tt 是名 01 c 02 08
    tz t = 0
    tz f = 0
    t = 01 c 02 >= 97
    f = 01 c 02 <= 122
    t = 01 t 02 hs 01 f 02
    f = 01 c 02 >= 65
    lr f 08
        f = 01 c 02 <= 90
        t = 01 t 02 hr 01 f 02
    09
    f = 01 c 02 == 95
    t = 01 t 02 hr 01 f 02
    f = 01 c 02 >= 128
    t = 01 t 02 hr 01 f 02
    zz t
09

00 载荷：把一个记号当值载入 rax（数字 / 局部 / 参数 / 全局标量）
tt 载荷 01 n3 02 08
    tz c = 0
    tz t = 0
    tz q1 = 0
    tz f = 0
    c = head 01 n3 02
    c = 01 c 02 hs 255
    t = 01 c 02 >= 48
    q1 = 01 c 02 <= 57
    t = 01 t 02 hs 01 q1 02
    lr t 08
        putb 01 9 02
        puts 01 03mov rax, 03 02
        puttok 01 n3 02
        putb 01 10 02
        zz 0
    09
    q1 = lookup 01 n3 02
    t = 01 q1 02 >= 8
    f = 01 q1 02 <= 512
    t = 01 t 02 hs 01 f 02
    lr t 08
        f = 参标[找索引]
        lr f 08
            putb 01 9 02
            puts 01 03lea rax, [rbp+03 02
            puti 01 q1 02
            puts 01 03]03 02
            putb 01 10 02
        09
        f = 01 f 02 == 0
        lr f 08
            putb 01 9 02
            puts 01 03lea rax, [rbp-03 02
            puti 01 q1 02
            puts 01 03]03 02
            putb 01 10 02
        09
        putb 01 9 02
        puts 01 03mov rax, [rax]03 02
        putb 01 10 02
        zz 0
    09
    putb 01 9 02
    puts 01 03mov rax, offset g_03 02
    曼 01 n3 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03mov rax, [rax]03 02
    putb 01 10 02
    zz 0
09

00 二元运算：约定 rax=右值、栈顶=左值；按 op token 输出指令，结果留在 rax
00   op 首字节 61('=') → cmp+sete；60/62/33 → cmp+setb/setbe/seta/setae/setne
00   op 首字节 104('h') → ht/hz/hh/hl/hf/hs/hr/hd 算术与位运算
tt 二op 01 op 02 08
    tz c = 0
    tz q2 = 0
    tz t = 0
    tz f = 0
    c = head 01 op 02
    c = 01 c 02 hs 255
    q2 = bytes 01 op , 1 02
    putb 01 9 02
    puts 01 03mov rcx, rax03 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03pop rax03 02
    putb 01 10 02
    00 相等
    t = 01 c 02 == 61
    lr t 08
        putb 01 9 02
        puts 01 03cmp rax, rcx03 02
        putb 01 10 02
        putb 01 9 02
        puts 01 03sete al03 02
        putb 01 10 02
        putb 01 9 02
        puts 01 03movzx rax, al03 02
        putb 01 10 02
        zz 0
    09
    00 其它比较
    f = 01 c 02 == 60
    t = 01 c 02 == 62
    f = 01 f 02 hr 01 t 02
    t = 01 c 02 == 33
    f = 01 f 02 hr 01 t 02
    lr f 08
        putb 01 9 02
        puts 01 03cmp rax, rcx03 02
        putb 01 10 02
        putb 01 9 02
        t = 01 c 02 == 60
        f = 01 c 02 == 62
        t = 01 t 02 hr 01 f 02
        lr t 08
            00 比较符已输出 cmp，这里只加 setcc + movzx
            t = 01 c 02 == 60
            lr t 08
                lr 01 q2 02 == 61 08 puts 01 03setbe al03 02 09
                lr 01 q2 02 == 0 08 puts 01 03setb al03 02 09
            09
            t = 01 c 02 == 62
            lr t 08
                lr 01 q2 02 == 61 08 puts 01 03setae al03 02 09
                lr 01 q2 02 == 0 08 puts 01 03seta al03 02 09
            09
        lr 01 t 02 == 0 08
            puts 01 03setne al03 02
        09
        09
        putb 01 10 02
        putb 01 9 02
        puts 01 03movzx rax, al03 02
        putb 01 10 02
        zz 0
    09
    00 算术与位运算
    t = 01 c 02 == 104
    lr t 08
        lr 01 q2 02 == 116 08
            putb 01 9 02
            puts 01 03add rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 == 122 08
            putb 01 9 02
            puts 01 03sub rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 == 104 08
            putb 01 9 02
            puts 01 03imul rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 == 115 08
            putb 01 9 02
            puts 01 03and rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 == 114 08
            putb 01 9 02
            puts 01 03or rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        lr 01 q2 02 == 100 08
            putb 01 9 02
            puts 01 03xor rax, rcx03 02
            putb 01 10 02
            zz 0
        09
        00 hl 除法 / hf 取模：xor rdx,rdx; div rcx
        f = 01 q2 02 == 108
        lr f 08
            putb 01 9 02
            puts 01 03xor rdx, rdx03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03div rcx03 02
            putb 01 10 02
            zz 0
        09
        f = 01 q2 02 == 102
        lr f 08
            putb 01 9 02
            puts 01 03xor rdx, rdx03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03div rcx03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03mov rax, rdx03 02
            putb 01 10 02
            zz 0
        09
    09
    00 兜底：什么都不是，当加法（不静默吞掉）
    putb 01 9 02
    puts 01 03add rax, rcx03 02
    putb 01 10 02
    zz 0
09

00 ─────────────────────────────────────────
00  主
00 ─────────────────────────────────────────

tt main 01 参数 02 08
    tz c = 0
    tz i = 0
    tz t = 0
    tz f = 0
    tz f2 = 0
    tz zz已 = 0
    tz 参已 = 0
    tz 跳过 = 0
    tz n = 0
    tz 起 = 0
    tz 有函 = 0
    tz k = 0
    tz n2 = 0
    tz n3 = 0
    tz r = 0
    tz q1 = 0
    tz q2 = 0
    tz v2 = 0
    tz 无load = 0
    tz 内建名 = 0
    tz 自增已 = 0
    tz s2 = 0
    tz 末 = 0
    tz 参位 = 0
    tz fp = 0
    tz 跳过2 = 0
    tz 比较 = 0
    tz 数字左 = 0
    tz 右括 = 0

    t = 载文件 01 参数 02
    长 = 文件长 01 参数 02
    缓冲 = 取缓冲 01 02
    出长 = 0

    00 ── 切词 ──
    i = 0
    n = 0
    ll 01 i 02 < 01 长 02 08
        00 跳空白
        ll 01 i 02 < 01 长 02 08
            c = getb 01 i 02
            f = isws 01 c 02
            lr f 08 i = 01 i 02 ht 1 09
            lh f 1 08 ls 09
        09

        00 到末尾就收工
        t = 01 i 02 >= 01 长 02
        lr t 08 ls 09

        00 是 00 开头的注释行吗：第一个字节是 0，第二个是 0
        c = getb 01 i 02
        f = 01 c 02 == 48
        lr f 08
            n3 = 01 i 02 ht 1
            c = getb 01 n3 02
            f = 01 c 02 == 48
            lr f 08
                00 注释：跳到行尾，然后重来
                ll 01 i 02 < 01 长 02 08
                    c = getb 01 i 02
                    t = 01 c 02 == 10
                    lr t 08 ls 09
                    i = 01 i 02 ht 1
                09
                Zn
            09
        09
        t = 01 i 02 >= 01 长 02
        lr t 08 ls 09

        位表[n] = i
        起 = i
        ll 01 i 02 < 01 长 02 08
            c = getb 01 i 02
            f = isws 01 c 02
            t = 01 f 02 == 1
            lr t 08 ls 09
            00 [ ] 单独切 token（C版词法把标点切 TK_P）
            f = 01 c 02 == 91
            q2 = 01 c 02 == 93
            f = 01 f 02 hr 01 q2 02
            lr f 08
                t = 01 i 02 == 01 起 02
                lr t 08
                    i = 01 i 02 ht 1
                09
                ls
            09
            i = 01 i 02 ht 1
        09
        长表[n] = 01 i 02 hz 01 起 02
        n = 01 n 02 ht 1
    09
    记数 = n

    puts 01 03MARK20403 02
    写串 01 03[VERIFY-MARK]03 02
    写字节 01 10 02
    putb 01 10 02

    00 ══ 生成汇编 ══
    puts 01 03# 由 卦方(Guafang) 编译器 gfx 生成03 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03.intel_syntax noprefix03 02
    putb 01 10 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03.section .text03 02
    putb 01 10 02

    i = 0
    ll 01 i 02 < 01 记数 02 08
        k = i
        自增已 = 0
        比较 = 0

        00 ── 括号深度跟踪 + lr 的 else 标签闭合 ──
        00 记号 09 = 字节 48,57；记号 08 = 字节 48,56
        n2 = getlen 01 k 02
        n3 = bytes 01 k , 0 02
        q1 = bytes 01 k , 1 02
        f = 01 n2 02 == 2
        lr f 08
            f = 01 n3 02 == 48
            lr f 08
                00 遇 09：若栈顶深度 == 当前深度-1，则这是个 lr 块的收尾
                f = 01 q1 02 == 57
                lr f 08
                    f = 01 else栈顶 02 > 0
                    lr f 08
                        n2 = 01 括号深 02 hz 1
                        n3 = 深栈[else栈顶]
                        f = 01 n2 02 hz 01 n3 02
                        f = 01 f 02 == 0
                        lr f 08
                            n3 = 型栈[else栈顶]
                            00 型1=lr：输出 .LelseN:
                            f = 01 n3 02 == 1
                            lr f 08
                                puts 01 03.Lelse03 02
                                n2 = else栈[else栈顶]
                                puti 01 n2 02
                                puts 01 03:03 02
                                putb 01 10 02
                            09
                            00 型2=ll无限：jmp .LltopT + .LlendN:
                            f = 01 n3 02 == 2
                            lr f 08
                                putb 01 9 02
                                puts 01 03jmp .Lltop03 02
                                n2 = 顶栈[else栈顶]
                                puti 01 n2 02
                                putb 01 10 02
                                puts 01 03.Llend03 02
                                n2 = else栈[else栈顶]
                                puti 01 n2 02
                                puts 01 03:03 02
                                putb 01 10 02
                            09
                            00 型3=ll条件：jmp .LwtopT + .LwendN:
                            f = 01 n3 02 == 3
                            lr f 08
                                putb 01 9 02
                                puts 01 03jmp .Lwtop03 02
                                n2 = 顶栈[else栈顶]
                                puti 01 n2 02
                                putb 01 10 02
                                puts 01 03.Lwend03 02
                                n2 = else栈[else栈顶]
                                puti 01 n2 02
                                puts 01 03:03 02
                                putb 01 10 02
                            09
                            else栈顶 = 01 else栈顶 02 hz 1
                        09
                    09
                    括号深 = 01 括号深 02 hz 1
                09
                00 遇 08：深度+1
                f = 01 q1 02 == 56
                lr f 08
                    括号深 = 01 括号深 02 ht 1
                09
            09
        09

        00 ls：跳出当前循环 → jmp .LlendN / .LwendN（从栈顶往下找最近循环层）
        f = tokis 01 k , 03ls03 02
        lr f 08
            s2 = else栈顶
            v2 = 0
            ll 08
                f = 01 s2 02 <= 0
                lr f 08 ls 09
                n2 = 型栈[ s2 ]
                f = 01 n2 02 == 2
                q1 = 01 n2 02 == 3
                f = 01 f 02 hr 01 q1 02
                lr f 08
                    v2 = s2
                    ls
                09
                s2 = 01 s2 02 hz 1
            09
            lr v2 08
                n2 = 型栈[ v2 ]
                q1 = else栈[ v2 ]
                f = 01 n2 02 == 2
                lr f 08
                    putb 01 9 02
                    puts 01 03jmp .Llend03 02
                    puti 01 q1 02
                    putb 01 10 02
                09
                f = 01 n2 02 == 3
                lr f 08
                    putb 01 9 02
                    puts 01 03jmp .Lwend03 02
                    puti 01 q1 02
                    putb 01 10 02
                09
            09
        09

        00 Zn：continue —— 跳回最近循环头（型2 → .Lltop，型3 → .Lwtop）
        f = tokis 01 k , 03Zn03 02
        lr f 08
            s2 = else栈顶
            v2 = 0
            ll 08
                f = 01 s2 02 <= 0
                lr f 08 ls 09
                n2 = 型栈[ s2 ]
                f = 01 n2 02 == 2
                q1 = 01 n2 02 == 3
                f = 01 f 02 hr 01 q1 02
                lr f 08
                    v2 = s2
                    ls
                09
                s2 = 01 s2 02 hz 1
            09
            lr v2 08
                n2 = 型栈[ v2 ]
                q1 = 顶栈[ v2 ]
                f = 01 n2 02 == 2
                lr f 08
                    putb 01 9 02
                    puts 01 03jmp .Lltop03 02
                    puti 01 q1 02
                    putb 01 10 02
                09
                f = 01 n2 02 == 3
                lr f 08
                    putb 01 9 02
                    puts 01 03jmp .Lwtop03 02
                    puti 01 q1 02
                    putb 01 10 02
                09
            09
        09

        00 tt 名字 → 补上函数尾声 + .globl + 序言
        f = tokis 01 k , 03tt03 02
        lr f 08
            00 第二个函数起，先补上一个函数的尾声（有函=已见函数数，非0则补）
            lr 有函 08
                puts 01 03.Lret_03 02
                n3 = 01 r 02
                曼 01 n3 02
                puts 01 03:03 02
                putb 01 10 02
                putb 01 9 02
                puts 01 03mov rsp, rbp03 02
                putb 01 10 02
                putb 01 9 02
                puts 01 03pop rbp03 02
                putb 01 10 02
                putb 01 9 02
                puts 01 03ret03 02
                putb 01 10 02
                putb 01 10 02
            09
            r = 01 k 02 ht 1
            有函 = 01 有函 02 ht 1
            putb 01 9 02
            puts 01 03.globl fn_03 02
            n3 = 01 k 02 ht 1
            曼 01 n3 02
            putb 01 10 02
            puts 01 03fn_03 02
            曼 01 n3 02
            puts 01 03:03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03push rbp03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03mov rbp, rsp03 02
            putb 01 10 02
            00 预扫描本函数 tz 数量 → 16 对齐帧大小
            n2 = 01 k 02 ht 1
            q1 = 0
            ll 01 n2 02 < 01 记数 02 08
                t = tokis 01 n2 , 03tt03 02
                lr t 08 ls 09
                t = tokis 01 n2 , 03tz03 02
                lr t 08 q1 = 01 q1 02 ht 1 09
                n2 = 01 n2 02 ht 1
            09
            q2 = 01 q1 02 hh 8
            q2 = 01 q2 02 ht 15
            n2 = 01 q2 02 hf 16
            q2 = 01 q2 02 hz 01 n2 02
            00 帧大小为0时不输出 sub rsp（对齐 C 版 if(framesz)）
            lr q2 08
                putb 01 9 02
                puts 01 03sub rsp, 03 02
                puti 01 q2 02
                putb 01 10 02
            09
            putb 01 9 02
            puts 01 03mov rax, 003 02
            putb 01 10 02
            00 函数开始重置局部名字表（C版 nvars=0），在登记参数之前
            名数 = 0
            槽 = 0
            00 登记参数：扫描 01 名1 , 名2 02，槽=16+8*(np-1-j)（正数），参标=1
            n3 = 01 k 02 ht 2
            q1 = 0
            ll 01 n3 02 < 01 记数 02 08
                c = head 01 n3 02
                c = 01 c 02 hs 255
                t = 01 c 02 == 48
                lr t 08
                    c = bytes 01 n3 , 1 02
                    t = 01 c 02 == 50
                    lr t 08 ls 09
                09
                t = 是名 01 c 02
                lr t 08
                    q1 = 01 q1 02 ht 1
                09
                n3 = 01 n3 02 ht 1
            09
            n3 = 01 k 02 ht 2
            q2 = 0
            ll 01 n3 02 < 01 记数 02 08
                c = head 01 n3 02
                c = 01 c 02 hs 255
                t = 01 c 02 == 48
                lr t 08
                    c = bytes 01 n3 , 1 02
                    t = 01 c 02 == 50
                    lr t 08 ls 09
                09
                t = 是名 01 c 02
                lr t 08
                    n = 01 q1 02 hz 01 q2 02
                    n = 01 n 02 hz 1
                    n = 01 n 02 hh 8
                    n = 01 n 02 ht 16
                    defname 01 n3 , n 02
                    f = 01 名数 02 hz 1
                    参标[f] = 1
                    q2 = 01 q2 02 ht 1
                09
                n3 = 01 n3 02 ht 1
            09
            i = 01 i 02 ht 1
        09

        00 tz 名字 = 数字   四个记号：tz / 名字 / = / 数字
        f = tokis 01 k , 03tz03 02
        lr f 08
            槽 = 01 槽 02 ht 8
            n3 = 01 k 02 ht 1
            defname 01 n3 , 槽 02
            putb 01 9 02
            puts 01 03mov rax, 03 02
            n3 = 01 k 02 ht 3
            puttok 01 n3 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03mov [rbp-03 02
            puti 01 槽 02
            puts 01 03], rax03 02
            putb 01 10 02
            i = 01 i 02 ht 3
        09

        00 目标 = fr → mov rax,rsp / mov [rbp-slot],rax（取栈指针内建）
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        lr f 08
            n3 = 01 k 02 ht 2
            f = tokis 01 n3 , 03fr03 02
            lr f 08
                n2 = lookup 01 k 02
                f = 01 n2 02 >= 8
                q1 = 01 n2 02 <= 512
                f = 01 f 02 hs 01 q1 02
                lr f 08
                    putb 01 9 02
                    puts 01 03mov rax, rsp03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03mov [rbp-03 02
                    puti 01 n2 02
                    puts 01 03], rax03 02
                    putb 01 10 02
                    i = 01 i 02 ht 2
                    自增已 = 1
                09
            09
        09

        00 ── 赋值：目标 = 变量（局部/参数/全局 四种互赋）──
        00 判据：k+1是=，k+2是标识符，k+3 不是运算符/括号/编码
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        q1 = 01 自增已 02 == 0
        f = 01 f 02 hs 01 q1 02
        lr f 08
            n3 = 01 k 02 ht 3
            fp = 0
            fp = getlen 01 n3 02
            c = head 01 n3 02
            c = 01 c 02 hs 255
            跳过2 = 0
            f = 01 fp 02 == 2
            lr f 08
                q1 = 01 c 02 == 104
                q2 = 01 c 02 == 100
                q1 = 01 q1 02 hr 01 q2 02
                q2 = 01 c 02 == 48
                q1 = 01 q1 02 hr 01 q2 02
                跳过2 = 01 q1 02
            09
            q1 = 01 c 02 == 91
            跳过2 = 01 跳过2 02 hr 01 q1 02
            q1 = 01 c 02 == 93
            跳过2 = 01 跳过2 02 hr 01 q1 02
            q1 = 01 c 02 == 60
            跳过2 = 01 跳过2 02 hr 01 q1 02
            q1 = 01 c 02 == 62
            跳过2 = 01 跳过2 02 hr 01 q1 02
            q1 = 01 c 02 == 33
            跳过2 = 01 跳过2 02 hr 01 q1 02
            q1 = 01 c 02 == 61
            跳过2 = 01 跳过2 02 hr 01 q1 02
            f = 01 跳过2 02 == 0
            lr f 08
                n3 = 01 k 02 ht 2
                c = head 01 n3 02
                c = 01 c 02 hs 255
                t = 是名 01 c 02
                lr t 08
                    n2 = lookup 01 k 02
                    q2 = 参标[ 找索引 ]
                    f = 01 n2 02 >= 8
                    q1 = 01 n2 02 <= 512
                    f = 01 f 02 hs 01 q1 02
                    载荷 01 n3 02
                    lr f 08
                        lr q2 08
                            putb 01 9 02
                            puts 01 03mov [rbp+03 02
                            puti 01 n2 02
                            puts 01 03], rax03 02
                            putb 01 10 02
                        09
                        q1 = 01 q2 02 == 0
                        lr q1 08
                            putb 01 9 02
                            puts 01 03mov [rbp-03 02
                            puti 01 n2 02
                            puts 01 03], rax03 02
                            putb 01 10 02
                        09
                    09
                    q1 = 01 f 02 == 0
                    lr q1 08
                        putb 01 9 02
                        puts 01 03push rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov rax, offset g_03 02
                        n3 = 01 k 02
                        曼 01 n3 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03pop rcx03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov [rax], rcx03 02
                        putb 01 10 02
                    09
                    i = 01 i 02 ht 2
                    自增已 = 1
                09
            09
        09

        00 裸二元表达式：局部 = A op B（5 token k..k+4），A/B 为数字或变量，op 为 h* / dh / dl
        00 必须放在"名字=单个数字"之前，否则只剩 A 被存回
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        lr f 08
            n2 = lookup 01 k 02
            f = 01 n2 02 >= 8
            q1 = 01 n2 02 <= 512
            f = 01 f 02 hs 01 q1 02
            lr f 08
                00 判 k+3 是合法二元算子：ht hz hh hl hf hs hr hd / dh dl（hi 之类不算）
                n3 = 01 k 02 ht 3
                c = head 01 n3 02
                c = 01 c 02 hs 255
                q2 = bytes 01 n3 , 1 02
                f2 = 0
                t = 01 c 02 == 104
                lr t 08
                    f = 01 q2 02 == 116
                    q1 = 01 q2 02 == 122
                    f = 01 f 02 hr 01 q1 02
                    q1 = 01 q2 02 == 104
                    f = 01 f 02 hr 01 q1 02
                    q1 = 01 q2 02 == 108
                    f = 01 f 02 hr 01 q1 02
                    q1 = 01 q2 02 == 102
                    f = 01 f 02 hr 01 q1 02
                    q1 = 01 q2 02 == 115
                    f = 01 f 02 hr 01 q1 02
                    q1 = 01 q2 02 == 114
                    f = 01 f 02 hr 01 q1 02
                    q1 = 01 q2 02 == 100
                    f = 01 f 02 hr 01 q1 02
                    f2 = f
                09
                t = 01 c 02 == 100
                lr t 08
                    f = 01 q2 02 == 104
                    q1 = 01 q2 02 == 108
                    f = 01 f 02 hr 01 q1 02
                    f2 = f
                09
                q1 = getlen 01 n3 02
                t = 01 q1 02 == 2
                t = 01 t 02 hs 01 f2 02
                00 左操作数：数字放行；是名字则必须是局部/参数（全局交给专用块）
                n3 = 01 k 02 ht 2
                c = head 01 n3 02
                c = 01 c 02 hs 255
                f2 = 01 c 02 >= 48
                q2 = 01 c 02 <= 57
                f2 = 01 f2 02 hs 01 q2 02
                lr f2 08
                    f2 = 1
                09
                q2 = 01 f2 02 == 0
                lr q2 08
                    q2 = lookup 01 n3 02
                    f = 01 q2 02 >= 8
                    q1 = 01 q2 02 <= 512
                    f2 = 01 f 02 hs 01 q1 02
                09
                t = 01 t 02 hs 01 f2 02
                lr t 08
                    00 右值先求（载荷 直接产出 mov rax），左值 push 后再 二op
                    n3 = 01 k 02 ht 2
                    载荷 01 n3 02
                    putb 01 9 02
                    puts 01 03push rax03 02
                    putb 01 10 02
                    00 右值 k+4；若是 01 X 02 则取 k+5，i 多进 2
                    n3 = 01 k 02 ht 4
                    右括 = 0
                    c = head 01 n3 02
                    c = 01 c 02 hs 255
                    f2 = 01 c 02 == 48
                    lr f2 08
                        q2 = bytes 01 n3 , 1 02
                        f2 = 01 q2 02 == 49
                        lr f2 08
                            n3 = 01 k 02 ht 6
                            q2 = head 01 n3 02
                            q2 = 01 q2 02 hs 255
                            f = 01 q2 02 == 48
                            lr f 08
                                q2 = bytes 01 n3 , 1 02
                                f = 01 q2 02 == 50
                                lr f 08
                                    n3 = 01 k 02 ht 5
                                    右括 = 2
                                09
                            09
                        09
                    09
                    载荷 01 n3 02
                    n3 = 01 k 02 ht 3
                    二op 01 n3 02
                    00 载荷 会改 找索引，这里必须重新 lookup 左值
                    n2 = lookup 01 k 02
                    f = 参标[找索引]
                    lr f 08
                        putb 01 9 02
                        puts 01 03mov [rbp+03 02
                        puti 01 n2 02
                        puts 01 03], rax03 02
                        putb 01 10 02
                    09
                    f = 01 f 02 == 0
                    lr f 08
                        putb 01 9 02
                        puts 01 03mov [rbp-03 02
                        puti 01 n2 02
                        puts 01 03], rax03 02
                        putb 01 10 02
                    09
                    i = 01 i 02 ht 4
                    i = i ht 右括
                    自增已 = 1
                09
            09
        09

        00 赋值：名字 = 单个数字（三个记号 r = 1）
        00 守卫：左值须是局部槽[8,512]，右值须长度1且首字节数字
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        lr f 08
            n2 = lookup 01 k 02
            n3 = 01 k 02 ht 2
            q1 = getlen 01 n3 02
            c = head 01 n3 02
            c = 01 c 02 hs 255
            t = 01 n2 02 >= 8
            f = 01 n2 02 <= 512
            t = 01 t 02 hs 01 f 02
            q2 = 01 q1 02 == 1
            t = 01 t 02 hs 01 q2 02
            f = 01 c 02 >= 48
            q2 = 01 c 02 <= 57
            f = 01 f 02 hs 01 q2 02
            t = 01 t 02 hs 01 f 02
            q2 = 01 自增已 02 == 0
            t = 01 t 02 hs 01 q2 02
            lr t 08
                putb 01 9 02
                puts 01 03mov rax, 03 02
                n3 = 01 k 02 ht 2
                puttok 01 n3 02
                putb 01 10 02
                00 参数(参标=1)存 [rbp+N]，局部(参标=0)存 [rbp-N]
                f = 参标[找索引]
                lr f 08
                    putb 01 9 02
                    puts 01 03mov [rbp+03 02
                    puti 01 n2 02
                    puts 01 03], rax03 02
                    putb 01 10 02
                09
                f = 01 f 02 == 0
                lr f 08
                    putb 01 9 02
                    puts 01 03mov [rbp-03 02
                    puti 01 n2 02
                    puts 01 03], rax03 02
                    putb 01 10 02
                09
                i = 01 i 02 ht 2
            09
            00 全局标量赋值：全名 = 数字（3 token，左值不是局部）
            n3 = 01 k 02 ht 1
            f = tokis 01 n3 , 03=03 02
            lr f 08
                q1 = lookup 01 k 02
                f = 01 q1 02 == 0
                lr f 08
                    t = 查全 01 k 02
                    lr t 08
                        v2 = 全大表[ 全索引 ]
                        t = 01 v2 02 == 8
                        n3 = 01 k 02 ht 2
                        c = head 01 n3 02
                        c = 01 c 02 hs 255
                        f2 = 01 c 02 >= 48
                        q2 = 01 c 02 <= 57
                        f2 = 01 f2 02 hs 01 q2 02
                        00 排除 01..09 编码记号：首字节 '0' 且长度 2
                        q2 = 01 c 02 == 48
                        q1 = getlen 01 n3 02
                        t = 01 q1 02 == 2
                        q2 = 01 q2 02 hs 01 t 02
                        t = 01 q2 02 == 0
                        f2 = 01 f2 02 hs 01 t 02
                        t = 01 v2 02 == 8
                        t = 01 t 02 hs 01 f2 02
                        lr t 08
                            putb 01 9 02
                            puts 01 03mov rax, 03 02
                            n3 = 01 k 02 ht 2
                            puttok 01 n3 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            n3 = 01 k 02
                            曼 01 n3 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov [rax], rcx03 02
                            putb 01 10 02
                            i = 01 i 02 ht 2
                            自增已 = 1
                        09
                    09
                09
            09
            00 全局自增/减：全局名 = 01 全局名 op 数字（k..k+6）
            q1 = 查全 01 k 02
            lr q1 08
                n3 = 01 k 02 ht 2
                c = head 01 n3 02
                c = 01 c 02 hs 255
                t = 01 c 02 == 48
                lr t 08
                    n3 = 01 k 02 ht 5
                    c = head 01 n3 02
                    c = 01 c 02 hs 255
                    f = 01 c 02 == 104
                    lr f 08
                        putb 01 9 02
                        puts 01 03mov rax, offset g_03 02
                        n3 = 01 k 02
                        曼 01 n3 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov rax, [rax]03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03push rax03 02
                        putb 01 10 02
                        n3 = 01 k 02 ht 6
                        putb 01 9 02
                        puts 01 03mov rax, 03 02
                        puttok 01 n3 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov rcx, rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03pop rax03 02
                        putb 01 10 02
                        n3 = 01 k 02 ht 5
                        q2 = bytes 01 n3 , 1 02
                        f = 01 q2 02 == 116
                        lr f 08
                            putb 01 9 02
                            puts 01 03add rax, rcx03 02
                            putb 01 10 02
                        09
                        f = 01 q2 02 == 122
                        lr f 08
                            putb 01 9 02
                            puts 01 03sub rax, rcx03 02
                            putb 01 10 02
                        09
                        putb 01 9 02
                        puts 01 03push rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov rax, offset g_03 02
                        n3 = 01 k 02
                        曼 01 n3 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03pop rcx03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov [rax], rcx03 02
                        putb 01 10 02
                        i = 01 i 02 ht 6
                        自增已 = 1
                    09
                09
            09
            00 局部守卫失败 → 查全局：mov rax,值 / push / mov rax,offset g_名 / pop rcx / mov [rax],rcx
            f = 01 自增已 02 == 0
            lr f 08
            t = 01 n2 02 >= 8
            f = 01 n2 02 <= 512
            t = 01 t 02 hs 01 f 02
            f = 01 t 02 == 0
            lr f 08
                q2 = 查全 01 k 02
                lr q2 08
                    putb 01 9 02
                    puts 01 03mov rax, 03 02
                    n3 = 01 k 02 ht 2
                    puttok 01 n3 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03push rax03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03mov rax, offset g_03 02
                    n3 = 01 k 02
                    曼 01 n3 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03pop rcx03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03mov [rax], rcx03 02
                    putb 01 10 02
                    i = 01 i 02 ht 2
                09
            09
            09
        09

        00 表达式：名字 = (左 op 右)，左=局部变量，右=数字，op 先做 ==
        00 形态：t = 01 b 02 == 32 （k..k+6）
        00 k+2 首字节是 0 且第二字节是 1 → 是 01 括号记号
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        lr f 08
            n3 = 01 k 02 ht 2
            c = head 01 n3 02
            c = 01 c 02 hs 255
            t = 01 c 02 == 48
            lr t 08
                c = bytes 01 n3 , 1 02
                t = 01 c 02 == 49
                lr t 08
                    n2 = lookup 01 k 02
                    f = 01 n2 02 >= 8
                    q2 = 01 n2 02 <= 512
                    f = 01 f 02 hs 01 q2 02
                    lr f 08
                        00 左值 b=k+3：数字→mov rax,N；否则 lea/mov
                        n3 = 01 k 02 ht 3
                        c = head 01 n3 02
                        c = 01 c 02 hs 255
                        数字左 = 0
                        f = 01 c 02 >= 48
                        q2 = 01 c 02 <= 57
                        f = 01 f 02 hs 01 q2 02
                        lr f 08
                            putb 01 9 02
                            puts 01 03mov rax, 03 02
                            puttok 01 n3 02
                            putb 01 10 02
                            数字左 = 1
                        09
                        q2 = 01 数字左 02 == 0
                        lr q2 08
                        n2 = lookup 01 n3 02
                        t = 01 n2 02 >= 8
                        q2 = 01 n2 02 <= 512
                        t = 01 t 02 hs 01 q2 02
                        无load = 0
                        lr t 08
                            00 局部/参数：f=参标判正负
                            f = 参标[找索引]
                            lr f 08
                                putb 01 9 02
                                puts 01 03lea rax, [rbp+03 02
                                puti 01 n2 02
                                puts 01 03]03 02
                                putb 01 10 02
                            09
                            q2 = 01 f 02 == 0
                            lr q2 08
                                putb 01 9 02
                                puts 01 03lea rax, [rbp-03 02
                                puti 01 n2 02
                                puts 01 03]03 02
                                putb 01 10 02
                            09
                        09
                        q2 = 01 t 02 == 0
                        lr q2 08
                            00 全局：mov rax,offset g_X；标量(全大==8)再 load
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            曼 01 n3 02
                            putb 01 10 02
                            n2 = 查全 01 n3 02
                            v2 = 全大表[ 全索引 ]
                            f = 01 v2 02 == 8
                            q2 = 01 f 02 == 0
                            lr q2 08
                                无load = 1
                            09
                        09
                        q2 = 01 无load 02 == 0
                        lr q2 08
                            putb 01 9 02
                            puts 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        09
                        putb 01 9 02
                        puts 01 03push rax03 02
                        putb 01 10 02
                        00 右值 = k+6；若是 01 X 02（k+6='01' 且 k+8='02'）则取 k+7，右括=2
                        n3 = 01 k 02 ht 6
                        c = head 01 n3 02
                        c = 01 c 02 hs 255
                        右括 = 0
                        f = 01 c 02 == 48
                        lr f 08
                            q2 = bytes 01 n3 , 1 02
                            f = 01 q2 02 == 49
                            lr f 08
                                n3 = 01 k 02 ht 8
                                q2 = head 01 n3 02
                                q2 = 01 q2 02 hs 255
                                f2 = 01 q2 02 == 48
                                lr f2 08
                                    q2 = bytes 01 n3 , 1 02
                                    f2 = 01 q2 02 == 50
                                    lr f2 08
                                        n3 = 01 k 02 ht 7
                                        右括 = 2
                                    09
                                09
                            09
                        09
                        c = head 01 n3 02
                        c = 01 c 02 hs 255
                        t = 01 c 02 >= 48
                        q2 = 01 c 02 <= 57
                        t = 01 t 02 hs 01 q2 02
                        lr t 08
                            putb 01 9 02
                            puts 01 03mov rax, 03 02
                            puttok 01 n3 02
                            putb 01 10 02
                        09
                        q2 = 01 t 02 == 0
                        lr q2 08
                            q1 = lookup 01 n3 02
                            t = 01 q1 02 >= 8
                            q2 = 01 q1 02 <= 512
                            t = 01 t 02 hs 01 q2 02
                            q2 = 01 t 02 == 0
                            lr q2 08
                                q2 = 查全 01 n3 02
                            09
                            lr q2 08
                                putb 01 9 02
                                puts 01 03mov rax, offset g_03 02
                                曼 01 n3 02
                                putb 01 10 02
                                putb 01 9 02
                                puts 01 03mov rax, [rax]03 02
                                putb 01 10 02
                            09
                            t = 01 t 02 hr 01 q2 02
                            lr t 08
                                f = 参标[找索引]
                                lr f 08
                                    putb 01 9 02
                                    puts 01 03lea rax, [rbp+03 02
                                    puti 01 q1 02
                                    puts 01 03]03 02
                                    putb 01 10 02
                                09
                                t = 01 f 02 == 0
                                lr t 08
                                    putb 01 9 02
                                    puts 01 03lea rax, [rbp-03 02
                                    puti 01 q1 02
                                    puts 01 03]03 02
                                    putb 01 10 02
                                09
                                putb 01 9 02
                                puts 01 03mov rax, [rax]03 02
                                putb 01 10 02
                            09
                        09
                        00 op=k+5 == 判断（首字节=）
                        n3 = 01 k 02 ht 5
                        c = head 01 n3 02
                        c = 01 c 02 hs 255
                        t = 01 c 02 == 61
                        lr t 08
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03cmp rax, rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03sete al03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03movzx rax, al03 02
                            putb 01 10 02
                        09
                        00 其余比较：< > <= >= != → cmp + setcc + movzx
                        00 判据 op token 首字节：60(<) 62(>) 33(!)；第二字节61(=)区分单双
                        n3 = 01 k 02 ht 5
                        q2 = head 01 n3 02
                        q2 = 01 q2 02 hs 255
                        f = 01 c 02 == 60
                        t = 01 c 02 == 62
                        f = 01 f 02 hr 01 t 02
                        t = 01 c 02 == 33
                        f = 01 f 02 hr 01 t 02
                        lr f 08
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03cmp rax, rcx03 02
                            putb 01 10 02
                            00 判第二字节是否 61(=)
                            n3 = 01 k 02 ht 5
                            v2 = bytes 01 n3 , 1 02
                            f2 = 01 v2 02 == 61
                            00 c==60: < → b / <= → be
                            t = 01 c 02 == 60
                            lr t 08
                                lr f2 08
                                    putb 01 9 02
                                    puts 01 03setbe al03 02
                                    putb 01 10 02
                                09
                                q1 = 01 f2 02 == 0
                                lr q1 08
                                    putb 01 9 02
                                    puts 01 03setb al03 02
                                    putb 01 10 02
                                09
                            09
                            00 c==62: > → a / >= → ae
                            t = 01 c 02 == 62
                            lr t 08
                                lr f2 08
                                    putb 01 9 02
                                    puts 01 03setae al03 02
                                    putb 01 10 02
                                09
                                q1 = 01 f2 02 == 0
                                lr q1 08
                                    putb 01 9 02
                                    puts 01 03seta al03 02
                                    putb 01 10 02
                                09
                            09
                            00 c==33: != → setne
                            t = 01 c 02 == 33
                            lr t 08
                                putb 01 9 02
                                puts 01 03setne al03 02
                                putb 01 10 02
                            09
                            putb 01 9 02
                            puts 01 03movzx rax, al03 02
                            putb 01 10 02
                        09
                        00 算术运算：op token 首字节 h(104) → ht加/hz减/hh乘 等
                        t = 01 c 02 == 104
                        lr t 08
                            n3 = 01 k 02 ht 5
                            q2 = bytes 01 n3 , 1 02
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            00 ht → add
                            f = 01 q2 02 == 116
                            lr f 08
                                putb 01 9 02
                                puts 01 03add rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hz → sub
                            f = 01 q2 02 == 122
                            lr f 08
                                putb 01 9 02
                                puts 01 03sub rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hh → imul
                            f = 01 q2 02 == 104
                            lr f 08
                                putb 01 9 02
                                puts 01 03imul rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hs → and
                            f = 01 q2 02 == 115
                            lr f 08
                                putb 01 9 02
                                puts 01 03and rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hr → or
                            f = 01 q2 02 == 114
                            lr f 08
                                putb 01 9 02
                                puts 01 03or rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hd → xor
                            f = 01 q2 02 == 100
                            lr f 08
                                putb 01 9 02
                                puts 01 03xor rax, rcx03 02
                                putb 01 10 02
                            09
                            00 hl → div (rdx清零)
                            f = 01 q2 02 == 108
                            lr f 08
                                putb 01 9 02
                                puts 01 03xor rdx, rdx03 02
                                putb 01 10 02
                                putb 01 9 02
                                puts 01 03div rcx03 02
                                putb 01 10 02
                            09
                            00 hf → mod (rdx清零, div, 取rdx)
                            f = 01 q2 02 == 102
                            lr f 08
                                putb 01 9 02
                                puts 01 03xor rdx, rdx03 02
                                putb 01 10 02
                                putb 01 9 02
                                puts 01 03div rcx03 02
                                putb 01 10 02
                                putb 01 9 02
                                puts 01 03mov rax, rdx03 02
                                putb 01 10 02
                            09
                        09
                        00 位移运算：op 首字节 d(100) → dh=shl rax,cl / dl=shr rax,cl
                        t = 01 c 02 == 100
                        lr t 08
                            n3 = 01 k 02 ht 5
                            q2 = bytes 01 n3 , 1 02
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            00 dh → shl
                            f = 01 q2 02 == 104
                            lr f 08
                                putb 01 9 02
                                puts 01 03shl rax, cl03 02
                                putb 01 10 02
                            09
                            00 dl → shr
                            f = 01 q2 02 == 108
                            lr f 08
                                putb 01 9 02
                                puts 01 03shr rax, cl03 02
                                putb 01 10 02
                            09
                        09
                        00 存回左值 = k：参数用 [rbp+N]，局部用 [rbp-N]
                        n2 = lookup 01 k 02
                        f = 参标[找索引]
                        lr f 08
                            putb 01 9 02
                            puts 01 03mov [rbp+03 02
                            puti 01 n2 02
                            puts 01 03], rax03 02
                            putb 01 10 02
                        09
                        f = 01 f 02 == 0
                        lr f 08
                            putb 01 9 02
                            puts 01 03mov [rbp-03 02
                            puti 01 n2 02
                            puts 01 03], rax03 02
                            putb 01 10 02
                        09
                        i = 01 i 02 ht 6
                        i = i ht 右括
                    09
                09
            09
        09

        00 裸左值表达式：目标 = 全局 ht 右值（5 token: k..k+4）
        00 C版 lvalue_full：全局 offset+load → push，右值 load → add → 存回局部
        00 判据：k+1 是 =，k 是局部[8,512]，k+2 查全命中(全局)，k+3 是 ht
        00 注意：通用裸二元块已覆盖本形态，靠 自增已 闸门避免重复触发
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        q2 = 01 自增已 02 == 0
        f = 01 f 02 hs 01 q2 02
        lr f 08
            n2 = lookup 01 k 02
            f = 01 n2 02 >= 8
            q1 = 01 n2 02 <= 512
            f = 01 f 02 hs 01 q1 02
            lr f 08
                n3 = 01 k 02 ht 2
                q2 = 查全 01 n3 02
                lr q2 08
                    n3 = 01 k 02 ht 3
                    t = tokis 01 n3 , 03ht03 02
                    lr t 08
                        00 左值全局：offset g_X；标量(全大==8)再 load，数组名仅取地址
                        putb 01 9 02
                        puts 01 03mov rax, offset g_03 02
                        n3 = 01 k 02 ht 2
                        曼 01 n3 02
                        putb 01 10 02
                        q2 = 全大表[ 全索引 ]
                        f = 01 q2 02 == 8
                        lr f 08
                            putb 01 9 02
                            puts 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        putb 01 9 02
                        puts 01 03push rax03 02
                        putb 01 10 02
                        00 右值 k+4：全局→offset+load；否则局部/参数→lea+load
                        n3 = 01 k 02 ht 4
                        q1 = lookup 01 n3 02
                        t = 01 q1 02 >= 8
                        q2 = 01 q1 02 <= 512
                        t = 01 t 02 hs 01 q2 02
                        q2 = 01 t 02 == 0
                        lr q2 08
                            q2 = 查全 01 n3 02
                        09
                        lr q2 08
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            n3 = 01 k 02 ht 4
                            曼 01 n3 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        lr t 08
                            n3 = 01 k 02 ht 4
                            q1 = lookup 01 n3 02
                            f = 参标[找索引]
                            lr f 08
                                putb 01 9 02
                                puts 01 03lea rax, [rbp+03 02
                                puti 01 q1 02
                                puts 01 03]03 02
                                putb 01 10 02
                            09
                            t = 01 f 02 == 0
                            lr t 08
                                putb 01 9 02
                                puts 01 03lea rax, [rbp-03 02
                                puti 01 q1 02
                                puts 01 03]03 02
                                putb 01 10 02
                            09
                            putb 01 9 02
                            puts 01 03mov rax, [rax]03 02
                            putb 01 10 02
                        09
                        00 op: mov rcx,rax / pop rax / add rax,rcx
                        putb 01 9 02
                        puts 01 03mov rcx, rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03pop rax03 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03add rax, rcx03 02
                        putb 01 10 02
                        00 存回目标：mov [rbp-slot], rax
                        n2 = lookup 01 k 02
                        putb 01 9 02
                        puts 01 03mov [rbp-03 02
                        puti 01 n2 02
                        puts 01 03], rax03 02
                        putb 01 10 02
                        i = 01 i 02 ht 4
                    09
                09
            09
        09

        00 ── 数组写：数组名 [ 下标 ] = 右值 ──
        00 C版：基址offset → 下标load → cmp count/jb .Lbok/call _rt_oob/.Lbok:
        00       → imul 8 → push → 基址 → rcx → pop/add → push → 右值 → rcx/pop/mov [rax]
        00 判据：k+1是'['(91)，k+3是']'(93)，k+4是=，k查全命中且全大>8
        n3 = 01 k 02 ht 1
        c = head 01 n3 02
        c = 01 c 02 hs 255
        t = 01 c 02 == 91
        lr t 08
            n3 = 01 k 02 ht 3
            c = head 01 n3 02
            c = 01 c 02 hs 255
            t = 01 c 02 == 93
            lr t 08
                n3 = 01 k 02 ht 4
                f = tokis 01 n3 , 03=03 02
                lr f 08
                    q2 = 查全 01 k 02
                    lr q2 08
                        v2 = 全大表[ 全索引 ]
                        t = 01 v2 02 >= 8
                        lr t 08
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            n3 = 01 k 02
                            曼 01 n3 02
                            putb 01 10 02
                            00 下标 k+2
                            n3 = 01 k 02 ht 2
                            载荷 01 n3 02
                            00 越界检查
                            putb 01 9 02
                            puts 01 03cmp rax, 03 02
                            q1 = 01 v2 02 hl 8
                            puti 01 q1 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03jb .Lbok03 02
                            else号 = 01 else号 02 ht 1
                            q1 = else号
                            puti 01 q1 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03call _rt_oob03 02
                            putb 01 10 02
                            puts 01 03.Lbok03 02
                            puti 01 q1 02
                            puts 01 03:03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03imul rax, 803 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            n3 = 01 k 02
                            曼 01 n3 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03add rax, rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03push rax03 02
                            putb 01 10 02
                            00 右值 k+5：字母→调用或变量；否则载荷
                            末 = 0
                            n3 = 01 k 02 ht 5
                            c = head 01 n3 02
                            c = 01 c 02 hs 255
                            00 括号表达式右值：01 A 02 op 01 B op2 C 02 / 01 A 02 op B
                            f2 = 01 c 02 == 48
                            lr f2 08
                                q1 = bytes 01 n3 , 1 02
                                f2 = 01 q1 02 == 49
                                lr f2 08
                                    n3 = 01 k 02 ht 6
                                    载荷 01 n3 02
                                    putb 01 9 02
                                    puts 01 03push rax03 02
                                    putb 01 10 02
                                    00 B 侧是否也是 01 ... 02
                                    n2 = 01 k 02 ht 9
                                    q2 = head 01 n2 02
                                    q2 = 01 q2 02 hs 255
                                    f = 01 q2 02 == 48
                                    lr f 08
                                        q1 = bytes 01 n2 , 1 02
                                        f = 01 q1 02 == 49
                                    09
                                    lr f 08
                                        n3 = 01 k 02 ht 10
                                        载荷 01 n3 02
                                        putb 01 9 02
                                        puts 01 03push rax03 02
                                        putb 01 10 02
                                        n3 = 01 k 02 ht 12
                                        载荷 01 n3 02
                                        n3 = 01 k 02 ht 11
                                        二op 01 n3 02
                                        n3 = 01 k 02 ht 8
                                        二op 01 n3 02
                                        末 = 01 k 02 ht 13
                                    09
                                    f2 = 01 末 02 == 0
                                    lr f2 08
                                        n3 = 01 k 02 ht 9
                                        载荷 01 n3 02
                                        n3 = 01 k 02 ht 8
                                        二op 01 n3 02
                                        末 = 01 k 02 ht 9
                                    09
                                09
                            09
                            t = 是名 01 c 02
                            lr t 08
                                n2 = 01 k 02 ht 6
                                00 判断 k+6 是不是 01（括号开）：长度2且字节 48/49
                                f = getlen 01 n2 02
                                t = 01 f 02 == 2
                                f2 = 0
                                lr t 08
                                    c = head 01 n2 02
                                    c = 01 c 02 hs 255
                                    f2 = 01 c 02 == 48
                                    lr f2 08
                                        c = bytes 01 n2 , 1 02
                                        f2 = 01 c 02 == 49
                                    09
                                09
                                lr f2 08
                                    n = 0
                                    参位 = 01 k 02 ht 7
                                    ll 08
                                        n3 = 参位
                                        f = getlen 01 n3 02
                                        t = 01 f 02 == 2
                                        f = 0
                                        lr t 08
                                            c = head 01 n3 02
                                            c = 01 c 02 hs 255
                                            q1 = 01 c 02 == 48
                                            lr q1 08
                                                c = bytes 01 n3 , 1 02
                                                f = 01 c 02 == 50
                                            09
                                        09
                                        lr f 08 ls 09
                                        f = tokis 01 n3 , 03,03 02
                                        lr f 08
                                            参位 = 01 参位 02 ht 1
                                        09
                                        n3 = 参位
                                        载荷 01 n3 02
                                        putb 01 9 02
                                        puts 01 03push rax03 02
                                        putb 01 10 02
                                        n = 01 n 02 ht 1
                                        参位 = 01 参位 02 ht 1
                                    09
                                    putb 01 9 02
                                    puts 01 03call fn_03 02
                                    n3 = 01 k 02 ht 5
                                    曼 01 n3 02
                                    putb 01 10 02
                                    t = 01 n 02 > 0
                                    lr t 08
                                        putb 01 9 02
                                        puts 01 03add rsp, 03 02
                                        q1 = 01 n 02 hh 8
                                        puti 01 q1 02
                                        putb 01 10 02
                                    09
                                    末 = 参位
                                09
                            09
                            00 还没发右值（末==0）→ 当变量载荷一次
                            f2 = 01 末 02 == 0
                            lr f2 08
                                载荷 01 n3 02
                                末 = 01 k 02 ht 5
                            09
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov [rax], rcx03 02
                            putb 01 10 02
                            i = 01 末 02
                        09
                    09
                09
            09
        09

        00 ── 数组读：目标 = 全局数组名[下标]（6 token: k..k+5）──
        00 C版：基址offset → 下标load → cmp count/jb .Lbok/call _rt_oob/.Lbok:
        00       → imul 8 → push → 基址 → rcx → pop/add → mov [rax] → 存回目标
        00 判据：k+1是=，k局部，k+2查全命中，k+3首字节'['(91)，k+4下标，k+5']'
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        lr f 08
            n2 = lookup 01 k 02
            f = 01 n2 02 >= 8
            q1 = 01 n2 02 <= 512
            f = 01 f 02 hs 01 q1 02
            lr f 08
                n3 = 01 k 02 ht 3
                c = head 01 n3 02
                c = 01 c 02 hs 255
                t = 01 c 02 == 91
                lr t 08
                    n3 = 01 k 02 ht 2
                    q2 = 查全 01 n3 02
                    lr q2 08
                        v2 = 全大表[ 全索引 ]
                        t = 01 v2 02 >= 8
                        lr t 08
                            00 基址 offset（先输出）
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            n3 = 01 k 02 ht 2
                            曼 01 n3 02
                            putb 01 10 02
                            00 先判表达式下标：01 A op B 02（如 缓冲[ 01 p 02 ht i 02 ]）
                            n3 = 01 k 02 ht 4
                            c = head 01 n3 02
                            c = 01 c 02 hs 255
                            q1 = 01 c 02 == 48
                            t = bytes 01 n3 , 1 02
                            f2 = 01 t 02 == 49
                            q1 = 01 q1 02 hs 01 f2 02
                            lr q1 08
                                00 表达式下标：载荷 A=k+5 / push / 载荷 B=k+7 / 二op(k+6)
                                n3 = 01 k 02 ht 5
                                载荷 01 n3 02
                                putb 01 9 02
                                puts 01 03push rax03 02
                                putb 01 10 02
                                n3 = 01 k 02 ht 7
                                载荷 01 n3 02
                                n3 = 01 k 02 ht 6
                                二op 01 n3 02
                                i = 01 i 02 ht 3
                            09
                            lr 01 q1 02 == 0 08
                            00 下标 k+4：数字→mov rax,N；变量→lea+load
                            n3 = 01 k 02 ht 4
                            c = head 01 n3 02
                            c = 01 c 02 hs 255
                            t = 01 c 02 >= 48
                            q2 = 01 c 02 <= 57
                            t = 01 t 02 hs 01 q2 02
                            lr t 08
                                putb 01 9 02
                                puts 01 03mov rax, 03 02
                                puttok 01 n3 02
                                putb 01 10 02
                            09
                            q2 = 01 t 02 == 0
                            lr q2 08
                                q1 = lookup 01 n3 02
                                f2 = 参标[找索引]
                                lr f2 08
                                    putb 01 9 02
                                    puts 01 03lea rax, [rbp+03 02
                                    puti 01 q1 02
                                    puts 01 03]03 02
                                    putb 01 10 02
                                09
                                t = 01 f2 02 == 0
                                lr t 08
                                    putb 01 9 02
                                    puts 01 03lea rax, [rbp-03 02
                                    puti 01 q1 02
                                    puts 01 03]03 02
                                    putb 01 10 02
                                09
                                putb 01 9 02
                                puts 01 03mov rax, [rax]03 02
                                putb 01 10 02
                            09
                            09
                            00 越界检查：cmp rax,count / jb .LbokN / call _rt_oob / .LbokN:
                            putb 01 9 02
                            puts 01 03cmp rax, 03 02
                            q1 = 01 v2 02 hl 8
                            puti 01 q1 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03jb .Lbok03 02
                            else号 = 01 else号 02 ht 1
                            q1 = else号
                            puti 01 q1 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03call _rt_oob03 02
                            putb 01 10 02
                            puts 01 03.Lbok03 02
                            puti 01 q1 02
                            puts 01 03:03 02
                            putb 01 10 02
                            00 imul 8 / push / 基址 / rcx / pop / add / load / 存回
                            putb 01 9 02
                            puts 01 03imul rax, 803 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03push rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rax, offset g_03 02
                            n3 = 01 k 02 ht 2
                            曼 01 n3 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rcx, rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03pop rax03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03add rax, rcx03 02
                            putb 01 10 02
                            putb 01 9 02
                            puts 01 03mov rax, [rax]03 02
                            putb 01 10 02
                            n2 = lookup 01 k 02
                            putb 01 9 02
                            puts 01 03mov [rbp-03 02
                            puti 01 n2 02
                            puts 01 03], rax03 02
                            putb 01 10 02
                            i = 01 i 02 ht 5
                        09
                    09
                09
            09
        09

        00 zz 值 → 求值进 rax，再 jmp .Lret_
        f = tokis 01 k , 03zz03 02
        lr f 08
            zz已 = 0
            n3 = 01 k 02 ht 1
            c = head 01 n3 02
            c = 01 c 02 hs 255
            q1 = getlen 01 n3 02
            00 字符串 token 03..03：首字节48('0') 且 第二字节51('3') 且 长度>1
            00 必须查第二字节，否则两位数字常量 10/08 会被误判成字符串
            00 用 q2 存第二字节，不覆盖 c（c 后面数字判据还要用）
            q2 = bytes 01 n3 , 1 02
            t = 01 c 02 == 48
            lr t 08
                f = 01 q2 02 == 51
                lr f 08
                    t = 01 q1 02 > 4
                    lr t 08
                        zz已 = 1
                        n2 = 登串 01 n3 02
                        putb 01 9 02
                        puts 01 03mov rax, offset .Lstr03 02
                        puti 01 n2 02
                        putb 01 10 02
                    09
                09
            09
            00 数字 token：长度==1 且首字节 48..57
            f = 01 q1 02 == 1
            q2 = 01 c 02 >= 48
            q1 = 01 c 02 <= 57
            q2 = 01 q2 02 hs 01 q1 02
            f = 01 f 02 hs 01 q2 02
            lr f 08
                00 数字：mov rax, 值
                zz已 = 1
                putb 01 9 02
                puts 01 03mov rax, 03 02
                n3 = 01 k 02 ht 1
                puttok 01 n3 02
                putb 01 10 02
            09
            00 其余按变量：全局查全命中走 offset g_，否则局部/参数（原样）
            q1 = 01 zz已 02 == 0
            lr q1 08
                n2 = lookup 01 n3 02
                q2 = 01 n2 02 >= 8
                f2 = 01 n2 02 <= 512
                q2 = 01 q2 02 hs 01 f2 02
                f2 = 01 q2 02 == 0
                q2 = 0
                lr f2 08
                    q2 = 查全 01 n3 02
                09
                lr q2 08
                    putb 01 9 02
                    puts 01 03mov rax, offset g_03 02
                    n2 = 01 k 02 ht 1
                    曼 01 n2 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03mov rax, [rax]03 02
                    putb 01 10 02
                09
                q2 = 01 f2 02 == 0
                lr q2 08
                    f = 参标[找索引]
                    lr f 08
                        putb 01 9 02
                        puts 01 03lea rax, [rbp+03 02
                        puti 01 n2 02
                        puts 01 03]03 02
                        putb 01 10 02
                    09
                    t = 01 f 02 == 0
                    lr t 08
                        putb 01 9 02
                        puts 01 03lea rax, [rbp-03 02
                        puti 01 n2 02
                        puts 01 03]03 02
                        putb 01 10 02
                    09
                    putb 01 9 02
                    puts 01 03mov rax, [rax]03 02
                    putb 01 10 02
                09
            09
            putb 01 9 02
            puts 01 03jmp .Lret_03 02
            n3 = 01 r 02
            曼 01 n3 02
            putb 01 10 02
        09

        00 lr 条件：k=lr，两种形态
        00   形1 变量：lr 变量 08          → load / test / jz .LelseN
        00   形2 比较：lr 01 A 02 op 01 B 02 08 → 载荷A/push/载荷B/rcx/cmp/setX/movzx/test/jz
        f = tokis 01 k , 03lr03 02
        lr f 08
            n2 = 01 k 02 ht 1
            c = head 01 n2 02
            c = 01 c 02 hs 255
            比较 = 0
            lr 01 c 02 == 48 08 比较 = 1 09
            lr 01 比较 02 == 1 08
                00 条件表达式：lr 01 A op B 02 08  或  lr 01 A 02 op 01 B 02 08
                n3 = 01 k 02 ht 2
                载荷 01 n3 02
                putb 01 9 02
                puts 01 03push rax03 02
                putb 01 10 02
                00 判 k+3 是否为 02 编码 → 决定形态
                n3 = 01 k 02 ht 3
                c = head 01 n3 02
                c = 01 c 02 hs 255
                t = 01 c 02 == 48
                q2 = bytes 01 n3 , 1 02
                f2 = 01 q2 02 == 50
                t = 01 t 02 hs 01 f2 02
                q1 = 01 k 02 ht 3
                n3 = 01 k 02 ht 4
                lr t 08
                    00 形2：A 02 op 01 B 02  → op=k+4, B=k+6
                    q1 = 01 k 02 ht 4
                    n3 = 01 k 02 ht 6
                    i = 01 i 02 ht 7
                09
                lr 01 t 02 == 0 08
                    00 形1：A op B 02 → op=k+3, B=k+4
                    i = 01 i 02 ht 5
                09
                载荷 01 n3 02
                二op 01 q1 02
                putb 01 9 02
                puts 01 03test rax, rax03 02
                putb 01 10 02
            09
            lr 01 比较 02 == 0 08
                00 变量形态
                n3 = lookup 01 n2 02
                putb 01 9 02
                puts 01 03lea rax, [rbp-03 02
                puti 01 n3 02
                puts 01 03]03 02
                putb 01 10 02
                putb 01 9 02
                puts 01 03mov rax, [rax]03 02
                putb 01 10 02
                putb 01 9 02
                puts 01 03test rax, rax03 02
                putb 01 10 02
            09
            比较 = 0
            else号 = 01 else号 02 ht 1
            putb 01 9 02
            puts 01 03jz .Lelse03 02
            puti 01 else号 02
            putb 01 10 02
            else栈顶 = 01 else栈顶 02 ht 1
            else栈[else栈顶] = else号
            深栈[else栈顶] = 括号深
            型栈[else栈顶] = 1
        09

        00 lh/lz A B：比较跳转（lh 不等 / lz 相等）→ 载荷A/push/载荷B/rcx/cmp/je|jne .LelseN
        f = tokis 01 k , 03lh03 02
        lr f 08 比较 = 1 09
        f = tokis 01 k , 03lz03 02
        lr f 08 比较 = 2 09
        lr 比较 08
            n2 = 01 k 02 ht 1
            载荷 01 n2 02
            putb 01 9 02
            puts 01 03push rax03 02
            putb 01 10 02
            n2 = 01 k 02 ht 2
            载荷 01 n2 02
            putb 01 9 02
            puts 01 03mov rcx, rax03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03pop rax03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03cmp rax, rcx03 02
            putb 01 10 02
            else号 = 01 else号 02 ht 1
            putb 01 9 02
            f = 01 比较 02 == 1
            lr f 08
                puts 01 03je .Lelse03 02
            09
            f = 01 比较 02 == 2
            lr f 08
                puts 01 03jne .Lelse03 02
            09
            puti 01 else号 02
            putb 01 10 02
            else栈顶 = 01 else栈顶 02 ht 1
            else栈[else栈顶] = else号
            深栈[else栈顶] = 括号深
            型栈[else栈顶] = 1
            比较 = 0
        09

        00 ll 循环：k=ll，k+1 记号首字节48('0')，第二字节56('8')→无限循环，49('1')→条件循环
        00 连续分配两个编号：top=N，end=N+1（与 C 版 newlab 顺序一致）
        f = tokis 01 k , 03ll03 02
        lr f 08
            n2 = 01 k 02 ht 1
            c = head 01 n2 02
            c = 01 c 02 hs 255
            f = 01 c 02 == 48
            lr f 08
                q2 = bytes 01 n2 , 1 02
                00 无限循环：bytes1==56('8')
                f = 01 q2 02 == 56
                lr f 08
                    else号 = 01 else号 02 ht 1
                    q1 = else号
                    else号 = 01 else号 02 ht 1
                    puts 01 03.Lltop03 02
                    puti 01 q1 02
                    puts 01 03:03 02
                    putb 01 10 02
                    else栈顶 = 01 else栈顶 02 ht 1
                    else栈[else栈顶] = else号
                    顶栈[else栈顶] = q1
                    深栈[else栈顶] = 括号深
                    型栈[else栈顶] = 2
                09
                00 条件循环：bytes1==49('1')，条件 01 变量 02 取 k+2 变量名
                f = 01 q2 02 == 49
                lr f 08
                    else号 = 01 else号 02 ht 1
                    q1 = else号
                    else号 = 01 else号 02 ht 1
                    puts 01 03.Lwtop03 02
                    puti 01 q1 02
                    puts 01 03:03 02
                    putb 01 10 02
                    00 条件：ll 01 A 02 < 01 B 02 08 → 载荷A/push/载荷B/rcx/cmp/setb/movzx/test/jz
                    n3 = 01 k 02 ht 2
                    载荷 01 n3 02
                    00 判 k+4 是否 08：是则单条件 ll 01 A 02 08，否则比较序列
                    n3 = 01 k 02 ht 4
                    c = head 01 n3 02
                    c = 01 c 02 hs 255
                    f2 = 01 c 02 == 48
                    q2 = bytes 01 n3 , 1 02
                    t = 01 q2 02 == 56
                    f2 = 01 f2 02 hs 01 t 02
                    lr f2 08
                        putb 01 9 02
                        puts 01 03test rax, rax03 02
                        putb 01 10 02
                    09
                    lr 01 f2 02 == 0 08
                    putb 01 9 02
                    puts 01 03push rax03 02
                    putb 01 10 02
                    n3 = 01 k 02 ht 6
                    载荷 01 n3 02
                    putb 01 9 02
                    puts 01 03mov rcx, rax03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03pop rax03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03cmp rax, rcx03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03setb al03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03movzx rax, al03 02
                    putb 01 10 02
                    putb 01 9 02
                    puts 01 03test rax, rax03 02
                    putb 01 10 02
                    09
                    putb 01 9 02
                    puts 01 03jz .Lwend03 02
                    puti 01 else号 02
                    putb 01 10 02
                    else栈顶 = 01 else栈顶 02 ht 1
                    else栈[else栈顶] = else号
                    顶栈[else栈顶] = q1
                    深栈[else栈顶] = 括号深
                    型栈[else栈顶] = 3
                09
            09
        09

        00 ── 顶层全局声明 ts 名 = 值 / tf 名[N]（有函==0 时才处理）──
        t = 01 有函 02 == 0
        lr t 08
            n3 = tokis 01 k , 03ts03 02
            lr n3 08
                n2 = 01 k 02 ht 1
                q1 = 8
                登全局 01 n2 , q1 02
                i = 01 k 02 ht 1
                00 可选初值：ts 名 = 数字
                n3 = 01 k 02 ht 2
                f = tokis 01 n3 , 03=03 02
                lr f 08
                    n3 = 01 k 02 ht 3
                    q1 = 串转数 01 n3 02
                    n2 = 01 全局数 02 hz 1
                    全初[n2] = q1
                    i = 01 k 02 ht 3
                09
            09
            n3 = tokis 01 k , 03tf03 02
            lr n3 08
                n2 = 01 k 02 ht 1
                q1 = 01 k 02 ht 3
                q1 = 串转数 01 q1 02
                q1 = 01 q1 02 hh 8
                登全局 01 n2 , q1 02
                i = 01 k 02 ht 3
            09
        09

        00 ── 赋值+内建 fh：目标 = fh 01 addr 02（6 token: k..k+5）──
        00 C版：expr(addr)→mov rax,[rax](解引用)→mov [rbp-slot],rax
        00 判据：k 局部[8,512]，k+1 是 =，k+2 是 fh
        n3 = 01 k 02 ht 1
        f = tokis 01 n3 , 03=03 02
        lr f 08
            n2 = lookup 01 k 02
            f = 01 n2 02 >= 8
            q1 = 01 n2 02 <= 512
            f = 01 f 02 hs 01 q1 02
            lr f 08
                n3 = 01 k 02 ht 2
                t = tokis 01 n3 , 03fh03 02
                lr t 08
                    00 addr 若是 01 A op B 02 形态 → 表达式地址
                    n2 = 01 k 02 ht 4
                    c = head 01 n2 02
                    c = 01 c 02 hs 255
                    t = 01 c 02 == 48
                    q2 = bytes 01 n2 , 1 02
                    f = 01 q2 02 == 49
                    t = 01 t 02 hs 01 f 02
                    lr t 08
                        00 表达式地址：载荷 A=k+5 / push / 载荷 B=k+7 / 二op(k+6)
                        n2 = 01 k 02 ht 5
                        载荷 01 n2 02
                        putb 01 9 02
                        puts 01 03push rax03 02
                        putb 01 10 02
                        n2 = 01 k 02 ht 7
                        载荷 01 n2 02
                        n2 = 01 k 02 ht 6
                        二op 01 n2 02
                        i = 01 i 02 ht 3
                    09
                    lr 01 t 02 == 0 08
                    00 addr = k+4，先查局部（否则查全全局）
                    n2 = 01 k 02 ht 4
                    q1 = lookup 01 n2 02
                    t = 01 q1 02 >= 8
                    q2 = 01 q1 02 <= 512
                    t = 01 t 02 hs 01 q2 02
                    q2 = 01 t 02 == 0
                    lr q2 08
                        q2 = 查全 01 n2 02
                    09
                    lr q2 08
                        putb 01 9 02
                        puts 01 03mov rax, offset g_03 02
                        n3 = 01 k 02 ht 4
                        曼 01 n3 02
                        putb 01 10 02
                        putb 01 9 02
                        puts 01 03mov rax, [rax]03 02
                        putb 01 10 02
                    09
                    t = 01 t 02 hr 01 q2 02
                    lr t 08
                        f2 = 参标[找索引]
                        lr f2 08
                            putb 01 9 02
                            puts 01 03lea rax, [rbp+03 02
                            puti 01 q1 02
                            puts 01 03]03 02
                            putb 01 10 02
                        09
                        t = 01 f2 02 == 0
                        lr t 08
                            putb 01 9 02
                            puts 01 03lea rax, [rbp-03 02
                            puti 01 q1 02
                            puts 01 03]03 02
                            putb 01 10 02
                        09
                        putb 01 9 02
                        puts 01 03mov rax, [rax]03 02
                        putb 01 10 02
                    09
                    09
                    00 fh 核心：再解引用一次
                    putb 01 9 02
                    puts 01 03mov rax, [rax]03 02
                    putb 01 10 02
                    00 存回目标
                    n2 = lookup 01 k 02
                    putb 01 9 02
                    puts 01 03mov [rbp-03 02
                    puti 01 n2 02
                    puts 01 03], rax03 02
                    putb 01 10 02
                    i = 01 i 02 ht 5
                09
            09
        09

        00 ── 函数调用：标识符 + 01( 参数 02 → eval/push + call fn_名 + add rsp ──
        00 排除 ll/lz/lh/fh/fr/lr（它们是"关键字+01括号"形态，会被误认成调用）
        跳过 = 0
        n3 = tokis 01 k , 03ll03 02
        lr n3 08 跳过 = 1 09
        n3 = tokis 01 k , 03lr03 02
        lr n3 08 跳过 = 1 09
        n3 = tokis 01 k , 03lz03 02
        lr n3 08 跳过 = 1 09
        n3 = tokis 01 k , 03lh03 02
        lr n3 08 跳过 = 1 09
        n3 = tokis 01 k , 03fh03 02
        lr n3 08 跳过 = 1 09
        n3 = tokis 01 k , 03fr03 02
        lr n3 08 跳过 = 1 09
        n3 = 01 跳过 02 == 0
        lr n3 08
            00 宿主内建名识别：写字→_rt_sb / 写字节→_rt_putc / 写串→_rt_puts / 写数→_rt_puti
            内建名 = 0
            f = tokis 01 k , 03写字03 02
            lr f 08 内建名 = 1 09
            f = tokis 01 k , 03写字节03 02
            lr f 08 内建名 = 2 09
            f = tokis 01 k , 03写串03 02
            lr f 08 内建名 = 3 09
            f = tokis 01 k , 03写数03 02
            lr f 08 内建名 = 4 09
            n3 = 01 k 02
            c = head 01 n3 02
            c = 01 c 02 hs 255
            t = 是名 01 c 02
            f = 01 内建名 02 > 0
            t = 01 t 02 hr 01 f 02
            lr t 08
                f = 1
                q2 = 01 内建名 02 > 0
                f = 01 f 02 hr 01 q2 02
                lr f 08
                n2 = 01 k 02 ht 1
                c = head 01 n2 02
                c = 01 c 02 hs 255
                f = 01 c 02 == 48
                lr f 08
                    c = bytes 01 n2 , 1 02
                    f = 01 c 02 == 49
                    lr f 08
                        00 确认 k+1 是 01 左括号 → 是函数调用
                        n = 0
                        q1 = 01 k 02 ht 2
                        ll 01 q1 02 < 01 记数 02 08
                            参已 = 0
                            00 右括号 02 → break
                            n3 = head 01 q1 02
                            n3 = 01 n3 02 hs 255
                            f = 01 n3 02 == 48
                            lr f 08
                                t = bytes 01 q1 , 1 02
                                f = 01 t 02 == 50
                                lr f 08 ls 09
                            09
                            00 编码左括号 01 → 参数是表达式 01 A op B 02
                            c = head 01 q1 02
                            c = 01 c 02 hs 255
                            f = 01 c 02 == 48
                            lr f 08
                                t = bytes 01 q1 , 1 02
                                f2 = 01 t 02 == 49
                                lr f2 08
                                    00 q1 本身是 01 → 形A：01 01 A 02 op B 02
                                    00 否则形B：01 A op B 02（q1=A）
                                    n3 = 01 q1 02
                                    c = head 01 n3 02
                                    c = 01 c 02 hs 255
                                    q2 = bytes 01 n3 , 1 02
                                    t = 01 c 02 == 48
                                    f = 01 q2 02 == 49
                                    t = 01 t 02 hs 01 f 02
                                    q2 = 01 q1 02
                                    n3 = 01 q1 02 ht 1
                                    f = 01 q1 02 ht 2
                                    lr t 08
                                        00 形A：A=q1+1 op=q1+3 B=q1+4
                                        q2 = 01 q1 02 ht 1
                                        n3 = 01 q1 02 ht 4
                                        f = 01 q1 02 ht 3
                                        q1 = 01 q1 02 ht 5
                                    09
                                    lr 01 t 02 == 0 08
                                        00 形B：A=q1 op=q1+1 B=q1+2
                                        q1 = 01 q1 02 ht 3
                                    09
                                    载荷 01 q2 02
                                    putb 01 9 02
                                    puts 01 03push rax03 02
                                    putb 01 10 02
                                    载荷 01 n3 02
                                    二op 01 f 02
                                    putb 01 9 02
                                    puts 01 03push rax03 02
                                    putb 01 10 02
                                    n = 01 n 02 ht 1
                                    参已 = 1
                                    Zn
                                09
                            09
                            00 字符串 03..03（首字节48 第二字节51）
                            c = head 01 q1 02
                            c = 01 c 02 hs 255
                            f = 01 c 02 == 48
                            lr f 08
                                q2 = bytes 01 q1 , 1 02
                                f = 01 q2 02 == 51
                                lr f 08
                                    t = getlen 01 q1 02
                                    q2 = 01 t 02 > 4
                                    lr q2 08
                                        n2 = 登串 01 q1 02
                                        putb 01 9 02
                                        puts 01 03mov rax, offset .Lstr03 02
                                        puti 01 n2 02
                                        putb 01 10 02
                                        putb 01 9 02
                                        puts 01 03push rax03 02
                                        putb 01 10 02
                                        n = 01 n 02 ht 1
                                        参已 = 1
                                    09
                                09
                            09
                            00 数字参数：c 是首字节，重新取（字符串分支没改 c 本身）
                            c = head 01 q1 02
                            c = 01 c 02 hs 255
                            q2 = 01 c 02 >= 48
                            f = 01 c 02 <= 57
                            q2 = 01 q2 02 hs 01 f 02
                            t = 01 参已 02 == 0
                            q2 = 01 q2 02 hs 01 t 02
                            t = 01 q2 02 == 1
                            lr t 08
                                putb 01 9 02
                                puts 01 03mov rax, 03 02
                                puttok 01 q1 02
                                putb 01 10 02
                                putb 01 9 02
                                puts 01 03push rax03 02
                                putb 01 10 02
                                n = 01 n 02 ht 1
                            09
                            00 变量参数：首字节 97..122
                            c = head 01 q1 02
                            c = 01 c 02 hs 255
                            t = 是名 01 c 02
                            lr t 08
                                f = 1
                                lr f 08
                                    n2 = lookup 01 q1 02
                                    f = 参标[找索引]
                                    lr f 08
                                        putb 01 9 02
                                        puts 01 03lea rax, [rbp+03 02
                                        puti 01 n2 02
                                        puts 01 03]03 02
                                        putb 01 10 02
                                    09
                                    t = 01 f 02 == 0
                                    lr t 08
                                        putb 01 9 02
                                        puts 01 03lea rax, [rbp-03 02
                                        puti 01 n2 02
                                        puts 01 03]03 02
                                        putb 01 10 02
                                    09
                                    putb 01 9 02
                                    puts 01 03mov rax, [rax]03 02
                                    putb 01 10 02
                                    putb 01 9 02
                                    puts 01 03push rax03 02
                                    putb 01 10 02
                                    n = 01 n 02 ht 1
                                09
                            09
                            q1 = 01 q1 02 ht 1
                        09
                        00 右括号 02 时停（上面循环碰到 02 时三个判据都不满足会 continue，需显式 break）
                        putb 01 9 02
                        f = 01 内建名 02 == 0
                        lr f 08
                            puts 01 03call fn_03 02
                            n2 = 01 k 02
                            曼 01 n2 02
                        09
                        f = 01 内建名 02 == 1
                        lr f 08
                            puts 01 03call _rt_sb03 02
                        09
                        f = 01 内建名 02 == 2
                        lr f 08
                            puts 01 03call _rt_putc03 02
                        09
                        f = 01 内建名 02 == 3
                        lr f 08
                            puts 01 03call _rt_puts03 02
                        09
                        f = 01 内建名 02 == 4
                        lr f 08
                            puts 01 03call _rt_puti03 02
                        09
                        putb 01 10 02
                        t = 01 n 02 > 0
                        lr t 08
                            putb 01 9 02
                            puts 01 03add rsp, 03 02
                            q1 = 01 n 02 hh 8
                            puti 01 q1 02
                            putb 01 10 02
                        09
                        00 调用结果存回：若 k-1 是 = 且 k-2 是局部槽，补 mov [rbp-slot],rax
                        n3 = 01 k 02 hz 1
                        f = tokis 01 n3 , 03=03 02
                        lr f 08
                            n3 = 01 k 02 hz 2
                            q1 = lookup 01 n3 02
                            t = 01 q1 02 >= 8
                            q2 = 01 q1 02 <= 512
                            t = 01 t 02 hs 01 q2 02
                            lr t 08
                                putb 01 9 02
                                puts 01 03mov [rbp-03 02
                                puti 01 q1 02
                                puts 01 03], rax03 02
                                putb 01 10 02
                            09
                        09
                        00 跳过整个调用到匹配的 02
                        q1 = 01 k 02 ht 2
                        ll 08
                            c = head 01 q1 02
                            c = 01 c 02 hs 255
                            f = 01 c 02 == 48
                            lr f 08
                                c = bytes 01 q1 , 1 02
                                f = 01 c 02 == 50
                                lr f 08 ls 09
                            09
                            i = q1
                            q1 = 01 q1 02 ht 1
                        09
                    09
                09
            09
        09
        09

        i = 01 i 02 ht 1
    09
    00 收尾：补最后一个函数的尾声
    puts 01 03.Lret_03 02
    n3 = 01 r 02
    曼 01 n3 02
    puts 01 03:03 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03mov rsp, rbp03 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03pop rbp03 02
    putb 01 10 02
    putb 01 9 02
    puts 01 03ret03 02
    putb 01 10 02

    00 ── dd 字符串表：输出 .section .rodata ──
    lr 串数 08
        putb 01 10 02
        putb 01 9 02
        puts 01 03.section .rodata03 02
        putb 01 10 02
        i = 0
        ll 01 i 02 < 01 串数 02 08
            puts 01 03.Lstr03 02
            puti 01 i 02
            puts 01 03:03 02
            putb 01 10 02
            putb 01 9 02
            puts 01 03.asciz 03 02
            putb 01 34 02
            n2 = 串位[ i ]
            n3 = 串长[ i ]
            q1 = 0
            ll 01 q1 02 < 01 n3 02 08
                c = fh 01 01 n2 ht q1 02 02
                c = 01 c 02 hs 255
                putb 01 c 02
                q1 = 01 q1 02 ht 1
            09
            putb 01 34 02
            putb 01 10 02
            i = 01 i 02 ht 1
        09
        putb 01 9 02
        puts 01 03.section .text03 02
        putb 01 10 02
    09

    00 ── ts 全局表：输出 .bss/.comm + .data ──
    lr 全局数 08
        putb 01 10 02
        putb 01 9 02
        puts 01 03.section .bss03 02
        putb 01 10 02
        putb 01 9 02
        puts 01 03.align 403 02
        putb 01 10 02
        i = 0
        ll 01 i 02 < 01 全局数 02 08
            f = 全初[ i ]
            q2 = 01 f 02 == 0
            lr q2 08
                putb 01 9 02
                puts 01 03.comm g_03 02
                n2 = 全位表[ i ]
                曼 01 n2 02
                puts 01 03, 03 02
                q1 = 全大表[ i ]
                puti 01 q1 02
                puts 01 03, 403 02
                putb 01 10 02
            09
            i = 01 i 02 ht 1
        09
        putb 01 10 02
        putb 01 9 02
        puts 01 03.section .data03 02
        putb 01 10 02
        putb 01 9 02
        puts 01 03.align 803 02
        putb 01 10 02
        i = 0
        ll 01 i 02 < 01 全局数 02 08
            f = 全初[ i ]
            lr f 08
                puts 01 03g_03 02
                n2 = 全位表[ i ]
                曼 01 n2 02
                puts 01 03:03 02
                putb 01 10 02
                putb 01 9 02
                puts 01 03.quad 03 02
                q1 = 全初[ i ]
                puti 01 q1 02
                putb 01 10 02
            09
            i = 01 i 02 ht 1
        09
    09

    写串 01 03诊断:长=03 02
    写数 01 长 02
    写串 01 03 记数=03 02
    写数 01 记数 02
    puts 01 03 求值测=03 02
    q1 = 01 8 02
    q2 = eval 01 q1 02
    puti 01 q2 02
    putb 01 10 02
    写串 01 03 出长=03 02
    写数 01 出长 02
    写字节 01 10 02
    写文件 01 03新清单999.txt03 , 出区 , 出长 02
    zz 0
09
