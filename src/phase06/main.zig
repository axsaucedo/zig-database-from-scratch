//! Phase 06: Cursor Demo
//!
//! Uses cursor abstraction for insert/select operations.

const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const phase05 = @import("phase05");
const cursor = @import("cursor.zig");

pub const Cursor = cursor.Cursor;

const Statement = struct {
    statement_type: phase02.StatementType,
    row_to_insert: phase03.Row,
};

fn prepareInsert(input: []const u8, stmt: *Statement) bool {
    stmt.statement_type = .insert;
    stmt.row_to_insert = phase03.Row.init();

    var iter = std.mem.tokenizeScalar(u8, input, ' ');
    _ = iter.next();

    const id_str = iter.next() orelse return false;
    const id = std.fmt.parseInt(u32, id_str, 10) catch return false;
    const username = iter.next() orelse return false;
    const email = iter.next() orelse return false;

    stmt.row_to_insert.id = id;
    stmt.row_to_insert.setUsername(username);
    stmt.row_to_insert.setEmail(email);
    return true;
}

fn executeInsert(stmt: *const Statement, table: *phase05.Table) !void {
    if (table.isFull()) return error.TableFull;

    var c = Cursor.tableEnd(table);
    const slot = try c.value();
    phase03.serializeRow(&stmt.row_to_insert, slot);
    table.num_rows += 1;
}

fn executeSelect(table: *phase05.Table) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    var c = Cursor.tableStart(table);

    while (!c.end_of_table) {
        var row: phase03.Row = undefined;
        const slot = try c.value();
        phase03.deserializeRow(slot, &row);
        stdout.print("({d}, {s}, {s})\n", .{ row.id, row.getUsernameSlice(), row.getEmailSlice() }) catch {};
        c.advance();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: db_phase06 <filename>\n", .{});
        return;
    }

    std.debug.print("Phase 06: Cursor Abstraction\n\n", .{});

    var table = try phase05.Table.dbOpen(allocator, args[1]);

    var input_buffer = try phase01.InputBuffer.init(allocator);
    defer input_buffer.deinit();
    const stdout = std.fs.File.stdout().deprecatedWriter();

    while (true) {
        phase01.printPrompt();
        phase01.readInput(&input_buffer) catch |err| {
            if (err == error.EndOfStream) { try table.dbClose(); return; }
            return err;
        };
        const input = input_buffer.getInput();

        if (phase02.isMetaCommand(input)) {
            if (std.mem.eql(u8, input, ".exit")) { try table.dbClose(); return; }
            stdout.print("Unrecognized command.\n", .{}) catch {};
            continue;
        }

        var stmt: Statement = undefined;
        if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
            if (!prepareInsert(input, &stmt)) { stdout.print("Syntax error.\n", .{}) catch {}; continue; }
            executeInsert(&stmt, &table) catch { stdout.print("Error.\n", .{}) catch {}; continue; };
        } else if (std.mem.eql(u8, input, "select")) {
            executeSelect(&table) catch {};
        } else {
            stdout.print("Unrecognized.\n", .{}) catch {};
            continue;
        }
        stdout.print("Executed.\n", .{}) catch {};
    }
}

test { _ = @import("tests.zig"); }
