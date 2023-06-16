const std = @import("std");
const testing = std.testing;
const log = std.log;

const HandShapes = enum(u8) {
    rock = 1,
    paper = 2,
    scissors = 3
};

const RoundOutcome = enum {
    win,
    lose,
    draw
};

const tags = std.ComptimeStringMap(HandShapes, .{
    .{"A", .rock },
    .{"B", .paper },
    .{"C", .scissors }
});

const outcome = std.ComptimeStringMap(RoundOutcome, .{
    .{"X", .lose},
    .{"Y", .draw}, 
    .{"Z", .win}, 
});


pub fn main() !void {
    // parse file
    var contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, "input.txt", 10*1024);
    defer std.heap.page_allocator.free(contents);

    var lineItr = std.mem.split(u8, contents , "\n");
    var score: u32 = 0;
    while (lineItr.next()) |line| {
        var moves = std.mem.split(u8, line, " ");
        if (moves.rest().len == 0) break;
        const op:[]const u8 = moves.next() orelse return error.InvalidFormat;
        const me:[]const u8 = moves.next() orelse return error.InvalidFormat;
        const op_move = tags.get(op) orelse error.InvalidFormat;
        const round_outcome = outcome.get(me) orelse return error.InvalidFormat;
        const my_move = getMyMove(round_outcome,try op_move);
        const round_score = calculateRoundScore( my_move,try op_move);
        score += round_score;
        std.log.debug("movesr: {s} {d}", .{line, round_score});
    }
    std.log.debug("my score {d}", .{score});
}

fn getMyMove(desired_outcome:RoundOutcome, opponent:HandShapes) HandShapes {
    switch (opponent) {
        .rock => {
            switch (desired_outcome) {
                .win => return .paper,
                .draw => return .rock,
                .lose => return .scissors,
            }
        },
        .paper => { 
            switch (desired_outcome) {
                .win => return .scissors,
                .draw => return .paper,
                .lose => return .rock,
            }
        },
        .scissors => {
            switch (desired_outcome) {
                .win => return .rock,
                .draw => return .scissors,
                .lose => return .paper,
            }
        },
    }
}

fn calculateRoundScore(you_move:HandShapes,opponent:HandShapes) u32 {
    const val = @enumToInt(you_move);
    switch (opponent) {
        .rock => {
            switch (you_move) {
                .rock => return 3 + val,
                .paper => return 6 + val,
                .scissors => return 0 + val,
            }
        },
        .paper => {
            switch (you_move) {
                .rock => return 0 + val,
                .paper => return 3 + val,
                .scissors => return 6 + val,
            }
        },

        .scissors => {
            switch (you_move) {
                .rock => return 6 + val,
                .paper => return 0 + val,
                .scissors => return 3 + val,
            }
        } 
    }
}

