const std = @import("std");
const _internal = @import("../urng/_internal.zig");
const urng = @import("../urng/prelude.zig");

const Sfc32Handle = opaque {};
const Sfc32x16Handle = opaque {};
const sfc32x16_size = 16;
const Sfc32State = struct {
    a: u32,
    b: u32,
    c: u32,
    counter: u32,

    inline fn load(rng: *urng.Sfc32) Sfc32State {
        return .{
            .a = rng.a,
            .b = rng.b,
            .c = rng.c,
            .counter = rng.counter,
        };
    }

    inline fn store(self: Sfc32State, rng: *urng.Sfc32) void {
        rng.* = .{
            .a = self.a,
            .b = self.b,
            .c = self.c,
            .counter = self.counter,
        };
    }

    inline fn nextu(self: *Sfc32State) u32 {
        const tmp = self.a +% self.b +% self.counter;
        self.counter +%= 1;
        self.a = self.b ^ (self.b >> 9);
        self.b = self.c +% (self.c << 3);
        self.c = _internal.rotl32(self.c, 21);
        self.c +%= tmp;
        return tmp;
    }
};

const Sfc32x16State = struct {
    rng: urng.Sfc32x16,
    cache: [sfc32x16_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Sfc32x16State {
        return .{ .rng = urng.Sfc32x16.new(seed) };
    }

    inline fn normalizeCache(self: *Sfc32x16State) void {
        if (self.cache_index == self.cache_len) {
            self.cache_index = 0;
            self.cache_len = 0;
        }
    }

    inline fn stashRemainder(self: *Sfc32x16State, values: [sfc32x16_size]u32, consumed: usize) void {
        self.cache = values;
        self.cache_index = @intCast(consumed);
        self.cache_len = sfc32x16_size;
        self.normalizeCache();
    }
};

fn toHandle(rng: *urng.Sfc32) *Sfc32Handle {
    return @ptrCast(rng);
}

fn fromHandle(rng: *Sfc32Handle) *urng.Sfc32 {
    return @ptrCast(@alignCast(rng));
}

fn toX16Handle(rng: *Sfc32x16State) *Sfc32x16Handle {
    return @ptrCast(rng);
}

fn fromX16Handle(rng: *Sfc32x16Handle) *Sfc32x16State {
    return @ptrCast(@alignCast(rng));
}

inline fn copyChunk(comptime T: type, dest: []T, src: [sfc32x16_size]T) void {
    @memcpy(dest, src[0..dest.len]);
}

pub export fn sfc32_new(seed: u32) ?*Sfc32Handle {
    const rng = std.heap.page_allocator.create(urng.Sfc32) catch return null;
    rng.* = urng.Sfc32.new(seed);
    return toHandle(rng);
}

pub export fn sfc32_free(rng: ?*Sfc32Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromHandle(handle));
}

pub export fn sfc32_nextu(rng: ?*Sfc32Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Sfc32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = state.nextu();
        out[i + 1] = state.nextu();
        out[i + 2] = state.nextu();
        out[i + 3] = state.nextu();
    }

    while (i < count) : (i += 1) {
        out[i] = state.nextu();
    }

    state.store(rng_ptr);
}

pub export fn sfc32_nextf(rng: ?*Sfc32Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Sfc32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = _internal.cvtu32_uf(state.nextu());
        out[i + 1] = _internal.cvtu32_uf(state.nextu());
        out[i + 2] = _internal.cvtu32_uf(state.nextu());
        out[i + 3] = _internal.cvtu32_uf(state.nextu());
    }

    while (i < count) : (i += 1) {
        out[i] = _internal.cvtu32_uf(state.nextu());
    }

    state.store(rng_ptr);
}

pub export fn sfc32_randi(rng: ?*Sfc32Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Sfc32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = _internal.cvtr32_ui(state.nextu(), min, max);
        out[i + 1] = _internal.cvtr32_ui(state.nextu(), min, max);
        out[i + 2] = _internal.cvtr32_ui(state.nextu(), min, max);
        out[i + 3] = _internal.cvtr32_ui(state.nextu(), min, max);
    }

    while (i < count) : (i += 1) {
        out[i] = _internal.cvtr32_ui(state.nextu(), min, max);
    }

    state.store(rng_ptr);
}

pub export fn sfc32_randf(rng: ?*Sfc32Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Sfc32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = _internal.cvtr32_uf(state.nextu(), min, max);
        out[i + 1] = _internal.cvtr32_uf(state.nextu(), min, max);
        out[i + 2] = _internal.cvtr32_uf(state.nextu(), min, max);
        out[i + 3] = _internal.cvtr32_uf(state.nextu(), min, max);
    }

    while (i < count) : (i += 1) {
        out[i] = _internal.cvtr32_uf(state.nextu(), min, max);
    }

    state.store(rng_ptr);
}

pub export fn sfc32x16_new(seed: u32) ?*Sfc32x16Handle {
    const rng = std.heap.page_allocator.create(Sfc32x16State) catch return null;
    rng.* = Sfc32x16State.init(seed);
    return toX16Handle(rng);
}

pub export fn sfc32x16_free(rng: ?*Sfc32x16Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX16Handle(handle));
}

pub export fn sfc32x16_nextu(rng: ?*Sfc32x16Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const state = fromX16Handle(handle);
    const out_ptr: [*]u32 = @ptrCast(out);
    var rng_state = state.rng;
    var cache = state.cache;
    var cache_index: usize = state.cache_index;
    var cache_len: usize = state.cache_len;

    var i: usize = 0;
    while (i < count and cache_index < cache_len) : (i += 1) {
        out_ptr[i] = cache[cache_index];
        cache_index += 1;
    }
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + sfc32x16_size <= count) : (i += sfc32x16_size) {
        copyChunk(u32, out_ptr[i .. i + sfc32x16_size], rng_state.nextu());
    }

    if (i < count) {
        const values = rng_state.nextu();
        copyChunk(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = sfc32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn sfc32x16_nextf(rng: ?*Sfc32x16Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const state = fromX16Handle(handle);
    const out_ptr: [*]f32 = @ptrCast(out);
    var rng_state = state.rng;
    var cache = state.cache;
    var cache_index: usize = state.cache_index;
    var cache_len: usize = state.cache_len;

    var i: usize = 0;
    while (i < count and cache_index < cache_len) : (i += 1) {
        out_ptr[i] = _internal.cvtu32_uf(cache[cache_index]);
        cache_index += 1;
    }
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + sfc32x16_size <= count) : (i += sfc32x16_size) {
        copyChunk(f32, out_ptr[i .. i + sfc32x16_size], rng_state.nextf());
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        }
        cache = values;
        cache_index = count - i;
        cache_len = sfc32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn sfc32x16_randi(rng: ?*Sfc32x16Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const state = fromX16Handle(handle);
    const out_ptr: [*]i32 = @ptrCast(out);
    var rng_state = state.rng;
    var cache = state.cache;
    var cache_index: usize = state.cache_index;
    var cache_len: usize = state.cache_len;

    var i: usize = 0;
    while (i < count and cache_index < cache_len) : (i += 1) {
        out_ptr[i] = _internal.cvtr32_ui(cache[cache_index], min, max);
        cache_index += 1;
    }
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + sfc32x16_size <= count) : (i += sfc32x16_size) {
        copyChunk(i32, out_ptr[i .. i + sfc32x16_size], rng_state.randi(min, max));
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        }
        cache = values;
        cache_index = count - i;
        cache_len = sfc32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn sfc32x16_randf(rng: ?*Sfc32x16Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const state = fromX16Handle(handle);
    const out_ptr: [*]f32 = @ptrCast(out);
    var rng_state = state.rng;
    var cache = state.cache;
    var cache_index: usize = state.cache_index;
    var cache_len: usize = state.cache_len;

    var i: usize = 0;
    while (i < count and cache_index < cache_len) : (i += 1) {
        out_ptr[i] = _internal.cvtr32_uf(cache[cache_index], min, max);
        cache_index += 1;
    }
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + sfc32x16_size <= count) : (i += sfc32x16_size) {
        copyChunk(f32, out_ptr[i .. i + sfc32x16_size], rng_state.randf(min, max));
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        }
        cache = values;
        cache_index = count - i;
        cache_len = sfc32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

test "sfc32_nextu matches Zig implementation" {
    const seed: u32 = 1234;
    const handle = sfc32_new(seed) orelse return error.OutOfMemory;
    defer sfc32_free(handle);

    var actual: [8]u32 = undefined;
    sfc32_nextu(handle, actual[0..].ptr, actual.len);

    var expected = urng.Sfc32.new(seed);
    for (actual) |value| {
        try std.testing.expectEqual(expected.nextu(), value);
    }
}

test "sfc32 range helpers match Zig implementation" {
    const seed: u32 = 5678;

    const int_handle = sfc32_new(seed) orelse return error.OutOfMemory;
    defer sfc32_free(int_handle);

    var actual_int: [6]i32 = undefined;
    sfc32_randi(int_handle, actual_int[0..].ptr, -5, 9, actual_int.len);

    var expected_int = urng.Sfc32.new(seed);
    for (actual_int) |value| {
        try std.testing.expectEqual(expected_int.randi(-5, 9), value);
    }

    const float_handle = sfc32_new(seed) orelse return error.OutOfMemory;
    defer sfc32_free(float_handle);

    var actual_float: [6]f32 = undefined;
    sfc32_randf(float_handle, actual_float[0..].ptr, -0.5, 2.5, actual_float.len);

    var expected_float = urng.Sfc32.new(seed);
    for (actual_float) |value| {
        try std.testing.expectEqual(expected_float.randf(-0.5, 2.5), value);
    }
}

test "sfc32x16_nextu matches linearized Zig implementation" {
    const seed: u32 = 2468;
    const handle = sfc32x16_new(seed) orelse return error.OutOfMemory;
    defer sfc32x16_free(handle);

    var actual: [37]u32 = undefined;
    sfc32x16_nextu(handle, actual[0..5].ptr, 5);
    sfc32x16_nextu(handle, actual[5..].ptr, actual.len - 5);

    var expected_rng = urng.Sfc32x16.new(seed);
    var expected: [37]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < sfc32x16_size and i + j < expected.len) : (j += 1) {
            expected[i + j] = values[j];
        }
        i += j;
    }

    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "sfc32x16 mixed helpers preserve sequence" {
    const seed: u32 = 1357;
    const handle = sfc32x16_new(seed) orelse return error.OutOfMemory;
    defer sfc32x16_free(handle);

    var actual_u: [3]u32 = undefined;
    var actual_f: [5]f32 = undefined;
    var actual_i: [7]i32 = undefined;
    var actual_rf: [19]f32 = undefined;

    sfc32x16_nextu(handle, actual_u[0..].ptr, actual_u.len);
    sfc32x16_nextf(handle, actual_f[0..].ptr, actual_f.len);
    sfc32x16_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    sfc32x16_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);

    var expected_rng = urng.Sfc32x16.new(seed);
    var raw: [34]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < sfc32x16_size and i + j < raw.len) : (j += 1) {
            raw[i + j] = values[j];
        }
        i += j;
    }

    for (actual_u, 0..) |value, index| {
        try std.testing.expectEqual(raw[index], value);
    }

    for (actual_f, 0..) |value, index| {
        try std.testing.expectEqual(_internal.cvtu32_uf(raw[actual_u.len + index]), value);
    }

    for (actual_i, 0..) |value, index| {
        try std.testing.expectEqual(_internal.cvtr32_ui(raw[actual_u.len + actual_f.len + index], -5, 9), value);
    }

    for (actual_rf, 0..) |value, index| {
        try std.testing.expectEqual(_internal.cvtr32_uf(raw[actual_u.len + actual_f.len + actual_i.len + index], -0.5, 2.5), value);
    }
}
