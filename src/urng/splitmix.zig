/// A SplitMix32 pseudo-random number generator.
///
/// Fast 32-bit finalizer-based PRNG commonly used to seed other generators.
/// Uses a single 32-bit state word advanced by the golden-ratio constant.
///
/// # Examples
///
/// ```
/// const urng = @import("urng/prelude.zig")
///
/// var rng = urng.splitmix.SplitMix32.new(1);
/// const x = rng.nextu();
/// ```
pub const SplitMix32 = struct {
    state: u32,

    pub fn new(seed: u32) SplitMix32 {
        return SplitMix32{
            .state = seed | 1,
        };
    }

    pub fn nextu(self: *SplitMix32) u32 {
        self.state +%= 0x9e3779b9;
        var z = self.state;
        z = (z ^ (z >> 16)) *% 0x85ebca6b;
        z = (z ^ (z >> 13)) *% 0xc2b2ae35;
        return z ^ (z >> 16);
    }
};

pub const SplitMix64 = struct {
    state: u64,

    pub fn new(seed: u64) SplitMix64 {
        return SplitMix64{
            .state = seed | 1,
        };
    }

    pub fn nextu(self: *SplitMix64) u64 {
        self.state +%= 0x9e3779b97f4a7c15;
        var z = self.state;
        z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
        z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
        return z ^ (z >> 31);
    }
};
