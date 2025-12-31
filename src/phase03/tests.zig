const std = @import("std");
const testing = std.testing;
const row = @import("row.zig");
const table = @import("table.zig");

test "Row serialize roundtrip" {
    var r = row.Row.init();
    r.id = 42;
    r.setUsername("test");
    r.setEmail("test@test.com");

    var buf: [row.ROW_SIZE]u8 = undefined;
    row.serializeRow(&r, &buf);

    var r2: row.Row = undefined;
    row.deserializeRow(&buf, &r2);

    try testing.expectEqual(@as(u32, 42), r2.id);
    try testing.expectEqualStrings("test", r2.getUsernameSlice());
}

test "Table rowSlot" {
    var t = table.Table.init(testing.allocator);
    defer t.deinit();
    _ = try t.rowSlot(0);
    try testing.expect(t.pages[0] != null);
}
