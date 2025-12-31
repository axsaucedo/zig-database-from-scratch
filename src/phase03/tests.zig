//! Phase 03: Unit Tests for Row and Table Modules

const std = @import("std");
const testing = std.testing;
const row = @import("row.zig");
const table = @import("table.zig");

// Row tests
test "Row init creates zeroed row" {
    const r = row.Row.init();
    try testing.expectEqual(@as(u32, 0), r.id);
    try testing.expectEqual(@as(usize, 0), r.getUsernameSlice().len);
    try testing.expectEqual(@as(usize, 0), r.getEmailSlice().len);
}

test "Row setUsername sets correctly" {
    var r = row.Row.init();
    r.setUsername("testuser");
    try testing.expectEqualStrings("testuser", r.getUsernameSlice());
}

test "Row setEmail sets correctly" {
    var r = row.Row.init();
    r.setEmail("test@example.com");
    try testing.expectEqualStrings("test@example.com", r.getEmailSlice());
}

test "Row setUsername truncates long strings" {
    var r = row.Row.init();
    const long_name = "a" ** 50; // 50 chars, limit is 32
    r.setUsername(long_name);
    try testing.expectEqual(@as(usize, row.COLUMN_USERNAME_SIZE), r.getUsernameSlice().len);
}

test "serializeRow and deserializeRow roundtrip" {
    var original = row.Row.init();
    original.id = 42;
    original.setUsername("testuser");
    original.setEmail("test@example.com");

    var buffer: [row.ROW_SIZE]u8 = undefined;
    row.serializeRow(&original, &buffer);

    var restored: row.Row = undefined;
    row.deserializeRow(&buffer, &restored);

    try testing.expectEqual(@as(u32, 42), restored.id);
    try testing.expectEqualStrings("testuser", restored.getUsernameSlice());
    try testing.expectEqualStrings("test@example.com", restored.getEmailSlice());
}

// Table tests
test "Table init creates empty table" {
    var t = table.Table.init(testing.allocator);
    defer t.deinit();

    try testing.expectEqual(@as(u32, 0), t.num_rows);
    try testing.expect(!t.isFull());
}

test "Table rowSlot allocates page on demand" {
    var t = table.Table.init(testing.allocator);
    defer t.deinit();

    // First access should allocate page 0
    try testing.expect(t.pages[0] == null);
    _ = try t.rowSlot(0);
    try testing.expect(t.pages[0] != null);
}

test "Table rowSlot returns correct slot for different rows" {
    var t = table.Table.init(testing.allocator);
    defer t.deinit();

    const slot0 = try t.rowSlot(0);
    const slot1 = try t.rowSlot(1);

    // Slots should be different addresses
    try testing.expect(slot0.ptr != slot1.ptr);

    // Slot size should be ROW_SIZE
    try testing.expectEqual(@as(usize, row.ROW_SIZE), slot0.len);
}

test "Table insert and retrieve row" {
    var t = table.Table.init(testing.allocator);
    defer t.deinit();

    // Insert row
    var r = row.Row.init();
    r.id = 1;
    r.setUsername("user1");
    r.setEmail("user1@example.com");

    const slot = try t.rowSlot(0);
    row.serializeRow(&r, slot);
    t.num_rows = 1;

    // Retrieve row
    var retrieved: row.Row = undefined;
    const read_slot = try t.rowSlot(0);
    row.deserializeRow(read_slot, &retrieved);

    try testing.expectEqual(@as(u32, 1), retrieved.id);
    try testing.expectEqualStrings("user1", retrieved.getUsernameSlice());
}
