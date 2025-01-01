const std = @import("std");
const ink = @cImport({
    @cInclude("inkcpp.h");
});

fn inkAdd(argc: c_int, argv: [*c]const ink.InkValue) callconv(.C) ink.InkValue {
    std.debug.assert(argc == 2);
    std.debug.assert(argv[0].type == ink.ValueTypeInt32);
    std.debug.assert(argv[1].type == ink.ValueTypeInt32);

    const sum = argv[0].unnamed_0.int32_v + argv[1].unnamed_0.int32_v;
    return ink.InkValue{ .type = ink.ValueTypeInt32, .unnamed_0 = .{ .int32_v = sum } };
}

fn readChoice() !c_int {
    var buffer: [1]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    try std.io.getStdIn().reader().streamUntilDelimiter(fbs.writer(), '\n', null);
    const line = fbs.getWritten();
    return std.fmt.parseInt(c_int, line, 10);
}

pub fn main() !void {
    ink.ink_compile_json("test.ink.json", "test.bin", null);
    const story = ink.ink_story_from_file("test.bin");
    const runner = ink.ink_story_new_runner(story, null);

    ink.ink_runner_bind(runner, "my_ink_function", &inkAdd, 1);

    while (true) {
        while (ink.ink_runner_can_continue(runner) != 0) {
            std.debug.print("{s}", .{ink.ink_runner_get_line(runner)});
        }

        if (ink.ink_runner_num_choices(runner) == 0) {
            break;
        }

        var i: c_int = 0;
        while (i < ink.ink_runner_num_choices(runner)) : (i += 1) {
            std.debug.print("{d}. {s}\n", .{ i, ink.ink_choice_text(ink.ink_runner_get_choice(runner, i)) });
        }

        const id = try readChoice();
        ink.ink_runner_choose(runner, id);
    }
}
