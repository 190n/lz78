const std = @import("std");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;

const ALPHABET = 256;

const Code = u16;

const SpecialCode = enum(Code) {
    stop,
    empty,
    start,
    max = std.math.maxInt(Code),
};

const TrieNode = struct {
    children: [ALPHABET]?*TrieNode,
    code: Code,
    allocator: Allocator,

    fn init(allocator: Allocator, code: Code) !*TrieNode {
        var n = try allocator.create(TrieNode);
        n.* = .{
            .children = [_]?*TrieNode{null} ** ALPHABET,
            .code = code,
            .allocator = allocator,
        };
        return n;
    }

    fn deinit(self: *TrieNode) void {
        self.allocator.destroy(self);
    }
};

fn trieCreate(allocator: Allocator) !*TrieNode {
    return TrieNode.init(allocator, @enumToInt(SpecialCode.empty));
}

test "TrieNode.init" {
    const n = try TrieNode.init(std.testing.allocator, 56);
    defer n.deinit();
    try expectEqual(@as(u16, 56), n.code);
    for (n.children) |c| {
        try expectEqual(@as(?*TrieNode, null), c);
    }
}

test "trieCreate" {
    const n = try trieCreate(std.testing.allocator);
    defer n.deinit();
    try expectEqual(@enumToInt(SpecialCode.empty), n.code);
}
