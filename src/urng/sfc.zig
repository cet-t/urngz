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
        self.c = _internal.rotl32(self.c, 21);
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

const sfc32x16_size = 16;
const sfc32x16_t = [sfc32x16_size]u32;

pub const Sfc32x16 = struct {
    a: sfc32x16_t,
    b: sfc32x16_t,
    c: sfc32x16_t,
    counter: sfc32x16_t,

    pub fn new(seed: u32) Sfc32x16 {
        var seedgen = sg.new(seed);
        var a: sfc32x16_t = undefined;
        var b: sfc32x16_t = undefined;
        var c: sfc32x16_t = undefined;
        var counter: sfc32x16_t = undefined;
        for (0..sfc32x16_size) |i| {
            a[i] = seedgen.nextu();
            b[i] = seedgen.nextu();
            c[i] = seedgen.nextu();
            counter[i] = 1;
        }
        return Sfc32x16{ .a = a, .b = b, .c = c, .counter = counter };
    }

    pub fn nextu(self: *Sfc32x16) sfc32x16_t {
        var tmp: sfc32x16_t = undefined;
        inline for (0..sfc32x16_size) |i| {
            tmp[i] = self.a[i] +% self.b[i] +% self.counter[i];

            self.counter[i] +%= 1;
            self.a[i] = self.b[i] ^ (self.b[i] >> 9);
            self.b[i] = self.c[i] +% (self.c[i] << 3);
            self.c[i] = _internal.rotl32(self.c[i], 21);
            self.c[i] +%= tmp[i];
        }
        return tmp;
    }

    pub fn nextf(self: *Sfc32x16) [sfc32x16_size]f32 {
        var res: [sfc32x16_size]f32 = undefined;
        const v = self.nextu();
        inline for (0..sfc32x16_size) |i| {
            res[i] = _internal.cvtu32_uf(v[i]);
        }
        return res;
    }

    pub fn randi(self: *Sfc32x16, min: i32, max: i32) [sfc32x16_size]i32 {
        var res: [sfc32x16_size]i32 = undefined;
        const v = self.nextu();
        inline for (0..sfc32x16_size) |i| {
            res[i] = _internal.cvtr32_ui(v[i], min, max);
        }
        return res;
    }

    pub fn randf(self: *Sfc32x16, min: f32, max: f32) [sfc32x16_size]f32 {
        var res: [sfc32x16_size]f32 = undefined;
        const v = self.nextu();
        inline for (0..sfc32x16_size) |i| {
            res[i] = _internal.cvtr32_uf(v[i], min, max);
        }
        return res;
    }
};
