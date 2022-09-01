const std = @import("std");
const os = std.os;
const mprotect = os.mprotect;
const munmap = os.munmap;
const PROT = os.linux.PROT;
const MAP = os.linux.MAP;
const mem = @import("std").mem;
const utils = @import("utils.zig");

const BufState = enum {
    WRITABLE,
    EXECUTABLE,
};

pub const BufError = error{ NotWritable, NotExecutable, OutOfBounds, OutOfMemory, ExecFailed };

pub const Buf = struct {
    len: u64,
    cap: u64,
    data: []u8,
    state: BufState,

    pub fn init(cap: u64) os.MMapError!Buf {
        return Buf{
            .len = 0,
            .cap = cap,
            .data = try os.mmap(
                null,
                1024 * 4,
                PROT.READ | PROT.WRITE | PROT.EXEC,
                MAP.PRIVATE | MAP.ANONYMOUS,
                -1,
                0,
            ),
            .state = BufState.WRITABLE,
        };
    }

    pub fn write(self: *Buf, bytes: []const u8) BufError!void {
        if (self.state != BufState.WRITABLE) return BufError.NotWritable;
        if (self.len + bytes.len > self.cap) return BufError.OutOfMemory;
        std.mem.copy(u8, self.data[self.len..], bytes);
        self.len += bytes.len;
    }
    
    pub fn make_exec(self: *Buf) BufError!void {
        if (self.state != BufState.WRITABLE) return BufError.NotWritable;
        var aligned = mem.alignInSlice(self.data, 4096);

        if (aligned != null) {
            const algnd = aligned.?;
            try mprotect(algnd, PROT.READ | PROT.EXEC) catch BufError.ExecFailed;
        }

        self.state = BufState.EXECUTABLE;
    }

    pub fn execute(self: *Buf) BufError!void {
        if (self.state != BufState.EXECUTABLE) return BufError.NotExecutable;
        const func = @ptrCast(fn () void, self.data[0..self.len]);
        func();
    }

    pub fn at(self: *Buf, index: u64) BufError!u8 {
        if (index >= self.len) return BufError.OutOfBounds;
        return self.data[index];
    }

    pub fn put_at(self: *Buf, index: u64, value: u8) BufError!void {
        if (index >= self.cap) return BufError.OutOfBounds;
        self.data[index] = value;
    }

    fn deinit(self: *Buf) void {
        std.os.munmap(self.data);
        self.data = {};
        self.len = 0;
        self.cap = 0;
    }
};
