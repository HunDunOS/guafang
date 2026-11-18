00 复杂测试程序

00 ---- 全局变量 ----
ts g_count a0 0
ts g_sum a0 0

00 ---- 全局数组 ----
tf g_arr a7 16 a8

00 函数0：输出一个字符
tt chu 01 c u64 02  08
    zt putc 01 c 02
 09

00 函数1：加法
tt add 01 a u64 b u64 02  08
    ht a b
    zz
 09

00 函数2：阶乘
tt fact 01 n u64 02  08
    lr n a5 1  08
        zz 1
     09
    tz t a0 n hz 1
    tz r a0 zt fact 01 t 02
    hh n r
    zz
 09

00 函数3：斐波那契
tt fib 01 n u64 02  08
    lr n a5 1  08
        zz n
     09
    tz a a0 zt fib 01 n hz 1 02
    tz b a0 zt fib 01 n hz 2 02
    ht a b
    zz
 09

00 函数4：数组求和
tt sum_arr 01 arr u64 len u64 02  08
    tz i a0 0
    tz s a0 0
    ll  08
        lz i len  08 ls  09
        tz v a0 arr a7 i a8 
        s a0 ht s v
        i a0 ht i 1
     09
    zz s
 09

00 函数5：判断质数
tt is_prime 01 n u64 02  08
    lr n a5 1  08
        zz 0
     09
    tz i a0 2
    ll  08
        lz i ht i a5 n  08 ls  09
        tz r a0 n hf i
        lr r a1 0  08
            zz 0
         09
        i a0 ht i 1
     09
    zz 1
 09

00 函数6：冒泡排序
tt bubble_sort 01 arr u64 len u64 02  08
    tz i a0 0
    ll  08
        lz i len hz 1  08 ls  09
        tz j a0 0
        ll  08
            lz j len hz i hz 1  08 ls  09
            tz a a0 arr a7 j a8 
            tz b a0 arr a7 j ht 1 a8 
            lr a > b  08
                arr a7 j a8  a0 b
                arr a7 j ht 1 a8  a0 a
             09
            j a0 ht j 1
         09
        i a0 ht i 1
     09
    zz 0
 09

00 主函数
tt zhu 01 fname 02  08
00 初始化数组
    tz i a0 0
    ll  08
        lz i 16  08 ls  09
        g_arr a7 i a8  a0 i ht 7
        i a0 ht i 1
     09

00 计算阶乘
    tz f a0 zt fact 01 10 02
    st dd "fact(10) a0 "
    st dt f

00 计算斐波那契
    tz fib10 a0 zt fib 01 10 02
    st dd " 
fib(10) a0 "
    st dt fib10

00 数组求和
    tz s a0 zt sum_arr 01 g_arr a9 16 02
    st dd " 
sum(arr) a0 "
    st dt s

00 判断质数
    tz p a0 zt is_prime 01 97 02
    st dd " 
is_prime(97) a0 "
    st dt p

00 冒泡排序
    zt bubble_sort 01 g_arr a9 16 02
    st dd " 
after sort: "
    tz j a0 0
    ll  08
        lz j 16  08 ls  09
        tz v a0 g_arr a7 j a8 
        st dt v
        zt chu 01 32 02
        j a0 ht j 1
     09

    st dd " 
done!
 "
    zz 0
 09
