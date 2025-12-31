//! Phase 04: Validation Module
//!
//! This module adds input validation for insert statements.
//! Validates ID (must be positive) and string lengths.

const std = @import("std");
const phase03 = @import("phase03");

/// Extended PrepareResult with validation errors
pub const PrepareResult = enum {
    success,
    negative_id,
    string_too_long,
    syntax_error,
    unrecognized_statement,
};

/// Statement with row data
pub const Statement = struct {
    statement_type: StatementType,
    row_to_insert: phase03.Row,
};

pub const StatementType = enum {
    insert,
    select,
};

/// Prepare an insert statement with full validation
pub fn prepareInsert(input: []const u8, statement: *Statement) PrepareResult {
    statement.statement_type = .insert;
    statement.row_to_insert = phase03.Row.init();

    var iter = std.mem.tokenizeScalar(u8, input, ' ');

    // Skip "insert" keyword
    _ = iter.next();

    // Parse ID - check for negative
    const id_str = iter.next() orelse return .syntax_error;
    const signed_id = std.fmt.parseInt(i64, id_str, 10) catch return .syntax_error;
    if (signed_id < 0) {
        return .negative_id;
    }
    if (signed_id > std.math.maxInt(u32)) {
        return .syntax_error;
    }

    // Parse username - check length
    const username = iter.next() orelse return .syntax_error;
    if (username.len > phase03.COLUMN_USERNAME_SIZE) {
        return .string_too_long;
    }

    // Parse email - check length
    const email = iter.next() orelse return .syntax_error;
    if (email.len > phase03.COLUMN_EMAIL_SIZE) {
        return .string_too_long;
    }

    statement.row_to_insert.id = @intCast(signed_id);
    statement.row_to_insert.setUsername(username);
    statement.row_to_insert.setEmail(email);

    return .success;
}

/// Prepare any statement with validation
pub fn prepareStatement(input: []const u8, statement: *Statement) PrepareResult {
    if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
        return prepareInsert(input, statement);
    }

    if (std.mem.eql(u8, input, "select")) {
        statement.statement_type = .select;
        return .success;
    }

    return .unrecognized_statement;
}
