00 多函数：一个加法函数，主函数调用它
tt add 01 a a9 b 02 08
    tz r a0 0
    r a0 01 a 02 ht b
    zz r
09

tt main 01 argv 02 08
    tz x a0 0
    x a0 zt add 01 1 a9 2 02
    st dt x
    st dt 10
    zz 0
09
