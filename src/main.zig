const std = @import("std");
const buffer = @import("buffer.zig");
const assembler = @import("asm.zig");
const syntax = @import("syntax.zig");

pub fn main() anyerror!void {
    var buf = try buffer.Buf.init(1024);
    const compiler = assembler.Compiler.init(&buf);
    const expr: syntax.Expr = .{
        .eint = 0xc001,
    };
    try compiler.compile_fn(&expr);
    try buf.make_exec();
    try buf.execute();
    buf.deinit();
    // accessing data would cause an error
    // std.debug.print("{s}", .{buf.data});
}
