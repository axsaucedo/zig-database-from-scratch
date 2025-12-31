//! Phase 02: SQL Compiler Demo
//!
//! This demonstrates statement parsing building on Phase 01.
//! Imports input handling from phase01, adds parsing logic.
//!
//! Run: zig build run-phase02

const std = @import("std");
const phase01 = @import("phase01");
const parser = @import("parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 02: SQL Compiler & Virtual Machine\n", .{});
    std.debug.print("Commands: insert <args>, select, .exit\n\n", .{});

    var input_buffer = try phase01.InputBuffer.init(allocator);
    defer input_buffer.deinit();

    const stdout = std.fs.File.stdout().deprecatedWriter();

    while (true) {
        phase01.printPrompt();

        phase01.readInput(&input_buffer) catch |err| {
            std.debug.print("Error reading input: {}\n", .{err});
            return err;
        };

        const input = input_buffer.getInput();

        // Handle meta commands (starting with '.')
        if (parser.isMetaCommand(input)) {
            switch (parser.doMetaCommand(input)) {
                .success => continue,
                .unrecognized_command => {
                    stdout.print("Unrecognized command '{s}'\n", .{input}) catch {};
                    continue;
                },
            }
        }

        // Parse and execute statement
        var statement: parser.Statement = undefined;
        switch (parser.prepareStatement(input, &statement)) {
            .success => {},
            .syntax_error => {
                stdout.print("Syntax error. Could not parse statement.\n", .{}) catch {};
                continue;
            },
            .unrecognized_statement => {
                stdout.print("Unrecognized keyword at start of '{s}'.\n", .{input}) catch {};
                continue;
            },
        }

        // Execute (stub for now)
        switch (statement.statement_type) {
            .insert => stdout.print("This is where we would do an insert.\n", .{}) catch {},
            .select => stdout.print("This is where we would do a select.\n", .{}) catch {},
        }
        stdout.print("Executed.\n", .{}) catch {};
    }
}

// Re-export for downstream phases
pub const Statement = parser.Statement;
pub const StatementType = parser.StatementType;
pub const PrepareResult = parser.PrepareResult;
pub const MetaCommandResult = parser.MetaCommandResult;
pub const doMetaCommand = parser.doMetaCommand;
pub const isMetaCommand = parser.isMetaCommand;
pub const prepareStatement = parser.prepareStatement;

test {
    _ = @import("tests.zig");
}
