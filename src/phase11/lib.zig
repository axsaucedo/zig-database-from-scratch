//! Phase 11: Recursively Searching the B-Tree
//!
//! Implements internal node searching with binary search.
//! When finding a key, we now recursively descend through internal nodes.

const std = @import("std");
const phase08 = @import("phase08");
const phase10 = @import("phase10");
const phase03 = @import("phase03");

pub const btree = phase08.btree;
pub const pager = phase08.pager;
pub const split = phase10.split;

// Re-export from phase08 and phase10
pub const Pager = phase08.Pager;
pub const Table = phase08.Table;
pub const Cursor = phase08.Cursor;
pub const PAGE_SIZE = phase08.PAGE_SIZE;
pub const LEAF_NODE_MAX_CELLS = phase08.LEAF_NODE_MAX_CELLS;
pub const getNodeType = phase08.getNodeType;
pub const leafNodeNumCells = phase08.leafNodeNumCells;
pub const leafNodeKey = phase08.leafNodeKey;

// Re-export from phase10
pub const getInternalNodeNumKeys = split.getInternalNodeNumKeys;
pub const getInternalNodeChild = split.getInternalNodeChild;
pub const getInternalNodeKey = split.getInternalNodeKey;
pub const getInternalNodeRightChild = split.getInternalNodeRightChild;
pub const initializeInternalNode = split.initializeInternalNode;
pub const getMaxKey = split.getMaxKey;

pub const ExecuteResult = enum { success, duplicate_key };

/// Binary search to find child index in internal node
pub fn internalNodeFindChild(node: []u8, key: u32) u32 {
    const num_keys = getInternalNodeNumKeys(node);

    // Binary search to find index of child to search
    var min_index: u32 = 0;
    var max_index: u32 = num_keys; // there is one more child than key

    while (min_index != max_index) {
        const index = (min_index + max_index) / 2;
        const key_to_right = getInternalNodeKey(node, index);
        if (key_to_right >= key) {
            max_index = index;
        } else {
            min_index = index + 1;
        }
    }

    return min_index;
}

/// Find the leaf node containing the key by recursively searching internal nodes
pub fn internalNodeFind(table: *pager.Table, page_num: u32, key: u32) !Cursor {
    const node = try table.pager.getPage(page_num);
    const child_index = internalNodeFindChild(node, key);
    const child_page_num = getInternalNodeChild(node, child_index);
    const child = try table.pager.getPage(child_page_num);

    switch (getNodeType(child)) {
        .leaf => return Cursor.leafNodeFind(table, child_page_num, key),
        .internal => return internalNodeFind(table, child_page_num, key),
    }
}

/// Table find - works with both leaf and internal root nodes
pub fn tableFind(table: *pager.Table, key: u32) !Cursor {
    const root = try table.pager.getPage(table.root_page_num);
    
    if (getNodeType(root) == .leaf) {
        return Cursor.leafNodeFind(table, table.root_page_num, key);
    } else {
        return internalNodeFind(table, table.root_page_num, key);
    }
}

/// Execute insert with internal node searching
pub fn executeInsert(row: *const phase03.Row, table: *pager.Table) ExecuteResult {
    const key = row.id;

    // Find where to insert (now supports internal nodes)
    const cursor = tableFind(table, key) catch return .duplicate_key;

    // Check for duplicate
    const node = table.pager.getPage(cursor.page_num) catch return .duplicate_key;
    const num_cells = leafNodeNumCells(node);
    if (cursor.cell_num < num_cells) {
        const existing_key = leafNodeKey(node, cursor.cell_num);
        if (existing_key == key) {
            return .duplicate_key;
        }
    }

    phase10.leafNodeInsert(table, cursor.page_num, cursor.cell_num, key, row) catch return .duplicate_key;
    return .success;
}

/// Print tree recursively (for .btree command)
pub fn printTree(table: *pager.Table, page_num: u32, indent: u32) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    const node = try table.pager.getPage(page_num);
    const node_type = getNodeType(node);

    var i: u32 = 0;
    while (i < indent) : (i += 1) try stdout.print("  ", .{});

    switch (node_type) {
        .leaf => {
            const num_cells = leafNodeNumCells(node);
            try stdout.print("- leaf (size {d})\n", .{num_cells});
            i = 0;
            while (i < num_cells) : (i += 1) {
                var j: u32 = 0;
                while (j < indent + 1) : (j += 1) try stdout.print("  ", .{});
                try stdout.print("- {d}\n", .{leafNodeKey(node, i)});
            }
        },
        .internal => {
            const num_keys = getInternalNodeNumKeys(node);
            try stdout.print("- internal (size {d})\n", .{num_keys});
            i = 0;
            while (i < num_keys) : (i += 1) {
                const child = getInternalNodeChild(node, i);
                try printTree(table, child, indent + 1);
                var j: u32 = 0;
                while (j < indent + 1) : (j += 1) try stdout.print("  ", .{});
                try stdout.print("- key {d}\n", .{getInternalNodeKey(node, i)});
            }
            const right_child = getInternalNodeRightChild(node);
            try printTree(table, right_child, indent + 1);
        },
    }
}
