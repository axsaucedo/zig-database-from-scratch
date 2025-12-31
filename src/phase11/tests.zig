//! Phase 11 Tests: Recursively Searching the B-Tree

const std = @import("std");
const testing = std.testing;
const phase11 = @import("lib.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

test "Insert 15 rows causes split and all can be found" {
    const filename = "/tmp/test_phase11_search.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 15 rows (will cause at least one split)
    var i: u32 = 1;
    while (i <= 15) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        const result = phase11.executeInsert(&row, &table);
        try testing.expectEqual(phase11.ExecuteResult.success, result);
    }

    // Verify all keys can be found via internal node search
    i = 1;
    while (i <= 15) : (i += 1) {
        const cursor = try phase11.tableFind(&table, i);
        const node = try table.pager.getPage(cursor.page_num);
        const key = phase11.leafNodeKey(node, cursor.cell_num);
        try testing.expectEqual(i, key);
    }
}

test "Internal node binary search finds correct child" {
    const filename = "/tmp/test_phase11_bsearch.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert enough to create internal node
    var i: u32 = 1;
    while (i <= 14) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase11.executeInsert(&row, &table);
    }

    // Now insert key 15 - this triggers split and internal node creation
    var row = phase03.Row.init();
    row.id = 15;
    row.setUsername("user15");
    row.setEmail("user15@test.com");
    const result = phase11.executeInsert(&row, &table);
    try testing.expectEqual(phase11.ExecuteResult.success, result);

    // Verify we can find key 15 after the split
    const cursor = try phase11.tableFind(&table, 15);
    const node = try table.pager.getPage(cursor.page_num);
    const key = phase11.leafNodeKey(node, cursor.cell_num);
    try testing.expectEqual(@as(u32, 15), key);
}

test "Duplicate key rejected after split" {
    const filename = "/tmp/test_phase11_dup.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 15 rows
    var i: u32 = 1;
    while (i <= 15) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase11.executeInsert(&row, &table);
    }

    // Try to insert duplicate
    var row = phase03.Row.init();
    row.id = 7; // Middle key
    row.setUsername("dup");
    row.setEmail("dup@test.com");
    const result = phase11.executeInsert(&row, &table);
    try testing.expectEqual(phase11.ExecuteResult.duplicate_key, result);
}
