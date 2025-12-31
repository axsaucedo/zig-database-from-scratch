//! Phase 03: Row Module
//!
//! This module defines the Row structure and serialization functions.
//! These are core data types used by all subsequent phases.

const std = @import("std");

/// Column size limits
pub const COLUMN_USERNAME_SIZE: usize = 32;
pub const COLUMN_EMAIL_SIZE: usize = 255;

/// Size constants for row serialization
pub const ID_SIZE: usize = @sizeOf(u32);
pub const USERNAME_SIZE: usize = COLUMN_USERNAME_SIZE + 1; // +1 for null terminator
pub const EMAIL_SIZE: usize = COLUMN_EMAIL_SIZE + 1;

pub const ID_OFFSET: usize = 0;
pub const USERNAME_OFFSET: usize = ID_OFFSET + ID_SIZE;
pub const EMAIL_OFFSET: usize = USERNAME_OFFSET + USERNAME_SIZE;
pub const ROW_SIZE: usize = ID_SIZE + USERNAME_SIZE + EMAIL_SIZE;

/// Row structure - represents a single database row
pub const Row = struct {
    id: u32,
    username: [COLUMN_USERNAME_SIZE + 1]u8,
    email: [COLUMN_EMAIL_SIZE + 1]u8,

    const Self = @This();

    /// Create a zero-initialized row
    pub fn init() Self {
        return Self{
            .id = 0,
            .username = std.mem.zeroes([COLUMN_USERNAME_SIZE + 1]u8),
            .email = std.mem.zeroes([COLUMN_EMAIL_SIZE + 1]u8),
        };
    }

    /// Set the username field from a slice
    pub fn setUsername(self: *Self, name: []const u8) void {
        const len = @min(name.len, COLUMN_USERNAME_SIZE);
        @memcpy(self.username[0..len], name[0..len]);
        self.username[len] = 0;
    }

    /// Set the email field from a slice
    pub fn setEmail(self: *Self, email_str: []const u8) void {
        const len = @min(email_str.len, COLUMN_EMAIL_SIZE);
        @memcpy(self.email[0..len], email_str[0..len]);
        self.email[len] = 0;
    }

    /// Get username as a slice (up to null terminator)
    pub fn getUsernameSlice(self: *const Self) []const u8 {
        const len = std.mem.indexOfScalar(u8, &self.username, 0) orelse COLUMN_USERNAME_SIZE;
        return self.username[0..len];
    }

    /// Get email as a slice (up to null terminator)
    pub fn getEmailSlice(self: *const Self) []const u8 {
        const len = std.mem.indexOfScalar(u8, &self.email, 0) orelse COLUMN_EMAIL_SIZE;
        return self.email[0..len];
    }
};

/// Serialize a Row into a byte buffer
pub fn serializeRow(source: *const Row, destination: []u8) void {
    // Copy id (as bytes)
    const id_bytes = std.mem.asBytes(&source.id);
    @memcpy(destination[ID_OFFSET..][0..ID_SIZE], id_bytes);

    // Copy username
    @memcpy(destination[USERNAME_OFFSET..][0..USERNAME_SIZE], &source.username);

    // Copy email
    @memcpy(destination[EMAIL_OFFSET..][0..EMAIL_SIZE], &source.email);
}

/// Deserialize a byte buffer into a Row
pub fn deserializeRow(source: []const u8, destination: *Row) void {
    // Read id
    destination.id = std.mem.bytesToValue(u32, source[ID_OFFSET..][0..ID_SIZE]);

    // Read username
    @memcpy(&destination.username, source[USERNAME_OFFSET..][0..USERNAME_SIZE]);

    // Read email
    @memcpy(&destination.email, source[EMAIL_OFFSET..][0..EMAIL_SIZE]);
}

/// Print a row to stdout
pub fn printRow(row: *const Row) void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    stdout.print("({d}, {s}, {s})\n", .{
        row.id,
        row.getUsernameSlice(),
        row.getEmailSlice(),
    }) catch {};
}
