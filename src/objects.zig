const assert = @import("std").debug.assert;

// High                                                         Low
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00  Integer
// 0000000000000000000000000000000000000000000000000XXXXXXX00001111  Character
// 00000000000000000000000000000000000000000000000000000000X0011111  Boolean
// 0000000000000000000000000000000000000000000000000000000000101111  Nil
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX001  Pair
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX010  Vector
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX011  String
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX101  Symbol
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX110  Closure

const BitsPerByte = 8;
const WordSize = 8;
const BitsPerWord = WordSize * BitsPerByte;

pub const IntegerTag: u8 = 0x00;
pub const IntegerTagMask: u8 = 0x03;
pub const IntegerShift: u8 = 2;
const IntegerBits = BitsPerWord - IntegerShift;

const IntegerMax: i64 = (1 << (IntegerBits - 1)) - 1;
const IntegerMin: i64 = -(1 << (IntegerBits - 1));

pub const ImmediateTagMask: u8 = 0x3f;

pub const CharTag: u8 = 0xf;
pub const CharMask: u8 = 0xff;
pub const CharShift = 8;

pub const BoolTag: u8 = 0x1f;
pub const BoolMask: u8 = 0x80;
pub const BoolShift = 7;

pub const NIL = 0x2f;

pub fn encode_integer(x: i64) i64 {
    assert(x <= IntegerMax);
    assert(x >= IntegerMin);
    return (x << IntegerShift);
}

pub fn decode_integer(x: i64) i64 {
    return (x >> IntegerShift);
}

pub fn is_integer(x: i64) bool {
    return (x & IntegerTagMask) == IntegerTag;
}

pub fn encode_char(x: u8) i64 {
    return (@as(i64, x) << CharShift) | CharTag;
}

pub fn decode_char(x: i64) u8 {
    return (x >> CharShift) & CharMask;
}

pub fn is_char(x: i64) bool {
    return (x & ImmediateTagMask) == CharTag;
}

pub fn encode_boolean(x: i64) i64 {
    return (x << BoolShift) | BoolTag;
}

pub fn decode_boolean(x: i64) bool {
    return (x >> BoolShift) & BoolMask;
}

pub fn is_boolean(x: i64) bool {
    return (x & ImmediateTagMask) == BoolTag;
}

pub const TRUE = encode_boolean(1);
pub const FALSE = encode_boolean(0);
