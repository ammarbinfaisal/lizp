const std = @import("std");
const mem = std.mem;
const integer = @import("integer.zig");

pub const RAX: u8 = 0;
pub const RBX: u8 = 1;
pub const RCX: u8 = 2;
pub const RDX: u8 = 3;
pub const RSI: u8 = 4;
pub const RDI: u8 = 5;
pub const RBP: u8 = 6;
pub const RSP: u8 = 7;

pub const RET = 0xc3;

pub const NOP = 0x90;

pub const PROLOGUE = [_]u8{
    0x55, // push rbp
    0x48, 0x89, 0xe5, // mov rbp, rsp
};

pub const EPILOGUE = [_]u8{
    0x5d, // pop rbp
    RET,
};

const REX_PREFIX = 0x48;

pub fn move_reg_imm32(reg: u8, src: i64) [7]u8 {
    const src_bytes = mem.asBytes(&src);
    const res = [_]u8{ REX_PREFIX, 0xc7, 0xc0 + reg, src_bytes[0], src_bytes[1], src_bytes[2], src_bytes[3] };
    return res;
}
