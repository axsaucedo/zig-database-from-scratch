const std = @import("std");
const row = @import("row.zig");

pub const PAGE_SIZE: usize = 4096;
pub const TABLE_MAX_PAGES: usize = 100;
pub const ROWS_PER_PAGE: usize = PAGE_SIZE / row.ROW_SIZE;
pub const TABLE_MAX_ROWS: usize = ROWS_PER_PAGE * TABLE_MAX_PAGES;

pub const Table = struct {
    num_rows: u32,
    pages: [TABLE_MAX_PAGES]?[]u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Table {
        return .{ .num_rows = 0, .pages = [_]?[]u8{null} ** TABLE_MAX_PAGES, .allocator = allocator };
    }

    pub fn deinit(self: *Table) void {
        for (&self.pages) |*page| {
            if (page.*) |p| { self.allocator.free(p); page.* = null; }
        }
    }

    pub fn rowSlot(self: *Table, row_num: u32) ![]u8 {
        const page_num = row_num / ROWS_PER_PAGE;
        if (page_num >= TABLE_MAX_PAGES) return error.TableFull;
        if (self.pages[page_num] == null) self.pages[page_num] = try self.allocator.alloc(u8, PAGE_SIZE);
        const row_offset = row_num % ROWS_PER_PAGE;
        return self.pages[page_num].?[row_offset * row.ROW_SIZE ..][0..row.ROW_SIZE];
    }

    pub fn isFull(self: *const Table) bool { return self.num_rows >= TABLE_MAX_ROWS; }
};
