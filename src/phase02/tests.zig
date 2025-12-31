//! Phase 02: Unit Tests for Parser Module

const std = @import("std");
const testing = std.testing;
const parser = @import("parser.zig");

test "prepareStatement recognizes insert" {
    var statement: parser.Statement = undefined;
    const result = parser.prepareStatement("insert 1 user foo@bar.com", &statement);

    try testing.expectEqual(parser.PrepareResult.success, result);
    try testing.expectEqual(parser.StatementType.insert, statement.statement_type);
}

test "prepareStatement recognizes select" {
    var statement: parser.Statement = undefined;
    const result = parser.prepareStatement("select", &statement);

    try testing.expectEqual(parser.PrepareResult.success, result);
    try testing.expectEqual(parser.StatementType.select, statement.statement_type);
}

test "prepareStatement rejects unknown statements" {
    var statement: parser.Statement = undefined;
    const result = parser.prepareStatement("delete", &statement);

    try testing.expectEqual(parser.PrepareResult.unrecognized_statement, result);
}

test "prepareStatement rejects empty input" {
    var statement: parser.Statement = undefined;
    const result = parser.prepareStatement("", &statement);

    try testing.expectEqual(parser.PrepareResult.unrecognized_statement, result);
}

test "isMetaCommand detects dot prefix" {
    try testing.expect(parser.isMetaCommand(".exit"));
    try testing.expect(parser.isMetaCommand(".tables"));
    try testing.expect(!parser.isMetaCommand("select"));
    try testing.expect(!parser.isMetaCommand(""));
}

test "doMetaCommand returns unrecognized for unknown commands" {
    // Note: .exit would call std.process.exit, so we only test unknown commands
    const result = parser.doMetaCommand(".tables");
    try testing.expectEqual(parser.MetaCommandResult.unrecognized_command, result);
}
