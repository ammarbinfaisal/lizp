const assert = @import("std").debug.assert;

const BitsPerByte = 8;
const WordSize = 8;
const BitsPerWord = WordSize * BitsPerByte;

const IntegerTag: u8 = 0x00;
const IntegerTagMask: u8 = 0x03;
const IntegerShift: u8 = 2;
const IntegerBits = BitsPerWord - IntegerShift;

const IntegerMax: i64 = (1 << (IntegerBits - 1)) - 1;
const IntegerMin: i64 = -(1 << (IntegerBits - 1));

pub fn encode(x: i64) i64 {
    assert(x <= IntegerMax);
    assert(x >= IntegerMin);
    return (x << IntegerShift);
}
