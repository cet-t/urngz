const std = @import("std");
const clap = @import("clap");
const cabi_jsf = @import("./cabi/jsf.zig");
const cabi_pcg = @import("./cabi/pcg.zig");
const cabi_sfc = @import("./cabi/sfc.zig");
const cabi_xoshiro = @import("./cabi/xoshiro.zig");
const urng = @import("./urng/prelude.zig");

extern "kernel32" fn QueryPerformanceCounter(out: *i64) callconv(.winapi) bool;
extern "kernel32" fn QueryPerformanceFrequency(out: *i64) callconv(.winapi) bool;

var qpc_freq: i64 = 0;

const cabi_sample_count = 1 << 20;
const cabi_bench_seconds: u64 = 1;

fn qpcNow() i64 {
    var t: i64 = undefined;
    _ = QueryPerformanceCounter(&t);
    return t;
}

fn qpcToNs(ticks: i64) u64 {
    return @intCast(@divTrunc(ticks * 1_000_000_000, qpc_freq));
}

inline fn xorSink(comptime RetType: type, v: RetType, sink: *u64) void {
    switch (@typeInfo(RetType)) {
        .array => inline for (v) |x| {
            sink.* ^= @intCast(x);
        },
        .int => sink.* ^= @intCast(v),
        else => @compileError("unsupported nextu return type"),
    }
}

fn benchNextu(comptime T: type, label: []const u8, seed: u64, iters: u64) void {
    const ret_type = @typeInfo(@TypeOf(T.nextu)).@"fn".return_type.?;
    const samples_per_call: comptime_int = switch (@typeInfo(ret_type)) {
        .array => |arr| arr.len,
        else => 1,
    };
    const seed_type = @typeInfo(@TypeOf(T.new)).@"fn".params[0].type.?;

    var rng = T.new(@as(seed_type, @truncate(seed)));
    var sink: u64 = 0;

    const t0 = qpcNow();
    for (0..iters) |_| {
        xorSink(ret_type, rng.nextu(), &sink);
    }
    const elapsed_ns = qpcToNs(qpcNow() - t0);

    const total_samples = iters * samples_per_call;
    const gs = @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(elapsed_ns));

    std.debug.print("{s:<14}: {d:.3} Gsamples/s  (sink=0x{x:0>16})\n", .{ label, gs, sink });
}

fn benchCabiNextu(
    comptime new_fn: anytype,
    comptime free_fn: anytype,
    comptime nextu_fn: anytype,
    label: []const u8,
    seed: anytype,
) !void {
    const handle = new_fn(seed) orelse return error.OutOfMemory;
    defer free_fn(handle);

    const out = try std.heap.page_allocator.alloc(u32, cabi_sample_count);
    defer std.heap.page_allocator.free(out);

    var sink: u64 = 0;
    var loops: u64 = 0;
    const t0 = qpcNow();

    while (qpcToNs(qpcNow() - t0) < cabi_bench_seconds * std.time.ns_per_s) {
        nextu_fn(handle, out.ptr, out.len);
        sink ^= out[loops & (out.len - 1)];
        loops += 1;
    }

    const elapsed_ns = qpcToNs(qpcNow() - t0);
    const total_samples = loops * out.len;
    const gs = @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(elapsed_ns));

    std.debug.print("{s:<14}: {d:.3} Gsamples/s  (sink=0x{x:0>16})\n", .{ label, gs, sink });
}

pub fn main() !void {
    _ = QueryPerformanceFrequency(&qpc_freq);

    const iters: u64 = 1_000_000_000;

    std.debug.print("Scalar PRNGs (u32 output)\n", .{});
    benchNextu(urng.SplitMix32, "SplitMix32", 1, iters);
    benchNextu(urng.SplitMix64, "SplitMix64", 1, iters);
    benchNextu(urng.Sfc32, "Sfc32", 1, iters);
    benchNextu(urng.Pcg32, "Pcg32", 1, iters);
    benchNextu(urng.Jsf32, "Jsf32", 1, iters);
    benchNextu(urng.Xoshiro128Pp, "Xoshiro128++", 1, iters);

    std.debug.print("\nVectorized PRNGs (u32xN output)\n", .{});
    benchNextu(urng.Sfc32x16, "Sfc32x16", 1, iters / 16);
    benchNextu(urng.Pcg32x8, "Pcg32x8", 1, iters / 8);
    benchNextu(urng.Jsf32x16, "Jsf32x16", 1, iters / 16);
    benchNextu(urng.Xoshiro128Ppx16, "Xoshiro128++x16", 1, iters / 16);

    std.debug.print("\nC ABI PRNGs (buffered u32 output)\n", .{});
    try benchCabiNextu(cabi_sfc.sfc32_new, cabi_sfc.sfc32_free, cabi_sfc.sfc32_nextu, "Sfc32", @as(u32, 1));
    try benchCabiNextu(cabi_pcg.pcg32_new, cabi_pcg.pcg32_free, cabi_pcg.pcg32_nextu, "Pcg32", @as(u64, 1));
    try benchCabiNextu(cabi_jsf.jsf32_new, cabi_jsf.jsf32_free, cabi_jsf.jsf32_nextu, "Jsf32", @as(u32, 1));
    try benchCabiNextu(cabi_xoshiro.xoshiro128pp_new, cabi_xoshiro.xoshiro128pp_free, cabi_xoshiro.xoshiro128pp_nextu, "Xoshiro128++", @as(u32, 1));
    try benchCabiNextu(cabi_sfc.sfc32x16_new, cabi_sfc.sfc32x16_free, cabi_sfc.sfc32x16_nextu, "Sfc32x16", @as(u32, 1));
    try benchCabiNextu(cabi_pcg.pcg32x8_new, cabi_pcg.pcg32x8_free, cabi_pcg.pcg32x8_nextu, "Pcg32x8", @as(u64, 1));
    try benchCabiNextu(cabi_jsf.jsf32x16_new, cabi_jsf.jsf32x16_free, cabi_jsf.jsf32x16_nextu, "Jsf32x16", @as(u32, 1));
    try benchCabiNextu(cabi_xoshiro.xoshiro128ppx16_new, cabi_xoshiro.xoshiro128ppx16_free, cabi_xoshiro.xoshiro128ppx16_nextu, "Xoshiro128++x16", @as(u32, 1));
}
