const std = @import("std");
const log = std.log.scoped(.calorie_counting_1);
const mem = std.mem;
const testing = std.testing;
const expect = std.testing.expect;

fn splitCalorieList(list:[]const u8) !mem.SplitIterator(u8) {
    return mem.split(u8, list, "\n");
}



fn calculateCalories(currentCount:u64,slice: []const u8) !u64 {
    const cal = std.fmt.parseUnsigned(u64, slice, 10) catch 0;
    return currentCount + cal;
}

pub fn main() !void {
    var buffer: [1024*15]u8 = undefined;
    var elves = try std.ArrayList(u64).initCapacity(std.heap.page_allocator,300);    
    defer elves.deinit();
    const contents = try std.fs.cwd().readFile("calories.txt", &buffer);
    try groupElvesCalories(&elves, contents);

    std.sort.sort(u64, elves.items, {}, std.sort.desc(u64));
    var sum_top_3:u64 = 0;
    for (elves.items[0..3],0..3) |cal, i| {
        std.log.debug("{d} {d}", .{i,cal});
        sum_top_3 += cal;
    }
    std.log.debug("sum top 3 {d}", .{sum_top_3});

}

fn groupElvesCalories(elves:*std.ArrayList(u64) ,calorie_list:[]const u8) !void {
    testing.log_level = .debug;
    var itr = try splitCalorieList(calorie_list);
    var count:usize = 0;
    var prev:bool = false;
    while (itr.next()) |line| {
        var is_number = true;

        const num :std.fmt.ParseIntError!u64 = std.fmt.parseUnsigned(u64, line, 10);
        _ = num catch {
            is_number = false;
        };



        if (!prev and is_number)  {
            count += 1;
            try elves.append(0);
        }
        prev = is_number;

        if (is_number) {
            var sum:*u64 = &elves.items[count-1];
            const new_sum = sum.* + (num catch 0);
            std.log.debug("{d} ({d}) = {d} + {d}", .{count-1, new_sum, sum.* , num catch 0});
            sum.* = new_sum;
        }
    }
}

test "elf calorie list" {
    std.testing.log_level = .debug;
    const alloc = std.testing.allocator;

    const calorie_list = 
    \\
    \\123
    \\235
    \\
    \\10
    \\12
    \\
    \\
    \\
    \\3
    \\
    \\dfff
    \\324
    ;
    var elves = try std.ArrayList(u64).initCapacity(alloc,100);
    var elves_expected = std.ArrayList(u64).init(alloc);
    try elves_expected.insertSlice(0,&[4]u64 {
        358,
        22,
        3,
        324,
    });
    defer {
        elves.deinit();
        elves_expected.deinit();
    }
    try groupElvesCalories(&elves, calorie_list);

    try testing.expectEqualSlices(u64, elves_expected.items , elves.items);
    const cal:u64 = try calculateCalories(12346,"233562");
    const expected_total:u64 = 233562 + 12346;
    try testing.expectEqual(expected_total, cal);

}