//! Phase 12: Scanning a Multi-Level B-Tree
//!
//! Fixes the select statement to work with multi-level B-Trees.
//! The key insight is that table_start() must find the leftmost leaf node,
//! and cursor_advance() must follow next_leaf pointers between siblings.

const std = @import("std");
const phase08 = @import("phase08");
const phase10 = @import("phase10");
const phase11 = @import("phase11");
const phase03 = @import("phase03");

pub const btree = phase08.btree;
pub const pager = phase08.pager;
pub const split = phase10.split;

// Re-export from previous phases
pub const Pager = phase08.Pager;
pub const Table = phase08.Table;
pub const PAGE_SIZE = phase08.PAGE_SIZE;
pub const LEAF_NODE_MAX_CELLS = phase08.LEAF_NODE_MAX_CELLS;
pub const getNodeType = phase08.getNodeType;
pub const leafNodeNumCells = phase08.leafNodeNumCells;
pub const leafNodeKey = phase08.leafNodeKey;
pub const leafNodeNextLeaf = btree.leafNodeNextLeaf;

// Re-export from phase11
pub const tableFind = phase11.tableFind;
pub const executeInsert = phase11.executeInsert;
pub const printTree = phase11.printTree;
pub const internalNodeFindChild = phase11.internalNodeFindChild;
pub const ExecuteResult = phase11.ExecuteResult;

// Re-export internal node functions
pub const getInternalNodeNumKeys = split.getInternalNodeNumKeys;
pub const getInternalNodeChild = split.getInternalNodeChild;
pub const getInternalNodeKey = split.getInternalNodeKey;
pub const getInternalNodeRightChild = split.getInternalNodeRightChild;

/// Cursor that properly traverses multi-level B-Tree
pub const Cursor = struct {
    table: *pager.Table,
    page_num: u32,
    cell_num: u32,
    end_of_table: bool,

    /// Start at the leftmost leaf node (key 0 position)
    /// This uses table_find to search for key 0, which will land us
    /// at the start of the leftmost leaf even if key 0 doesn't exist.
    pub fn tableStart(table: *pager.Table) !Cursor {
        // Find position where key 0 would be (leftmost position)
        var cursor = try tableFind(table, 0);
        
        // Check if this leaf is empty
        const node = try table.pager.getPage(cursor.page_num);
        const num_cells = leafNodeNumCells(node);
        cursor.end_of_table = (num_cells == 0);
        
        return Cursor{
            .table = cursor.table,
            .page_num = cursor.page_num,
            .cell_num = cursor.cell_num,
            .end_of_table = cursor.end_of_table,
        };
    }

    /// Get the value at current cursor position
    pub fn value(self: *Cursor) ![]u8 {
        const node = try self.table.pager.getPage(self.page_num);
        return btree.leafNodeValue(node, self.cell_num);
    }

    /// Advance cursor to next row
    /// Key change: when reaching end of a leaf, follow next_leaf pointer
    /// to continue to sibling leaf node.
    pub fn advance(self: *Cursor) !void {
        const node = try self.table.pager.getPage(self.page_num);
        self.cell_num += 1;

        if (self.cell_num >= leafNodeNumCells(node)) {
            // Advance to next leaf node using next_leaf pointer
            const next_page_num = leafNodeNextLeaf(node);
            if (next_page_num == 0) {
                // This was the rightmost leaf - we're at end of table
                self.end_of_table = true;
            } else {
                // Move to sibling leaf
                self.page_num = next_page_num;
                self.cell_num = 0;
            }
        }
    }
};

/// Execute select by scanning all leaves using next_leaf pointers
pub fn executeSelect(table: *pager.Table, writer: anytype) !void {
    var cursor = try Cursor.tableStart(table);
    
    while (!cursor.end_of_table) {
        var row: phase03.Row = undefined;
        phase03.deserializeRow(try cursor.value(), &row);
        try writer.print("({d}, {s}, {s})\n", .{
            row.id,
            row.getUsernameSlice(),
            row.getEmailSlice(),
        });
        try cursor.advance();
    }
}
