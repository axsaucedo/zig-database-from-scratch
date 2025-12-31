//! Phase 10: Splitting a Leaf Node
//!
//! Exports splitting functionality and internal node operations.

pub const split = @import("split.zig");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

// Re-export from phase08
pub const btree = phase08.btree;
pub const Pager = phase08.Pager;
pub const Table = phase08.Table;
pub const Cursor = phase08.Cursor;
pub const PAGE_SIZE = phase08.PAGE_SIZE;
pub const LEAF_NODE_MAX_CELLS = phase08.LEAF_NODE_MAX_CELLS;

// Re-export splitting
pub const leafNodeSplitAndInsert = split.leafNodeSplitAndInsert;
pub const initializeInternalNode = split.initializeInternalNode;
pub const getInternalNodeNumKeys = split.getInternalNodeNumKeys;
pub const getInternalNodeChild = split.getInternalNodeChild;
pub const getInternalNodeKey = split.getInternalNodeKey;
pub const getMaxKey = split.getMaxKey;

pub const ExecuteResult = enum { success, duplicate_key };

/// Insert with automatic splitting
pub fn leafNodeInsert(table: *phase08.pager.Table, page_num: u32, cell_num: u32, key: u32, row: *const phase03.Row) !void {
    const node = try table.pager.getPage(page_num);
    const num_cells = phase08.leafNodeNumCells(node);

    if (num_cells >= LEAF_NODE_MAX_CELLS) {
        // Need to split
        try split.leafNodeSplitAndInsert(table, page_num, cell_num, key, row);
        return;
    }

    // Make room
    if (cell_num < num_cells) {
        var i = num_cells;
        while (i > cell_num) : (i -= 1) {
            const src = phase08.leafNodeCell(node, i - 1);
            const dst = phase08.leafNodeCell(node, i);
            @memcpy(dst, src);
        }
    }

    phase08.setLeafNodeNumCells(node, num_cells + 1);
    phase08.setLeafNodeKey(node, cell_num, key);
    phase03.serializeRow(row, phase08.leafNodeValue(node, cell_num));
}

/// Execute insert with splitting support
pub fn executeInsert(row: *const phase03.Row, table: *phase08.pager.Table) ExecuteResult {
    const root = table.pager.getPage(table.root_page_num) catch return .duplicate_key;
    const key = row.id;

    // Find where to insert
    const cursor = findLeafNode(table, table.root_page_num, key) catch return .duplicate_key;

    // Check for duplicate
    const node = table.pager.getPage(cursor.page_num) catch return .duplicate_key;
    const num_cells = phase08.leafNodeNumCells(node);
    if (cursor.cell_num < num_cells) {
        const existing_key = phase08.leafNodeKey(node, cursor.cell_num);
        if (existing_key == key) {
            return .duplicate_key;
        }
    }
    _ = root;

    leafNodeInsert(table, cursor.page_num, cursor.cell_num, key, row) catch return .duplicate_key;
    return .success;
}

/// Find the leaf node containing the key
pub fn findLeafNode(table: *phase08.pager.Table, page_num: u32, key: u32) !phase08.Cursor {
    const node = try table.pager.getPage(page_num);
    const node_type = phase08.getNodeType(node);

    if (node_type == .leaf) {
        return phase08.Cursor.leafNodeFind(table, page_num, key);
    }

    // Internal node - find correct child
    const num_keys = split.getInternalNodeNumKeys(node);
    var min_index: u32 = 0;
    var max_index: u32 = num_keys;

    while (min_index != max_index) {
        const index = (min_index + max_index) / 2;
        const key_to_right = split.getInternalNodeKey(node, index);
        if (key_to_right >= key) {
            max_index = index;
        } else {
            min_index = index + 1;
        }
    }

    const child_page_num = split.getInternalNodeChild(node, min_index);
    return findLeafNode(table, child_page_num, key);
}
