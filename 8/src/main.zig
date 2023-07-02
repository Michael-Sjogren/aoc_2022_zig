const std = @import("std");

const Tree = struct {
    x: u32 = undefined,
    y: u32 = undefined,
    height: u32 = undefined,
    is_visible: bool = false,
    pub fn isEdgeTree(self: *Tree, map_width: u32, map_height: u32) bool {
        return self.x == 0 or self.x == map_width - 1 or self.y == 0 or self.y == map_height - 1;
    }
};

pub fn main() !void {
    const input =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    const stdout = std.io.getStdOut();
    defer stdout.close();
    const writer = stdout.writer();

    var itr = std.mem.splitAny(u8, input, "\n");
    const first_line = itr.next() orelse return error.@"Unable get get line width of first line";
    const width: u32 = @intCast(u32, first_line.len);
    itr.reset();
    const height: u32 = @intCast(
        u32,
        itr.rest().len,
    ) % @intCast(u32, width + 1);
    const alloc = std.heap.page_allocator;
    var map = try std.ArrayList(std.ArrayList(Tree)).initCapacity(
        alloc,
        width,
    );

    defer {
        for (map.items) |trees| {
            trees.deinit();
        }
        map.deinit();
    }

    for (0..width) |_| {
        try map.append(try std.ArrayList(Tree).initCapacity(alloc, height));
    }

    var row: u32 = 0;
    var visibleCount: u32 = 0;
    while (itr.next()) |line| : (row += 1) {
        for (line, 0..line.len) |height_str, col| {
            var tree: Tree = .{
                .x = @intCast(u32, col),
                .y = @intCast(u32, row),
                .height = try std.fmt.parseInt(
                    u32,
                    &.{height_str},
                    10,
                ),
            };
            tree.is_visible = tree.isEdgeTree(width, height);
            try map.items[col].append(tree);

            if (tree.is_visible) {
                const t: *Tree = &map.items[col].items[row];
                try writer.print("[{d}]", .{t.height});
                visibleCount += 1;
            } else {
                const t: *Tree = &map.items[col].items[row];
                try writer.print(" {d} ", .{t.height});
            }
        }
        try writer.print("\n", .{});
    }

    try writer.print("\nTrees visible: {d}\n\n\r", .{visibleCount});
}

test "is edge tree" {
    const testing = std.testing;
    var actual: Tree = .{
        .x = 1,
        .y = 1,
        .height = 69,
    };
    try testing.expectEqual(false, actual.isEdgeTree(3, 3));

    try testing.expectEqual(true, actual.isEdgeTree(2, 2));
}
