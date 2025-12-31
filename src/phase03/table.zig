//! Phase 03: Table Module
//!
//! This module provides the Table structure for in-memory storage.
//! Tables use page-based storage with on-demand allocation.

const std = @import("std");
const row = @import("row.zig");

/// Page and table constants
pub const PAGE_SIZE: usize = 4096;
pub const TABLE_MAX_PAGES: usize = 100;
pub const ROWS_PER_PAGE: usize = PAGE_SIZE / row.ROW_SIZE;
pub const TABLE_MAX_ROWS: usize = ROWS_PER_PAGE * TABLE_MAX_PAGES;

/// Table structure - holds pages of rows
pub const Table = struct {
    num_rows: u32,
    pages: [TABLE_MAX_PAGES]?[]u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Create a new empty table
    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .num_rows = 0,
            .pages = [_]?[]u8{null} ** TABLE_MAX_PAGES,
            .allocator = allocator,
        };
    }

    /// Free all allocated pages
    pub fn deinit(self: *Self) void {
        for (&self.pages) |*page| {
            if (page.*) |p| {
                self.allocator.free(p);
                page.* = null;
            }
        }
    }

    /// Get the memory slot for a given row number.
    /// Allocates the page if not already allocated.
    pub fn rowSlot(self: *Self, row_num: u32) ![]u8 {
        const page_num = row_num / ROWS_PER_PAGE;

        if (page_num >= TABLE_MAX_PAGES) {
            return error.TableFull;
        }

        if (self.pages[page_num] == null) {
            // Allocate page on demand
            self.pages[page_num] = try self.allocator.alloc(u8, PAGE_SIZE);
        }

        const row_offset = row_num % ROWS_PER_PAGE;
        const byte_offset = row_offset * row.ROW_SIZE;

        return self.pages[page_num].?[byte_offset..][0..row.ROW_SIZE];
    }

    /// Check if the table is full
    pub fn isFull(self: *const Self) bool {
        return self.num_rows >= TABLE_MAX_ROWS;
    }
};
