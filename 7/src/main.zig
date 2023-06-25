const std = @import("std");
const log = std.log;
const fs = std.fs;
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const ArrayList = std.ArrayList;

const Dir = struct {
    files: std.hash_map.StringHashMap(File) = undefined,
    dirs: std.ArrayList([]const u8) = undefined,
    path: []const u8 = "",
    parent: []const u8 = "",
    size: u32 = 0,
};

const File = struct {
    size: u32 = 0,
    name: []const u8 = undefined,
};

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

    var directories = std.hash_map.StringHashMap(Dir).init(alloc);
    var path = try ArrayList([]const u8).initCapacity(alloc, 30);

    defer {
        var dirsItr = directories.iterator();
        while (dirsItr.next()) |entry| {
            var value = entry.value_ptr.*;
            var key = entry.key_ptr.*;

            value.files.deinit();
            value.dirs.deinit();
            defer alloc.free(key);
        }
        directories.deinit();
        path.deinit();
    }

    const input = try std.fs.cwd().readFileAlloc(alloc, "input-test.txt", 1024 * 15);

    var itr = std.mem.splitAny(u8, input, "\n");
    var fullPath: []u8 = "";
    var currentDir: *Dir = undefined;
    while (itr.next()) |line| {
        if (line.len == 0) continue;
        if (line.len < 4) {
            log.debug("line is less than 4 in len '{s}'", .{line});
            return error.UnhandledBranch;
        }
        const command = ShellCommands.get(line[0..4]) orelse .file;

        const parent: []const u8 = fullPath;
        switch (command) {
            // discovered new sibling directory when listing in pwd
            .dir => {
                try path.append(line[5..]);
                var dirPath = try std.mem.join(alloc, "/", path.items);
                try currentDir.dirs.append(dirPath);
                _ = path.pop();
            },
            // change directory
            .cd => {
                const target: []const u8 = line[5..];

                if (mem.eql(u8, "/", target)) {
                    path.clearRetainingCapacity();
                    try path.append("root");
                } else if (mem.eql(u8, "..", target)) {
                    _ = path.pop();
                } else {
                    try path.append(target);
                }
                fullPath = try std.mem.join(alloc, "/", path.items);

                currentDir = try getDir(&directories, alloc, fullPath, parent);

                std.log.debug("cd {s}", .{currentDir.path});
            },
            // detected command to list all files
            .list => {},
            // discovered file when listing in pwd
            .file => {
                var fileInfo = mem.splitAny(u8, line, " ");
                const size = blk: {
                    const size_str = fileInfo.next() orelse return error.CouldNotReadSizeOfFile;
                    break :blk try fmt.parseInt(u32, size_str, 10);
                };
                const file_name = fileInfo.next() orelse return error.CouldNotReadFileName;
                var file = try currentDir.files.getOrPut(file_name);
                file.value_ptr.*.name = file_name;
                file.value_ptr.*.size = size;
                currentDir.size += size;
            },
        }
    }
}

fn getDir(directories: *std.hash_map.StringHashMap(Dir), alloc: anytype, fullPath: []const u8, parent: []const u8) !*Dir {
    if (!directories.contains(fullPath)) {
        try directories.put(fullPath, .{
            .path = fullPath,
            .files = std.hash_map.StringHashMap(File).init(alloc),
            .dirs = ArrayList([]const u8).init(alloc),
            .parent = parent,
        });
    }

    return directories.getPtr(fullPath) orelse return error.NotFoundDir;
}
