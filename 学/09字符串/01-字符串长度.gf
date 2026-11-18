00 ══════════════════════════════════════════════════════
00  09 字符串：求长度
00 ══════════════════════════════════════════════════════
00
00  字符串是 0 结尾的字节序列。从头数，遇到 0 就停。
00 ══════════════════════════════════════════════════════

tt slen 01 str 02 08
    tz cnt a0 0
    tz chv a0 0
    tz adr a0 0
    ll 08
        adr a0 01 str 02 ht cnt
        chv a0 fh adr
        chv a0 01 chv 02 hs 255
        lr 01 chv 02 a1 0 08
            ls
        09
        cnt a0 01 cnt 02 ht 1
    09
    zz cnt
09

tt main 01 argv 02 08
    tz res a0 0
    res a0 zt slen 01 argv 02
    st dt res
    st dt 10
    zz 0
09
