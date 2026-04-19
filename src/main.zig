const std = @import("std");
const urng = @import("./urng/prelude.zig");
const spice = @import("spice");

pub fn main() void {
    var sfc32 = urng.Sfc32.new(1);
    for (0..10) |i| {
        std.debug.print("[{d:>2}] Sfc32: {:>12}\n", .{ i, sfc32.nextf() });
    }

    var sfc32x16 = urng.Sfc32x16.new(1);
    const v = sfc32x16.nextf();
    for (0..16) |j| {
        std.debug.print("[{d:>2}] Sfc32x16: {:>12}\n", .{ j, v[j] });
    }
}
