const std = @import("std");

pub const MetaCommandResult = enum { success, unrecognized_command };
pub const PrepareResult = enum { success, syntax_error, unrecognized_statement };
pub const StatementType = enum { insert, select };
pub const Statement = struct { statement_type: StatementType };

pub fn isMetaCommand(input: []const u8) bool {
    return input.len > 0 and input[0] == '.';
}

pub fn doMetaCommand(input: []const u8) MetaCommandResult {
    if (std.mem.eql(u8, input, ".exit")) return .success;
    return .unrecognized_command;
}

pub fn prepareStatement(input: []const u8, statement: *Statement) PrepareResult {
    if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
        statement.statement_type = .insert;
        return .success;
    }
    if (std.mem.eql(u8, input, "select")) {
        statement.statement_type = .select;
        return .success;
    }
    return .unrecognized_statement;
}
