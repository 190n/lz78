const std = @import("std");
const Allocator = std.mem.Allocator;

const Code = @import("./code.zig");
const Word = @import("./Word.zig");

const WordTable = [Code.max]?*Word;

pub fn create(allocator: Allocator) WordTable {
    var wt = [Code.max]?*Word{null};
    wt[Code.empty] = try Word.init(allocator, [0]u8{});
    return wt;
}

pub fn reset(wt: *WordTable) void {
    for (wt) |*w, i| {
        if (i != Code.empty) {
            if (w.*) |word| {
                word.deinit();
                w.* = null;
            }
        }
    }
}
