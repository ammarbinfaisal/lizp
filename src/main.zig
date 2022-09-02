const std = @import("std");
const buffer = @import("buffer.zig");
const assembler = @import("asm.zig");

pub fn main() anyerror!void {
    const mov_int_rax = assembler.move_reg_imm32(assembler.RAX, 0xc001);
    var buf = try buffer.Buf.init(1024);
    try buf.write(assembler.PROLOGUE[0..]);
    try buf.write(mov_int_rax[0..]);
    try buf.write(assembler.EPILOGUE[0..]);
    try buf.make_exec();
    try buf.execute();
    buf.deinit();
    // accessing data would cause an error
    // std.debug.print("{s}", .{buf.data});
}
