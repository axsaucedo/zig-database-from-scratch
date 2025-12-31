const std = @import("std");
const testing = std.testing;
const phase09 = @import("lib.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

test "Keys stored in sorted order" {
    const filename = "/tmp/test_sorted.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert in reverse order: 3, 2, 1
    const ids = [_]u32{ 3, 2, 1 };
    for (ids) |id| {
        var row = phase03.Row.init();
        row.id = id;
        row.setUsername("user");
        row.setEmail("user@test.com");

        const result = phase09.executeInsert(&row, &table);
        try testing.expectEqual(phase09.ExecuteResult.success, result);
    }

    // Verify keys are sorted
    const root = try table.pager.getPage(0);
    try testing.expectEqual(@as(u32, 3), phase08.leafNodeNumCells(root));
    try testing.expectEqual(@as(u32, 1), phase08.leafNodeKey(root, 0));
    try testing.expectEqual(@as(u32, 2), phase08.leafNodeKey(root, 1));
    try testing.expectEqual(@as(u32, 3), phase08.leafNodeKey(root, 2));
}

test "Duplicate key rejected" {
    const filename = "/tmp/test_duplicate.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    var row = phase03.Row.init();
    row.id = 1;
    row.setUsername("user1");
    row.setEmail("user1@test.com");

    // First insert succeeds
    try testing.expectEqual(phase09.ExecuteResult.success, phase09.executeInsert(&row, &table));

    // Duplicate insert fails
    try testing.expectEqual(phase09.ExecuteResult.duplicate_key, phase09.executeInsert(&row, &table));

    // Verify only one row
    const root = try table.pager.getPage(0);
    try testing.expectEqual(@as(u32, 1), phase08.leafNodeNumCells(root));
}

test "Table full when leaf is full" {
    const filename = "/tmp/test_full.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Fill the leaf node
    var i: u32 = 1;
    while (i <= phase08.LEAF_NODE_MAX_CELLS) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");

        const result = phase09.executeInsert(&row, &table);
        try testing.expectEqual(phase09.ExecuteResult.success, result);
    }

    // Next insert should fail
    var extra = phase03.Row.init();
    extra.id = 999;
    try testing.expectEqual(phase09.ExecuteResult.table_full, phase09.executeInsert(&extra, &table));
}
