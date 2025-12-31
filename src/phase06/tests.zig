const std = @import("std");
const testing = std.testing;
const cursor = @import("cursor.zig");
const phase05 = @import("phase05");
const phase03 = @import("phase03");

test "Cursor tableStart on empty table" {
    const filename = "/tmp/test_cursor_start.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase05.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    const c = cursor.Cursor.tableStart(&table);
    try testing.expectEqual(@as(u32, 0), c.row_num);
    try testing.expect(c.end_of_table);
}

test "Cursor tableEnd" {
    const filename = "/tmp/test_cursor_end.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase05.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert a row
    var row = phase03.Row.init();
    row.id = 1;
    row.setUsername("test");
    row.setEmail("test@test.com");
    const slot = try table.rowSlot(0);
    phase03.serializeRow(&row, slot);
    table.num_rows = 1;

    const c = cursor.Cursor.tableEnd(&table);
    try testing.expectEqual(@as(u32, 1), c.row_num);
    try testing.expect(c.end_of_table);
}

test "Cursor advance" {
    const filename = "/tmp/test_cursor_advance.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try phase05.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert 3 rows
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        var row = phase03.Row.init();
        row.id = i;
        const slot = try table.rowSlot(i);
        phase03.serializeRow(&row, slot);
    }
    table.num_rows = 3;

    var c = cursor.Cursor.tableStart(&table);
    try testing.expectEqual(@as(u32, 0), c.row_num);
    try testing.expect(!c.end_of_table);

    c.advance();
    try testing.expectEqual(@as(u32, 1), c.row_num);
    try testing.expect(!c.end_of_table);

    c.advance();
    try testing.expectEqual(@as(u32, 2), c.row_num);
    try testing.expect(!c.end_of_table);

    c.advance();
    try testing.expectEqual(@as(u32, 3), c.row_num);
    try testing.expect(c.end_of_table);
}
