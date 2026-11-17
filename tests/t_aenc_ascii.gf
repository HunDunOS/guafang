tf tab[10]
tt foo 01 a b 02 08
    tz x = 5
    tab[0] = 7
    lr 01 a 02 == 5 08
        x = tab[0]
    09
    lr 01 b 02 >= 3 08
        x = 12
    09
    zz x
09
