const std = @import("std");

const Code = @import("./code.zig");
const WordTable = @import("./WordTable.zig");
const io = @import("./io.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var bufReader = std.io.bufferedReader(std.io.getStdIn().reader());
    var bitReader = std.io.bitReader(.Little, bufReader.reader());

    _ = try io.readHeader(bufReader.reader());

    var bufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = bufWriter.writer();

    var table = WordTable.init(allocator);
    defer table.deinit();

    var next_code: Code.Code = Code.start;

    while (io.readPair(&bitReader, io.bitLength(next_code))) |pair| {
        if (pair.code == Code.stop) break;
        const word = try table.insert(pair.code, next_code, pair.sym);
        try writer.writeAll(word);
        next_code += 1;
        if (next_code == Code.max) {
            table.reset();
            next_code = Code.start;
        }
    } else |e| switch (e) {
        error.EndOfStream => {},
        else => |other| return other,
    }

    try bufWriter.flush();
}
