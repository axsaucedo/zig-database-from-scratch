//! Phase 08: B-Tree Leaf Node Demo
//!
//! This phase uses B-Tree leaf nodes for storage.
//! Commands: insert, select, .btree, .constants, .exit

const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const btree = @import("btree.zig");
const pager = @import("pager.zig");
const cursor = @import("cursor.zig");

const ExecuteResult = enum { success, duplicate_key, table_full };

fn leafNodeInsert(c: *cursor.Cursor, key: u32, row: *const phase03.Row) !void {
    const node = try c.table.pager.getPage(c.page_num);
    const num_cells = btree.leafNodeNumCells(node);

    if (num_cells >= btree.LEAF_NODE_MAX_CELLS) {
        return error.NodeFull; // Will implement splitting later
    }

    // Make room for new cell
    if (c.cell_num < num_cells) {
        var i = num_cells;
        while (i > c.cell_num) : (i -= 1) {
            const src = btree.leafNodeCell(node, i - 1);
            const dst = btree.leafNodeCell(node, i);
            @memcpy(dst, src);
        }
    }

    btree.setLeafNodeNumCells(node, num_cells + 1);
    btree.setLeafNodeKey(node, c.cell_num, key);
    phase03.serializeRow(row, btree.leafNodeValue(node, c.cell_num));
}

fn executeInsert(row: *const phase03.Row, table: *pager.Table) ExecuteResult {
    const node = table.pager.getPage(table.root_page_num) catch return .table_full;
    const num_cells = btree.leafNodeNumCells(node);

    if (num_cells >= btree.LEAF_NODE_MAX_CELLS) {
        return .table_full;
    }

    const key = row.id;
    var c = cursor.Cursor.tableFind(table, key) catch return .table_full;

    // Check for duplicate
    if (c.cell_num < num_cells) {
        const existing_key = btree.leafNodeKey(node, c.cell_num);
        if (existing_key == key) {
            return .duplicate_key;
        }
    }

    leafNodeInsert(&c, key, row) catch return .table_full;
    return .success;
}

fn executeSelect(table: *pager.Table) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    var c = try cursor.Cursor.tableStart(table);

    while (!c.end_of_table) {
        var row: phase03.Row = undefined;
        const val = try c.value();
        phase03.deserializeRow(val, &row);
        stdout.print("({d}, {s}, {s})\n", .{ row.id, row.getUsernameSlice(), row.getEmailSlice() }) catch {};
        try c.advance();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: db_phase08 <filename>\n", .{});
        return;
    }

    std.debug.print("Phase 08: B-Tree Leaf Node Format\n", .{});
    std.debug.print("Max cells per leaf: {d}\n\n", .{btree.LEAF_NODE_MAX_CELLS});

    var table = try pager.Table.dbOpen(allocator, args[1]);

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
            if (std.mem.eql(u8, input, ".exit")) {
                try table.dbClose();
                return;
            } else if (std.mem.eql(u8, input, ".btree")) {
                stdout.print("Tree:\n", .{}) catch {};
                const root = try table.pager.getPage(0);
                btree.printLeafNode(root);
            } else if (std.mem.eql(u8, input, ".constants")) {
                stdout.print("Constants:\n", .{}) catch {};
                btree.printConstants();
            } else {
                stdout.print("Unrecognized command.\n", .{}) catch {};
            }
            continue;
        }

        if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
            var iter = std.mem.tokenizeScalar(u8, input, ' ');
            _ = iter.next();
            const id_str = iter.next() orelse { stdout.print("Syntax error.\n", .{}) catch {}; continue; };
            const id = std.fmt.parseInt(u32, id_str, 10) catch { stdout.print("Syntax error.\n", .{}) catch {}; continue; };
            const username = iter.next() orelse { stdout.print("Syntax error.\n", .{}) catch {}; continue; };
            const email = iter.next() orelse { stdout.print("Syntax error.\n", .{}) catch {}; continue; };

            var row = phase03.Row.init();
            row.id = id;
            row.setUsername(username);
            row.setEmail(email);

            switch (executeInsert(&row, &table)) {
                .success => stdout.print("Executed.\n", .{}) catch {},
                .duplicate_key => stdout.print("Error: Duplicate key.\n", .{}) catch {},
                .table_full => stdout.print("Error: Table full.\n", .{}) catch {},
            }
        } else if (std.mem.eql(u8, input, "select")) {
            executeSelect(&table) catch {};
            stdout.print("Executed.\n", .{}) catch {};
        } else {
            stdout.print("Unrecognized.\n", .{}) catch {};
        }
    }
}

test {
    _ = @import("tests.zig");
}
