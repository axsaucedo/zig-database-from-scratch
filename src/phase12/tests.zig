//! Phase 12 Tests: Scanning a Multi-Level B-Tree

const std = @import("std");
const testing = std.testing;
const phase12 = @import("lib.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

test "Select returns all 15 rows in sorted order" {
    const filename = "/tmp/test_phase12_select.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 15 rows (triggers split into multi-level tree)
    var i: u32 = 1;
    while (i <= 15) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase12.executeInsert(&row, &table);
    }

    // Verify select traverses all leaves
    var cursor = try phase12.Cursor.tableStart(&table);
    var count: u32 = 0;
    var expected_id: u32 = 1;

    while (!cursor.end_of_table) {
        var row: phase03.Row = undefined;
        phase03.deserializeRow(try cursor.value(), &row);
        try testing.expectEqual(expected_id, row.id);
        expected_id += 1;
        count += 1;
        try cursor.advance();
    }

    try testing.expectEqual(@as(u32, 15), count);
}

test "Next leaf pointer links sibling leaves" {
    const filename = "/tmp/test_phase12_nextleaf.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert enough to create multiple leaves
    var i: u32 = 1;
    while (i <= 15) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase12.executeInsert(&row, &table);
    }

    // Start at leftmost leaf and follow next_leaf pointers
    var cursor = try phase12.Cursor.tableStart(&table);
    const first_page = cursor.page_num;
    const first_node = try table.pager.getPage(first_page);
    const first_count = phase12.leafNodeNumCells(first_node);

    // Advance through first leaf and verify we end up on a different page
    var advances: u32 = 0;
    while (!cursor.end_of_table and advances < first_count + 1) {
        try cursor.advance();
        advances += 1;
    }

    // With 15 rows, we should have moved to a second leaf
    if (!cursor.end_of_table) {
        try testing.expect(cursor.page_num != first_page);
    }
}

test "Empty table select works" {
    const filename = "/tmp/test_phase12_empty.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    const cursor = try phase12.Cursor.tableStart(&table);
    try testing.expect(cursor.end_of_table);
}

test "Single row select works" {
    const filename = "/tmp/test_phase12_single.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    var row = phase03.Row.init();
    row.id = 42;
    row.setUsername("test");
    row.setEmail("test@test.com");
    _ = phase12.executeInsert(&row, &table);

    var cursor = try phase12.Cursor.tableStart(&table);
    try testing.expect(!cursor.end_of_table);

    var found_row: phase03.Row = undefined;
    phase03.deserializeRow(try cursor.value(), &found_row);
    try testing.expectEqual(@as(u32, 42), found_row.id);

    try cursor.advance();
    try testing.expect(cursor.end_of_table);
}
