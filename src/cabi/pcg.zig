const std = @import("std");
const common = @import("./common.zig");
const _internal = @import("../urng/_internal.zig");
const urng = @import("../urng/prelude.zig");

const Pcg32Handle = opaque {};
const Pcg32x8Handle = opaque {};
const pcg32x8_size = 8;

const Pcg32State = struct {
    state: u64,
    inc: u64,

    inline fn load(rng: *urng.Pcg32) Pcg32State {
        return .{ .state = rng.state, .inc = rng.inc };
    }

    inline fn store(self: Pcg32State, rng: *urng.Pcg32) void {
        rng.* = .{ .state = self.state, .inc = self.inc };
    }

    inline fn nextu(self: *Pcg32State) u32 {
        const oldstate = self.state;
        self.state = oldstate *% 6364136223846793005 +% self.inc;
        const xorshifted: u32 = @truncate(((oldstate >> 18) ^ oldstate) >> 27);
        const rot: u5 = @intCast(oldstate >> 59);
        const inv_rot = 0 -% rot;
        return (xorshifted >> rot) | (xorshifted << inv_rot);
    }
};

const Pcg32x8State = struct {
    rng: urng.Pcg32x8,
    cache: [pcg32x8_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u64) Pcg32x8State {
        return .{ .rng = urng.Pcg32x8.new(seed) };
    }
};

fn toHandle(rng: *urng.Pcg32) *Pcg32Handle {
    return @ptrCast(rng);
}

fn fromHandle(rng: *Pcg32Handle) *urng.Pcg32 {
    return @ptrCast(@alignCast(rng));
}

fn toX8Handle(rng: *Pcg32x8State) *Pcg32x8Handle {
    return @ptrCast(rng);
}

fn fromX8Handle(rng: *Pcg32x8Handle) *Pcg32x8State {
    return @ptrCast(@alignCast(rng));
}

pub export fn pcg32_new(seed: u64) ?*Pcg32Handle {
    const rng = std.heap.page_allocator.create(urng.Pcg32) catch return null;
    rng.* = urng.Pcg32.new(seed);
    return toHandle(rng);
}

pub export fn pcg32_free(rng: ?*Pcg32Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromHandle(handle));
}

pub export fn pcg32_nextu(rng: ?*Pcg32Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const rng_ptr = fromHandle(handle);
    var state = Pcg32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = state.nextu();
        out[i + 1] = state.nextu();
        out[i + 2] = state.nextu();
        out[i + 3] = state.nextu();
    }
    while (i < count) : (i += 1) out[i] = state.nextu();

    state.store(rng_ptr);
}

pub export fn pcg32_nextf(rng: ?*Pcg32Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const rng_ptr = fromHandle(handle);
    var state = Pcg32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = _internal.cvtu32_uf(state.nextu());
        out[i + 1] = _internal.cvtu32_uf(state.nextu());
        out[i + 2] = _internal.cvtu32_uf(state.nextu());
        out[i + 3] = _internal.cvtu32_uf(state.nextu());
    }
    while (i < count) : (i += 1) out[i] = _internal.cvtu32_uf(state.nextu());

    state.store(rng_ptr);
}

pub export fn pcg32_randi(rng: ?*Pcg32Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const rng_ptr = fromHandle(handle);
    var state = Pcg32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = _internal.cvtr32_ui(state.nextu(), min, max);
        out[i + 1] = _internal.cvtr32_ui(state.nextu(), min, max);
        out[i + 2] = _internal.cvtr32_ui(state.nextu(), min, max);
        out[i + 3] = _internal.cvtr32_ui(state.nextu(), min, max);
    }
    while (i < count) : (i += 1) out[i] = _internal.cvtr32_ui(state.nextu(), min, max);

    state.store(rng_ptr);
}

pub export fn pcg32_randf(rng: ?*Pcg32Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const rng_ptr = fromHandle(handle);
    var state = Pcg32State.load(rng_ptr);

    var i: usize = 0;
    while (i + 4 <= count) : (i += 4) {
        out[i] = _internal.cvtr32_uf(state.nextu(), min, max);
        out[i + 1] = _internal.cvtr32_uf(state.nextu(), min, max);
        out[i + 2] = _internal.cvtr32_uf(state.nextu(), min, max);
        out[i + 3] = _internal.cvtr32_uf(state.nextu(), min, max);
    }
    while (i < count) : (i += 1) out[i] = _internal.cvtr32_uf(state.nextu(), min, max);

    state.store(rng_ptr);
}

pub export fn pcg32x8_new(seed: u64) ?*Pcg32x8Handle {
    const rng = std.heap.page_allocator.create(Pcg32x8State) catch return null;
    rng.* = Pcg32x8State.init(seed);
    return toX8Handle(rng);
}

pub export fn pcg32x8_free(rng: ?*Pcg32x8Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX8Handle(handle));
}

pub export fn pcg32x8_nextu(rng: ?*Pcg32x8Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const state = fromX8Handle(handle);
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
    common.normalizeCache(&cache_index, &cache_len);

    while (i + pcg32x8_size <= count) : (i += pcg32x8_size) {
        common.copyChunk(u32, out_ptr[i .. i + pcg32x8_size], rng_state.nextu());
    }
    if (i < count) {
        const values = rng_state.nextu();
        common.copyChunk(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = pcg32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn pcg32x8_nextf(rng: ?*Pcg32x8Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const state = fromX8Handle(handle);
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
    common.normalizeCache(&cache_index, &cache_len);

    while (i + pcg32x8_size <= count) : (i += pcg32x8_size) {
        common.copyChunk(f32, out_ptr[i .. i + pcg32x8_size], rng_state.nextf());
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        cache = values;
        cache_index = count - i;
        cache_len = pcg32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn pcg32x8_randi(rng: ?*Pcg32x8Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const state = fromX8Handle(handle);
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
    common.normalizeCache(&cache_index, &cache_len);

    while (i + pcg32x8_size <= count) : (i += pcg32x8_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < pcg32x8_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = pcg32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn pcg32x8_randf(rng: ?*Pcg32x8Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const state = fromX8Handle(handle);
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
    common.normalizeCache(&cache_index, &cache_len);

    while (i + pcg32x8_size <= count) : (i += pcg32x8_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < pcg32x8_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = pcg32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

test "pcg32_nextu matches Zig implementation" {
    const seed: u64 = 1234;
    const handle = pcg32_new(seed) orelse return error.OutOfMemory;
    defer pcg32_free(handle);

    var actual: [8]u32 = undefined;
    pcg32_nextu(handle, actual[0..].ptr, actual.len);

    var expected = urng.Pcg32.new(seed);
    for (actual) |value| try std.testing.expectEqual(expected.nextu(), value);
}

test "pcg32 range helpers match Zig implementation" {
    const seed: u64 = 5678;
    const int_handle = pcg32_new(seed) orelse return error.OutOfMemory;
    defer pcg32_free(int_handle);

    var actual_int: [6]i32 = undefined;
    pcg32_randi(int_handle, actual_int[0..].ptr, -5, 9, actual_int.len);
    var expected_int = urng.Pcg32.new(seed);
    for (actual_int) |value| try std.testing.expectEqual(_internal.cvtr32_ui(expected_int.nextu(), -5, 9), value);

    const float_handle = pcg32_new(seed) orelse return error.OutOfMemory;
    defer pcg32_free(float_handle);

    var actual_float: [6]f32 = undefined;
    pcg32_randf(float_handle, actual_float[0..].ptr, -0.5, 2.5, actual_float.len);
    var expected_float = urng.Pcg32.new(seed);
    for (actual_float) |value| try std.testing.expectEqual(_internal.cvtr32_uf(expected_float.nextu(), -0.5, 2.5), value);
}

test "pcg32x8_nextu matches linearized Zig implementation" {
    const seed: u64 = 2468;
    const handle = pcg32x8_new(seed) orelse return error.OutOfMemory;
    defer pcg32x8_free(handle);

    var actual: [21]u32 = undefined;
    pcg32x8_nextu(handle, actual[0..5].ptr, 5);
    pcg32x8_nextu(handle, actual[5..].ptr, actual.len - 5);

    var expected_rng = urng.Pcg32x8.new(seed);
    var expected: [21]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < pcg32x8_size and i + j < expected.len) : (j += 1) expected[i + j] = values[j];
        i += j;
    }

    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "pcg32x8 mixed helpers preserve sequence" {
    const seed: u64 = 1357;
    const handle = pcg32x8_new(seed) orelse return error.OutOfMemory;
    defer pcg32x8_free(handle);

    var actual_u: [3]u32 = undefined;
    var actual_f: [5]f32 = undefined;
    var actual_i: [7]i32 = undefined;
    var actual_rf: [9]f32 = undefined;

    pcg32x8_nextu(handle, actual_u[0..].ptr, actual_u.len);
    pcg32x8_nextf(handle, actual_f[0..].ptr, actual_f.len);
    pcg32x8_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    pcg32x8_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);

    var expected_rng = urng.Pcg32x8.new(seed);
    var raw: [24]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < pcg32x8_size and i + j < raw.len) : (j += 1) raw[i + j] = values[j];
        i += j;
    }

    for (actual_u, 0..) |value, index| try std.testing.expectEqual(raw[index], value);
    for (actual_f, 0..) |value, index| try std.testing.expectEqual(_internal.cvtu32_uf(raw[actual_u.len + index]), value);
    for (actual_i, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_ui(raw[actual_u.len + actual_f.len + index], -5, 9), value);
    for (actual_rf, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_uf(raw[actual_u.len + actual_f.len + actual_i.len + index], -0.5, 2.5), value);
}
