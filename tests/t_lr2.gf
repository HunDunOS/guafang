tt foo 01 a 02 08
    tz t = 0
    tz u = 0
    tz r = 0
    t = 01 a 02 == 32
    lr t 08
        u = 01 a 02 == 9
        lr u 08
            r = 1
        09
        r = 2
    09
    zz r
09
