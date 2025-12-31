//! Phase 02: Statement Parser Module
//!
//! This module provides SQL statement parsing.
//! It imports from phase01 and exports parsing functions.

const std = @import("std");

/// Result of executing a meta command
pub const MetaCommandResult = enum {
    success,
    unrecognized_command,
};

/// Result of preparing (parsing) a statement
pub const PrepareResult = enum {
    success,
    syntax_error,
    unrecognized_statement,
};

/// Type of SQL statement
pub const StatementType = enum {
    insert,
    select,
};

/// Represents a parsed SQL statement
pub const Statement = struct {
    statement_type: StatementType,
    // Row data will be added in phase03
};

/// Handle meta-commands that start with '.'
/// Returns .success and exits if command is .exit
pub fn doMetaCommand(input_slice: []const u8) MetaCommandResult {
    if (std.mem.eql(u8, input_slice, ".exit")) {
        std.process.exit(0);
    }
    return .unrecognized_command;
}

/// Check if input is a meta command (starts with '.')
pub fn isMetaCommand(input_slice: []const u8) bool {
    return input_slice.len > 0 and input_slice[0] == '.';
}

/// Parse input into a Statement (basic version)
pub fn prepareStatement(input_slice: []const u8, statement: *Statement) PrepareResult {
    // Check if input starts with "insert"
    if (input_slice.len >= 6 and std.mem.eql(u8, input_slice[0..6], "insert")) {
        statement.statement_type = .insert;
        return .success;
    }

    // Check for "select"
    if (std.mem.eql(u8, input_slice, "select")) {
        statement.statement_type = .select;
        return .success;
    }

    return .unrecognized_statement;
}
