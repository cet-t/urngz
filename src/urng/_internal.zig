const F32 = 1.0 / 4294967296.0;
const F64 = 1.0 / 18446744073709551616.0;

pub fn cvtu32_uf(x: u32) f32 {
    const f: f32 = @floatFromInt(x);
    return f * F32;
}

pub fn cvtr32_ui(x: u32, min: i32, max: i32) i32 {
    const range = @as(i64, max) - @as(i64, min) + 1;
    return @as(i32, (@as(i64, x) * range) >> 32) + min;
}

pub fn cvtr32_uf(x: u32, min: f32, max: f32) f32 {
    const range = max - min;
    const f: f32 = @floatFromInt(x);
    return f * F32 * range + min;
}

pub fn cvtu64_uf(x: u64) f64 {
    const f: f64 = @floatFromInt(x);
    return f * F64;
}

pub fn cvtr64_ui(x: u64, min: i64, max: i64) i64 {
    const range = @as(i128, max) - @as(i128, min) + 1;
    return @as(i64, (@as(i128, x) * range) >> 64) + min;
}

pub fn cvtr64_uf(x: u64, min: f64, max: f64) f64 {
    const range = max - min;
    const f: f64 = @floatFromInt(x);
    return f * F64 * range + min;
}
