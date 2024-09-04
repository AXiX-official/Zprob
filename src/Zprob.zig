//! A simple console progress bar for Zig.

/// The length of range to iterate.
capacity: u32 = 0,
/// File to write the progress bar to, usually `std.io.getStdOut()`.
/// Must be set before calling `Update`.
out: ?*const std.fs.File = null,
progress: u32 = 0,
start_time: i64 = 0,
p: u8 = 0,
bar: [bar_len]u8 = init_bar(),

const bar_len = 112;

const ZprobError = error{
    OutFileNotSet,
};

inline fn init_bar() [bar_len]u8 {
    var bar: [bar_len]u8 = [_]u8{0} ** bar_len;
    const head = "\r[\x1b[46m\x1b[0m";
    for (head, 0..) |c, i| {
        bar[i] = c;
    }
    for (0..100) |i| {
        bar[i + 11] = ' ';
    }
    bar[bar_len - 1] = ']';
    return bar;
}

/// Update the progress bar's status.
/// `count` is the number of items processed in this iteration.
/// `desc` is the description text to show of the current iteration.
pub fn Update(self: *Self, count: u32, desc: []const u8) anyerror!void {
    if (self.capacity == 0) {
        return self.UpdateBar(100, desc);
    } else {
        self.progress += count;
        if (self.progress >= self.capacity) {
            self.progress = self.capacity;
        }
        const p: u8 = @intCast(self.progress * 100 / self.capacity);
        return self.UpdateBar(p, desc);
    }
}

inline fn UpdateBar(self: *Self, p: u8, desc: []const u8) anyerror!void {
    self.p = p;
    for (0..p) |i| {
        self.bar[i + 7] = ' ';
    }
    var buffer: [100]u8 = undefined;
    const number_str = std.fmt.bufPrint(buffer[0..], "{}/{}|", .{ self.progress, self.capacity }) catch unreachable;
    var len = self.SetString(number_str, 0);
    len = self.SetString(self.GetSpeed(), len);
    self.SetChar('|', len);
    len += 1;
    len = self.SetString(desc, len);
    const tail = "\x1b[0m";
    self.SetStringForce(tail, p + 7);
    if (self.out == null) {
        return ZprobError.OutFileNotSet;
    } else {
        try self.out.?.*.writer().print("{s}", .{self.bar});
        if (self.progress == self.capacity) {
            try self.out.?.*.writer().print("\n", .{});
        }
    }
}

fn GetSpeed(self: *Self) []const u8 {
    const time_cost: i64 = std.time.milliTimestamp() - self.start_time;
    var buffer: [100]u8 = undefined;
    var per: f64 = @as(f64, @floatFromInt(time_cost)) / @as(f64, @floatFromInt(self.progress * 1000));
    const flag: bool = per < 1;
    per = if (flag) 1.0 / per else per;
    const left: f64 = @as(f64, @floatFromInt(self.capacity - self.progress)) / per;
    if (flag) {
        return std.fmt.bufPrint(buffer[0..], "{d:.2}it/s,{d:.2}s left", .{ per, left }) catch unreachable;
    } else {
        return std.fmt.bufPrint(buffer[0..], "{d:.2}s/it,{d:.2}s left", .{ per, left }) catch unreachable;
    }
}

inline fn SetString(self: *Self, s: []const u8, i: u8) u8 {
    for (s, 0..) |c, j| {
        self.SetChar(c, @intCast(j + i));
    }
    return @intCast(s.len + i);
}

inline fn SetChar(self: *Self, c: u8, i: u8) void {
    if (i >= self.p) {
        self.bar[i + 11] = c;
    } else {
        self.bar[i + 7] = c;
    }
}

inline fn SetStringForce(self: *Self, s: []const u8, i: u8) void {
    for (s, 0..) |c, j| {
        self.bar[i + j] = c;
    }
}

/// Reset status, must be called just before the loop, or use Resize instead.
/// This will reset the progress to 0 and start the timer.
pub fn Reset(self: *Self) void {
    self.progress = 0;
    self.bar = init_bar();
    self.start_time = std.time.milliTimestamp();
}

/// Resize the capacity of the progress bar, will reset the status as well.
pub fn Resize(self: *Self, len: u32) void {
    self.capacity = len;
    self.Reset();
}

const std = @import("std");
const Self = @This();
