const std = @import("std");
const Allocator = std.mem.Allocator;

const Code = @import("./code.zig");

const Word = @This();

syms: []u8,
allocator: Allocator,

pub fn init(self: *Word, allocator: Allocator, syms: []const u8) !void {
    self.* = .{
        .syms = try allocator.alloc(u8, syms.len),
        .allocator = allocator,
    };
    for (syms) |s, i| {
        self.syms[i] = s;
    }
}

pub fn create(allocator: Allocator, syms: []const u8) !Word {
    var w: Word = undefined;
    try init(&w, allocator, syms);
    return w;
}

pub fn appendSym(self: *const Word, allocator: Allocator, sym: u8) !Word {
    const w = Word{
        .syms = try allocator.alloc(u8, self.syms.len + 1),
        .allocator = allocator,
    };
    for (self.syms) |s, i| {
        w.syms[i] = s;
    }
    w.syms[self.syms.len] = sym;
    return w;
}

pub fn deinit(self: *Word) void {
    self.allocator.free(self.syms);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Word.init" {
    var w: Word = undefined;
    try init(&w, std.testing.allocator, "abc");
    defer w.deinit();
    try expect(std.mem.eql(u8, "abc", w.syms));
}

test "Word.create" {
    var w = try create(std.testing.allocator, "def");
    defer w.deinit();
    try expect(std.mem.eql(u8, "def", w.syms));
}

test "Word.appendSym" {
    var w = try create(std.testing.allocator, "monke");
    defer w.deinit();
    var w2 = try w.appendSym(std.testing.allocator, 'y');
    defer w2.deinit();
    try expect(std.mem.eql(u8, "monkey", w2.syms));
}
