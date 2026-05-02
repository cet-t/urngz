const std = @import("std");
const sm = @import("./splitmix.zig");
const _internal = @import("./_internal.zig");

const f32x16 = _internal.f32x16;
const u32x16 = _internal.u32x16;
const xoshiro128x16_size = 16;

pub const Xoshiro128Pp = struct {
    s: [4]u32,

    pub fn new(seed: u32) Xoshiro128Pp {
        var seedgen = sm.SplitMix32.new(seed);
        var s: [4]u32 = undefined;
        for (0..4) |i| {
            s[i] = seedgen.nextu();
        }
        return Xoshiro128Pp{
            .s = s,
        };
    }

    pub inline fn nextu(self: *Xoshiro128Pp) u32 {
        const result = self.s[0] + self.s[3];

        const t = self.s[1] << 9;

        self.s[2] ^= self.s[0];
        self.s[3] ^= self.s[1];
        self.s[1] ^= self.s[2];
        self.s[0] ^= self.s[3];

        self.s[2] ^= t;

        self.s[3] = _internal.rotl32(self.s[3], 11);

        return result;
    }
};

pub const Xoshiro128Ss = struct {
    s: [4]u32,

    pub fn new(seed: u32) Xoshiro128Ss {
        var seedgen = sm.SplitMix32.new(seed);
        var s: [4]u32 = undefined;
        for (0..4) |i| {
            s[i] = seedgen.nextu();
        }
        return Xoshiro128Ss{
            .s = s,
        };
    }

    pub inline fn nextu(self: *Xoshiro128Ss) u32 {
        const result = _internal.rotl32(self.s[1] *% 5, 7) *% 9;

        const t = self.s[1] << 9;

        self.s[2] ^= self.s[0];
        self.s[3] ^= self.s[1];
        self.s[1] ^= self.s[2];
        self.s[0] ^= self.s[3];

        self.s[2] ^= t;

        self.s[3] = _internal.rotl32(self.s[3], 11);

        return result;
    }
};

pub const Xoshiro128Ppx16 = struct {
    s0: u32x16,
    s1: u32x16,
    s2: u32x16,
    s3: u32x16,

    pub fn new(seed: u32) Xoshiro128Ppx16 {
        var seedgen = sm.SplitMix32.new(seed);
        var s0: [xoshiro128x16_size]u32 = undefined;
        var s1: [xoshiro128x16_size]u32 = undefined;
        var s2: [xoshiro128x16_size]u32 = undefined;
        var s3: [xoshiro128x16_size]u32 = undefined;

        inline for (0..xoshiro128x16_size) |i| {
            s0[i] = seedgen.nextu();
            s1[i] = seedgen.nextu();
            s2[i] = seedgen.nextu();
            s3[i] = seedgen.nextu();
        }

        return Xoshiro128Ppx16{
            .s0 = s0,
            .s1 = s1,
            .s2 = s2,
            .s3 = s3,
        };
    }

    pub inline fn nextuVec(self: *Xoshiro128Ppx16) u32x16 {
        const result = self.s0 + self.s3;
        const t = self.s1 << @splat(9);
        self.s2 ^= self.s0;
        self.s3 ^= self.s1;
        self.s1 ^= self.s2;
        self.s0 ^= self.s3;
        self.s2 ^= t;
        self.s3 = (self.s3 << @splat(11)) | (self.s3 >> @splat(21));
        return result;
    }

    pub inline fn nextu(self: *Xoshiro128Ppx16) [xoshiro128x16_size]u32 {
        return @bitCast(self.nextuVec());
    }

    pub inline fn nextfVec(self: *Xoshiro128Ppx16) f32x16 {
        const v = self.nextuVec();
        const f: f32x16 = @floatFromInt(v);
        return f * @as(f32x16, @splat(1.0 / 4294967296.0));
    }

    pub inline fn nextf(self: *Xoshiro128Ppx16) [xoshiro128x16_size]f32 {
        return @bitCast(self.nextfVec());
    }
};

pub const Xoshiro128Ssx16 = struct {
    s0: u32x16,
    s1: u32x16,
    s2: u32x16,
    s3: u32x16,

    pub fn new(seed: u32) Xoshiro128Ssx16 {
        var seedgen = sm.SplitMix32.new(seed);
        var s0: [xoshiro128x16_size]u32 = undefined;
        var s1: [xoshiro128x16_size]u32 = undefined;
        var s2: [xoshiro128x16_size]u32 = undefined;
        var s3: [xoshiro128x16_size]u32 = undefined;

        inline for (0..xoshiro128x16_size) |i| {
            s0[i] = seedgen.nextu();
            s1[i] = seedgen.nextu();
            s2[i] = seedgen.nextu();
            s3[i] = seedgen.nextu();
        }

        return Xoshiro128Ssx16{
            .s0 = s0,
            .s1 = s1,
            .s2 = s2,
            .s3 = s3,
        };
    }

    pub inline fn nextuVec(self: *Xoshiro128Ssx16) u32x16 {
        const x = self.s1 *% @as(u32x16, @splat(5));
        const result = ((x << @splat(7)) |
            (x >> @splat(25))) *%
            @as(u32x16, @splat(9));
        const t = self.s1 << @splat(9);
        self.s2 ^= self.s0;
        self.s3 ^= self.s1;
        self.s1 ^= self.s2;
        self.s0 ^= self.s3;
        self.s2 ^= t;
        self.s3 = (self.s3 << @splat(11)) | (self.s3 >> @splat(21));
        return result;
    }

    pub inline fn nextu(self: *Xoshiro128Ssx16) [xoshiro128x16_size]u32 {
        return @bitCast(self.nextuVec());
    }

    pub inline fn nextfVec(self: *Xoshiro128Ssx16) f32x16 {
        const v = self.nextuVec();
        const f: f32x16 = @floatFromInt(v);
        return f * @as(f32x16, @splat(1.0 / 4294967296.0));
    }

    pub inline fn nextf(self: *Xoshiro128Ssx16) [xoshiro128x16_size]f32 {
        return @bitCast(self.nextfVec());
    }
};

test "xoshiro128ssx16 nextu matches scalarized reference" {
    const seed: u32 = 1234;
    var rng = Xoshiro128Ssx16.new(seed);
    var seedgen = sm.SplitMix32.new(seed);
    var refs: [xoshiro128x16_size]Xoshiro128Ss = undefined;

    for (0..xoshiro128x16_size) |i| {
        refs[i] = .{
            .s = .{
                seedgen.nextu(),
                seedgen.nextu(),
                seedgen.nextu(),
                seedgen.nextu(),
            },
        };
    }

    for (0..8) |_| {
        const actual = rng.nextu();
        for (0..xoshiro128x16_size) |i| {
            try std.testing.expectEqual(refs[i].nextu(), actual[i]);
        }
    }
}
