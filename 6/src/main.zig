const std = @import("std");
const log = std.log;
const fs = std.fs;
const testing = std.testing;

pub fn main() !void {
    var buffer: [1024 * 10]u8 = undefined;

    const contents = try fs.cwd().readFile("input-test.txt", &buffer);
    var slice: []const u8 = contents;
    for (contents, 0..) |_, i| {
        if (try isSequenceUnique(slice[0..4])) {
            log.debug("first marker after {d}", .{i});
            break;
        }
        slice = contents[i + 4 ..];
    }
}

fn isSequenceUnique(slice: []const u8) !bool {
    if (slice.len != 4) return error.MustBeFourInLength;
    var alphabet: [26]u32 = [_]u32{0} ** 26;
    log.debug("slice {s}", .{slice});
    for (slice) |l| {
        const index: u8 = l - 'a';
        var current: *u32 = &alphabet[index];
        current.* += 1;
    }

    for (alphabet) |val| {
        if (val >= 2) {
            return false;
        }
    }

    return true;
}
