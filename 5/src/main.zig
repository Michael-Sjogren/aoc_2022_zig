const std = @import("std");
const fs = std.fs;
const log = std.log;
const mem = std.mem;
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const Crates = ArrayList(ArrayList(u8));
pub fn main() !void {
    var buffer: [1024 * 10]u8 = undefined;
    const contents = try fs.cwd().readFile("input-test.txt", &buffer);
    var lineItr = mem.splitAny(u8, contents, "\n");
    const alloc = std.heap.page_allocator;
    // get column count
    const columns: u32 = getColumnCount(lineItr.next() orelse return error.FailedToGetFirstLine);
    // initialize stacks
    var stacks = try Crates.initCapacity(alloc, columns);
    log.debug("colum size {d}", .{columns});
    for (0..columns) |_| {
        var list = try ArrayList(u8).initCapacity(alloc, 100);
        try stacks.append(list);
    }
    log.debug("stack size {d}", .{stacks.items.len});

    defer stacks.deinit();
    // fill original crates positions
    lineItr.reset();
    while (lineItr.next()) |line| {
        if (line.len == 0) break;
        for (line, 0..) |c, i| {
            const col = getColumnFromIndex(i);
            if (c == '[') {
                const value = line[i + 1];
                var stack: ArrayList(u8) = stacks.items[col - 1];
                try stack.append(value);

                stacks.items[col - 1] = stack;
            }
        }
    }

    // reverse the stacks

    for (0..stacks.items.len) |i| {
        const crates = &stacks.items[i];
        std.mem.reverse(u8, crates.items);
    }

    // parse crate moves
    while (lineItr.next()) |line| {
        var itr = mem.splitSequence(u8, line, " ");
        var from: usize = 1;
        var to: usize = 1;
        var amount: u32 = 0;

        while (itr.next()) |command| {
            if (mem.eql(u8, command, " ")) continue;

            if (mem.eql(u8, command, "move")) {
                amount = blk: {
                    const str = itr.next() orelse {
                        log.err("{s}", .{command});
                        return error.FailedToGetAmountValue;
                    };
                    break :blk try fmt.parseInt(u32, str, 10);
                };
            } else if (mem.eql(u8, command, "from")) {
                from = blk: {
                    const str = itr.next() orelse "1";
                    break :blk try fmt.parseInt(usize, str, 10);
                };
            } else if (mem.eql(u8, command, "to")) {
                to = blk: {
                    const str = itr.next() orelse "1";
                    break :blk try fmt.parseInt(usize, str, 10);
                };
            }
        }
        try moveCrate(from - 1, to - 1, amount, &stacks);
    }

    var col: usize = 0;
    _ = col;
    log.debug("stacks size {d}", .{stacks.items.len});
    for (0..stacks.items.len) |i| {
        const first = stacks.items[i].getLastOrNull() orelse ' ';
        log.debug("{c}", .{first});
    }
}

pub fn getColumnFromIndex(index: usize) u32 {
    return @intCast(u32, index) / 4 + 1;
}

pub fn getColumnCount(line: []const u8) u32 {
    return @intCast(u32, line.len) / 4 + 1;
}

pub fn moveCrate(from: usize, to: usize, amount: u32, crates: *Crates) !void {
    var movedCount: u32 = 0;
    for (0..amount) |_| {
        const fromVal = crates.items[from].popOrNull() orelse {
            log.debug("breaking empty column", .{});
            break;
        };
        log.debug("moving ({d}) {c} to ({d})", .{ from + 1, fromVal, to + 1 });

        try crates.items[to].append(fromVal);
        movedCount += 1;
    }
    var stack: *ArrayList(u8) = &crates.items[to];

    std.mem.rotate(u8, stack.items, 1);
}
