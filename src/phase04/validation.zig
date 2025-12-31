const std = @import("std");
const phase03 = @import("phase03");

pub const PrepareResult = enum { success, negative_id, string_too_long, syntax_error, unrecognized_statement };
pub const StatementType = enum { insert, select };
pub const Statement = struct { statement_type: StatementType, row_to_insert: phase03.Row };

pub fn prepareInsert(input: []const u8, stmt: *Statement) PrepareResult {
    stmt.statement_type = .insert;
    stmt.row_to_insert = phase03.Row.init();

    var iter = std.mem.tokenizeScalar(u8, input, ' ');
    _ = iter.next();

    const id_str = iter.next() orelse return .syntax_error;
    const signed_id = std.fmt.parseInt(i64, id_str, 10) catch return .syntax_error;
    if (signed_id < 0) return .negative_id;
    if (signed_id > std.math.maxInt(u32)) return .syntax_error;

    const username = iter.next() orelse return .syntax_error;
    if (username.len > phase03.COLUMN_USERNAME_SIZE) return .string_too_long;

    const email = iter.next() orelse return .syntax_error;
    if (email.len > phase03.COLUMN_EMAIL_SIZE) return .string_too_long;

    stmt.row_to_insert.id = @intCast(signed_id);
    stmt.row_to_insert.setUsername(username);
    stmt.row_to_insert.setEmail(email);
    return .success;
}

pub fn prepareStatement(input: []const u8, stmt: *Statement) PrepareResult {
    if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) return prepareInsert(input, stmt);
    if (std.mem.eql(u8, input, "select")) { stmt.statement_type = .select; return .success; }
    return .unrecognized_statement;
}
