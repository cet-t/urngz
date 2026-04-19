/// SplitMix implementations.
pub const splitmix = @import("./splitmix.zig");
pub const SplitMix32 = splitmix.SplitMix32;
pub const SplitMix64 = splitmix.SplitMix64;

/// PCG implementations.
pub const pcg = @import("./pcg.zig");
pub const Pcg32 = pcg.Pcg32;

/// SFC implementations.
pub const sfc = @import("./sfc.zig");
pub const Sfc32 = sfc.Sfc32;
pub const Sfc32x16 = sfc.Sfc32x16;
