const std = @import("std");
const log = std.log;
const fs = std.fs;
const testing = std.testing;

pub fn main() !void {
    var buffer: [1024 * 10]u8 = undefined;

    const contents = try fs.cwd().readFile("input.txt", &buffer);
    const start = try findFirstMarker(contents);
    log.debug("first marker after character {d}", .{start});
}

fn isSequenceUnique(slice: []const u8) !bool {
    if (slice.len != 4) return error.MustBeFourInLength;
    var alphabet: [26]u32 = [_]u32{0} ** 26;
    log.debug("slice {s}", .{slice});
    for (slice) |l| {
        const index: u8 = l - 'a';
        var current: *u32 = &alphabet[index];
        current.* += 1;
        if (current.* >= 2) {
            return false;
        }
    }
    return true;
}

fn findFirstMarker(dataStream: []const u8) !usize {
    var slice: []const u8 = dataStream;
    for (dataStream, 0..) |_, i| {
        if (try isSequenceUnique(slice[0..4])) {
            return i + 4;
        }
        slice = dataStream[i + 1 ..];
    }

    return error.FailedToFindAMarker;
}

test "test unique sequence" {
    try testing.expectEqual(true, try isSequenceUnique("abcd"));

    try testing.expectEqual(false, try isSequenceUnique("abca"));
}

test "find first market" {
    try testing.expectEqual(@as(usize, 5), try findFirstMarker("bvwbjplbgvbhsrlpgdmjqwftvncz"));

    try testing.expectEqual(@as(usize, 6), try findFirstMarker("nppdvjthqldpwncqszvftbrmjlhg"));

    try testing.expectEqual(@as(usize, 10), try findFirstMarker("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"));

    try testing.expectEqual(@as(usize, 11), try findFirstMarker("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"));
}
