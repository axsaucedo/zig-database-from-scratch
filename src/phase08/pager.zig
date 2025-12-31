//! Phase 08: Updated Pager for B-Tree
//!
//! The pager now tracks num_pages instead of file_length/ROW_SIZE.
//! Pages are always full PAGE_SIZE (no partial pages).

const std = @import("std");
const btree = @import("btree.zig");

pub const PAGE_SIZE = btree.PAGE_SIZE;
pub const TABLE_MAX_PAGES: usize = 100;

pub const Pager = struct {
    file: std.fs.File,
    file_length: u64,
    num_pages: u32,
    pages: [TABLE_MAX_PAGES]?[]u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn open(allocator: std.mem.Allocator, filename: []const u8) !Self {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_write }) catch |err| {
            if (err == error.FileNotFound) {
                const new_file = try std.fs.cwd().createFile(filename, .{ .read = true });
                return Self{
                    .file = new_file,
                    .file_length = 0,
                    .num_pages = 0,
                    .pages = [_]?[]u8{null} ** TABLE_MAX_PAGES,
                    .allocator = allocator,
                };
            }
            return err;
        };
        const stat = try file.stat();

        // Verify file is whole number of pages
        if (stat.size % PAGE_SIZE != 0) {
            return error.CorruptFile;
        }

        return Self{
            .file = file,
            .file_length = stat.size,
            .num_pages = @intCast(stat.size / PAGE_SIZE),
            .pages = [_]?[]u8{null} ** TABLE_MAX_PAGES,
            .allocator = allocator,
        };
    }

    pub fn getPage(self: *Self, page_num: u32) ![]u8 {
        if (page_num >= TABLE_MAX_PAGES) return error.PageOutOfBounds;

        if (self.pages[page_num] == null) {
            const page = try self.allocator.alloc(u8, PAGE_SIZE);
            @memset(page, 0);

            if (page_num < self.num_pages) {
                try self.file.seekTo(page_num * PAGE_SIZE);
                _ = try self.file.read(page);
            }

            self.pages[page_num] = page;

            if (page_num >= self.num_pages) {
                self.num_pages = page_num + 1;
            }
        }

        return self.pages[page_num].?;
    }

    /// Get an unused page number (allocates at end)
    pub fn getUnusedPageNum(self: *const Self) u32 {
        return self.num_pages;
    }

    /// Flush a page to disk (always full PAGE_SIZE now)
    pub fn flush(self: *Self, page_num: u32) !void {
        if (self.pages[page_num] == null) return error.FlushNullPage;
        try self.file.seekTo(page_num * PAGE_SIZE);
        _ = try self.file.write(self.pages[page_num].?[0..PAGE_SIZE]);
    }

    pub fn close(self: *Self) void {
        for (&self.pages) |*page| {
            if (page.*) |p| {
                self.allocator.free(p);
                page.* = null;
            }
        }
        self.file.close();
    }
};

/// Table now stores root_page_num instead of num_rows
pub const Table = struct {
    pager: *Pager,
    root_page_num: u32,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn dbOpen(allocator: std.mem.Allocator, filename: []const u8) !Self {
        const pager = try allocator.create(Pager);
        pager.* = try Pager.open(allocator, filename);

        const table = Self{
            .pager = pager,
            .root_page_num = 0,
            .allocator = allocator,
        };

        // Initialize root as empty leaf node if new database
        if (pager.num_pages == 0) {
            const root_node = try pager.getPage(0);
            btree.initializeRootNode(root_node);
        }

        return table;
    }

    pub fn dbClose(self: *Self) !void {
        var i: u32 = 0;
        while (i < self.pager.num_pages) : (i += 1) {
            if (self.pager.pages[i] != null) {
                try self.pager.flush(i);
            }
        }
        self.pager.close();
        self.allocator.destroy(self.pager);
    }
};
