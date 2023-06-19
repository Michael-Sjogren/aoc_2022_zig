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

const test_input =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    _ = alloc;

    var itr = std.mem.splitAny(u8, test_input, "\n");
    var largestDirSize: u32 = 0;
    var currentDirSize: u32 = 0;
    var depth: u32 = 0;
    while (itr.next()) |line| {
        if (line.len < 4) {
            log.debug("line is less than 4 in len '{s}'", .{line});
            return error.UnhandledBranch;
        }

        const command = ShellCommands.get(line[0..4]) orelse .file;

        switch (command) {
            .dir => {
                const dir_name = line[4..];
                log.debug("- {s} (dir)", .{dir_name});
            },
            .cd => {
                const path = line[5..];
                if (mem.eql(u8, "/", path)) {
                    // set depth to 0

                    depth = 0;
                } else if (mem.eql(u8, "..", path)) {
                    currentDirSize = 0;
                    // go up in depth
                    if (depth >= 1) {
                        depth -= 1;
                    }
                } else {
                    // go into a directory, increase depth
                    depth += 1;
                }
            },
            .list => {
                largestDirSize = std.math.max(currentDirSize, largestDirSize);
            },
            .file => {
                var fileInfo = mem.splitAny(u8, line, " ");
                const size = blk: {
                    const size_str = fileInfo.next() orelse return error.CouldNotReadSizeOfFile;
                    break :blk try fmt.parseInt(u32, size_str, 10);
                };

                const file_name = fileInfo.next() orelse return error.CouldNotReadFileName;
                currentDirSize += size;
                log.debug("-[{d}]\t {s} (file, size={d})", .{ depth, file_name, size });
            },
        }
    }

    log.debug("largest directory size {d} bytes", .{largestDirSize});
}
