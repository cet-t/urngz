const std = @import("std");
const common = @import("./common.zig");
const _internal = @import("../urng/_internal.zig");
const urng = @import("../urng/prelude.zig");

const f32x16 = _internal.f32x16;
const u32x16 = _internal.u32x16;
const Jsf32Handle = opaque {};
const Jsf32x16Handle = opaque {};
const jsf32x16_size = 16;

const Jsf32State = struct {
    a: u32,
    b: u32,
    c: u32,
    d: u32,

    inline fn load(rng: *urng.Jsf32) Jsf32State {
        return .{ .a = rng.a, .b = rng.b, .c = rng.c, .d = rng.d };
    }

    inline fn store(self: Jsf32State, rng: *urng.Jsf32) void {
        rng.* = .{ .a = self.a, .b = self.b, .c = self.c, .d = self.d };
    }

    inline fn nextu(self: *Jsf32State) u32 {
        const e = self.a -% _internal.rotl32(self.b, 27);
        self.a = self.b ^ _internal.rotl32(self.c, 17);
        self.b = self.c +% self.d;
        self.c = self.d +% e;
        self.d = e +% self.a;
        return self.d;
    }
};

const Jsf32x16State = struct {
    rng: urng.Jsf32x16,
    cache: [jsf32x16_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Jsf32x16State {
        return .{ .rng = urng.Jsf32x16.new(seed) };
    }
};

fn toHandle(rng: *urng.Jsf32) *Jsf32Handle {
    return @ptrCast(rng);
}

fn fromHandle(rng: *Jsf32Handle) *urng.Jsf32 {
    return @ptrCast(@alignCast(rng));
}

fn toX16Handle(rng: *Jsf32x16State) *Jsf32x16Handle {
    return @ptrCast(rng);
}

fn fromX16Handle(rng: *Jsf32x16Handle) *Jsf32x16State {
    return @ptrCast(@alignCast(rng));
}

pub export fn jsf32_new(seed: u32) ?*Jsf32Handle {
    const rng = std.heap.page_allocator.create(urng.Jsf32) catch return null;
    rng.* = urng.Jsf32.new(seed);
    return toHandle(rng);
}

pub export fn jsf32_free(rng: ?*Jsf32Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromHandle(handle));
}

pub export fn jsf32_nextu(rng: ?*Jsf32Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Jsf32State.load(rng_ptr);
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

pub export fn jsf32_nextf(rng: ?*Jsf32Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Jsf32State.load(rng_ptr);
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

pub export fn jsf32_randi(rng: ?*Jsf32Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Jsf32State.load(rng_ptr);
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

pub export fn jsf32_randf(rng: ?*Jsf32Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Jsf32State.load(rng_ptr);
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

pub export fn jsf32x16_new(seed: u32) ?*Jsf32x16Handle {
    const rng = std.heap.page_allocator.create(Jsf32x16State) catch return null;
    rng.* = Jsf32x16State.init(seed);
    return toX16Handle(rng);
}

pub export fn jsf32x16_free(rng: ?*Jsf32x16Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX16Handle(handle));
}

pub export fn jsf32x16_nextu(rng: ?*Jsf32x16Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
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
    common.normalizeCache(&cache_index, &cache_len);
    while (i + jsf32x16_size <= count) : (i += jsf32x16_size) {
        const chunk_ptr: *align(1) u32x16 = @ptrCast(out_ptr + i);
        chunk_ptr.* = rng_state.nextuVec();
    }

    if (i < count) {
        const values = rng_state.nextu();
        common.copyChunk(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = jsf32x16_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn jsf32x16_nextf(rng: ?*Jsf32x16Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
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
    common.normalizeCache(&cache_index, &cache_len);

    while (i + jsf32x16_size <= count) : (i += jsf32x16_size) {
        const chunk_ptr: *align(1) f32x16 = @ptrCast(out_ptr + i);
        chunk_ptr.* = rng_state.nextfVec();
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        cache = values;
        cache_index = count - i;
        cache_len = jsf32x16_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn jsf32x16_randi(rng: ?*Jsf32x16Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
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
    common.normalizeCache(&cache_index, &cache_len);
    while (i + jsf32x16_size <= count) : (i += jsf32x16_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < jsf32x16_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = jsf32x16_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn jsf32x16_randf(rng: ?*Jsf32x16Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
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
    common.normalizeCache(&cache_index, &cache_len);
    while (i + jsf32x16_size <= count) : (i += jsf32x16_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < jsf32x16_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = jsf32x16_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

test "jsf32_nextu matches Zig implementation" {
    const seed: u32 = 1234;
    const handle = jsf32_new(seed) orelse return error.OutOfMemory;
    defer jsf32_free(handle);
    var actual: [8]u32 = undefined;
    jsf32_nextu(handle, actual[0..].ptr, actual.len);
    var expected = urng.Jsf32.new(seed);
    for (actual) |value| try std.testing.expectEqual(expected.nextu(), value);
}

test "jsf32 range helpers match Zig implementation" {
    const seed: u32 = 5678;
    const int_handle = jsf32_new(seed) orelse return error.OutOfMemory;
    defer jsf32_free(int_handle);
    var actual_int: [6]i32 = undefined;
    jsf32_randi(int_handle, actual_int[0..].ptr, -5, 9, actual_int.len);
    var expected_int = urng.Jsf32.new(seed);
    for (actual_int) |value| try std.testing.expectEqual(_internal.cvtr32_ui(expected_int.nextu(), -5, 9), value);
    const float_handle = jsf32_new(seed) orelse return error.OutOfMemory;
    defer jsf32_free(float_handle);
    var actual_float: [6]f32 = undefined;
    jsf32_randf(float_handle, actual_float[0..].ptr, -0.5, 2.5, actual_float.len);
    var expected_float = urng.Jsf32.new(seed);
    for (actual_float) |value| try std.testing.expectEqual(_internal.cvtr32_uf(expected_float.nextu(), -0.5, 2.5), value);
}

test "jsf32x16_nextu matches linearized Zig implementation" {
    const seed: u32 = 2468;
    const handle = jsf32x16_new(seed) orelse return error.OutOfMemory;
    defer jsf32x16_free(handle);
    var actual: [37]u32 = undefined;
    jsf32x16_nextu(handle, actual[0..5].ptr, 5);
    jsf32x16_nextu(handle, actual[5..].ptr, actual.len - 5);
    var expected_rng = urng.Jsf32x16.new(seed);
    var expected: [37]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < jsf32x16_size and i + j < expected.len) : (j += 1) expected[i + j] = values[j];
        i += j;
    }
    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "jsf32x16 mixed helpers preserve sequence" {
    const seed: u32 = 1357;
    const handle = jsf32x16_new(seed) orelse return error.OutOfMemory;
    defer jsf32x16_free(handle);
    var actual_u: [3]u32 = undefined;
    var actual_f: [5]f32 = undefined;
    var actual_i: [7]i32 = undefined;
    var actual_rf: [19]f32 = undefined;
    jsf32x16_nextu(handle, actual_u[0..].ptr, actual_u.len);
    jsf32x16_nextf(handle, actual_f[0..].ptr, actual_f.len);
    jsf32x16_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    jsf32x16_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);
    var expected_rng = urng.Jsf32x16.new(seed);
    var raw: [34]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < jsf32x16_size and i + j < raw.len) : (j += 1) raw[i + j] = values[j];
        i += j;
    }
    for (actual_u, 0..) |value, index| try std.testing.expectEqual(raw[index], value);
    for (actual_f, 0..) |value, index| try std.testing.expectEqual(_internal.cvtu32_uf(raw[actual_u.len + index]), value);
    for (actual_i, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_ui(raw[actual_u.len + actual_f.len + index], -5, 9), value);
    for (actual_rf, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_uf(raw[actual_u.len + actual_f.len + actual_i.len + index], -0.5, 2.5), value);
}
