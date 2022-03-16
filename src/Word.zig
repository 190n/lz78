const std = @import("std");
const Allocator = std.mem.Allocator;

const Code = @import("./code.zig");

const Self = @This();

ptr: [*]u8,
len: usize,
allocator: Allocator,

pub const WordTable = [Code.max]?*Self;

pub fn init(allocator: Allocator, syms: []const u8) !*Self {
    const w = try allocator.create(Self);
    errdefer allocator.destroy(w);
    w.* = .{
        .ptr = try allocator.alloc(u8, syms.len),
        .len = syms.len,
        .allocator = allocator,
    };
    @memcpy(w.ptr, syms.ptr, syms.len);
    return w;
}

pub fn appendSym(self: *const Self, sym: u8) !*Self {
    const w = try self.allocator.create(Self);
    errdefer self.allocator.destroy(w);
    w.* = .{
        .ptr = try self.allocator.alloc(u8, self.len + 1),
        .len = self.len + 1,
        .allocator = self.allocator,
    };
    @memcpy(w.ptr, self.ptr, self.len);
    w.ptr[self.len] = sym;
    return w;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.ptr);
    self.allocator.destroy(self);
}
