const urng = @import("./prelude.zig");
const _internal = @import("./_internal.zig");

const f32x16 = _internal.f32x16;
const sg = urng.splitmix.SplitMix32;
const u32x16 = _internal.u32x16;

/// Jenkins Small Fast implementation.
///
/// # Example
///
/// ```zig
/// const std = @import("std");
/// const urng = @import("./prelude.zig");
///
/// var mt = urng.Jsf32.new(0);
/// for (0..) |i| {
///    std.debug.print("[{d}] Jsf32: {d}\n", .{ i, mt.nextu() });
/// }
/// ```
pub const Jsf32 = struct {
    a: u32,
    b: u32,
    c: u32,
    d: u32,

    pub fn new(seed: u32) Jsf32 {
        var seedgen = sg.new(seed);

        return Jsf32{
            .a = seedgen.nextu(),
            .b = seedgen.nextu(),
            .c = seedgen.nextu(),
            .d = seedgen.nextu(),
        };
    }

    pub inline fn nextu(self: *Jsf32) u32 {
        const e = self.a -% _internal.rotl32(self.b, 27);
        self.a = self.b ^ _internal.rotl32(self.c, 17);
        self.b = self.c +% self.d;
        self.c = self.d +% e;
        self.d = e +% self.a;

        return self.d;
    }
};

const jsf32x16_size = 16;

/// Jenkins Small Fast Vectorise implementation.
///
/// # Example
///
/// ```zig
/// const std = @import("std");
/// const urng = @import("./prelude.zig");
///
/// var mt = urng.Jsf32x16.new(0);
/// for (0..) |i| {
///    std.debug.print("[{d}] Jsf32x16: {d}\n", .{ i, mt.nextu() });
/// }
/// ```
pub const Jsf32x16 = struct {
    a: u32x16,
    b: u32x16,
    c: u32x16,
    d: u32x16,

    pub fn new(seed: u32) Jsf32x16 {
        var seedgen = sg.new(seed);
        var a: [jsf32x16_size]u32 = undefined;
        var b: [jsf32x16_size]u32 = undefined;
        var c: [jsf32x16_size]u32 = undefined;
        var d: [jsf32x16_size]u32 = undefined;
        for (0..jsf32x16_size) |i| {
            a[i] = seedgen.nextu();
            b[i] = seedgen.nextu();
            c[i] = seedgen.nextu();
            d[i] = seedgen.nextu();
        }
        return Jsf32x16{
            .a = a,
            .b = b,
            .c = c,
            .d = d,
        };
    }

    pub inline fn nextuVec(self: *Jsf32x16) u32x16 {
        const e = self.a -% ((self.b << @splat(27)) | (self.b >> @splat(5)));
        self.a = self.b ^ ((self.c << @splat(17)) | (self.c >> @splat(15)));
        self.b = self.c +% self.d;
        self.c = self.d +% e;
        self.d = e +% self.a;
        return self.d;
    }

    pub inline fn nextu(self: *Jsf32x16) [jsf32x16_size]u32 {
        return @bitCast(self.nextuVec());
    }

    pub inline fn nextfVec(self: *Jsf32x16) f32x16 {
        const v = self.nextuVec();
        const f: f32x16 = @floatFromInt(v);
        return f * @as(f32x16, @splat(1.0 / 4294967296.0));
    }

    pub inline fn nextf(self: *Jsf32x16) [jsf32x16_size]f32 {
        return @bitCast(self.nextfVec());
    }
};
