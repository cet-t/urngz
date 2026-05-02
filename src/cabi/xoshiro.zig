const std = @import("std");
const common = @import("./common.zig");
const _internal = @import("../urng/_internal.zig");
const urng = @import("../urng/prelude.zig");

const f32x16 = _internal.f32x16;
const u32x16 = _internal.u32x16;
const Xoshiro128SsHandle = opaque {};
const Xoshiro128PpHandle = opaque {};
const Xoshiro128Ssx16Handle = opaque {};
const Xoshiro128Ppx16Handle = opaque {};
const xoshiro128pp_size = 16;

const Xoshiro128SsState = struct {
    s0: u32,
    s1: u32,
    s2: u32,
    s3: u32,

    inline fn load(rng: *urng.Xoshiro128Ss) Xoshiro128SsState {
        return .{ .s0 = rng.s[0], .s1 = rng.s[1], .s2 = rng.s[2], .s3 = rng.s[3] };
    }

    inline fn store(self: Xoshiro128SsState, rng: *urng.Xoshiro128Ss) void {
        rng.* = .{ .s = .{ self.s0, self.s1, self.s2, self.s3 } };
    }

    inline fn nextu(self: *Xoshiro128SsState) u32 {
        const result = _internal.rotl32(self.s1 *% 5, 7) *% 9;
        const t = self.s1 << 9;
        self.s2 ^= self.s0;
        self.s3 ^= self.s1;
        self.s1 ^= self.s2;
        self.s0 ^= self.s3;
        self.s2 ^= t;
        self.s3 = _internal.rotl32(self.s3, 11);
        return result;
    }
};

const Xoshiro128PpState = struct {
    s0: u32,
    s1: u32,
    s2: u32,
    s3: u32,

    inline fn load(rng: *urng.Xoshiro128Pp) Xoshiro128PpState {
        return .{ .s0 = rng.s[0], .s1 = rng.s[1], .s2 = rng.s[2], .s3 = rng.s[3] };
    }

    inline fn store(self: Xoshiro128PpState, rng: *urng.Xoshiro128Pp) void {
        rng.* = .{ .s = .{ self.s0, self.s1, self.s2, self.s3 } };
    }

    inline fn nextu(self: *Xoshiro128PpState) u32 {
        const result = self.s0 + self.s3;
        const t = self.s1 << 9;
        self.s2 ^= self.s0;
        self.s3 ^= self.s1;
        self.s1 ^= self.s2;
        self.s0 ^= self.s3;
        self.s2 ^= t;
        self.s3 = _internal.rotl32(self.s3, 11);
        return result;
    }
};

const Xoshiro128Ppx16State = struct {
    rng: urng.Xoshiro128Ppx16,
    cache: [xoshiro128pp_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Xoshiro128Ppx16State {
        return .{ .rng = urng.Xoshiro128Ppx16.new(seed) };
    }
};

const Xoshiro128Ssx16State = struct {
    rng: urng.Xoshiro128Ssx16,
    cache: [xoshiro128pp_size]u32 = undefined,
    cache_index: u8 = 0,
    cache_len: u8 = 0,

    inline fn init(seed: u32) Xoshiro128Ssx16State {
        return .{ .rng = urng.Xoshiro128Ssx16.new(seed) };
    }
};

fn toSsHandle(rng: *urng.Xoshiro128Ss) *Xoshiro128SsHandle {
    return @ptrCast(rng);
}
fn fromSsHandle(rng: *Xoshiro128SsHandle) *urng.Xoshiro128Ss {
    return @ptrCast(@alignCast(rng));
}

fn toHandle(rng: *urng.Xoshiro128Pp) *Xoshiro128PpHandle {
    return @ptrCast(rng);
}
fn fromHandle(rng: *Xoshiro128PpHandle) *urng.Xoshiro128Pp {
    return @ptrCast(@alignCast(rng));
}
fn toSsX16Handle(rng: *Xoshiro128Ssx16State) *Xoshiro128Ssx16Handle {
    return @ptrCast(rng);
}
fn fromSsX16Handle(rng: *Xoshiro128Ssx16Handle) *Xoshiro128Ssx16State {
    return @ptrCast(@alignCast(rng));
}
fn toX16Handle(rng: *Xoshiro128Ppx16State) *Xoshiro128Ppx16Handle {
    return @ptrCast(rng);
}
fn fromX16Handle(rng: *Xoshiro128Ppx16Handle) *Xoshiro128Ppx16State {
    return @ptrCast(@alignCast(rng));
}

pub export fn xoshiro128ss_new(seed: u32) ?*Xoshiro128SsHandle {
    const rng = std.heap.page_allocator.create(urng.Xoshiro128Ss) catch return null;
    rng.* = urng.Xoshiro128Ss.new(seed);
    return toSsHandle(rng);
}

pub export fn xoshiro128ss_free(rng: ?*Xoshiro128SsHandle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromSsHandle(handle));
}

pub export fn xoshiro128ss_nextu(rng: ?*Xoshiro128SsHandle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromSsHandle(handle);
    var state = Xoshiro128SsState.load(rng_ptr);
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

pub export fn xoshiro128ss_nextf(rng: ?*Xoshiro128SsHandle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromSsHandle(handle);
    var state = Xoshiro128SsState.load(rng_ptr);
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

pub export fn xoshiro128ss_randi(rng: ?*Xoshiro128SsHandle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromSsHandle(handle);
    var state = Xoshiro128SsState.load(rng_ptr);
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

pub export fn xoshiro128ss_randf(rng: ?*Xoshiro128SsHandle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromSsHandle(handle);
    var state = Xoshiro128SsState.load(rng_ptr);
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

pub export fn xoshiro128pp_new(seed: u32) ?*Xoshiro128PpHandle {
    const rng = std.heap.page_allocator.create(urng.Xoshiro128Pp) catch return null;
    rng.* = urng.Xoshiro128Pp.new(seed);
    return toHandle(rng);
}

pub export fn xoshiro128pp_free(rng: ?*Xoshiro128PpHandle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromHandle(handle));
}

pub export fn xoshiro128pp_nextu(rng: ?*Xoshiro128PpHandle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Xoshiro128PpState.load(rng_ptr);
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

pub export fn xoshiro128pp_nextf(rng: ?*Xoshiro128PpHandle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Xoshiro128PpState.load(rng_ptr);
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

pub export fn xoshiro128pp_randi(rng: ?*Xoshiro128PpHandle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Xoshiro128PpState.load(rng_ptr);
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

pub export fn xoshiro128pp_randf(rng: ?*Xoshiro128PpHandle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const rng_ptr = fromHandle(handle);
    var state = Xoshiro128PpState.load(rng_ptr);
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

pub export fn xoshiro128ppx16_new(seed: u32) ?*Xoshiro128Ppx16Handle {
    const rng = std.heap.page_allocator.create(Xoshiro128Ppx16State) catch return null;
    rng.* = Xoshiro128Ppx16State.init(seed);
    return toX16Handle(rng);
}

pub export fn xoshiro128ppx16_free(rng: ?*Xoshiro128Ppx16Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromX16Handle(handle));
}

pub export fn xoshiro128ppx16_nextu(rng: ?*Xoshiro128Ppx16Handle, out: [*c]u32, count: usize) void {
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
    if (i + xoshiro128pp_size <= count) {
        const out_vec: [*]align(1) u32x16 = @ptrCast(out_ptr + i);
        const vec_count = (count - i) / xoshiro128pp_size;
        var vec_index: usize = 0;
        while (vec_index < vec_count) : (vec_index += 1) {
            out_vec[vec_index] = rng_state.nextuVec();
        }
        i += vec_count * xoshiro128pp_size;
    }
    if (i < count) {
        const values = rng_state.nextu();
        common.copyChunk(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ppx16_nextf(rng: ?*Xoshiro128Ppx16Handle, out: [*c]f32, count: usize) void {
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
    if (i + xoshiro128pp_size <= count) {
        const out_vec: [*]align(1) f32x16 = @ptrCast(out_ptr + i);
        const vec_count = (count - i) / xoshiro128pp_size;
        var vec_index: usize = 0;
        while (vec_index < vec_count) : (vec_index += 1) {
            out_vec[vec_index] = rng_state.nextfVec();
        }
        i += vec_count * xoshiro128pp_size;
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ppx16_randi(rng: ?*Xoshiro128Ppx16Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
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
    while (i + xoshiro128pp_size <= count) : (i += xoshiro128pp_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ppx16_randf(rng: ?*Xoshiro128Ppx16Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
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
    while (i + xoshiro128pp_size <= count) : (i += xoshiro128pp_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ssx16_new(seed: u32) ?*Xoshiro128Ssx16Handle {
    const rng = std.heap.page_allocator.create(Xoshiro128Ssx16State) catch return null;
    rng.* = Xoshiro128Ssx16State.init(seed);
    return toSsX16Handle(rng);
}

pub export fn xoshiro128ssx16_free(rng: ?*Xoshiro128Ssx16Handle) void {
    const handle = rng orelse return;
    std.heap.page_allocator.destroy(fromSsX16Handle(handle));
}

pub export fn xoshiro128ssx16_nextu(rng: ?*Xoshiro128Ssx16Handle, out: [*c]u32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const state = fromSsX16Handle(handle);
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
    if (i + xoshiro128pp_size <= count) {
        const out_vec: [*]align(1) u32x16 = @ptrCast(out_ptr + i);
        const vec_count = (count - i) / xoshiro128pp_size;
        var vec_index: usize = 0;
        while (vec_index < vec_count) : (vec_index += 1) {
            out_vec[vec_index] = rng_state.nextuVec();
        }
        i += vec_count * xoshiro128pp_size;
    }
    if (i < count) {
        const values = rng_state.nextu();
        common.copyChunk(u32, out_ptr[i..count], values);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ssx16_nextf(rng: ?*Xoshiro128Ssx16Handle, out: [*c]f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const state = fromSsX16Handle(handle);
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
    if (i + xoshiro128pp_size <= count) {
        const out_vec: [*]align(1) f32x16 = @ptrCast(out_ptr + i);
        const vec_count = (count - i) / xoshiro128pp_size;
        var vec_index: usize = 0;
        while (vec_index < vec_count) : (vec_index += 1) {
            out_vec[vec_index] = rng_state.nextfVec();
        }
        i += vec_count * xoshiro128pp_size;
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtu32_uf(values[j]);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ssx16_randi(rng: ?*Xoshiro128Ssx16Handle, out: [*c]i32, min: i32, max: i32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const state = fromSsX16Handle(handle);
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
    while (i + xoshiro128pp_size <= count) : (i += xoshiro128pp_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_ui(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

pub export fn xoshiro128ssx16_randf(rng: ?*Xoshiro128Ssx16Handle, out: [*c]f32, min: f32, max: f32, count: usize) void {
    const handle = rng orelse return;
    if (count == 0 or out == null) return;
    const state = fromSsX16Handle(handle);
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
    while (i + xoshiro128pp_size <= count) : (i += xoshiro128pp_size) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
    }
    if (i < count) {
        const values = rng_state.nextu();
        var j: usize = 0;
        while (j < count - i) : (j += 1) out_ptr[i + j] = _internal.cvtr32_uf(values[j], min, max);
        cache = values;
        cache_index = count - i;
        cache_len = xoshiro128pp_size;
    }
    state.rng = rng_state;
    state.cache = cache;
    state.cache_index = @intCast(cache_index);
    state.cache_len = @intCast(cache_len);
}

test "xoshiro128pp_nextu matches Zig implementation" {
    const seed: u32 = 1234;
    const handle = xoshiro128pp_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128pp_free(handle);
    var actual: [8]u32 = undefined;
    xoshiro128pp_nextu(handle, actual[0..].ptr, actual.len);
    var expected = urng.Xoshiro128Pp.new(seed);
    for (actual) |value| try std.testing.expectEqual(expected.nextu(), value);
}

test "xoshiro128ss_nextu matches Zig implementation" {
    const seed: u32 = 4321;
    const handle = xoshiro128ss_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ss_free(handle);
    var actual: [8]u32 = undefined;
    xoshiro128ss_nextu(handle, actual[0..].ptr, actual.len);
    var expected = urng.Xoshiro128Ss.new(seed);
    for (actual) |value| try std.testing.expectEqual(expected.nextu(), value);
}

test "xoshiro128pp range helpers match Zig implementation" {
    const seed: u32 = 5678;
    const int_handle = xoshiro128pp_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128pp_free(int_handle);
    var actual_int: [6]i32 = undefined;
    xoshiro128pp_randi(int_handle, actual_int[0..].ptr, -5, 9, actual_int.len);
    var expected_int = urng.Xoshiro128Pp.new(seed);
    for (actual_int) |value| try std.testing.expectEqual(_internal.cvtr32_ui(expected_int.nextu(), -5, 9), value);
    const float_handle = xoshiro128pp_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128pp_free(float_handle);
    var actual_float: [6]f32 = undefined;
    xoshiro128pp_randf(float_handle, actual_float[0..].ptr, -0.5, 2.5, actual_float.len);
    var expected_float = urng.Xoshiro128Pp.new(seed);
    for (actual_float) |value| try std.testing.expectEqual(_internal.cvtr32_uf(expected_float.nextu(), -0.5, 2.5), value);
}

test "xoshiro128ss range helpers match Zig implementation" {
    const seed: u32 = 8765;
    const int_handle = xoshiro128ss_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ss_free(int_handle);
    var actual_int: [6]i32 = undefined;
    xoshiro128ss_randi(int_handle, actual_int[0..].ptr, -5, 9, actual_int.len);
    var expected_int = urng.Xoshiro128Ss.new(seed);
    for (actual_int) |value| try std.testing.expectEqual(_internal.cvtr32_ui(expected_int.nextu(), -5, 9), value);
    const float_handle = xoshiro128ss_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ss_free(float_handle);
    var actual_float: [6]f32 = undefined;
    xoshiro128ss_randf(float_handle, actual_float[0..].ptr, -0.5, 2.5, actual_float.len);
    var expected_float = urng.Xoshiro128Ss.new(seed);
    for (actual_float) |value| try std.testing.expectEqual(_internal.cvtr32_uf(expected_float.nextu(), -0.5, 2.5), value);
}

test "xoshiro128ppx16_nextu matches linearized Zig implementation" {
    const seed: u32 = 2468;
    const handle = xoshiro128ppx16_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ppx16_free(handle);
    var actual: [37]u32 = undefined;
    xoshiro128ppx16_nextu(handle, actual[0..5].ptr, 5);
    xoshiro128ppx16_nextu(handle, actual[5..].ptr, actual.len - 5);
    var expected_rng = urng.Xoshiro128Ppx16.new(seed);
    var expected: [37]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size and i + j < expected.len) : (j += 1) expected[i + j] = values[j];
        i += j;
    }
    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "xoshiro128ssx16_nextu matches linearized Zig implementation" {
    const seed: u32 = 8642;
    const handle = xoshiro128ssx16_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ssx16_free(handle);
    var actual: [37]u32 = undefined;
    xoshiro128ssx16_nextu(handle, actual[0..5].ptr, 5);
    xoshiro128ssx16_nextu(handle, actual[5..].ptr, actual.len - 5);
    var expected_rng = urng.Xoshiro128Ssx16.new(seed);
    var expected: [37]u32 = undefined;
    var i: usize = 0;
    while (i < expected.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size and i + j < expected.len) : (j += 1) expected[i + j] = values[j];
        i += j;
    }
    try std.testing.expectEqualSlices(u32, &expected, &actual);
}

test "xoshiro128ppx16 mixed helpers preserve sequence" {
    const seed: u32 = 1357;
    const handle = xoshiro128ppx16_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ppx16_free(handle);
    var actual_u: [3]u32 = undefined;
    var actual_f: [5]f32 = undefined;
    var actual_i: [7]i32 = undefined;
    var actual_rf: [19]f32 = undefined;
    xoshiro128ppx16_nextu(handle, actual_u[0..].ptr, actual_u.len);
    xoshiro128ppx16_nextf(handle, actual_f[0..].ptr, actual_f.len);
    xoshiro128ppx16_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    xoshiro128ppx16_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);
    var expected_rng = urng.Xoshiro128Ppx16.new(seed);
    var raw: [34]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size and i + j < raw.len) : (j += 1) raw[i + j] = values[j];
        i += j;
    }
    for (actual_u, 0..) |value, index| try std.testing.expectEqual(raw[index], value);
    for (actual_f, 0..) |value, index| try std.testing.expectEqual(_internal.cvtu32_uf(raw[actual_u.len + index]), value);
    for (actual_i, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_ui(raw[actual_u.len + actual_f.len + index], -5, 9), value);
    for (actual_rf, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_uf(raw[actual_u.len + actual_f.len + actual_i.len + index], -0.5, 2.5), value);
}

test "xoshiro128ssx16 mixed helpers preserve sequence" {
    const seed: u32 = 9753;
    const handle = xoshiro128ssx16_new(seed) orelse return error.OutOfMemory;
    defer xoshiro128ssx16_free(handle);
    var actual_u: [3]u32 = undefined;
    var actual_f: [5]f32 = undefined;
    var actual_i: [7]i32 = undefined;
    var actual_rf: [19]f32 = undefined;
    xoshiro128ssx16_nextu(handle, actual_u[0..].ptr, actual_u.len);
    xoshiro128ssx16_nextf(handle, actual_f[0..].ptr, actual_f.len);
    xoshiro128ssx16_randi(handle, actual_i[0..].ptr, -5, 9, actual_i.len);
    xoshiro128ssx16_randf(handle, actual_rf[0..].ptr, -0.5, 2.5, actual_rf.len);
    var expected_rng = urng.Xoshiro128Ssx16.new(seed);
    var raw: [34]u32 = undefined;
    var i: usize = 0;
    while (i < raw.len) {
        const values = expected_rng.nextu();
        var j: usize = 0;
        while (j < xoshiro128pp_size and i + j < raw.len) : (j += 1) raw[i + j] = values[j];
        i += j;
    }
    for (actual_u, 0..) |value, index| try std.testing.expectEqual(raw[index], value);
    for (actual_f, 0..) |value, index| try std.testing.expectEqual(_internal.cvtu32_uf(raw[actual_u.len + index]), value);
    for (actual_i, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_ui(raw[actual_u.len + actual_f.len + index], -5, 9), value);
    for (actual_rf, 0..) |value, index| try std.testing.expectEqual(_internal.cvtr32_uf(raw[actual_u.len + actual_f.len + actual_i.len + index], -0.5, 2.5), value);
}
