const std = @import("std");

const io = @import("./io.zig");
const Code = @import("./code.zig");
const TrieNode = @import("./Trie.zig");
const FileHeader = @import("./FileHeader.zig");

pub fn main() !void {
    var bufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
    var bitWriter = std.io.bitWriter(.Little, bufWriter.writer());

    var bufReader = std.io.bufferedReader(std.io.getStdIn().reader());
    var reader = bufReader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var root = TrieNode.createRoot();
    defer root.reset(allocator);

    var curr_node = &root;
    var prev_node: ?*TrieNode = null;

    var prev_sym: u8 = 0;
    var next_code = Code.start;

    try io.writeHeader(bufWriter.writer(), FileHeader.FileHeader{
        .magic = FileHeader.magic,
        .protection = 0o644,
    });

    while (reader.readByte()) |curr_sym| {
        const next_node = curr_node.step(curr_sym);
        if (next_node) |n| {
            prev_node = curr_node;
            curr_node = n;
        } else {
            try io.writePair(&bitWriter, .{
                .code = curr_node.code,
                .sym = curr_sym,
            }, io.bitLength(next_code));
            curr_node.children[curr_sym] = try TrieNode.create(allocator, next_code);
            curr_node = &root;
            next_code += 1;
        }

        if (next_code == Code.max) {
            root.reset(allocator);
            std.debug.assert(arena.reset(.retain_capacity));
            curr_node = &root;
            next_code = Code.start;
        }

        prev_sym = curr_sym;
    } else |e| switch (e) {
        error.EndOfStream => {},
        else => |other| return other,
    }

    if (curr_node != &root) {
        try io.writePair(&bitWriter, .{
            .code = prev_node.?.code,
            .sym = prev_sym,
        }, io.bitLength(next_code));
        next_code = (next_code + 1) % Code.max;
    }

    try io.writePair(&bitWriter, .{
        .code = Code.stop,
        .sym = 0,
    }, io.bitLength(next_code));

    try bitWriter.flushBits();
    try bufWriter.flush();
}
