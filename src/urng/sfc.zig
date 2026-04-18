const urng = @import("./prelude.zig");
const _internal = @import("./_internal.zig");

const sg = urng.splitmix.SplitMix32;

/// A SFC32 pseudo-random number generator.
///
/// # Examples
///
/// ```
/// const urng = @import("urng/prelude.zig");
///
/// var rng = urng.Sfc32.new(1);
/// const x = rng.nextu();
/// ```
pub const Sfc32 = struct {
    a: u32,
    b: u32,
    c: u32,
    counter: u32,

    pub fn new(seed: u32) Sfc32 {
        var seedgen = sg.new(seed);
        return Sfc32{ .a = seedgen.nextu(), .b = seedgen.nextu(), .c = seedgen.nextu(), .counter = 1 };
    }

    pub fn nextu(self: *Sfc32) u32 {
        const tmp = self.a +% self.b +% self.counter;

        self.counter += 1;
        self.a = self.b ^ (self.b >> 9);
        self.b = self.c +% (self.c << 3);
        self.c = (self.c << 21) | (self.c >> 32 - 11);
        self.c +%= tmp;

        return tmp;
    }

    pub fn nextf(self: *Sfc32) f32 {
        return _internal.cvtu32_uf(self.nextu());
    }

    pub fn randi(self: *Sfc32, min: i32, max: i32) i32 {
        return _internal.cvtr32_ui(self.nextu(), min, max);
    }

    pub fn randf(self: *Sfc32, min: f32, max: f32) f32 {
        return _internal.cvtr32_uf(self.nextu(), min, max);
    }
};
