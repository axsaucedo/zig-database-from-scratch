//! Phase 14 Tests: Splitting Internal Nodes

const std = @import("std");
const testing = std.testing;
const phase14 = @import("lib.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

test "Insert 64 rows creates multi-level internal tree" {
    const filename = "/tmp/test_phase14_large.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 64 rows - will cause multiple internal node splits
    var i: u32 = 1;
    while (i <= 64) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        const result = phase14.executeInsert(&row, &table);
        try testing.expectEqual(phase14.ExecuteResult.success, result);
    }

    // Verify all 64 rows can be retrieved in sorted order
    var cursor = try phase14.Cursor.tableStart(&table);
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

    try testing.expectEqual(@as(u32, 64), count);
}

test "7-leaf-node tree structure (from original tutorial)" {
    const filename = "/tmp/test_phase14_7leaf.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert the exact sequence from Part 14 of the tutorial
    const order = [_]u32{
        58, 56, 8,  54, 77, 7,  25, 71, 13, 22,
        53, 51, 59, 32, 36, 79, 10, 33, 20, 4,
        35, 76, 49, 24, 70, 48, 39, 15, 47, 30,
        86, 31, 68, 37, 66, 63, 40, 78, 19, 46,
        14, 81, 72, 6,  50, 85, 67, 2,  55, 69,
        5,  65, 52, 1,  29, 9,  43, 75, 21, 82,
        12, 18, 60, 44,
    };

    for (order) |id| {
        var row = phase03.Row.init();
        row.id = id;
        var buf: [32]u8 = undefined;
        const name = std.fmt.bufPrint(&buf, "user{d}", .{id}) catch "user";
        row.setUsername(name);
        var email_buf: [64]u8 = undefined;
        const email = std.fmt.bufPrint(&email_buf, "person{d}@example.com", .{id}) catch "test@test.com";
        row.setEmail(email);
        const result = phase14.executeInsert(&row, &table);
        try testing.expectEqual(phase14.ExecuteResult.success, result);
    }

    // Verify all can be found
    for (order) |id| {
        const cursor = try phase14.tableFind(&table, id);
        const node = try table.pager.getPage(cursor.page_num);
        const key = phase14.leafNodeKey(node, cursor.cell_num);
        try testing.expectEqual(id, key);
    }

    // Verify select returns all in order
    var cursor = try phase14.Cursor.tableStart(&table);
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

    try testing.expectEqual(@as(u32, 64), count);
}

test "Pseudorandom insertions with internal splits" {
    const filename = "/tmp/test_phase14_random.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Linear congruential generator for reproducible "random" order
    var x: u32 = 12345;
    var inserted = std.AutoHashMap(u32, void).init(testing.allocator);
    defer inserted.deinit();

    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        x = (1103515245 *% x +% 12345) % 100 + 1;
        if (inserted.contains(x)) continue;
        try inserted.put(x, {});

        var row = phase03.Row.init();
        row.id = x;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase14.executeInsert(&row, &table);
    }

    // Verify all inserted keys can be found
    var iter = inserted.keyIterator();
    while (iter.next()) |key| {
        const cursor = try phase14.tableFind(&table, key.*);
        const node = try table.pager.getPage(cursor.page_num);
        const found_key = phase14.leafNodeKey(node, cursor.cell_num);
        try testing.expectEqual(key.*, found_key);
    }
}

test "Duplicate rejection after internal split" {
    const filename = "/tmp/test_phase14_dup.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 40 rows
    var i: u32 = 1;
    while (i <= 40) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase14.executeInsert(&row, &table);
    }

    // Try duplicate
    var row = phase03.Row.init();
    row.id = 25;
    row.setUsername("dup");
    row.setEmail("dup@test.com");
    const result = phase14.executeInsert(&row, &table);
    try testing.expectEqual(phase14.ExecuteResult.duplicate_key, result);
}
