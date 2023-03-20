const std = @import("std");

const Code = @import("./code.zig");
const WordTable = @import("./WordTable.zig");
const io = @import("./io.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var bufReader = std.io.bufferedReader(std.io.getStdIn().reader());
    var bitReader = std.io.bitReader(.Little, bufReader.reader());

    _ = try io.readHeader(bufReader.reader());

    var bufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = bufWriter.writer();

    var table = WordTable.init(allocator);
    defer table.deinit();

    var next_code: Code.Code = Code.start;

    while (io.readPair(@TypeOf(bufReader.reader()), &bitReader, io.bitLength(next_code))) |pair| {
        if (pair.code == Code.stop) break;
        const word = try table.insert(pair.code, next_code, pair.sym);
        try writer.writeAll(word);
        next_code += 1;
        if (next_code == Code.max) {
            table.reset();
            std.debug.assert(arena.reset(.retain_capacity));
            next_code = Code.start;
        }
    } else |e| switch (e) {
        error.EndOfStream => {},
        else => |other| return other,
    }

    try bufWriter.flush();
}
