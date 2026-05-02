const urng = @import("./prelude.zig");
const _internal = @import("./_internal.zig");

const u32x16 = _internal.u32x16;
const f32x16 = _internal.f32x16;
const sg = urng.splitmix.SplitMix32;

pub const Philox32x4 = struct {
    state: [4]u32,
    counter: [2]u32,

    pub fn new(seed: u32) Philox32x4 {
        var seedgen = sg.new(seed);
        return Philox32x4{
            .state = .{ seedgen.nextu(), seedgen.nextu(), seedgen.nextu(), seedgen.nextu() },
            .counter = .{ seedgen.nextu(), seedgen.nextu() },
        };
    }

    inline fn compute(c: [4]u32, k: [2]u32) [4]u32 {
        const M0: u64 = 0xD256D193;
        const M1: u64 = 0xCD9E8D57;
        const W0: u64 = 0x9E3779B9;
        const W1: u64 = 0xBB67AE85;

        inline for (0..10) |_| {
            const prod0 = c[0] *% M0;
            const hi0: u32 = @truncate(prod0 >> 32);
            const lo0: u32 = @truncate(prod0);

            const prod1 = c[2] *% M1;
            const hi1: u32 = @truncate(prod1 >> 32);
            const lo1: u32 = @truncate(prod1);

            c[0] = hi1 ^ k[1] ^ c[0];
            c[1] = lo1;
            c[2] = hi0 ^ k[3] ^ c[1];
            c[3] = lo0;

            k[0] *%= W0;
            k[1] *%= W1;

            const prod2 = c[0] *% M0;
            const hi2: u32 = @truncate(prod2 >> 32);
            const lo2: u32 = @truncate(prod2);

            const prod3 = c[2] *% M1;
            const hi3: u32 = @truncate(prod3 >> 32);
            const lo3: u32 = @truncate(prod3);

            c[0] = hi3 ^ k[1] ^ c[0];
            c[1] = lo3;
            c[2] = hi2 ^ k[3] ^ c[1];
            c[3] = lo2;

            k[0] *%= W0;
            k[1] *%= W1;
        }

        return c;
    }

    pub inline fn nextu(self: *Philox32x4) [4]u32 {
        const out = compute(self.c, self.k);

        self.c[0] +%= 1;
        if (self.c[0] == 0) {
            self.c[1] +%= 1;
            if (self.c[1] == 0) {
                self.c[2] +%= 1;
                if (self.c[2] == 0) {
                    self.c[3] +%= 1;
                }
            }
        }

        return out;
    }
};
