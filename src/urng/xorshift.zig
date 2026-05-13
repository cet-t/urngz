const std = @import("std");
const sm = @import("./splitmix.zig");
const _internal = @import("./_internal.zig");

pub const Xorshift16 = struct {
    a: u16,

    pub fn new(seed: u32) Xorshift16 {
        var seedgen = sm.SplitMix32.new(seed);
        return Xorshift16{
            .a = @truncate(seedgen.nextu()),
        };
    }

    pub inline fn nextu(self: *Xorshift16) u16 {
        var x = self.a;
        x ^= x << 7;
        x ^= x >> 9;
        x ^= x << 8;
        self.a = x;
        return self.a;
    }

    pub inline fn nextf(self: *Xorshift16) f32 {
        return _internal.cvtu16_uf(self.nextu());
    }

    pub inline fn randi(self: *Xorshift32, min: i32, max: i32) i32 {
        return _internal.cvtr32_ui(self.nextu(), min, max);
    }

    pub inline fn randf(self: *Xorshift32, min: f32, max: f32) f32 {
        return _internal.cvtr32_uf(self.nextu(), min, max);
    }
};

pub const Xorshift32 = struct {
    a: u32,

    pub fn new(seed: u32) Xorshift32 {
        var seedgen = sm.SplitMix32.new(seed);
        return Xorshift32{
            .a = seedgen.nextu(),
        };
    }

    pub inline fn nextu(self: *Xorshift32) u32 {
        var x = self.a;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.a = x;
        return self.a;
    }

    pub inline fn nextf(self: *Xorshift32) f32 {
        return _internal.cvtu32_uf(self.nextu());
    }

    pub inline fn randi(self: *Xorshift32, min: i32, max: i32) i32 {
        return _internal.cvtr32_ui(self.nextu(), min, max);
    }

    pub inline fn randf(self: *Xorshift32, min: f32, max: f32) f32 {
        return _internal.cvtr32_uf(self.nextu(), min, max);
    }
};

pub const Xorshift64 = struct {
    a: u64,

    pub fn new(seed: u64) Xorshift64 {
        var seedgen = sm.SplitMix64.new(seed);
        return Xorshift64{
            .a = seedgen.nextu(),
        };
    }

    pub inline fn nextu(self: *Xorshift64) u64 {
        var x = self.a;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.a = x;
        return self.a;
    }

    pub inline fn nextf(self: *Xorshift64) f64 {
        return _internal.cvtu64_uf(self.nextu());
    }

    pub inline fn randi(self: *Xorshift64, min: i64, max: i64) i64 {
        return _internal.cvtr64_ui(self.nextu(), min, max);
    }

    pub inline fn randf(self: *Xorshift64, min: f64, max: f64) f64 {
        return _internal.cvtr64_uf(self.nextu(), min, max);
    }
};

pub const Xorshift128 = struct {
    a: [4]u32,

    pub fn new(seed: u32) Xorshift32 {
        var seedgen = sm.SplitMix32.new(seed);
        var a: [4]u32 = undefined;
        inline for (0..4) |i| {
            a[i] = seedgen.nextu();
        }
        return Xorshift32{ .a = a };
    }

    pub inline fn nextu(self: *Xorshift32) u32 {
        var t = self.a[3];
        t ^= t << 11;
        t ^= t >> 8;
        const s = self.a[0];
        {
            // (1, 2, 3) = (0, 1, 2)
            const tmp = s ^ (s >> 19) ^ t;
            self.a[3] = self.a[2];
            self.a[2] = self.a[1];
            self.a[1] = s;
            self.a[0] = tmp;
        }
        self.a[0] = t ^ s ^ (s >> 19);
        return self.a[0];
    }

    pub inline fn nextf(self: *Xorshift32) f32 {
        return _internal.cvtu32_uf(self.nextu());
    }

    pub inline fn randi(self: *Xorshift32, min: i32, max: i32) i32 {
        return _internal.cvtr32_ui(self.nextu(), min, max);
    }

    pub inline fn randf(self: *Xorshift32, min: f32, max: f32) f32 {
        return _internal.cvtr32_uf(self.nextu(), min, max);
    }
};
