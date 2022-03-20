const std = @import("std");

pub fn storeBigEndian(comptime T: type, dest: [*]u8, src: T) void {
    comptime var i = 0;
    const bits = @typeInfo(@TypeOf(src)).Int.bits;
    if (bits % 8 != 0) {
        @compileError("Source argument to storeBigEndian must be a whole number of bytes");
    }
    const bytes = bits / 8;
    inline while (i < bytes) : (i += 1) {
        dest[bytes - i - 1] = @intCast(u8, (src & (0xff << (i * 8))) >> (i * 8));
    }
}

const expect = std.testing.expect;

test "storeBigEndian" {
    var byte: [1]u8 = undefined;
    var two: [2]u8 = undefined;
    var four: [4]u8 = undefined;
    var eight: [8]u8 = undefined;

    storeBigEndian(u8, &byte, 0xAA);
    storeBigEndian(u16, &two, 0xAABB);
    storeBigEndian(u32, &four, 0xAABBCCDD);
    storeBigEndian(u64, &eight, 0x0123456789ABCDEF);

    try expect(std.mem.eql(u8, &byte, &[_]u8{0xAA}));
    try expect(std.mem.eql(u8, &two, &[_]u8{0xBB, 0xAA}));
    try expect(std.mem.eql(u8, &four, &[_]u8{0xDD, 0xCC, 0xBB, 0xAA}));
    try expect(std.mem.eql(u8, &eight, &[_]u8{0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01}));
}
