const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const phase08 = @import("phase08");
const phase09 = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: db_phase09 <filename>\n", .{});
        return;
    }

    std.debug.print("Phase 09: Binary Search & Duplicate Keys\n", .{});
    std.debug.print("Keys are now stored in sorted order!\n\n", .{});

    var table = try phase08.Table.dbOpen(allocator, args[1]);

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
            if (std.mem.eql(u8, input, ".btree")) {
                stdout.print("Tree:\n", .{}) catch {};
                phase08.printLeafNode(try table.pager.getPage(0));
            } else if (std.mem.eql(u8, input, ".constants")) {
                stdout.print("Constants:\n", .{}) catch {};
                phase08.printConstants();
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

            switch (phase09.executeInsert(&row, &table)) {
                .success => stdout.print("Executed.\n", .{}) catch {},
                .duplicate_key => stdout.print("Error: Duplicate key.\n", .{}) catch {},
                .table_full => stdout.print("Error: Table full.\n", .{}) catch {},
            }
        } else if (std.mem.eql(u8, input, "select")) {
            var c = try phase08.Cursor.tableStart(&table);
            while (!c.end_of_table) {
                var row: phase03.Row = undefined;
                phase03.deserializeRow(try c.value(), &row);
                stdout.print("({d}, {s}, {s})\n", .{ row.id, row.getUsernameSlice(), row.getEmailSlice() }) catch {};
                try c.advance();
            }
            stdout.print("Executed.\n", .{}) catch {};
        } else {
            stdout.print("Unrecognized.\n", .{}) catch {};
        }
    }
}

test { _ = @import("tests.zig"); }
