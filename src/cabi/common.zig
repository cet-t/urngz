pub fn copyChunk(comptime T: type, dest: []T, src: anytype) void {
    @memcpy(dest, src[0..dest.len]);
}

pub fn normalizeCache(index: *usize, len: *usize) void {
    if (index.* == len.*) {
        index.* = 0;
        len.* = 0;
    }
}
