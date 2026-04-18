const std = @import("std");
const urng = @import("./urng/prelude.zig");
const spice = @import("spice");

pub fn main() void {
    var rng = urng.Sfc32.new(1);
    for (0..10) |i| {
        std.debug.print("[{d}] Sfc32: {}\n", .{ i, rng.nextf() });
    }
}
