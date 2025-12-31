const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const phase08 = @import("phase08");
const phase10 = @import("lib.zig");

fn printTree(table: *phase08.pager.Table, page_num: u32, indent: u32) !void {
    const node = try table.pager.getPage(page_num);
    const node_type = phase08.getNodeType(node);

    var i: u32 = 0;
    while (i < indent) : (i += 1) std.debug.print("  ", .{});

    switch (node_type) {
        .leaf => {
            const num_cells = phase08.leafNodeNumCells(node);
            std.debug.print("- leaf (size {d})\n", .{num_cells});
            i = 0;
            while (i < num_cells) : (i += 1) {
                var j: u32 = 0;
                while (j < indent + 1) : (j += 1) std.debug.print("  ", .{});
                std.debug.print("- {d}\n", .{phase08.leafNodeKey(node, i)});
            }
        },
        .internal => {
            const num_keys = phase10.getInternalNodeNumKeys(node);
            std.debug.print("- internal (size {d})\n", .{num_keys});
            i = 0;
            while (i < num_keys) : (i += 1) {
                const child = phase10.getInternalNodeChild(node, i);
                try printTree(table, child, indent + 1);
                var j: u32 = 0;
                while (j < indent + 1) : (j += 1) std.debug.print("  ", .{});
                std.debug.print("- key {d}\n", .{phase10.getInternalNodeKey(node, i)});
            }
            const right_child = phase10.split.getInternalNodeRightChild(node);
            try printTree(table, right_child, indent + 1);
        },
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: db_phase10 <filename>\n", .{});
        return;
    }

    std.debug.print("Phase 10: Leaf Node Splitting\n", .{});
    std.debug.print("Tree grows automatically when nodes are full!\n\n", .{});

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
                try printTree(&table, table.root_page_num, 0);
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

            switch (phase10.executeInsert(&row, &table)) {
                .success => stdout.print("Executed.\n", .{}) catch {},
                .duplicate_key => stdout.print("Error: Duplicate key.\n", .{}) catch {},
            }
        } else if (std.mem.eql(u8, input, "select")) {
            var cursor = try phase10.findLeafNode(&table, table.root_page_num, 0);
            while (!cursor.end_of_table) {
                var row: phase03.Row = undefined;
                phase03.deserializeRow(try cursor.value(), &row);
                stdout.print("({d}, {s}, {s})\n", .{ row.id, row.getUsernameSlice(), row.getEmailSlice() }) catch {};
                try cursor.advance();
            }
            stdout.print("Executed.\n", .{}) catch {};
        } else {
            stdout.print("Unrecognized.\n", .{}) catch {};
        }
    }
}

test { _ = @import("tests.zig"); }
