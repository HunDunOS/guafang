00 64个指令全部测试程序

00 ---- t类指令 ----
ts g_test a0 0
tf g_arr a7 8 a8
th g_const a0 100
tr g_enum 08 A B 09
tl g_struct 08
    a: u64
    b: u64
09

00 ---- 函数 ----
tt test_func 01 a u64 b u64 02  08
    ht a b
    zz 0
 09

tt zhu 01 fname 02  08
    00 tz 定义变量
    tz x a0 0
    tz y a0 0
    td g_bool a0 1

    00 ---- h类运算 ----
    x a0 ht 1 2
    x a0 hz 5 3
    x a0 hh 2 3
    x a0 hl 10 2
    x a0 hf 10 3
    x a0 hs 12 10
    x a0 hr 12 10
    x a0 hd 12 10

    00 ---- d类数据 ----
    tz num a0 dt 42
    tz null a0 dz 0
    tz shl a0 dh 1 4
    tz shr a0 dl 16 2
    tz not a0 dr 255
    tz str a0 dd "hello"

    00 ---- f类输入 ----
    tz c a0 ft 0
    tz mem a0 fh g_arr
    tz arr a0 ff g_arr 0
    tz ptr a0 fr x
    tz not a0 fd x

    00 ---- s类输出 ----
    st dd "test"
    st dt x
    sd dd "debug"

    00 ---- z类函数 ----
    tz r a0 zt test_func 01 1 a9 2 02
    zz 0
 09
