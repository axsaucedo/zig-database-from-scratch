//! Phase 05: Pager Module
//! TODO: Implement file I/O and page caching

const std = @import("std");
const phase03 = @import("phase03");

pub const PAGE_SIZE: usize = 4096;
pub const TABLE_MAX_PAGES: usize = 100;

pub const Pager = struct {
    file: ?std.fs.File,
    file_length: u64,
    pages: [TABLE_MAX_PAGES]?[]u8,
    allocator: std.mem.Allocator,
    
    // TODO: Implement open, getPage, flush, close
};
