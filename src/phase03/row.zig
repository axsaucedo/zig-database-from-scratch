const std = @import("std");

pub const COLUMN_USERNAME_SIZE: usize = 32;
pub const COLUMN_EMAIL_SIZE: usize = 255;
pub const ID_SIZE: usize = @sizeOf(u32);
pub const USERNAME_SIZE: usize = COLUMN_USERNAME_SIZE + 1;
pub const EMAIL_SIZE: usize = COLUMN_EMAIL_SIZE + 1;
pub const ROW_SIZE: usize = ID_SIZE + USERNAME_SIZE + EMAIL_SIZE;

pub const Row = struct {
    id: u32,
    username: [COLUMN_USERNAME_SIZE + 1]u8,
    email: [COLUMN_EMAIL_SIZE + 1]u8,

    pub fn init() Row {
        return .{ .id = 0, .username = std.mem.zeroes([COLUMN_USERNAME_SIZE + 1]u8), .email = std.mem.zeroes([COLUMN_EMAIL_SIZE + 1]u8) };
    }

    pub fn setUsername(self: *Row, name: []const u8) void {
        const len = @min(name.len, COLUMN_USERNAME_SIZE);
        @memcpy(self.username[0..len], name[0..len]);
        self.username[len] = 0;
    }

    pub fn setEmail(self: *Row, email_str: []const u8) void {
        const len = @min(email_str.len, COLUMN_EMAIL_SIZE);
        @memcpy(self.email[0..len], email_str[0..len]);
        self.email[len] = 0;
    }

    pub fn getUsernameSlice(self: *const Row) []const u8 {
        const len = std.mem.indexOfScalar(u8, &self.username, 0) orelse COLUMN_USERNAME_SIZE;
        return self.username[0..len];
    }

    pub fn getEmailSlice(self: *const Row) []const u8 {
        const len = std.mem.indexOfScalar(u8, &self.email, 0) orelse COLUMN_EMAIL_SIZE;
        return self.email[0..len];
    }
};

pub fn serializeRow(source: *const Row, destination: []u8) void {
    @memcpy(destination[0..ID_SIZE], std.mem.asBytes(&source.id));
    @memcpy(destination[ID_SIZE..][0..USERNAME_SIZE], &source.username);
    @memcpy(destination[ID_SIZE + USERNAME_SIZE ..][0..EMAIL_SIZE], &source.email);
}

pub fn deserializeRow(source: []const u8, destination: *Row) void {
    destination.id = std.mem.bytesToValue(u32, source[0..ID_SIZE]);
    @memcpy(&destination.username, source[ID_SIZE..][0..USERNAME_SIZE]);
    @memcpy(&destination.email, source[ID_SIZE + USERNAME_SIZE ..][0..EMAIL_SIZE]);
}
