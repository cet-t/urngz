const urng = @import("./prelude.zig");
const _internal = @import("./_internal.zig");

const u32x16 = _internal.u32x16;
const f32x16 = _internal.f32x16;
const sg = urng.splitmix.SplitMix32;

/// Small Fast Chaotic Implementation.
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

        self.counter +%= 1;
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

pub const Sfc32x16 = struct {
    a: u32x16,
    b: u32x16,
    c: u32x16,
    counter: u32x16,

    pub fn new(seed: u32) Sfc32x16 {
        var seedgen = sg.new(seed);
        var a: [sfc32x16_size]u32 = undefined;
        var b: [sfc32x16_size]u32 = undefined;
        var c: [sfc32x16_size]u32 = undefined;
        var counter: [sfc32x16_size]u32 = undefined;
        for (0..sfc32x16_size) |i| {
            a[i] = seedgen.nextu();
            b[i] = seedgen.nextu();
            c[i] = seedgen.nextu();
            counter[i] = 1;
        }
        return Sfc32x16{ .a = a, .b = b, .c = c, .counter = counter };
    }

    pub fn nextu(self: *Sfc32x16) [sfc32x16_size]u32 {
        const tmp = self.a +% self.b +% self.counter;
        self.counter +%= @splat(1);
        self.a = self.b ^ (self.b >> @splat(9));
        self.b = self.c +% (self.c << @splat(3));
        self.c = (self.c << @splat(21)) | (self.c >> @splat(11));
        self.c +%= tmp;
        return @bitCast(tmp);
    }

    pub fn nextf(self: *Sfc32x16) [sfc32x16_size]f32 {
        const v: u32x16 = @bitCast(self.nextu());
        const f: f32x16 = @floatFromInt(v);
        return @bitCast(f * @as(f32x16, @splat(1.0 / 4294967296.0)));
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
        const v: u32x16 = @bitCast(self.nextu());
        const f: f32x16 = @floatFromInt(v);
        return @bitCast(f * @as(f32x16, @splat(1.0 / 4294967296.0)) * @as(f32x16, @splat(max - min)) + @as(f32x16, @splat(min)));
    }
};
