//! Phase 09: Binary Search and Duplicate Keys
//!
//! This phase adds:
//! - Binary search for key lookup
//! - Sorted insertion (keys stored in order)
//! - Duplicate key detection and rejection

const std = @import("std");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

// Re-export from phase08
pub const btree = phase08.btree;
pub const Pager = phase08.Pager;
pub const Table = phase08.Table;
pub const Cursor = phase08.Cursor;
pub const PAGE_SIZE = phase08.PAGE_SIZE;
pub const LEAF_NODE_MAX_CELLS = phase08.LEAF_NODE_MAX_CELLS;

pub const ExecuteResult = enum {
    success,
    duplicate_key,
    table_full,
};

/// Insert a key/value into a leaf node at cursor position
pub fn leafNodeInsert(c: *phase08.Cursor, key: u32, row: *const phase03.Row) !void {
    const node = try c.table.pager.getPage(c.page_num);
    const num_cells = phase08.leafNodeNumCells(node);

    if (num_cells >= LEAF_NODE_MAX_CELLS) {
        return error.NodeFull;
    }

    // Shift cells to make room
    if (c.cell_num < num_cells) {
        var i = num_cells;
        while (i > c.cell_num) : (i -= 1) {
            const src = phase08.leafNodeCell(node, i - 1);
            const dst = phase08.leafNodeCell(node, i);
            @memcpy(dst, src);
        }
    }

    phase08.setLeafNodeNumCells(node, num_cells + 1);
    phase08.setLeafNodeKey(node, c.cell_num, key);
    phase03.serializeRow(row, phase08.leafNodeValue(node, c.cell_num));
}

/// Execute an insert with duplicate key checking
pub fn executeInsert(row: *const phase03.Row, table: *phase08.pager.Table) ExecuteResult {
    const node = table.pager.getPage(table.root_page_num) catch return .table_full;
    const num_cells = phase08.leafNodeNumCells(node);

    if (num_cells >= LEAF_NODE_MAX_CELLS) {
        return .table_full;
    }

    const key = row.id;
    var cursor = phase08.Cursor.tableFind(table, key) catch return .table_full;

    // Check for duplicate key
    if (cursor.cell_num < num_cells) {
        const existing_key = phase08.leafNodeKey(node, cursor.cell_num);
        if (existing_key == key) {
            return .duplicate_key;
        }
    }

    leafNodeInsert(&cursor, key, row) catch return .table_full;
    return .success;
}
