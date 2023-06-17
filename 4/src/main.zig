const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;

pub fn main() !void {
    var buffer: [1024 * 15]u8 = undefined;
    const contents = try fs.cwd().readFile("input.txt", &buffer);
    var itr = mem.splitAny(u8, contents, "\n");
    var count: u32 = 0;
    while (itr.next()) |line| {
        log.debug("line({d}): {s}", .{ line.len, line });
        if (line.len == 0) break;
        var ranges = mem.splitAny(u8, line, ",");
        const a = try parseRange(ranges.next() orelse return error.FailedToGetNextRange);
        const b = try parseRange(ranges.next() orelse return error.FailedToGetNextRange);
        if (a.isFullyOverlapping(b)) {
            count += 1;
        }
    }

    log.info("assignment pairs fully intersecting {d}", .{count});
    itr.reset();
    count = 0;

    while (itr.next()) |line| {
        if (line.len == 0) break;
        var ranges = mem.splitAny(u8, line, ",");
        const a = try parseRange(ranges.next() orelse return error.FailedToGetNextRange);
        const b = try parseRange(ranges.next() orelse return error.FailedToGetNextRange);
        if (a.isIntersecting(b)) {
            count += 1;
        }
    }

    log.info("assignment pairs intersecting {d}", .{count});
}

fn parseRange(range: []const u8) !Range {
    var nums = mem.splitAny(u8, range, "-");
    testing.log_level = .debug;

    const x1 = nums.next() orelse return error.FailedToGetX1;
    const x2 = nums.next() orelse return error.FailedToGetX2;

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
    pub fn isIntersecting(self: Range, b: Range) bool {
        return (self.x1 - b.x2) * (b.x1 - self.x2) >= 0;
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

test "is intersecting" {
    var a: Range = .{ .x1 = 6, .x2 = 6 };
    var b: Range = .{ .x1 = 4, .x2 = 6 };
    try expectEqual(true, a.isIntersecting(b));

    a = .{ .x1 = -55, .x2 = 3 };
    b = .{ .x1 = 4, .x2 = 6 };
    try expectEqual(false, a.isIntersecting(b));
}
