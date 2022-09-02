const std = @import("std");
const mem = std.mem;
const objects = @import("objects.zig");
const buffer = @import("buffer.zig");
const syntax = @import("syntax.zig");

pub const RAX: u8 = 0;
pub const RCX: u8 = 1;
pub const RDX: u8 = 2;
pub const RBX: u8 = 3;
pub const RSP: u8 = 4;
pub const RBP: u8 = 5;
pub const RSI: u8 = 6;
pub const RDI: u8 = 7;

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

pub const Compiler = struct {
    buf: *buffer.Buf,

    pub fn init(buf: *buffer.Buf) Compiler {
        return Compiler{
            .buf = buf,
        };
    }

    fn compile_expr(self: *const Compiler, expr: *const syntax.Expr) buffer.BufError!void {
        switch (expr.*) {
            syntax.ExprType.eint => {
                const val = objects.encode_integer(expr.eint);
                const imm = move_reg_imm32(RAX, val);
                try self.buf.write(imm[0..]);
            },
            syntax.ExprType.ebool => {
                const val = objects.encode_boolean(if (expr.ebool) 1 else 0);
                const imm = move_reg_imm32(RAX, val);
                try self.buf.write(imm[0..]);
            },
            syntax.ExprType.echar => {
                const val = objects.encode_char(expr.echar);
                const imm = move_reg_imm32(RAX, val);
                try self.buf.write(imm[0..]);
            },
            syntax.ExprType.enil => {
                const val = objects.NIL;
                const imm = move_reg_imm32(RAX, val);
                try self.buf.write(imm[0..]);
            },
        }
    }

    pub fn compile_fn(self: *const Compiler, expr: *const syntax.Expr) buffer.BufError!void {
        try self.buf.write(PROLOGUE[0..]);
        try self.compile_expr(expr);
        try self.buf.write(EPILOGUE[0..]);
    }
};
