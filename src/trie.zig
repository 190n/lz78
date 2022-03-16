const std = @import("std");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;

const ALPHABET = 256;

const Code = @import("./code.zig");

const Self = @This();

children: [ALPHABET]?*Self,
code: Code.Code,
allocator: Allocator,

pub fn init(allocator: Allocator, code: Code.Code) !*Self {
    var n = try allocator.create(Self);
    n.* = .{
        .children = [_]?*Self{null} ** ALPHABET,
        .code = code,
        .allocator = allocator,
    };
    return n;
}

pub fn create(allocator: Allocator) !*Self {
    return init(allocator, Code.empty);
}

pub fn deinit(self: *Self) void {
    self.allocator.destroy(self);
}

pub fn reset(self: *Self) void {
    for (self.children) |c, i| {
        if (c) |node| {
            node.delete();
            self.children[i] = null;
        }
    }
}

pub fn delete(self: *Self) void {
    for (self.children) |c, i| {
        if (c) |node| {
            node.delete();
            self.children[i] = null;
        }
    }

    self.deinit();
}

pub fn step(self: *const Self, symbol: u8) ?*Self {
    return self.children[symbol];
}

test "TrieNode.init" {
    const n = try Self.init(std.testing.allocator, 56);
    defer n.deinit();
    try expectEqual(@as(u16, 56), n.code);
    for (n.children) |c| {
        try expectEqual(@as(?*Self, null), c);
    }
}

test "TrieNode.create" {
    const n = try Self.create(std.testing.allocator);
    defer n.deinit();
    try expectEqual(Code.empty, n.code);
}

test "TrieNode.reset" {
    const root = try Self.create(std.testing.allocator);
    defer root.deinit();
    root.children['a'] = try Self.init(std.testing.allocator, 'a');
    root.reset();
    try expectEqual(@as(?*Self, null), root.children['a']);
}

test "TrieNode.delete" {
    const root = try Self.create(std.testing.allocator);
    root.children['a'] = try Self.init(std.testing.allocator, 'a');
    root.children['b'] = try Self.init(std.testing.allocator, 'b');
    root.delete();
}

test "TrieNode.step" {
    const root = try Self.create(std.testing.allocator);
    defer root.delete();
    root.children['a'] = try Self.init(std.testing.allocator, 'a');
    root.children['b'] = try Self.init(std.testing.allocator, 'b');
    try expectEqual(root.children['a'], root.step('a'));
    try expectEqual(root.children['b'], root.step('b'));
}
