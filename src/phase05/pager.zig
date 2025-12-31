const std = @import("std");
const phase03 = @import("phase03");

pub const PAGE_SIZE: usize = 4096;
pub const TABLE_MAX_PAGES: usize = 100;
pub const ROWS_PER_PAGE: usize = PAGE_SIZE / phase03.ROW_SIZE;
pub const TABLE_MAX_ROWS: usize = ROWS_PER_PAGE * TABLE_MAX_PAGES;

pub const Pager = struct {
    file: std.fs.File,
    file_length: u64,
    pages: [TABLE_MAX_PAGES]?[]u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn open(allocator: std.mem.Allocator, filename: []const u8) !Self {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_write }) catch |err| {
            if (err == error.FileNotFound) {
                const new_file = try std.fs.cwd().createFile(filename, .{ .read = true });
                return Self{ .file = new_file, .file_length = 0, .pages = [_]?[]u8{null} ** TABLE_MAX_PAGES, .allocator = allocator };
            }
            return err;
        };
        const stat = try file.stat();
        return Self{ .file = file, .file_length = stat.size, .pages = [_]?[]u8{null} ** TABLE_MAX_PAGES, .allocator = allocator };
    }

    pub fn getPage(self: *Self, page_num: usize) ![]u8 {
        if (page_num >= TABLE_MAX_PAGES) return error.PageOutOfBounds;
        if (self.pages[page_num] == null) {
            const page = try self.allocator.alloc(u8, PAGE_SIZE);
            @memset(page, 0);
            const num_pages = self.file_length / PAGE_SIZE;
            const has_partial = (self.file_length % PAGE_SIZE) > 0;
            const total_pages = num_pages + (if (has_partial) @as(u64, 1) else 0);
            if (page_num < total_pages) {
                try self.file.seekTo(page_num * PAGE_SIZE);
                _ = try self.file.read(page);
            }
            self.pages[page_num] = page;
        }
        return self.pages[page_num].?;
    }

    pub fn flush(self: *Self, page_num: usize, size: usize) !void {
        if (self.pages[page_num] == null) return error.FlushNullPage;
        try self.file.seekTo(page_num * PAGE_SIZE);
        _ = try self.file.write(self.pages[page_num].?[0..size]);
    }

    pub fn close(self: *Self) void {
        for (&self.pages) |*page| {
            if (page.*) |p| { self.allocator.free(p); page.* = null; }
        }
        self.file.close();
    }
};

pub const Table = struct {
    pager: *Pager,
    num_rows: u32,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn dbOpen(allocator: std.mem.Allocator, filename: []const u8) !Self {
        const pager = try allocator.create(Pager);
        pager.* = try Pager.open(allocator, filename);
        const num_rows: u32 = @intCast(pager.file_length / phase03.ROW_SIZE);
        return Self{ .pager = pager, .num_rows = num_rows, .allocator = allocator };
    }

    pub fn rowSlot(self: *Self, row_num: u32) ![]u8 {
        const page_num = row_num / ROWS_PER_PAGE;
        const page = try self.pager.getPage(page_num);
        const row_offset = row_num % ROWS_PER_PAGE;
        const byte_offset = row_offset * phase03.ROW_SIZE;
        return page[byte_offset..][0..phase03.ROW_SIZE];
    }

    pub fn dbClose(self: *Self) !void {
        const num_full_pages = self.num_rows / ROWS_PER_PAGE;
        var i: usize = 0;
        while (i < num_full_pages) : (i += 1) {
            if (self.pager.pages[i] != null) try self.pager.flush(i, PAGE_SIZE);
        }
        const num_additional_rows = self.num_rows % ROWS_PER_PAGE;
        if (num_additional_rows > 0) {
            const page_num = num_full_pages;
            if (self.pager.pages[page_num] != null) try self.pager.flush(page_num, num_additional_rows * phase03.ROW_SIZE);
        }
        self.pager.close();
        self.allocator.destroy(self.pager);
    }

    pub fn isFull(self: *const Self) bool { return self.num_rows >= TABLE_MAX_ROWS; }
};
