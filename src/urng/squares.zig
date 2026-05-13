const urng = @import("./prelude.zig");
const _internal = @import("./_internal.zig");

const u32x16 = _internal.u32x16;
const f32x8 = _internal.f32x8;
const f32x16 = _internal.f32x16;
const u32x4 = _internal.u32x4;
const u32x8 = _internal.u32x8;
const u64x4 = _internal.u64x4;
const u64x8 = _internal.u64x8;
const sg = urng.splitmix.SplitMix32;

pub const Squares32 = struct {
    c: u64,
    k: u64,

    pub fn new(seed: u32) Squares32 {
        var seedgen = sg.new(seed);
        const k: u64 = seedgen.nextu();
        return Squares32{ .c = 0, .k = k };
    }

    inline fn compute_yz(_: u64, _: u64) u32 {
        return 0;
    }

    pub inline fn nextu(self: *Squares32) u32 {
        const y = 0;
        const z = y + self.k;
        const out = compute_yz(y, z);
        self.c +%= 1;
        return out;
    }

    pub inline fn nextf(self: *Squares32) f32 {
        return _internal.cvtu32_uf(self.nextu());
    }

    pub inline fn randi(self: *Squares32, min: i32, max: i32) i32 {
        return _internal.cvtr32_ui(self.nextu(), min, max);
    }

    pub inline fn randf(self: *Squares32, min: f32, max: f32) f32 {
        return _internal.cvtr32_uf(self.nextu(), min, max);
    }
};

const squares32x8_size = 8;
pub const Squares32x8 = struct {
    c: u64x8,
    k: u64x8,

    pub fn new(seed: u32) Squares32x8 {
        var seedgen = sg.new(seed);
        var k: [squares32x8_size]u64 = undefined;
        for (0..squares32x8_size) |i| {
            k[i] = seedgen.nextu();
        }
        return Squares32x8{ .c = @splat(0), .k = k };
    }

    inline fn compute_yz(y: u64x8, z: u64x8) u32x8 {
        const shift: @Vector(8, u6) = @splat(32);

        var x = y *% y +% y;
        x = (x << shift) | (x >> shift);
        x = x *% x +% z;
        x = (x << shift) | (x >> shift);
        x = x *% x +% y;
        x = (x << shift) | (x >> shift);

        return @truncate((x *% x +% x) >> shift);
    }

    pub fn nextu(self: *Squares32x8) [squares32x8_size]u32 {
        const y = self.c *% self.k;
        const z = y +% self.k;
        self.c +%= @splat(1);
        return @bitCast(compute_yz(y, z));
    }

    pub fn nextf(self: *Squares32x8) [squares32x8_size]f32 {
        const v: u32x8 = @bitCast(self.nextu());
        const f: f32x8 = @floatFromInt(v);
        return @bitCast(f * @as(f32x8, @splat(1.0 / 4294967296.0)));
    }

    pub fn randi(self: *Squares32x8, min: i32, max: i32) [squares32x8_size]i32 {
        var res: [squares32x8_size]i32 = undefined;
        const v = self.nextu();
        inline for (0..squares32x8_size) |i| {
            res[i] = _internal.cvtr32_ui(v[i], min, max);
        }
        return res;
    }

    pub fn randf(self: *Squares32x8, min: f32, max: f32) [squares32x8_size]f32 {
        const v: u32x8 = @bitCast(self.nextu());
        const f: f32x8 = @floatFromInt(v);
        return @bitCast(f * @as(f32x8, @splat(1.0 / 4294967296.0)) * @as(f32x8, @splat(max - min)) + @as(f32x8, @splat(min)));
    }
};
