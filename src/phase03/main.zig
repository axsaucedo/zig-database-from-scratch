//! Phase 03: In-Memory Database Demo
//!
//! This demonstrates in-memory storage building on Phases 01-02.
//! Implements actual insert and select operations.
//!
//! Run: zig build run-phase03

const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const row = @import("row.zig");
const table = @import("table.zig");

/// Extended Statement with row data for insert
const Statement = struct {
    statement_type: phase02.StatementType,
    row_to_insert: row.Row,
};

/// Extended PrepareResult with syntax_error
const PrepareResult = enum {
    success,
    syntax_error,
    unrecognized_statement,
};

/// Execute result
const ExecuteResult = enum {
    success,
    table_full,
};

fn prepareInsert(input: []const u8, statement: *Statement) PrepareResult {
    statement.statement_type = .insert;
    statement.row_to_insert = row.Row.init();

    // Parse: "insert ID USERNAME EMAIL"
    var iter = std.mem.tokenizeScalar(u8, input, ' ');

    // Skip "insert" keyword
    _ = iter.next();

    // Parse ID
    const id_str = iter.next() orelse return .syntax_error;
    const id = std.fmt.parseInt(u32, id_str, 10) catch return .syntax_error;

    // Parse username
    const username = iter.next() orelse return .syntax_error;

    // Parse email
    const email = iter.next() orelse return .syntax_error;

    statement.row_to_insert.id = id;
    statement.row_to_insert.setUsername(username);
    statement.row_to_insert.setEmail(email);

    return .success;
}

fn prepareStatement(input: []const u8, statement: *Statement) PrepareResult {
    if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
        return prepareInsert(input, statement);
    }

    if (std.mem.eql(u8, input, "select")) {
        statement.statement_type = .select;
        return .success;
    }

    return .unrecognized_statement;
}

fn executeInsert(statement: *const Statement, tbl: *table.Table) ExecuteResult {
    if (tbl.isFull()) {
        return .table_full;
    }

    const slot = tbl.rowSlot(tbl.num_rows) catch return .table_full;
    row.serializeRow(&statement.row_to_insert, slot);
    tbl.num_rows += 1;

    return .success;
}

fn executeSelect(tbl: *table.Table) ExecuteResult {
    var r: row.Row = undefined;
    var i: u32 = 0;
    while (i < tbl.num_rows) : (i += 1) {
        const slot = tbl.rowSlot(i) catch continue;
        row.deserializeRow(slot, &r);
        row.printRow(&r);
    }
    return .success;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 03: In-Memory Database\n", .{});
    std.debug.print("Commands: insert <id> <username> <email>, select, .exit\n\n", .{});

    var tbl = table.Table.init(allocator);
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

        // Parse statement
        var statement: Statement = undefined;
        switch (prepareStatement(input, &statement)) {
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

// Re-export modules for downstream phases
pub const Row = row.Row;
pub const Table = table.Table;
pub const ROW_SIZE = row.ROW_SIZE;
pub const serializeRow = row.serializeRow;
pub const deserializeRow = row.deserializeRow;
pub const printRow = row.printRow;
pub const TABLE_MAX_ROWS = table.TABLE_MAX_ROWS;
pub const COLUMN_USERNAME_SIZE = row.COLUMN_USERNAME_SIZE;
pub const COLUMN_EMAIL_SIZE = row.COLUMN_EMAIL_SIZE;

test {
    _ = @import("tests.zig");
}
