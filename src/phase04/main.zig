//! Phase 04: Validation Demo
//!
//! This demonstrates input validation building on Phases 01-03.
//! Adds proper error messages for invalid input.
//!
//! Run: zig build run-phase04

const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const validation = @import("validation.zig");

const ExecuteResult = enum {
    success,
    table_full,
};

fn executeInsert(statement: *const validation.Statement, tbl: *phase03.Table) ExecuteResult {
    if (tbl.isFull()) {
        return .table_full;
    }

    const slot = tbl.rowSlot(tbl.num_rows) catch return .table_full;
    phase03.serializeRow(&statement.row_to_insert, slot);
    tbl.num_rows += 1;

    return .success;
}

fn executeSelect(tbl: *phase03.Table) ExecuteResult {
    var r: phase03.Row = undefined;
    var i: u32 = 0;
    while (i < tbl.num_rows) : (i += 1) {
        const slot = tbl.rowSlot(i) catch continue;
        phase03.deserializeRow(slot, &r);
        phase03.printRow(&r);
    }
    return .success;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 04: Input Validation\n", .{});
    std.debug.print("Commands: insert <id> <username> <email>, select, .exit\n", .{});
    std.debug.print("Try: insert -1 user foo@bar.com (negative ID error)\n\n", .{});

    var tbl = phase03.Table.init(allocator);
    defer tbl.deinit();

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

        // Handle meta commands
        if (phase02.isMetaCommand(input)) {
            switch (phase02.doMetaCommand(input)) {
                .success => continue,
                .unrecognized_command => {
                    stdout.print("Unrecognized command '{s}'\n", .{input}) catch {};
                    continue;
                },
            }
        }

        // Parse statement with validation
        var statement: validation.Statement = undefined;
        switch (validation.prepareStatement(input, &statement)) {
            .success => {},
            .negative_id => {
                stdout.print("ID must be positive.\n", .{}) catch {};
                continue;
            },
            .string_too_long => {
                stdout.print("String is too long.\n", .{}) catch {};
                continue;
            },
            .syntax_error => {
                stdout.print("Syntax error. Could not parse statement.\n", .{}) catch {};
                continue;
            },
            .unrecognized_statement => {
                stdout.print("Unrecognized keyword at start of '{s}'.\n", .{input}) catch {};
                continue;
            },
        }

        // Execute statement
        const result = switch (statement.statement_type) {
            .insert => executeInsert(&statement, &tbl),
            .select => executeSelect(&tbl),
        };

        switch (result) {
            .success => stdout.print("Executed.\n", .{}) catch {},
            .table_full => stdout.print("Error: Table full.\n", .{}) catch {},
        }
    }
}

// Re-export validation module
pub const PrepareResult = validation.PrepareResult;
pub const Statement = validation.Statement;
pub const StatementType = validation.StatementType;
pub const prepareInsert = validation.prepareInsert;
pub const prepareStatement = validation.prepareStatement;

test {
    _ = @import("tests.zig");
}
