const std = @import("std");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;

const ALPHABET = 256;

const Code = u16;

const SpecialCode = enum(u16) {
    stop,
    empty,
    start,
    max = @typeInfo(Code).integer.max,
};

const TrieNode = struct {
    children: [ALPHABET]?*TrieNode,
    code: u16,
    allocator: Allocator,

    fn init(allocator: Allocator, code: u16) !*TrieNode {
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

test "TrieNode.init" {
    const n = try TrieNode.init(std.testing.allocator, 56);
    defer n.deinit();
    try expectEqual(@as(u16, 56), n.code);
    for (n.children) |c| {
        try expectEqual(@as(?*TrieNode, null), c);
    }
}
