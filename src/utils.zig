pub fn next_pow_of_2(n: u32) u32 {
    var m = n - 1;
    m |= m >> 1;
    m |= m >> 2;
    m |= m >> 4;
    m |= m >> 8;
    m |= m >> 16;
    return m + 1;
}
