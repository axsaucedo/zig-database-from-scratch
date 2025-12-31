const std = @import("std");
const testing = std.testing;
const phase10 = @import("lib.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

test "Basic insert without split" {
    const filename = "/tmp/test_nosplit.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    var row = phase03.Row.init();
    row.id = 1;
    row.setUsername("user");
    row.setEmail("user@test.com");

    const result = phase10.executeInsert(&row, &table);
    try testing.expectEqual(phase10.ExecuteResult.success, result);

    const root = try table.pager.getPage(0);
    try testing.expectEqual(@as(u32, 1), phase08.leafNodeNumCells(root));
}

test "Multiple inserts in sorted order" {
    const filename = "/tmp/test_sorted2.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 5 rows in reverse order
    var i: u32 = 5;
    while (i > 0) : (i -= 1) {
        var row = phase03.Row.init();
        row.id = i;
        row.setUsername("user");
        row.setEmail("user@test.com");
        _ = phase10.executeInsert(&row, &table);
    }

    // Verify sorted order
    const root = try table.pager.getPage(0);
    try testing.expectEqual(@as(u32, 5), phase08.leafNodeNumCells(root));

    i = 0;
    while (i < 5) : (i += 1) {
        try testing.expectEqual(i + 1, phase08.leafNodeKey(root, i));
    }
}

test "Duplicate key rejected" {
    const filename = "/tmp/test_dup2.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase08.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    var row = phase03.Row.init();
    row.id = 1;
    row.setUsername("user");
    row.setEmail("user@test.com");

    try testing.expectEqual(phase10.ExecuteResult.success, phase10.executeInsert(&row, &table));
    try testing.expectEqual(phase10.ExecuteResult.duplicate_key, phase10.executeInsert(&row, &table));
}
