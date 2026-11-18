00 参数：读取命令行第一个参数，输出它的首字节
tt main 01 argv 02 08
    tz chv a0 0
    chv a0 fh argv
    chv a0 01 chv 02 hs 255
    st dt chv
    st dt 10
    zz 0
09
