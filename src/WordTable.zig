const std = @import("std");

const Code = @import("./code.zig");

table: [Code.max]?[]const u8,
allocator: std.mem.Allocator,

const WordTable = @This();

pub fn init(allocator: std.mem.Allocator) WordTable {
    var wt = WordTable{
        .table = [_]?[]const u8{null} ** Code.max,
        .allocator = allocator,
    };
    // freeing zero length slice is ok
    // cannot use undefined for the pointer as it may be zero which would make the slice null
    wt.table[Code.empty] = @intToPtr([*]u8, std.math.maxInt(usize))[0..0];
    return wt;
}

/// delete all words except the one for the empty code
pub fn reset(self: *WordTable) void {
    for (&self.table, 0..) |*entry, i| {
        if (entry.*) |slice| {
            if (i != Code.empty) {
                self.allocator.free(slice);
                entry.* = null;
            }
        }
    }
}

/// delete all words
pub fn deinit(self: *WordTable) void {
    for (self.table) |entry| {
        if (entry) |slice| {
            self.allocator.free(slice);
        }
    }
    self.* = undefined;
}

/// append a symbol to the word at index old_code, store the new word at index new_code, and also
/// return the new word. returned slice is owned by the word table and should not be freed by
/// caller. old_code must exist in the table.
pub fn insert(self: *WordTable, old_code: Code.Code, new_code: Code.Code, sym: u8) ![]const u8 {
    const new_word = try std.mem.concat(self.allocator, u8, &.{
        self.table[old_code].?,
        &.{sym},
    });
    self.table[new_code] = new_word;
    return new_word;
}

test "WordTable.init" {
    var wt = WordTable.init(std.testing.allocator);
    defer wt.deinit();
    for (wt.table, 0..) |entry, i| {
        if (i == Code.empty) {
            try std.testing.expectEqual(@as(usize, 0), entry.?.len);
        } else {
            try std.testing.expectEqual(@as(?[]const u8, null), entry);
        }
    }
}

test "WordTable.reset" {
    var wt = WordTable.init(std.testing.allocator);
    defer wt.deinit();
    wt.table[50] = try std.testing.allocator.dupe(u8, "foobar");
    wt.table[51] = try std.testing.allocator.dupe(u8, "wombat");
    wt.reset();
    for (wt.table, 0..) |entry, i| {
        if (i == Code.empty) {
            try std.testing.expectEqual(@as(usize, 0), entry.?.len);
        } else {
            try std.testing.expectEqual(@as(?[]const u8, null), entry);
        }
    }
}

test "WordTable.insert" {
    var wt = WordTable.init(std.testing.allocator);
    defer wt.deinit();
    var word = try wt.insert(Code.empty, 50, 'a');
    try std.testing.expectEqualSlices(u8, "a", word);
    try std.testing.expectEqual(word, wt.table[50].?);
    word = try wt.insert(50, 51, 'b');
    try std.testing.expectEqualSlices(u8, "ab", word);
    try std.testing.expectEqual(word, wt.table[51].?);
}
