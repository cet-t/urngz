const std = @import("std");
const _internal = @import("../urng/_internal.zig");
const urng = @import("../urng/prelude.zig");

const Squares32Handle = opaque {};
const Squares32x8Handle = opaque {};
const Squares32x16Handle = opaque {};
const Squares32x64Handle = opaque {};
const squares32x8_size = 8;
const squares32x16_size = 16;
const squares32x64_size = 64;

const Squares32State = struct {
    c: u64,
    k: u64,
    k2: u64,

    inline fn load(rng: *urng.Squares32) Squares32State {
        return .{
            .c = rng.c,
            .k = rng.k,
            .k2 = rng.k2,
        };
    }

    inline fn store(self: Squares32State, rng: *urng.Squares32) void {
        rng.* = .{
            .c = self.c,
            .k = self.k,
            .k2 = self.k2,
        };
    }

    inline fn nextu(self: *Squares32State) u32 {
        const y = self.c *% self.k;
        const z = self.c *% self.k2;

        var x = y *% y +% y;
        x = _internal.rotl64(x, 32);

        x = x *% x +% z;
        x = _internal.rotl64(x, 32);

        x = x *% x +% y;
        x = _internal.rotl64(x, 32);

        const out: u32 = @truncate((x *% x +% x) >> 32);

        self.c +%= 1;
        return out;
    }
};

const Squares32x8State = struct {
    rng: urng.Squares32x8,
    cache: [squares32x8_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Squares32x8State {
        return .{ .rng = urng.Squares32x8.new(seed) };
    }
};

const Squares32x16State = struct {
    rng: urng.Squares32x16,
    cache: [squares32x16_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Squares32x16State {
        return .{ .rng = urng.Squares32x16.new(seed) };
    }
};

const Squares32x64State = struct {
    rng: urng.Squares32x64,
    cache: [squares32x64_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Squares32x64State {
        return .{ .rng = urng.Squares32x64.new(seed) };
    }
};

fn toHandle(rng: *urng.Squares32) *Squares32Handle {
    return @ptrCast(rng);
}

fn fromHandle(rng: *Squares32Handle) *urng.Squares32 {
    return @ptrCast(@alignCast(rng));
}

fn toX8Handle(rng: *Squares32x8State) *Squares32x8Handle {
    return @ptrCast(rng);
}

fn fromX8Handle(rng: *Squares32x8Handle) *Squares32x8State {
    return @ptrCast(@alignCast(rng));
}

fn toX16Handle(rng: *Squares32x16State) *Squares32x16Handle {
    return @ptrCast(rng);
}

fn fromX16Handle(rng: *Squares32x16Handle) *Squares32x16State {
    return @ptrCast(@alignCast(rng));
}

fn toX64Handle(rng: *Squares32x64State) *Squares32x64Handle {
    return @ptrCast(rng);
}

fn fromX64Handle(rng: *Squares32x64Handle) *Squares32x64State {
    return @ptrCast(@alignCast(rng));
}

inline fn copyChunk8(comptime T: type, dest: []T, src: [squares32x8_size]T) void {
    @memcpy(dest, src[0..dest.len]);
}

inline fn copyChunk16(comptime T: type, dest: []T, src: [squares32x16_size]T) void {
    @memcpy(dest, src[0..dest.len]);
}

inline fn copyChunk64(comptime T: type, dest: []T, src: [squares32x64_size]T) void {
    @memcpy(dest, src[0..dest.len]);
}

pub export fn squares32_new(seed: u32) ?*Squares32Handle {
    const rng = std.heap.page_allocator.create(urng.Squares32) catch return null;
    rng.* = urng.Squares32.new(seed);
    return toHandle(rng);
}

pub export fn squares32_free(rng: ?*Squares32Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromHandle(handle));
}

pub export fn squares32_nextu(rng: ?*Squares32Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Squares32State.load(rng_ptr);

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

pub export fn squares32_nextf(rng: ?*Squares32Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Squares32State.load(rng_ptr);

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

pub export fn squares32_randi(rng: ?*Squares32Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Squares32State.load(rng_ptr);

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

pub export fn squares32_randf(rng: ?*Squares32Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

    const rng_ptr = fromHandle(handle);
    var state = Squares32State.load(rng_ptr);

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

pub export fn squares32x8_new(seed: u32) ?*Squares32x8Handle {
    const rng = std.heap.page_allocator.create(Squares32x8State) catch return null;
    rng.* = Squares32x8State.init(seed);
    return toX8Handle(rng);
}

pub export fn squares32x8_free(rng: ?*Squares32x8Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX8Handle(handle));
}

pub export fn squares32x8_nextu(rng: ?*Squares32x8Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

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
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + squares32x8_size <= count) : (i += squares32x8_size) {
        copyChunk8(u32, out_ptr[i .. i + squares32x8_size], rng_state.nextu());
    }

    if (i < count) {
        const values = rng_state.nextu();
        copyChunk8(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = squares32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x8_nextf(rng: ?*Squares32x8Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

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
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + squares32x8_size <= count) : (i += squares32x8_size) {
        copyChunk8(f32, out_ptr[i .. i + squares32x8_size], rng_state.nextf());
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        }
        cache = values;
        cache_index = count - i;
        cache_len = squares32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x8_randi(rng: ?*Squares32x8Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

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
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + squares32x8_size <= count) : (i += squares32x8_size) {
        copyChunk8(i32, out_ptr[i .. i + squares32x8_size], rng_state.randi(min, max));
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        }
        cache = values;
        cache_index = count - i;
        cache_len = squares32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x8_randf(rng: ?*Squares32x8Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) {
        return;
    }

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
    if (cache_index == cache_len) {
        cache_index = 0;
        cache_len = 0;
    }

    while (i + squares32x8_size <= count) : (i += squares32x8_size) {
        copyChunk8(f32, out_ptr[i .. i + squares32x8_size], rng_state.randf(min, max));
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        }
        cache = values;
        cache_index = count - i;
        cache_len = squares32x8_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x16_new(seed: u32) ?*Squares32x16Handle {
    const rng = std.heap.page_allocator.create(Squares32x16State) catch return null;
    rng.* = Squares32x16State.init(seed);
    return toX16Handle(rng);
}

pub export fn squares32x16_free(rng: ?*Squares32x16Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX16Handle(handle));
}

pub export fn squares32x16_nextu(rng: ?*Squares32x16Handle, out: [*c]u32, count: usize) void {
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

    while (i + squares32x16_size <= count) : (i += squares32x16_size) {
        copyChunk16(u32, out_ptr[i .. i + squares32x16_size], rng_state.nextu());
    }

    if (i < count) {
        const values = rng_state.nextu();
        copyChunk16(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = squares32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x16_nextf(rng: ?*Squares32x16Handle, out: [*c]f32, count: usize) void {
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

    while (i + squares32x16_size <= count) : (i += squares32x16_size) {
        copyChunk16(f32, out_ptr[i .. i + squares32x16_size], rng_state.nextf());
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        }
        cache = values;
        cache_index = count - i;
        cache_len = squares32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x16_randi(rng: ?*Squares32x16Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
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

    while (i + squares32x16_size <= count) : (i += squares32x16_size) {
        copyChunk16(i32, out_ptr[i .. i + squares32x16_size], rng_state.randi(min, max));
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        }
        cache = values;
        cache_index = count - i;
        cache_len = squares32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x16_randf(rng: ?*Squares32x16Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
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

    while (i + squares32x16_size <= count) : (i += squares32x16_size) {
        copyChunk16(f32, out_ptr[i .. i + squares32x16_size], rng_state.randf(min, max));
    }

    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) {
            out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        }
        cache = values;
        cache_index = count - i;
        cache_len = squares32x16_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn squares32x64_new(seed: u32) ?*Squares32x64Handle {
    const rng = std.heap.page_allocator.create(Squares32x64State) catch return null;
    rng.* = Squares32x64State.init(seed);
    return toX64Handle(rng);
}

pub export fn squares32x64_free(rng: ?*Squares32x64Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX64Handle(handle));
}

pub export fn squares32x64_nextu(rng: ?*Squares32x64Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;

    const state = fromX64Handle(handle);
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

    while (i + squares32x64_size <= count) : (i += squares32x64_size) {
        copyChunk64(u32, out_ptr[i .. i + squares32x64_size], rng_state.nextu());
    }

    if (i < count) {
        const values = rng_state.nextu();
        copyChunk64(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = squares32x64_size;
    }

    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

test "squares32_nextu matches Zig implementation" {
    const seed: u32 = 1234;
    const handle = squares32_new(seed) orelse return error.OutOfMemory;
    defer squares32_free(handle);

    var actual: [8]u32 = undefined;
    squares32_nextu(handle, actual[0..].ptr, actual.len);

    var expected = urng.Squares32.new(seed);
    for (actual) |value| {
        try std.testing.expectEqual(expected.nextu(), value);
    }
}

test "squares32 range helpers match Zig implementation" {
    const seed: u32 = 5678;

    const int_handle = squares32_new(seed) orelse return error.OutOfMemory;
    defer squares32_free(int_handle);

    var actual_int: [6]i32 = undefined;
    squares32_randi(int_handle, actual_int[0..].ptr, -5, 9, actual_int.len);

    var expected_int = urng.Squares32.new(seed);
    for (actual_int) |value| {
        try std.testing.expectEqual(expected_int.randi(-5, 9), value);
    }

    const float_handle = squares32_new(seed) orelse return error.OutOfMemory;
    defer squares32_free(float_handle);

    var actual_float: [6]f32 = undefined;
    squares32_randf(float_handle, actual_float[0..].ptr, -0.5, 2.5, actual_float.len);

    var expected_float = urng.Squares32.new(seed);
    for (actual_float) |value| {
        try std.testing.expectEqual(expected_float.randf(-0.5, 2.5), value);
    }
}

test "squares32x8_nextu matches linearized Zig implementation" {
    const seed: u32 = 2468;
    const handle = squares32x8_new(seed) orelse return error.OutOfMemory;
    defer squares32x8_free(handle);

    var actual: [37]u32 = undefined;
    squares32x8_nextu(handle, actual[0..5].ptr, 5);
    squares32x8_nextu(handle, actual[5..].ptr, actual.len - 5);

    var expected_rng = urng.Squares32x8.new(seed);
    var expected: [37]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < squares32x8_size and i + j < expected.len) : (j += 1) {
            expected[i + j] = values[j];
        }
        i += j;
    }

    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "squares32x8 mixed helpers preserve sequence" {
    const seed: u32 = 1357;
    const handle = squares32x8_new(seed) orelse return error.OutOfMemory;
    defer squares32x8_free(handle);

    var actual_u: [3]u32 = undefined;
    var actual_f: [5]f32 = undefined;
    var actual_i: [7]i32 = undefined;
    var actual_rf: [19]f32 = undefined;

    squares32x8_nextu(handle, actual_u[0..].ptr, actual_u.len);
    squares32x8_nextf(handle, actual_f[0..].ptr, actual_f.len);
    squares32x8_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    squares32x8_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);

    var expected_rng = urng.Squares32x8.new(seed);
    var raw: [34]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < squares32x8_size and i + j < raw.len) : (j += 1) {
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

test "squares32x16_nextu matches linearized Zig implementation" {
    const seed: u32 = 3691;
    const handle = squares32x16_new(seed) orelse return error.OutOfMemory;
    defer squares32x16_free(handle);

    var actual: [53]u32 = undefined;
    squares32x16_nextu(handle, actual[0..7].ptr, 7);
    squares32x16_nextu(handle, actual[7..].ptr, actual.len - 7);

    var expected_rng = urng.Squares32x16.new(seed);
    var expected: [53]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < squares32x16_size and i + j < expected.len) : (j += 1) {
            expected[i + j] = values[j];
        }
        i += j;
    }

    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "squares32x16 mixed helpers preserve sequence" {
    const seed: u32 = 8024;
    const handle = squares32x16_new(seed) orelse return error.OutOfMemory;
    defer squares32x16_free(handle);

    var actual_u: [5]u32 = undefined;
    var actual_f: [9]f32 = undefined;
    var actual_i: [11]i32 = undefined;
    var actual_rf: [23]f32 = undefined;

    squares32x16_nextu(handle, actual_u[0..].ptr, actual_u.len);
    squares32x16_nextf(handle, actual_f[0..].ptr, actual_f.len);
    squares32x16_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    squares32x16_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);

    var expected_rng = urng.Squares32x16.new(seed);
    var raw: [48]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < squares32x16_size and i + j < raw.len) : (j += 1) {
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

test "squares32x64_nextu matches linearized Zig implementation" {
    const seed: u32 = 7531;
    const handle = squares32x64_new(seed) orelse return error.OutOfMemory;
    defer squares32x64_free(handle);

    var actual: [193]u32 = undefined;
    squares32x64_nextu(handle, actual[0..37].ptr, 37);
    squares32x64_nextu(handle, actual[37..].ptr, actual.len - 37);

    var expected_rng = urng.Squares32x64.new(seed);
    var expected: [193]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < squares32x64_size and i + j < expected.len) : (j += 1) {
            expected[i + j] = values[j];
        }
        i += j;
    }

    try std.testing.expectEqualSlices(u32, &expected, &actual);
}
