//! Phase 05: Tests for Pager and Persistence

const std = @import("std");
const testing = std.testing;
const pager = @import("pager.zig");
const phase03 = @import("phase03");

test "Pager creates new file" {
    const filename = "/tmp/test_db_phase05_create.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var p = try pager.Pager.open(testing.allocator, filename);
    defer p.close();

    try testing.expectEqual(@as(u64, 0), p.file_length);
}

test "Pager getPage allocates on demand" {
    const filename = "/tmp/test_db_phase05_getpage.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var p = try pager.Pager.open(testing.allocator, filename);
    defer p.close();

    try testing.expect(p.pages[0] == null);
    _ = try p.getPage(0);
    try testing.expect(p.pages[0] != null);
}

test "Pager flush writes to file" {
    const filename = "/tmp/test_db_phase05_flush.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var p = try pager.Pager.open(testing.allocator, filename);

    const page = try p.getPage(0);
    page[0] = 0xDE;
    page[1] = 0xAD;
    page[2] = 0xBE;
    page[3] = 0xEF;

    try p.flush(0, 4);
    p.close();

    // Reopen and verify
    var p2 = try pager.Pager.open(testing.allocator, filename);
    defer p2.close();

    const page2 = try p2.getPage(0);
    try testing.expectEqual(@as(u8, 0xDE), page2[0]);
    try testing.expectEqual(@as(u8, 0xAD), page2[1]);
    try testing.expectEqual(@as(u8, 0xBE), page2[2]);
    try testing.expectEqual(@as(u8, 0xEF), page2[3]);
}

test "Table persists rows across sessions" {
    const filename = "/tmp/test_db_phase05_persist.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    // Session 1: Insert a row
    {
        var table = try pager.Table.dbOpen(testing.allocator, filename);

        var row = phase03.Row.init();
        row.id = 1;
        row.setUsername("testuser");
        row.setEmail("test@example.com");

        const slot = try table.rowSlot(0);
        phase03.serializeRow(&row, slot);
        table.num_rows = 1;

        try table.dbClose();
    }

    // Session 2: Read the row back
    {
        var table = try pager.Table.dbOpen(testing.allocator, filename);
        defer table.dbClose() catch {};

        try testing.expectEqual(@as(u32, 1), table.num_rows);

        var row: phase03.Row = undefined;
        const slot = try table.rowSlot(0);
        phase03.deserializeRow(slot, &row);

        try testing.expectEqual(@as(u32, 1), row.id);
        try testing.expectEqualStrings("testuser", row.getUsernameSlice());
        try testing.expectEqualStrings("test@example.com", row.getEmailSlice());
    }
}

test "Table persists multiple rows" {
    const filename = "/tmp/test_db_phase05_multi.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    // Session 1: Insert multiple rows
    {
        var table = try pager.Table.dbOpen(testing.allocator, filename);

        var i: u32 = 0;
        while (i < 5) : (i += 1) {
            var row = phase03.Row.init();
            row.id = i + 1;
            row.setUsername("user");
            row.setEmail("user@test.com");

            const slot = try table.rowSlot(i);
            phase03.serializeRow(&row, slot);
        }
        table.num_rows = 5;

        try table.dbClose();
    }

    // Session 2: Read rows back
    {
        var table = try pager.Table.dbOpen(testing.allocator, filename);
        defer table.dbClose() catch {};

        try testing.expectEqual(@as(u32, 5), table.num_rows);

        var i: u32 = 0;
        while (i < 5) : (i += 1) {
            var row: phase03.Row = undefined;
            const slot = try table.rowSlot(i);
            phase03.deserializeRow(slot, &row);

            try testing.expectEqual(i + 1, row.id);
        }
    }
}
