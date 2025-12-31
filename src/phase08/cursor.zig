//! Phase 08: Cursor for B-Tree
//!
//! Cursor now uses page_num and cell_num instead of row_num.

const std = @import("std");
const btree = @import("btree.zig");
const pager = @import("pager.zig");

pub const Cursor = struct {
    table: *pager.Table,
    page_num: u32,
    cell_num: u32,
    end_of_table: bool,

    const Self = @This();

    /// Create cursor at start of table
    pub fn tableStart(table: *pager.Table) !Self {
        const root_node = try table.pager.getPage(table.root_page_num);
        const num_cells = btree.leafNodeNumCells(root_node);

        return Self{
            .table = table,
            .page_num = table.root_page_num,
            .cell_num = 0,
            .end_of_table = num_cells == 0,
        };
    }

    /// Binary search for key in leaf node
    pub fn leafNodeFind(table: *pager.Table, page_num: u32, key: u32) !Self {
        const node = try table.pager.getPage(page_num);
        const num_cells = btree.leafNodeNumCells(node);

        var min_index: u32 = 0;
        var one_past_max: u32 = num_cells;

        while (one_past_max != min_index) {
            const index = (min_index + one_past_max) / 2;
            const key_at_index = btree.leafNodeKey(node, index);

            if (key == key_at_index) {
                return Self{
                    .table = table,
                    .page_num = page_num,
                    .cell_num = index,
                    .end_of_table = false,
                };
            }
            if (key < key_at_index) {
                one_past_max = index;
            } else {
                min_index = index + 1;
            }
        }

        return Self{
            .table = table,
            .page_num = page_num,
            .cell_num = min_index,
            .end_of_table = false,
        };
    }

    /// Find position for key (binary search)
    pub fn tableFind(table: *pager.Table, key: u32) !Self {
        const root_node = try table.pager.getPage(table.root_page_num);
        const node_type = btree.getNodeType(root_node);

        if (node_type == .leaf) {
            return leafNodeFind(table, table.root_page_num, key);
        } else {
            // TODO: Implement internal node search
            return error.NotImplemented;
        }
    }

    /// Get value at cursor position
    pub fn value(self: *Self) ![]u8 {
        const page = try self.table.pager.getPage(self.page_num);
        return btree.leafNodeValue(page, self.cell_num);
    }

    /// Advance cursor to next cell
    pub fn advance(self: *Self) !void {
        const page = try self.table.pager.getPage(self.page_num);
        self.cell_num += 1;

        if (self.cell_num >= btree.leafNodeNumCells(page)) {
            // Check for next leaf
            const next_page_num = btree.leafNodeNextLeaf(page);
            if (next_page_num == 0) {
                self.end_of_table = true;
            } else {
                self.page_num = next_page_num;
                self.cell_num = 0;
            }
        }
    }
};
