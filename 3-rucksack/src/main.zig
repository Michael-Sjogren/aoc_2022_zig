const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;

pub fn main() !void {}

test "rucksack" {
    var compartment_1: [52]u8 = .{0} ** (52);
    var compartment_2: [52]u8 = .{0} ** (52);

    testing.log_level = .debug;

    var lines = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, "input.txt", 10 * 1024);
    defer std.heap.page_allocator.free(lines);

    var rucksacks = mem.split(u8, lines, "\n");
    std.log.debug("", .{});
    var total: u32 = 0;
    while (rucksacks.next()) |sack| {
        const comp_1: []const u8 = sack[0 .. sack.len / 2];
        const comp_2: []const u8 = sack[sack.len / 2 ..];

        for (comp_1, comp_2) |item_1, item_2| {
            try assignSeenLetter(item_1, &compartment_1);
            try assignSeenLetter(item_2, &compartment_2);
        }

        for (compartment_1, compartment_2, 0..) |item_1, item_2, i| {
            if (item_1 + item_2 == 2) {
                var start: u8 = 'a';
                if (i > 25) {
                    start = 65;
                }

                const letter = start + @intCast(u8, i % 26);
                std.log.debug("matched (2) {s} {d}", .{ &[1]u8{letter}, letter });

                total += try prioritzeItem(letter);
            }
        }

        clearSack(&compartment_1, &compartment_2);
    }
    std.log.debug("sack total {d}", .{total});
}

fn assignSeenLetter(letter: u8, compartment: *[52]u8) !void {
    testing.log_level = .debug;

    if (isLowerCase(letter)) {
        compartment[letter - 'a'] = 1;
        return;
    } else if (isUpperCase(letter)) {
        compartment[(letter - 'A') + 26] = 1;
        return;
    }

    return error.NotALetter;
}

fn clearSack(compartment_1: *[52]u8, compartment_2: *[52]u8) void {
    for (compartment_1, compartment_2) |*a, *b| {
        a.* = 0;
        b.* = 0;
    }
}

fn prioritzeItem(item: u8) !u32 {
    testing.log_level = .debug;

    if (isLowerCase(item)) {
        return (item - 'a') + 1;
    } else if (isUpperCase(item)) {
        return (item - 'A') + 27;
    }
    return error.NotALetter;
}

fn isLowerCase(char: u8) bool {
    return char >= 'a' and char <= 'z';
}

fn isUpperCase(char: u8) bool {
    return char >= 'A' and char <= 'Z';
}
