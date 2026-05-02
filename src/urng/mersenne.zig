const sm = @import("./splitmix.zig");
const _internal = @import("./_internal.zig");

/// Mersenne Twister 19937 implementation.
///
/// # Example
///
/// ```zig
/// const std = @import("std");
/// const urng = @import("./prelude.zig");
///
/// var mt = urng.Mt19937.new(0);
/// for (0..) |i| {
///    std.debug.print("[{d}] Mt19937: {d}\n", .{ i, mt.nextu() });
/// }
/// ```
pub const Mt19937 = struct {
    state: [624]u32,
    index: u16,

    pub fn new(seed: u32) Mt19937 {
        var seedgen = sm.SplitMix32.new(seed);
        var state: [624]u32 = undefined;
        for (0..state.len()) |i| {
            state[i] = seedgen.nextu();
        }
        return Mt19937{
            .state = state,
            .index = 624,
        };
    }

    fn twist(self: *Mt19937) void {
        inline for (0..624) |i| {
            const x = (self.state[i] & 0x80000000) + (self.state[(i + 1) % 624] & 0x7fffffff);
            var xA = x >> 1;
            if ((x % 2) != 0) {
                xA ^= 0x9908b0df;
            }
            self.state[i] = self.state[(i + 397) % 624] ^ xA;
        }
        self.index = 0;
    }

    pub inline fn nextu(self: *Mt19937) u32 {
        if (self.index >= 624) {
            self.twist();
        }

        var y = self.state[self.index];
        y ^= y >> 11;
        y ^= (y << 7) & 0x9d2c5680;
        y ^= (y << 15) & 0xefc60000;
        y ^= y >> 18;

        self.index += 1;
        return y;
    }

    pub inline fn nextf(self: *Mt19937) f32 {
        return _internal.cvtu32_uf(self.nextu());
    }

    pub inline fn randi(self: *Mt19937, min: i32, max: i32) i32 {
        return _internal.cvtr32_uf(self.nextf(), min, max);
    }

    pub inline fn randf(self: *Mt19937, min: f32, max: f32) f32 {
        return _internal.cvtrf_uf(self.nextf(), min, max);
    }
};
