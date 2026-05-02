const std = @import("std");
const cabi = @import("./cabi/sfc.zig");
const urng = @import("./urng/prelude.zig");

extern "kernel32" fn QueryPerformanceCounter(out: *i64) callconv(.winapi) bool;
extern "kernel32" fn QueryPerformanceFrequency(out: *i64) callconv(.winapi) bool;

const sample_count = 1 << 20;
const bench_seconds = 1;

var qpc_freq: i64 = 0;

fn qpcNow() i64 {
    var t: i64 = undefined;
    _ = QueryPerformanceCounter(&t);
    return t;
}

fn qpcToNs(ticks: i64) u64 {
    return @intCast(@divTrunc(ticks * 1_000_000_000, qpc_freq));
}

inline fn copyChunk(comptime T: type, dest: []T, src: [16]T) void {
    @memcpy(dest, src[0..dest.len]);
}

fn benchScalarNextu() !void {
    const handle = cabi.sfc32_new(1) orelse return error.OutOfMemory;
    defer cabi.sfc32_free(handle);

    const out = try std.heap.page_allocator.alloc(u32, sample_count);
    defer std.heap.page_allocator.free(out);

    var sink: u64 = 0;
    var loops: u64 = 0;
    const start = qpcNow();

    while (qpcToNs(qpcNow() - start) < bench_seconds * std.time.ns_per_s) {
        cabi.sfc32_nextu(handle, out.ptr, out.len);
        sink ^= out[loops & (out.len - 1)];
        loops += 1;
    }

    const elapsed_ns = qpcToNs(qpcNow() - start);
    const total_samples = loops * out.len;
    const gsamples = @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(elapsed_ns));
    std.debug.print("cabi sfc32_nextu   : {d:.3} Gsamples/s  (sink=0x{x:0>16})\n", .{ gsamples, sink });
}

fn benchZigVectorNextu() !void {
    var rng = urng.Sfc32x16.new(1);
    const out = try std.heap.page_allocator.alloc(u32, sample_count);
    defer std.heap.page_allocator.free(out);

    var sink: u64 = 0;
    var loops: u64 = 0;
    const start = qpcNow();

    while (qpcToNs(qpcNow() - start) < bench_seconds * std.time.ns_per_s) {
        var i: usize = 0;
        while (i < out.len) : (i += 16) {
            copyChunk(u32, out[i .. i + 16], rng.nextu());
        }
        sink ^= out[loops & (out.len - 1)];
        loops += 1;
    }

    const elapsed_ns = qpcToNs(qpcNow() - start);
    const total_samples = loops * out.len;
    const gsamples = @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(elapsed_ns));
    std.debug.print("zig  sfc32x16     : {d:.3} Gsamples/s  (sink=0x{x:0>16})\n", .{ gsamples, sink });
}

fn benchCabiVectorNextu() !void {
    const handle = cabi.sfc32x16_new(1) orelse return error.OutOfMemory;
    defer cabi.sfc32x16_free(handle);

    const out = try std.heap.page_allocator.alloc(u32, sample_count);
    defer std.heap.page_allocator.free(out);

    var sink: u64 = 0;
    var loops: u64 = 0;
    const start = qpcNow();

    while (qpcToNs(qpcNow() - start) < bench_seconds * std.time.ns_per_s) {
        cabi.sfc32x16_nextu(handle, out.ptr, out.len);
        sink ^= out[loops & (out.len - 1)];
        loops += 1;
    }

    const elapsed_ns = qpcToNs(qpcNow() - start);
    const total_samples = loops * out.len;
    const gsamples = @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(elapsed_ns));
    std.debug.print("cabi sfc32x16     : {d:.3} Gsamples/s  (sink=0x{x:0>16})\n", .{ gsamples, sink });
}

pub fn main() !void {
    _ = QueryPerformanceFrequency(&qpc_freq);
    try benchScalarNextu();
    try benchZigVectorNextu();
    try benchCabiVectorNextu();
}
