//! Phase 05: Persistence Demo
//!
//! This demonstrates file-based persistence using the Pager.
//! Data survives program restarts.
//!
//! Run: zig build run-phase05 -- mydb.db

const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const pager = @import("pager.zig");

const Statement = struct {
    statement_type: phase02.StatementType,
    row_to_insert: phase03.Row,
};

const PrepareResult = enum {
    success,
    negative_id,
    string_too_long,
    syntax_error,
    unrecognized_statement,
};

const ExecuteResult = enum {
    success,
    table_full,
};

fn prepareInsert(input: []const u8, statement: *Statement) PrepareResult {
    statement.statement_type = .insert;
    statement.row_to_insert = phase03.Row.init();

    var iter = std.mem.tokenizeScalar(u8, input, ' ');
    _ = iter.next(); // Skip "insert"

    const id_str = iter.next() orelse return .syntax_error;
    const signed_id = std.fmt.parseInt(i64, id_str, 10) catch return .syntax_error;
    if (signed_id < 0) return .negative_id;
    if (signed_id > std.math.maxInt(u32)) return .syntax_error;

    const username = iter.next() orelse return .syntax_error;
    if (username.len > phase03.COLUMN_USERNAME_SIZE) return .string_too_long;

    const email = iter.next() orelse return .syntax_error;
    if (email.len > phase03.COLUMN_EMAIL_SIZE) return .string_too_long;

    statement.row_to_insert.id = @intCast(signed_id);
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

fn executeInsert(statement: *const Statement, table: *pager.Table) ExecuteResult {
    if (table.isFull()) return .table_full;

    const slot = table.rowSlot(table.num_rows) catch return .table_full;
    phase03.serializeRow(&statement.row_to_insert, slot);
    table.num_rows += 1;

    return .success;
}

fn executeSelect(table: *pager.Table) ExecuteResult {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    var r: phase03.Row = undefined;
    var i: u32 = 0;
    while (i < table.num_rows) : (i += 1) {
        const slot = table.rowSlot(i) catch continue;
        phase03.deserializeRow(slot, &r);
        stdout.print("({d}, {s}, {s})\n", .{
            r.id,
            r.getUsernameSlice(),
            r.getEmailSlice(),
        }) catch {};
    }
    return .success;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Must supply a database filename.\n", .{});
        std.debug.print("Usage: db_phase05 <filename>\n", .{});
        return;
    }

    const filename = args[1];
    std.debug.print("Phase 05: Persistence to Disk\n", .{});
    std.debug.print("Database file: {s}\n", .{filename});
    std.debug.print("Commands: insert <id> <username> <email>, select, .exit\n\n", .{});

    var table = try pager.Table.dbOpen(allocator, filename);

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

        if (phase02.isMetaCommand(input)) {
            if (std.mem.eql(u8, input, ".exit")) {
                try table.dbClose();
                return;
            }
            stdout.print("Unrecognized command '{s}'\n", .{input}) catch {};
            continue;
        }

        var statement: Statement = undefined;
        switch (prepareStatement(input, &statement)) {
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

        const result = switch (statement.statement_type) {
            .insert => executeInsert(&statement, &table),
            .select => executeSelect(&table),
        };

        switch (result) {
            .success => stdout.print("Executed.\n", .{}) catch {},
            .table_full => stdout.print("Error: Table full.\n", .{}) catch {},
        }
    }
}

// Re-export for downstream phases
pub const Pager = pager.Pager;
pub const Table = pager.Table;
pub const PAGE_SIZE = pager.PAGE_SIZE;
pub const TABLE_MAX_PAGES = pager.TABLE_MAX_PAGES;
pub const ROWS_PER_PAGE = pager.ROWS_PER_PAGE;

test {
    _ = @import("tests.zig");
}
