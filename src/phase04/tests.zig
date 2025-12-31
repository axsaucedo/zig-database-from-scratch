//! Phase 04: Unit Tests for Validation Module

const std = @import("std");
const testing = std.testing;
const validation = @import("validation.zig");

test "prepareInsert accepts valid input" {
    var statement: validation.Statement = undefined;
    const result = validation.prepareInsert("insert 1 user1 user1@example.com", &statement);

    try testing.expectEqual(validation.PrepareResult.success, result);
    try testing.expectEqual(@as(u32, 1), statement.row_to_insert.id);
    try testing.expectEqualStrings("user1", statement.row_to_insert.getUsernameSlice());
    try testing.expectEqualStrings("user1@example.com", statement.row_to_insert.getEmailSlice());
}

test "prepareInsert rejects negative ID" {
    var statement: validation.Statement = undefined;
    const result = validation.prepareInsert("insert -1 user foo@bar.com", &statement);

    try testing.expectEqual(validation.PrepareResult.negative_id, result);
}

test "prepareInsert rejects username too long" {
    var statement: validation.Statement = undefined;
    // 33 characters (one more than allowed)
    const result = validation.prepareInsert("insert 1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa foo@bar.com", &statement);

    try testing.expectEqual(validation.PrepareResult.string_too_long, result);
}

test "prepareInsert accepts max length username" {
    var statement: validation.Statement = undefined;
    // Exactly 32 characters
    const result = validation.prepareInsert("insert 1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa foo@bar.com", &statement);

    try testing.expectEqual(validation.PrepareResult.success, result);
}

test "prepareInsert rejects missing fields" {
    var statement: validation.Statement = undefined;

    // Missing email
    var result = validation.prepareInsert("insert 1 user", &statement);
    try testing.expectEqual(validation.PrepareResult.syntax_error, result);

    // Missing username
    result = validation.prepareInsert("insert 1", &statement);
    try testing.expectEqual(validation.PrepareResult.syntax_error, result);

    // Missing ID
    result = validation.prepareInsert("insert", &statement);
    try testing.expectEqual(validation.PrepareResult.syntax_error, result);
}

test "prepareInsert rejects non-numeric ID" {
    var statement: validation.Statement = undefined;
    const result = validation.prepareInsert("insert abc user foo@bar.com", &statement);

    try testing.expectEqual(validation.PrepareResult.syntax_error, result);
}

test "prepareStatement recognizes select" {
    var statement: validation.Statement = undefined;
    const result = validation.prepareStatement("select", &statement);

    try testing.expectEqual(validation.PrepareResult.success, result);
    try testing.expectEqual(validation.StatementType.select, statement.statement_type);
}

test "prepareStatement rejects unknown" {
    var statement: validation.Statement = undefined;
    const result = validation.prepareStatement("delete", &statement);

    try testing.expectEqual(validation.PrepareResult.unrecognized_statement, result);
}
