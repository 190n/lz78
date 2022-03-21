const std = @import("std");
const Allocator = std.mem.Allocator;

const Code = @import("./code.zig");
const Word = @import("./Word.zig");

const WordTable = @This();

words: []?Word,
allocator: Allocator,

pub fn init(allocator: Allocator) !*WordTable {
    var wt: *WordTable = try allocator.create(WordTable);
    errdefer allocator.destroy(wt);
    wt.* = .{
        .words = try allocator.alloc(?Word, Code.max),
        .allocator = allocator
    };
    errdefer allocator.free(wt.words);
    // create empty word
    wt.words[Code.empty] = try Word.create(allocator, &[_]u8{});
    return wt;
}

pub fn deinit(wt: *WordTable) void {
    wt.reset();
    wt.words[Code.empty].?.deinit();
    wt.allocator.free(wt.words);
    wt.allocator.destroy(wt);
}

pub fn reset(wt: *WordTable) void {
    for (wt.words) |*w, i| {
        if (i != Code.empty) {
            if (w.*) |*word| {
                word.deinit();
                w.* = null;
            }
        }
    }
}

test "WordTable.init" {
    var wt = try init(std.testing.allocator);
    defer wt.deinit();
    for (wt.words) |w, i| {
        if (i == Code.empty) {
            try std.testing.expectEqual(@as(usize, 0), w.?.syms.len);
        } else {
            try std.testing.expectEqual(@as(?Word, null), w);
        }
    }
}

test "WordTable.reset" {
    var wt = try init(std.testing.allocator);
    defer wt.deinit();
    wt.words[638] = try Word.create(std.testing.allocator, "monke");
    wt.words[20] = try Word.create(std.testing.allocator, "taco");
    wt.reset();
    for (wt.words) |w, i| {
        if (i == Code.empty) {
            try std.testing.expectEqual(@as(usize, 0), w.?.syms.len);
        } else {
            try std.testing.expectEqual(@as(?Word, null), w);
        }
    }
}
