const sm = @import("./splitmix.zig");

/// # Example
/// ```zig
/// const std = @import("std");
/// const urng = @import("./prelude.zig");
/// var pcg32 = urng.pcg.Pcg32.new(0);
/// for (0..) |i| {
///     std.debug.print("[{d}] Pcg32: {d}\n", .{ i, pcg32.nextu() });
/// }
/// ```
pub const Pcg32 = struct {
    state: u64,
    inc: u64,

    pub fn new(seed: u64) Pcg32 {
        var seedgen = sm.SplitMix64.new(seed);
        return Pcg32{
            .state = seedgen.nextu(),
            .inc = seedgen.nextu(),
        };
    }

    pub fn nextu(self: *Pcg32) u32 {
        const oldstate = self.state;
        self.state = oldstate *% 6364136223846793005 +% self.inc;
        const xorshifted: u32 = @truncate(((oldstate >> 18) ^ oldstate) >> 27);
        const rot: u5 = @intCast(oldstate >> 59);
        const inv_rot: u5 = @as(u5, 0) -% rot;
        return (xorshifted >> rot) | (xorshifted << inv_rot);
    }
};
