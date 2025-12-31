const std = @import("std");
const testing = std.testing;
const parser = @import("parser.zig");

test "isMetaCommand" {
    try testing.expect(parser.isMetaCommand(".exit"));
    try testing.expect(!parser.isMetaCommand("select"));
}

test "doMetaCommand" {
    try testing.expectEqual(parser.MetaCommandResult.success, parser.doMetaCommand(".exit"));
    try testing.expectEqual(parser.MetaCommandResult.unrecognized_command, parser.doMetaCommand(".foo"));
}

test "prepareStatement insert" {
    var stmt: parser.Statement = undefined;
    try testing.expectEqual(parser.PrepareResult.success, parser.prepareStatement("insert 1 u e", &stmt));
    try testing.expectEqual(parser.StatementType.insert, stmt.statement_type);
}

test "prepareStatement select" {
    var stmt: parser.Statement = undefined;
    try testing.expectEqual(parser.PrepareResult.success, parser.prepareStatement("select", &stmt));
    try testing.expectEqual(parser.StatementType.select, stmt.statement_type);
}
