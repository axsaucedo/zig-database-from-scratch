//! Phase 12: Scanning a Multi-Level B-Tree
//! Demo of proper multi-level tree traversal

const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const phase08 = @import("phase08");
const phase12 = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: db_phase12 <filename>\n", .{});
        return;
    }

    std.debug.print("Phase 12: Scanning a Multi-Level B-Tree\n", .{});
    std.debug.print("Select now works across all leaf nodes!\n\n", .{});

    var table = try phase08.Table.dbOpen(allocator, args[1]);
    const stdout = std.fs.File.stdout().deprecatedWriter();

    var input_buffer = try phase01.InputBuffer.init(allocator);
    defer input_buffer.deinit();

    while (true) {
        phase01.printPrompt();
        phase01.readInput(&input_buffer) catch |err| {
            if (err == error.EndOfStream) {
                try table.dbClose();
                return;
            }
            return err;
        };
        const input = input_buffer.getInput();

        if (phase02.isMetaCommand(input)) {
            if (std.mem.eql(u8, input, ".exit")) {
                try table.dbClose();
                return;
            }
            if (std.mem.eql(u8, input, ".btree")) {
                try stdout.print("Tree:\n", .{});
                try phase12.printTree(&table, table.root_page_num, 0);
            } else if (std.mem.eql(u8, input, ".constants")) {
                try stdout.print("Constants:\n", .{});
                phase08.printConstants();
            } else {
                try stdout.print("Unrecognized command.\n", .{});
            }
            continue;
        }

        if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
            var iter = std.mem.tokenizeScalar(u8, input, ' ');
            _ = iter.next();
            const id_str = iter.next() orelse {
                try stdout.print("Syntax error.\n", .{});
                continue;
            };
            const id = std.fmt.parseInt(u32, id_str, 10) catch {
                try stdout.print("Syntax error.\n", .{});
                continue;
            };
            const username = iter.next() orelse {
                try stdout.print("Syntax error.\n", .{});
                continue;
            };
            const email = iter.next() orelse {
                try stdout.print("Syntax error.\n", .{});
                continue;
            };

            var row = phase03.Row.init();
            row.id = id;
            row.setUsername(username);
            row.setEmail(email);

            switch (phase12.executeInsert(&row, &table)) {
                .success => try stdout.print("Executed.\n", .{}),
                .duplicate_key => try stdout.print("Error: Duplicate key.\n", .{}),
            }
        } else if (std.mem.eql(u8, input, "select")) {
            try phase12.executeSelect(&table, stdout);
            try stdout.print("Executed.\n", .{});
        } else {
            try stdout.print("Unrecognized.\n", .{});
        }
    }
}

test {
    _ = @import("tests.zig");
}
