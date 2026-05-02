const std = @import("std");
const sm = @import("./splitmix.zig");
const _internal = @import("./_internal.zig");

const f32x8 = _internal.f32x8;
const u64x8 = _internal.u64x8;
const u32x8 = _internal.u32x8;
const u5x8 = @Vector(pcg32x8_size, u5);

/// PCG implementation.
///
/// # Example
///
/// ```zig
/// const std = @import("std");
/// const urng = @import("./prelude.zig");
/// var pcg32 = urng.Pcg32.new(0);
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

    pub inline fn nextu(self: *Pcg32) u32 {
        const oldstate = self.state;
        self.state = oldstate *% 6364136223846793005 +% self.inc;
        const xorshifted: u32 = @truncate(((oldstate >> 18) ^ oldstate) >> 27);
        const rot: u5 = @intCast(oldstate >> 59);
        const inv_rot = 0 -% rot;
        return (xorshifted >> rot) | (xorshifted << inv_rot);
    }
};

const pcg32x8_size = 8;

/// PCG Vectorise implementation.
///
/// # Example
///
/// ```zig
/// const std = @import("std");
/// const urng = @import("./prelude.zig");
/// var pcg32 = urng.Pcg32x8.new(0);
/// for (0..) |i| {
///     std.debug.print("[{d}] Pcg32x8: {d}\n", .{ i, pcg32.nextu() });
/// }
/// ```
pub const Pcg32x8 = struct {
    state: u64x8,
    inc: u64x8,

    pub fn new(seed: u64) Pcg32x8 {
        var seedgen = sm.SplitMix64.new(seed);
        var state: [pcg32x8_size]u64 = undefined;
        var inc: [pcg32x8_size]u64 = undefined;
        for (0..pcg32x8_size) |i| {
            state[i] = seedgen.nextu();
            inc[i] = seedgen.nextu();
        }
        return Pcg32x8{
            .state = state,
            .inc = inc,
        };
    }

    pub inline fn nextu(self: *Pcg32x8) [pcg32x8_size]u32 {
        const oldstate = self.state;
        self.state = oldstate *% @as(u64x8, @splat(6364136223846793005)) +% self.inc;

        const xorshifted: u32x8 = @truncate(((oldstate >> @as(u64x8, @splat(18))) ^ oldstate) >> @as(u64x8, @splat(27)));
        const rot: u5x8 = @truncate(oldstate >> @as(u64x8, @splat(59)));
        const inv_rot: u5x8 = @as(u5x8, @splat(0)) -% rot;

        return @bitCast((xorshifted >> rot) | (xorshifted << inv_rot));
    }

    pub inline fn nextf(self: *Pcg32x8) [pcg32x8_size]f32 {
        const v: u32x8 = @bitCast(self.nextu());
        const f: f32x8 = @floatFromInt(v);
        return @bitCast(f * @as(f32x8, @splat(1.0 / 4294967296.0)));
    }
};

test "pcg32x8 nextu matches scalarized reference" {
    const seed: u64 = 0x1234_5678_9abc_def0;
    var rng = Pcg32x8.new(seed);

    var seedgen = sm.SplitMix64.new(seed);
    var state: [pcg32x8_size]u64 = undefined;
    var inc: [pcg32x8_size]u64 = undefined;
    for (0..pcg32x8_size) |i| {
        state[i] = seedgen.nextu();
        inc[i] = seedgen.nextu();
    }

    for (0..64) |_| {
        const actual = rng.nextu();
        var expected: [pcg32x8_size]u32 = undefined;

        for (0..pcg32x8_size) |i| {
            const oldstate = state[i];
            state[i] = oldstate *% 6364136223846793005 +% inc[i];
            const xorshifted: u32 = @truncate(((oldstate >> 18) ^ oldstate) >> 27);
            const rot: u5 = @intCast(oldstate >> 59);
            const inv_rot = 0 -% rot;
            expected[i] = (xorshifted >> rot) | (xorshifted << inv_rot);
        }

        try std.testing.expectEqualSlices(u32, expected[0..], actual[0..]);
    }
}
