pub const u32x4 = @Vector(4, u32);
pub const u32x8 = @Vector(8, u32);
pub const u32x16 = @Vector(16, u32);

pub const i32x4 = @Vector(4, i32);
pub const i32x8 = @Vector(8, i32);
pub const i32x16 = @Vector(16, i32);

pub const f32x4 = @Vector(4, f32);
pub const f32x8 = @Vector(8, f32);
pub const f32x16 = @Vector(16, f32);

pub const u64x2 = @Vector(2, u64);
pub const u64x4 = @Vector(4, u64);
pub const u64x8 = @Vector(8, u64);

pub const i64x2 = @Vector(2, i64);
pub const i64x4 = @Vector(4, i64);
pub const i64x8 = @Vector(8, i64);

pub const f64x2 = @Vector(2, f64);
pub const f64x4 = @Vector(4, f64);
pub const f64x8 = @Vector(8, f64);

const F16 = 1.0 / 65536.0;
const F32 = 1.0 / 4294967296.0;
const F64 = 1.0 / 18446744073709551616.0;

pub inline fn rotl16(x: u16, k: u4) u16 {
    return (x << k) | (x >> @truncate(16 - @as(u5, k)));
}

pub inline fn rotr16(x: u16, k: u4) u16 {
    return (x >> k) | (x << @truncate(16 - @as(u5, k)));
}

pub inline fn rotl32(x: u32, k: u5) u32 {
    return (x << k) | (x >> @truncate(32 - @as(u6, k)));
}

pub inline fn rotr32(x: u32, k: u5) u32 {
    return (x >> k) | (x << @truncate(32 - @as(u6, k)));
}

pub inline fn rotl64(x: u64, k: u64) u64 {
    return (x << k) | (x >> (64 - k));
}

pub inline fn rotr64(x: u64, k: u64) u64 {
    return (x >> k) | (x << (64 - k));
}

pub inline fn cvtu16_uf(x: u16) f32 {
    const f: f32 = @floatFromInt(x);
    return f * F16;
}

pub inline fn cvtr16_ui(x: u16, min: i16, max: i16) i16 {
    const range = @as(i32, max) - @as(i32, min) + 1;
    return @as(i16, @intCast((@as(i32, x) * range) >> 16)) + min;
}

pub inline fn cvtr16_uf(x: u16, min: f32, max: f32) f32 {
    const range = max - min;
    const f: f32 = @floatFromInt(x);
    return f * F16 * range + min;
}

pub inline fn cvtu24_uf(x: u32) f32 {
    const f: f32 = @floatFromInt(x);
    return f * F32 * 256.0;
}

pub inline fn cvtu32_uf(x: u32) f32 {
    const f: f32 = @floatFromInt(x);
    return f * F32;
}

pub inline fn cvtr32_ui(x: u32, min: i32, max: i32) i32 {
    const range = @as(i64, max) - @as(i64, min) + 1;
    return @as(i32, @intCast((@as(i64, x) * range) >> 32)) + min;
}

pub inline fn cvtr32_uf(x: u32, min: f32, max: f32) f32 {
    const range = max - min;
    const f: f32 = @floatFromInt(x);
    return f * F32 * range + min;
}

pub inline fn cvtu64_uf(x: u64) f64 {
    const f: f64 = @floatFromInt(x);
    return f * F64;
}

pub inline fn cvtr64_ui(x: u64, min: i64, max: i64) i64 {
    const range = @as(i128, max) - @as(i128, min) + 1;
    return @as(i64, (@as(i128, x) * range) >> 64) + min;
}

pub inline fn cvtr64_uf(x: u64, min: f64, max: f64) f64 {
    const range = max - min;
    const f: f64 = @floatFromInt(x);
    return f * F64 * range + min;
}
