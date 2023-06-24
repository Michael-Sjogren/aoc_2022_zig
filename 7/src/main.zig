const std = @import("std");
const log = std.log;
const fs = std.fs;
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const Programs = enum {
    cd,
    list,
    dir,
    file,
};

const ShellCommands = std.ComptimeStringMap(Programs, .{
    .{ "$ cd", .cd },
    .{ "$ ls", .list },
    .{ "dir ", .dir },
});

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var list = std.ArrayList(u8).init(alloc);
    const writer = list.writer();
    defer list.deinit();

    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1024 * 15);

    var itr = std.mem.splitAny(u8, input, "\n");
    var sizeSum: u32 = 0;
    var currentDirSize: u32 = 0;
    var depth: u32 = 0;
    var currentDirname: []const u8 = "";

    while (itr.next()) |line| {
        if (line.len == 0) continue;
        if (line.len < 4) {
            log.debug("line is less than 4 in len '{s}'", .{line});
            return error.UnhandledBranch;
        }

        const command = ShellCommands.get(line[0..4]) orelse .file;

        switch (command) {
            .dir => {
                for (0..depth) |_| {
                    _ = try writer.write("\t");
                }
                const dir_name = line[4..];
                _ = try writer.print("- {s} (dir) \n", .{dir_name});
            },
            .cd => {
                const path = line[5..];

                if (mem.eql(u8, "/", path)) {
                    _ = try writer.write("- / (dir)\n");
                    // set depth to 0
                    currentDirSize = 0;
                    depth = 0;
                    currentDirname = "/";
                } else if (mem.eql(u8, "..", path)) {
                    if (currentDirSize >= 10000) {
                        sizeSum += currentDirSize;
                    }
                    currentDirSize = 0;
                    // go up in depth
                    if (depth >= 1) {
                        depth -= 1;
                    }
                    currentDirname = "unkwn";
                } else {
                    // go into a directory, increase depth
                    currentDirname = line[5..];

                    depth += 1;
                }
            },
            .list => {},
            .file => {
                var fileInfo = mem.splitAny(u8, line, " ");
                const size = blk: {
                    const size_str = fileInfo.next() orelse return error.CouldNotReadSizeOfFile;
                    break :blk try fmt.parseInt(u32, size_str, 10);
                };

                const file_name = fileInfo.next() orelse return error.CouldNotReadFileName;
                currentDirSize += size;
                for (0..depth) |_| {
                    _ = try writer.write("\t");
                }
                _ = try writer.print("- {s} (file, size={d}) (dir {s})\n", .{ file_name, size, currentDirname });
            },
        }
    }
    try std.io.getStdOut().writeAll(list.items);
    log.debug("largest directory size {d} bytes", .{sizeSum});
}
