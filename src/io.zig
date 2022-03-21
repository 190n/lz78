const std = @import("std");
const File = std.fs.File;
const builtin = @import("builtin");

const FileHeader = @import("./FileHeader.zig").FileHeader;
const magic = @import("./FileHeader.zig").magic;
const endianness = @import("builtin").cpu.arch.endian();

pub fn readHeader(infile: File, header: *FileHeader) !void {
    var buf: FileHeader = undefined;
    const read = try infile.readAll(@ptrCast([*]u8, &buf)[0..@sizeOf(FileHeader)]);
    if (read < @sizeOf(FileHeader)) {
        return error.UnexpectedEOF;
    }

    if (endianness == .Little) {
        std.mem.byteSwapAllFields(FileHeader, &buf);
    }
    header.* = buf;
}

pub fn writeHeader(outfile: File, header: *const FileHeader) !void {
    var h = header.*;
    if (endianness == .Little) {
        std.mem.byteSwapAllFields(FileHeader, &h);
    }

    try outfile.writeAll(@ptrCast([*]u8, &h)[0..@sizeOf(FileHeader)]);
}

test "io.readHeader" {
    var dir = std.testing.tmpDir(.{});
    defer dir.cleanup();
    var file = try dir.dir.createFile("header", .{ .read = true });
    defer file.close();
    try file.writeAll(&[_]u8{0xBA, 0xAD, 0xBA, 0xAC, 0x12, 0x34, 0x00, 0x00});
    var h: FileHeader = undefined;
    try file.seekTo(0);
    try readHeader(file, &h);
    try std.testing.expectEqual(magic, h.magic);
    try std.testing.expectEqual(@as(u16, 0x1234), h.protection);
}

test "io.writeHeader" {
    var dir = std.testing.tmpDir(.{});
    defer dir.cleanup();
    var file = try dir.dir.createFile("header", .{ .read = true });
    defer file.close();
    const h = FileHeader{ .magic = magic, .protection = 0x1234 };
    try writeHeader(file, &h);
    try file.seekTo(0);
    var buf: [@sizeOf(FileHeader)]u8 = undefined;
    const read = try file.readAll(&buf);
    try std.testing.expectEqual(@as(usize, @sizeOf(FileHeader)), read);
    try std.testing.expect(std.mem.eql(u8, &buf, &[_]u8{0xBA, 0xAD, 0xBA, 0xAC, 0x12, 0x34, 0x00, 0x00}));
}
