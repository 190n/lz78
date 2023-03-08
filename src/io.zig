const std = @import("std");

const Code = @import("./code.zig").Code;
const FileHeader = @import("./FileHeader.zig");

pub const Pair = struct {
    code: Code,
    sym: u8,
};

/// bit_writer is pointer to little-endian std.io.BitWriter
pub fn writePair(bit_writer: anytype, pair: Pair, bit_len: u5) !void {
    try bit_writer.writeBits(pair.code, bit_len);
    try bit_writer.writeBits(pair.sym, 8);
}

/// bit_reader is pointer to little-endian std.io.BitReader
pub fn readPair(bit_reader: anytype, bit_len: u5) !Pair {
    var p = Pair{ .code = 0, .sym = 0 };
    p.code = try bit_reader.readBitsNoEof(Code, bit_len);
    p.sym = try bit_reader.readBitsNoEof(u8, 8);
    return p;
}

pub fn readHeader(reader: anytype) !FileHeader.FileHeader {
    var header = try reader.readStruct(FileHeader.FileHeader);
    header.magic = std.mem.littleToNative(u32, header.magic);
    header.protection = std.mem.littleToNative(u16, header.protection);

    if (header.magic != FileHeader.magic) {
        return error.InvalidMagicNumber;
    }
}

pub fn writeHeader(writer: anytype, _header: FileHeader.FileHeader) !void {
    var header = FileHeader.FileHeader{
        .magic = std.mem.nativeToLittle(u32, _header.magic),
        .protection = std.mem.nativeToLittle(u16, _header.protection),
    };
    try writer.writeAll(std.mem.asBytes(&header));
}

test "writePair" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    var bw = std.io.bitWriter(.Little, list.writer());

    try writePair(&bw, .{ .code = 0b101, .sym = 0xff }, 3);
    try writePair(&bw, .{ .code = 0b11100000110, .sym = 0xff }, 11);
    try bw.flushBits();

    try std.testing.expectEqualSlices(u8, &[_]u8{
        (0b11111 << 3) | 0b101, // 3 bit code + first 5 bits of sym
        (0b00110 << 3) | 0b111, // 5 bits of next code + remaining 3 bits of sym
        (0b11 << 6) | 0b111000, // first 2 bits of sym + remaining 6 bits of code
        0b111111, // rest of sym
    }, list.items);
}

test "readPair" {
    var stream = std.io.fixedBufferStream(&[_]u8{
        0b11111101,
        0b00110111,
        0b11111000,
        0b111111,
    });
    var br = std.io.bitReader(.Little, stream.reader());

    const codes = [_]Code{ 0b101, 0b11100000110 };
    const syms = [_]u8{ 0xff, 0xff };
    const bit_lens = [_]u4{ 3, 11 };
    for (bit_lens, 0..) |bl, i| {
        const pair = try readPair(&br, bl);
        try std.testing.expectEqual(codes[i], pair.code);
        try std.testing.expectEqual(syms[i], pair.sym);
    }
}
