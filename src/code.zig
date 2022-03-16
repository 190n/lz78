const std = @import("std");

pub const Code = u16;

pub const stop: Code = 0;
pub const empty: Code = 1;
pub const start: Code = 2;
pub const max: Code = std.math.maxInt(Code);
