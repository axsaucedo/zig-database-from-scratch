//! Phase 08: B-Tree Tests

const std = @import("std");
const testing = std.testing;
const btree = @import("btree.zig");
const pager = @import("pager.zig");
const cursor = @import("cursor.zig");
const phase03 = @import("phase03");

test "Leaf node constants" {
    // Verify calculated constants
    try testing.expect(btree.LEAF_NODE_MAX_CELLS > 0);
    try testing.expect(btree.LEAF_NODE_MAX_CELLS < 20); // Should be around 13
    try testing.expectEqual(@as(usize, 6), btree.COMMON_NODE_HEADER_SIZE);
}

test "Initialize leaf node" {
    var node: [btree.PAGE_SIZE]u8 = undefined;
    @memset(&node, 0);

    btree.initializeLeafNode(&node);

    try testing.expectEqual(btree.NodeType.leaf, btree.getNodeType(&node));
    try testing.expectEqual(@as(u32, 0), btree.leafNodeNumCells(&node));
    try testing.expect(!btree.isNodeRoot(&node));
}

test "Leaf node key/value operations" {
    var node: [btree.PAGE_SIZE]u8 = undefined;
    @memset(&node, 0);
    btree.initializeLeafNode(&node);

    // Set a key
    btree.setLeafNodeKey(&node, 0, 42);
    btree.setLeafNodeNumCells(&node, 1);

    try testing.expectEqual(@as(u32, 42), btree.leafNodeKey(&node, 0));
    try testing.expectEqual(@as(u32, 1), btree.leafNodeNumCells(&node));
}

test "Table with B-Tree creates root node" {
    const filename = "/tmp/test_btree_table.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try pager.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Root node should be initialized
    const root = try table.pager.getPage(0);
    try testing.expectEqual(btree.NodeType.leaf, btree.getNodeType(root));
    try testing.expect(btree.isNodeRoot(root));
}

test "Cursor binary search" {
    const filename = "/tmp/test_btree_cursor.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    var table = try pager.Table.dbOpen(testing.allocator, filename);
    defer table.dbClose() catch {};

    // Insert some keys manually
    const root = try table.pager.getPage(0);
    btree.setLeafNodeKey(root, 0, 10);
    btree.setLeafNodeKey(root, 1, 20);
    btree.setLeafNodeKey(root, 2, 30);
    btree.setLeafNodeNumCells(root, 3);

    // Find existing key
    const c1 = try cursor.Cursor.tableFind(&table, 20);
    try testing.expectEqual(@as(u32, 1), c1.cell_num);

    // Find insertion point for new key
    const c2 = try cursor.Cursor.tableFind(&table, 15);
    try testing.expectEqual(@as(u32, 1), c2.cell_num); // Would insert at position 1

    // Find insertion point at end
    const c3 = try cursor.Cursor.tableFind(&table, 40);
    try testing.expectEqual(@as(u32, 3), c3.cell_num);
}

test "Persistence with B-Tree format" {
    const filename = "/tmp/test_btree_persist.db";
    defer std.fs.cwd().deleteFile(filename) catch {};

    // Session 1: Insert
    {
        var table = try pager.Table.dbOpen(testing.allocator, filename);
        const root = try table.pager.getPage(0);

        var row = phase03.Row.init();
        row.id = 1;
        row.setUsername("alice");
        row.setEmail("alice@test.com");

        btree.setLeafNodeKey(root, 0, row.id);
        phase03.serializeRow(&row, btree.leafNodeValue(root, 0));
        btree.setLeafNodeNumCells(root, 1);

        try table.dbClose();
    }

    // Session 2: Read
    {
        var table = try pager.Table.dbOpen(testing.allocator, filename);
        defer table.dbClose() catch {};

        const root = try table.pager.getPage(0);
        try testing.expectEqual(@as(u32, 1), btree.leafNodeNumCells(root));
        try testing.expectEqual(@as(u32, 1), btree.leafNodeKey(root, 0));

        var row: phase03.Row = undefined;
        phase03.deserializeRow(btree.leafNodeValue(root, 0), &row);
        try testing.expectEqualStrings("alice", row.getUsernameSlice());
    }
}
