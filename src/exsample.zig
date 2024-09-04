const std = @import("std");
const Zprob = @import("Zprob.zig");

pub fn main() !void {
    // Get a new Zprob instance.
    // The capacity is set to 100.
    // The output file is set to the standard output.
    var zprob = Zprob{ .capacity = 100, .out = &std.io.getStdOut() };

    // Reset(initialize) the progress bar.
    // Must be called just before the loop.
    zprob.Reset();
    for (0..100) |i| {
        _ = i;
        // Because write to the standard output may fail, we use `try`.
        // Can't use `defer` here because return value is not `void`.
        try zprob.Update(1, "test");
    }

    // Reuse the Zprob instance.
    zprob.Resize(1000);
    var b: u32 = 0;
    while (b < 1000) : (b += 1) {
        var buffer: [10]u8 = undefined;
        const curr_number_str = std.fmt.bufPrint(buffer[0..], "{}", .{b}) catch unreachable;
        // Update the progress bar with description.
        try zprob.Update(1, curr_number_str);
        std.time.sleep(10_000_000);
    }

    zprob.Reset();
    b = 0;
    while (b < 1000) : (try zprob.Update(1, "")) {
        b += 1;
        std.time.sleep(10_000_000);
    }
}
