const std = @import("std");

const Code = @import("./code.zig");

pub const TrieNode = struct {
    children: [256]?*TrieNode,
    code: Code.Code,

    pub fn create(allocator: std.mem.Allocator, code: Code.Code) !*TrieNode {
        const tn = try allocator.create(TrieNode);
        tn.* = .{
            .children = [_]?*TrieNode{null} ** 256,
            .code = code,
        };
        return tn;
    }

    /// Delete every child of the trie node and then the node itself
    pub fn destroy(self: *TrieNode, allocator: std.mem.Allocator) void {
        self.reset(allocator);
        self.* = undefined;
        allocator.destroy(self);
    }

    /// Delete every child of the trie node
    pub fn reset(self: *TrieNode, allocator: std.mem.Allocator) void {
        for (&self.children) |*child| {
            if (child.*) |ptr| {
                ptr.destroy(allocator);
            }
            child.* = null;
        }
    }

    pub fn createRoot() TrieNode {
        return .{
            .children = [_]?*TrieNode{null} ** 256,
            .code = Code.empty,
        };
    }

    pub fn step(self: *const TrieNode, sym: u8) ?*TrieNode {
        return self.children[sym];
    }
};

test "TrieNode.create" {
    var tn = try TrieNode.create(std.testing.allocator, 50);
    defer tn.destroy(std.testing.allocator);
    try std.testing.expectEqual(@as(u16, 50), tn.code);

    try std.testing.expectEqualSlices(?*TrieNode, &[_]?*TrieNode{null} ** 256, &tn.children);

    for (tn.children) |c| {
        try std.testing.expectEqual(@as(?*TrieNode, null), c);
    }
}

test "TrieNode.createRoot" {
    var root = TrieNode.createRoot();
    try std.testing.expectEqual(Code.empty, root.code);
    try std.testing.expectEqualSlices(?*TrieNode, &[_]?*TrieNode{null} ** 256, &root.children);
}

test "TrieNode.reset" {
    var root = TrieNode.createRoot();
    root.children['a'] = try TrieNode.create(std.testing.allocator, 50);
    root.children['b'] = try TrieNode.create(std.testing.allocator, 60);
    root.reset(std.testing.allocator);
    try std.testing.expectEqual(@as(?*TrieNode, null), root.children['a']);
    try std.testing.expectEqual(@as(?*TrieNode, null), root.children['b']);
}

test "TrieNode.step" {
    var root = TrieNode.createRoot();
    defer root.reset(std.testing.allocator);
    root.children['a'] = try TrieNode.create(std.testing.allocator, 50);
    try std.testing.expectEqual(@as(Code.Code, 50), root.step('a').?.code);
    try std.testing.expectEqual(@as(?*TrieNode, null), root.step('b'));
}
