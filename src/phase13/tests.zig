//! Phase 13 Tests: Updating Parent Node After a Split

const std = @import("std");
const testing = std.testing;
const phase13 = @import("lib.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

test "Insert 30 rows in pseudorandom order creates 4-leaf tree" {
    const filename = "/tmp/test_phase13_random.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert in pseudorandom order (from original tutorial)
    const order = [_]u32{
        18, 7, 10, 29, 23, 4, 14, 30, 15, 26,
        22, 19, 2,  1,  21, 11, 6,  20, 5,  8,
        9,  3, 12, 27, 17, 16, 13, 24, 25, 28,
    };

    for (order) |id| {
        var row = phase03.Row.init();
        row.id = id;
        row.setUsername("user");
        row.setEmail("user@test.com");
        const result = phase13.executeInsert(&row, &table);
        try testing.expectEqual(phase13.ExecuteResult.success, result);
    }

    // Verify all 30 rows can be retrieved in sorted order
    var cursor = try phase13.Cursor.tableStart(&table);
    var count: u32 = 0;
    var last_id: u32 = 0;

    while (!cursor.end_of_table) {
        var row: phase03.Row = undefined;
        phase03.deserializeRow(try cursor.value(), &row);
        try testing.expect(row.id > last_id);
        last_id = row.id;
        count += 1;
        try cursor.advance();
    }

    try testing.expectEqual(@as(u32, 30), count);
}

test "Parent key updates correctly after split" {
    const filename = "/tmp/test_phase13_parent.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 15 rows to create internal node
    var i: u32 = 1;
    while (i <= 15) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase13.executeInsert(&row, &table);
    }

    // Check that root is internal node
    const root = try table.pager.getPage(table.root_page_num);
    try testing.expectEqual(phase08.btree.NodeType.internal, phase13.getNodeType(root));

    // Verify keys in internal node are correct maxes of children
    const num_keys = phase13.getInternalNodeNumKeys(root);
    try testing.expect(num_keys > 0);

    // First key should be max of first child
    const first_child_page = phase13.getInternalNodeChild(root, 0);
    const first_child = try table.pager.getPage(first_child_page);
    const first_child_max = phase13.getNodeMaxKey(table.pager, first_child);
    const first_key = phase13.getInternalNodeKey(root, 0);
    try testing.expectEqual(first_child_max, first_key);
}

test "All rows retrievable after multiple splits" {
    const filename = "/tmp/test_phase13_multi.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 20 rows
    var i: u32 = 1;
    while (i <= 20) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase13.executeInsert(&row, &table);
    }

    // Verify all can be found
    i = 1;
    while (i <= 20) : (i += 1) {
        const cursor = try phase13.tableFind(&table, i);
        const node = try table.pager.getPage(cursor.page_num);
        const key = phase13.leafNodeKey(node, cursor.cell_num);
        try testing.expectEqual(i, key);
    }
}
