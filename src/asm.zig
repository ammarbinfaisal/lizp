const std = @import("std");
const mem = std.mem;
const objects = @import("objects.zig");
const buffer = @import("buffer.zig");
const syntax = @import("syntax.zig");

const RAX: u8 = 0;
const RCX: u8 = 1;
const RDX: u8 = 2;
const RBX: u8 = 3;
const RSP: u8 = 4;
const RBP: u8 = 5;
const RSI: u8 = 6;
const RDI: u8 = 7;

const AL: u8 = 0;
const CL: u8 = 1;
const DL: u8 = 2;
const BL: u8 = 3;
const AH: u8 = 4;
const CH: u8 = 5;
const DH: u8 = 6;
const BH: u8 = 7;

const Cond = enum(u8) {
    Overflow = 0,
    NotOverflow,
    Below,
    Carry,
    NotAboveOrEqual,
    AboveOrEqual,
    NotBelow,
    NotCarry,
    Equal,
    Zero,
};

pub const RET = 0xc3;

pub const NOP = 0x90;

const REX_PREFIX = 0x48;

pub const PROLOGUE = [_]u8{
    0x55, // push rbp
    REX_PREFIX, 0x89, 0xe5, // mov rbp, rsp
};

pub const EPILOGUE = [_]u8{
    0x5d, // pop rbp
    RET,
};

pub const Compiler = struct {
    buf: *buffer.Buf,

    pub fn init(buf: *buffer.Buf) Compiler {
        return Compiler{
            .buf = buf,
        };
    }

    fn move_reg_imm32(self: *const Compiler, reg: u8, src: i64) buffer.BufError!void {
        const src_bytes = mem.asBytes(&src);
        const res = [_]u8{ REX_PREFIX, 0xc7, 0xc0 + reg, src_bytes[0], src_bytes[1], src_bytes[2], src_bytes[3] };
        try self.buf.write(res[0..]);
    }

    fn emit_add_reg_imm32(self: *const Compiler, reg: u8, src: i64) buffer.BufError!void {
        const src_bytes = mem.asBytes(&src);
        try self.buf.writeByte(REX_PREFIX);
        if (reg == RAX) {
            try self.buf.writeByte(0x05);
        } else {
            try self.buf.writeByte(0x81);
            try self.buf.writeByte(0xc0 + reg);
        }
        try self.buf.writeByte(src_bytes[0]);
        try self.buf.writeByte(src_bytes[1]);
        try self.buf.writeByte(src_bytes[2]);
        try self.buf.writeByte(src_bytes[3]);
    }

    fn emit_shl_reg_imm8(self: *const Compiler, reg: u8, src: u8) buffer.BufError!void {
        try self.buf.writeByte(REX_PREFIX);
        try self.buf.writeByte(0xc1);
        try self.buf.writeByte(0xe0 + reg);
        try self.buf.writeByte(src);
    }

    fn emit_shr_reg_imm8(self: *const Compiler, reg: u8, src: u8) buffer.BufError!void {
        try self.buf.writeByte(REX_PREFIX);
        try self.buf.writeByte(0xc1);
        try self.buf.writeByte(0xe8 + reg);
        try self.buf.writeByte(src);
    }

    fn emit_or_reg_imm8(self: *const Compiler, reg: u8, tag: u8) buffer.BufError!void {
        try self.buf.writeByte(REX_PREFIX);
        try self.buf.writeByte(0x83);
        try self.buf.writeByte(0xc8 + reg);
        try self.buf.writeByte(tag);
    }

    fn emit_and_reg_imm8(self: *const Compiler, reg: u8, tag: u8) buffer.BufError!void {
        try self.buf.writeByte(REX_PREFIX);
        try self.buf.writeByte(0x83);
        try self.buf.writeByte(0xe0 + reg);
        try self.buf.writeByte(tag);
    }

    fn emit_cmp_reg_imm32(self: *const Compiler, reg: u8, src: i64) buffer.BufError!void {
        const src_bytes = mem.asBytes(&src);
        try self.buf.writeByte(REX_PREFIX);
        if (reg == RAX) {
            try self.buf.writeByte(0x3d);
        } else {
            try self.buf.writeByte(0x81);
            try self.buf.writeByte(0xf8 + reg);
        }
        try self.buf.writeByte(src_bytes[0]);
        try self.buf.writeByte(src_bytes[1]);
        try self.buf.writeByte(src_bytes[2]);
        try self.buf.writeByte(src_bytes[3]);
    }

    fn emit_setcc_imm8(self: *const Compiler, cond: Cond, dst: u8) buffer.BufError!void {
        try self.buf.writeByte(0x0f);
        try self.buf.writeByte(0x90 + @enumToInt(cond));
        try self.buf.writeByte(0xc0 + dst);
    }

    fn emit_compare_imm32(self: *const Compiler, value: i64) buffer.BufError!void {
        try self.emit_cmp_reg_imm32(RAX, value);
    }

    fn compile_expr(self: *const Compiler, expr: *const syntax.Expr) buffer.BufError!void {
        switch (expr.*) {
            syntax.ExprType.eint => {
                const val = objects.encode_integer(expr.eint);
                try self.move_reg_imm32(RAX, val);
            },
            syntax.ExprType.ebool => {
                const val = objects.encode_boolean(if (expr.ebool) 1 else 0);
                try self.move_reg_imm32(RAX, val);
            },
            syntax.ExprType.echar => {
                const val = objects.encode_char(expr.echar);
                try self.move_reg_imm32(RAX, val);
            },
            syntax.ExprType.enil => {
                const val = objects.NIL;
                try self.move_reg_imm32(RAX, val);
            },
            syntax.ExprType.econs => {
                try self.compile_call(expr.econs);
            },
            syntax.ExprType.esymbol => unreachable
        }
    }

    fn compile_call(self: *const Compiler, call: *const syntax.Cons) buffer.BufError!void {
        switch (call.car.*) {
            syntax.ExprType.esymbol => {
                const sym = call.car.esymbol;
                if (mem.eql(u8, sym, "add1")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_add_reg_imm32(RAX, 1);
                } else if (mem.eql(u8, sym, "sub1")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_add_reg_imm32(RAX, -1);
                } else if (mem.eql(u8, sym, "integer->char")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_shl_reg_imm8(RAX, objects.CharShift - objects.IntegerShift);
                    try self.emit_or_reg_imm8(RAX, objects.CharTag);
                } else if (mem.eql(u8, sym, "char->integer")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_shr_reg_imm8(RAX, objects.CharShift - objects.IntegerShift);
                } else if (mem.eql(u8, sym, "integer?")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_and_reg_imm8(RAX, objects.ImmediateTagMask);
                    try self.emit_cmp_reg_imm32(RAX, objects.IntegerTag);
                    try self.emit_setcc_imm8(Cond.Equal, RAX);
                    try self.emit_and_reg_imm8(RAX, 1);
                } else if (mem.eql(u8, sym, "char?")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_and_reg_imm8(RAX, objects.ImmediateTagMask);
                    try self.emit_cmp_reg_imm32(RAX, objects.CharTag);
                    try self.emit_setcc_imm8(Cond.Equal, RAX);
                    try self.emit_and_reg_imm8(RAX, 1);
                } else if (mem.eql(u8, sym, "boolean?")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_and_reg_imm8(RAX, objects.ImmediateTagMask);
                    try self.emit_cmp_reg_imm32(RAX, objects.BoolTag);
                    try self.emit_setcc_imm8(Cond.Equal, RAX);
                    try self.emit_and_reg_imm8(RAX, 1);
                } else if (mem.eql(u8, sym, "nil?")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_cmp_reg_imm32(RAX, objects.NIL);
                    try self.emit_setcc_imm8(Cond.Equal, RAX);
                    try self.emit_and_reg_imm8(RAX, 1);
                } else if (mem.eql(u8, sym, "not")) {
                    try self.compile_expr(call.cdr.econs.car);
                    try self.emit_cmp_reg_imm32(RAX, objects.FALSE);
                }
            },
            else => unreachable,
        }
    }

    pub fn compile_fn(self: *const Compiler, expr: *const syntax.Expr) buffer.BufError!void {
        try self.buf.write(PROLOGUE[0..]);
        try self.compile_expr(expr);
        try self.buf.write(EPILOGUE[0..]);
    }
};
