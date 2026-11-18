00 读文件：输出参数里的前几个字节
tt main 01 argv 02 08
    tz chv a0 0
    tz pos a0 0
    tz adr a0 0
    ll 01 pos 02 a3 5 08
        adr a0 01 argv 02 ht pos
        chv a0 fh adr
        chv a0 01 chv 02 hs 255
        st dt chv
        st dt 32
        pos a0 01 pos 02 ht 1
    09
    st dt 10
    zz 0
09
