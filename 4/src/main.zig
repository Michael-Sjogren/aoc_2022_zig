const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;

pub fn main() !void {}

fn parseRange(range: []const u8) !Range {
    var nums = mem.splitAny(u8, range, "-");
    testing.log_level = .debug;

    const x1 = nums.next() orelse return error.FailedToGetX1;
    const x2 = nums.next() orelse return error.FailedToGetX2;
    std.log.debug("x1 {s}", .{x1});
    std.log.debug("x2 {s}", .{x2});

    return .{ .x1 = try fmt.parseInt(i32, x1, 10), .x2 = try fmt.parseInt(i32, x2, 10) };
}

const Range = struct {
    x1: i32 = 0,
    x2: i32 = 0,

    // tests if this range is within b
    pub fn isFullyOverlapping(self: Range, b: Range) bool {
        return self.x1 >= b.x1 and self.x2 <= self.x2 or
            b.x1 >= self.x1 and b.x2 <= self.x2;
    }

    // tests if either range is intersecting
    pub fn isOverlapping(self: Range, b: Range) bool {
        return (b.x2 - self.x1) * (b.x1 - self.x2) >= 0;
    }
};

test "parse range" {
    const result = try parseRange("6-2");
    const expected: Range = .{ .x1 = 6, .x2 = 2 };
    try expectEqual(expected, result);
}

test "is range overlapping" {
    var a: Range = .{ .x1 = 0, .x2 = 0 };
    var b: Range = .{ .x1 = 0, .x2 = 0 };
    try expectEqual(true, a.isFullyOverlapping(b));
    a = .{ .x1 = 2, .x2 = 4 };
    b = .{ .x1 = 6, .x2 = 8 };
    try expectEqual(false, a.isFullyOverlapping(b));

    a = .{ .x1 = 6, .x2 = 6 };
    b = .{ .x1 = 4, .x2 = 6 };
    try expectEqual(true, a.isFullyOverlapping(b));
}
