const std = @import("std");

const io = @import("./io.zig");
const Code = @import("./code.zig");

pub fn main() anyerror!void {
    var bufWrite = std.io.bufferedWriter(std.io.getStdOut().writer());
    var bw = std.io.bitWriter(.Little, bufWrite.writer());
    try bw.writeBits(@as(u16, 0x1234), 16);
    try bufWrite.flush();
}
