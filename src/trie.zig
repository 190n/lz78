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

    fn create(allocator: Allocator) !*TrieNode {
        return init(allocator, @enumToInt(SpecialCode.empty));
    }

    fn deinit(self: *TrieNode) void {
        self.allocator.destroy(self);
    }

    fn reset(self: *TrieNode) void {
        for (self.children) |c, i| {
            if (c) |node| {
                node.delete();
                self.children[i] = null;
            }
        }
    }

    fn delete(self: *TrieNode) void {
        for (self.children) |c, i| {
            if (c) |node| {
                node.delete();
                self.children[i] = null;
            }
        }

        self.deinit();
    }

    fn step(self: *TrieNode, symbol: u8) ?*TrieNode {
        return self.children[symbol];
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

test "TrieNode.create" {
    const n = try TrieNode.create(std.testing.allocator);
    defer n.deinit();
    try expectEqual(@enumToInt(SpecialCode.empty), n.code);
}

test "TrieNode.reset" {
    const root = try TrieNode.create(std.testing.allocator);
    defer root.deinit();
    root.children['a'] = try TrieNode.init(std.testing.allocator, 'a');
    root.reset();
    try expectEqual(@as(?*TrieNode, null), root.children['a']);
}

test "TrieNode.delete" {
    const root = try TrieNode.create(std.testing.allocator);
    root.children['a'] = try TrieNode.init(std.testing.allocator, 'a');
    root.children['b'] = try TrieNode.init(std.testing.allocator, 'b');
    root.delete();
}

test "TrieNode.step" {
    const root = try TrieNode.create(std.testing.allocator);
    defer root.delete();
    root.children['a'] = try TrieNode.init(std.testing.allocator, 'a');
    root.children['b'] = try TrieNode.init(std.testing.allocator, 'b');
    try expectEqual(root.children['a'], root.step('a'));
    try expectEqual(root.children['b'], root.step('b'));
}
