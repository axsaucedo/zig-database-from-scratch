//! Phase 13: Updating Parent Node After a Split
//!
//! When a leaf node splits and it's not the root, we need to:
//! 1. Update the first key in the parent to reflect the new max of the left child
//! 2. Add a new child pointer/key pair for the new node
//!
//! This phase implements internal_node_insert() and update_internal_node_key().

const std = @import("std");
const phase08 = @import("phase08");
const phase10 = @import("phase10");
const phase11 = @import("phase11");
const phase12 = @import("phase12");
const phase03 = @import("phase03");

pub const btree = phase08.btree;
pub const pager = phase08.pager;
pub const split = phase10.split;

// Re-export from previous phases
pub const Pager = phase08.Pager;
pub const Table = phase08.Table;
pub const Cursor = phase12.Cursor;
pub const PAGE_SIZE = phase08.PAGE_SIZE;
pub const LEAF_NODE_MAX_CELLS = phase08.LEAF_NODE_MAX_CELLS;
pub const getNodeType = phase08.getNodeType;
pub const leafNodeNumCells = phase08.leafNodeNumCells;
pub const leafNodeKey = phase08.leafNodeKey;
pub const leafNodeNextLeaf = btree.leafNodeNextLeaf;
pub const tableFind = phase11.tableFind;
pub const printTree = phase11.printTree;
pub const executeSelect = phase12.executeSelect;
pub const ExecuteResult = phase11.ExecuteResult;

// Internal node functions
pub const getInternalNodeNumKeys = split.getInternalNodeNumKeys;
pub const setInternalNodeNumKeys = split.setInternalNodeNumKeys;
pub const getInternalNodeChild = split.getInternalNodeChild;
pub const setInternalNodeChild = split.setInternalNodeChild;
pub const getInternalNodeKey = split.getInternalNodeKey;
pub const setInternalNodeKey = split.setInternalNodeKey;
pub const getInternalNodeRightChild = split.getInternalNodeRightChild;
pub const setInternalNodeRightChild = split.setInternalNodeRightChild;
pub const initializeInternalNode = split.initializeInternalNode;
pub const internalNodeFindChild = phase11.internalNodeFindChild;

// Keep INTERNAL_NODE_MAX_CELLS small for testing (as in the original tutorial)
pub const INTERNAL_NODE_MAX_CELLS: u32 = 3;

/// Get maximum key in a node (works for both leaf and internal nodes)
pub fn getNodeMaxKey(table_pager: *pager.Pager, node: []u8) u32 {
    if (getNodeType(node) == .leaf) {
        const num_cells = leafNodeNumCells(node);
        return leafNodeKey(node, num_cells - 1);
    }
    // For internal node, recursively find max in rightmost child
    const right_child_page = getInternalNodeRightChild(node);
    const right_child = table_pager.getPage(right_child_page) catch return 0;
    return getNodeMaxKey(table_pager, right_child);
}

/// Update the key for a child in an internal node
pub fn updateInternalNodeKey(node: []u8, old_key: u32, new_key: u32) void {
    const old_child_index = internalNodeFindChild(node, old_key);
    setInternalNodeKey(node, old_child_index, new_key);
}

/// Insert a new child/key pair into a parent internal node
pub fn internalNodeInsert(table: *pager.Table, parent_page_num: u32, child_page_num: u32) !void {
    const parent = try table.pager.getPage(parent_page_num);
    const child = try table.pager.getPage(child_page_num);
    const child_max_key = getNodeMaxKey(table.pager, child);
    const index = internalNodeFindChild(parent, child_max_key);

    const original_num_keys = getInternalNodeNumKeys(parent);

    if (original_num_keys >= INTERNAL_NODE_MAX_CELLS) {
        // Need to split internal node - implement in phase 14
        return error.NeedToSplitInternalNode;
    }

    const right_child_page_num = getInternalNodeRightChild(parent);
    const right_child = try table.pager.getPage(right_child_page_num);

    if (child_max_key > getNodeMaxKey(table.pager, right_child)) {
        // Replace right child - new child becomes rightmost
        setInternalNodeChild(parent, original_num_keys, right_child_page_num);
        setInternalNodeKey(parent, original_num_keys, getNodeMaxKey(table.pager, right_child));
        setInternalNodeRightChild(parent, child_page_num);
    } else {
        // Make room for the new cell by shifting
        var i = original_num_keys;
        while (i > index) : (i -= 1) {
            const src_child = getInternalNodeChild(parent, i - 1);
            const src_key = getInternalNodeKey(parent, i - 1);
            setInternalNodeChild(parent, i, src_child);
            setInternalNodeKey(parent, i, src_key);
        }
        setInternalNodeChild(parent, index, child_page_num);
        setInternalNodeKey(parent, index, child_max_key);
    }

    setInternalNodeNumKeys(parent, original_num_keys + 1);
}

/// Leaf node split that updates parent when not root
pub fn leafNodeSplitAndInsert(
    table: *pager.Table,
    page_num: u32,
    cell_num: u32,
    key: u32,
    row: *const phase03.Row,
) !void {
    const old_node = try table.pager.getPage(page_num);
    const old_max = getNodeMaxKey(table.pager, old_node);
    const new_page_num = table.pager.getUnusedPageNum();
    const new_node = try table.pager.getPage(new_page_num);

    btree.initializeLeafNode(new_node);
    
    // Copy parent pointer to new node
    btree.setParentPointer(new_node, btree.getParentPointer(old_node));
    
    // Update sibling pointers
    btree.setLeafNodeNextLeaf(new_node, btree.leafNodeNextLeaf(old_node));
    btree.setLeafNodeNextLeaf(old_node, new_page_num);

    const left_count: u32 = @intCast(btree.LEAF_NODE_LEFT_SPLIT_COUNT);
    const right_count: u32 = @intCast(btree.LEAF_NODE_RIGHT_SPLIT_COUNT);
    const total: u32 = @intCast(btree.LEAF_NODE_MAX_CELLS + 1);

    // Redistribute cells
    var i: u32 = total;
    while (i > 0) {
        i -= 1;
        const dest_node = if (i >= left_count) new_node else old_node;
        const dest_idx: u32 = if (i >= left_count) i - left_count else i;

        if (i == cell_num) {
            btree.setLeafNodeKey(dest_node, dest_idx, key);
            phase03.serializeRow(row, btree.leafNodeValue(dest_node, dest_idx));
        } else {
            const src_idx: u32 = if (i > cell_num) i - 1 else i;
            const src = btree.leafNodeCell(old_node, src_idx);
            const dst = btree.leafNodeCell(dest_node, dest_idx);
            // Use copyBackwards to handle overlapping regions safely
            if (dest_node.ptr == old_node.ptr) {
                std.mem.copyBackwards(u8, dst, src);
            } else {
                @memcpy(dst, src);
            }
        }
    }

    btree.setLeafNodeNumCells(old_node, left_count);
    btree.setLeafNodeNumCells(new_node, right_count);

    if (btree.isNodeRoot(old_node)) {
        try createNewRoot(table, new_page_num);
    } else {
        // Update parent after split
        const parent_page_num = btree.getParentPointer(old_node);
        const new_max = getNodeMaxKey(table.pager, old_node);
        const parent = try table.pager.getPage(parent_page_num);

        updateInternalNodeKey(parent, old_max, new_max);
        try internalNodeInsert(table, parent_page_num, new_page_num);
    }
}

fn createNewRoot(table: *pager.Table, right_child_page_num: u32) !void {
    const root = try table.pager.getPage(table.root_page_num);
    const left_child_page_num = table.pager.getUnusedPageNum();
    const left_child = try table.pager.getPage(left_child_page_num);

    @memcpy(left_child, root);
    btree.setNodeRoot(left_child, false);

    initializeInternalNode(root);
    btree.setNodeRoot(root, true);
    setInternalNodeNumKeys(root, 1);
    setInternalNodeChild(root, 0, left_child_page_num);

    const left_max = getNodeMaxKey(table.pager, left_child);
    setInternalNodeKey(root, 0, left_max);
    setInternalNodeRightChild(root, right_child_page_num);

    btree.setParentPointer(left_child, table.root_page_num);

    const right_child = try table.pager.getPage(right_child_page_num);
    btree.setParentPointer(right_child, table.root_page_num);
}

/// Insert with automatic splitting and parent updates
pub fn leafNodeInsert(table: *pager.Table, page_num: u32, cell_num: u32, key: u32, row: *const phase03.Row) !void {
    const node = try table.pager.getPage(page_num);
    const num_cells = leafNodeNumCells(node);

    if (num_cells >= LEAF_NODE_MAX_CELLS) {
        try leafNodeSplitAndInsert(table, page_num, cell_num, key, row);
        return;
    }

    // Make room
    if (cell_num < num_cells) {
        var i = num_cells;
        while (i > cell_num) : (i -= 1) {
            const src = btree.leafNodeCell(node, i - 1);
            const dst = btree.leafNodeCell(node, i);
            @memcpy(dst, src);
        }
    }

    btree.setLeafNodeNumCells(node, num_cells + 1);
    btree.setLeafNodeKey(node, cell_num, key);
    phase03.serializeRow(row, btree.leafNodeValue(node, cell_num));
}

/// Execute insert with parent update support
pub fn executeInsert(row: *const phase03.Row, table: *pager.Table) ExecuteResult {
    const key = row.id;

    const cursor = tableFind(table, key) catch return .duplicate_key;

    const node = table.pager.getPage(cursor.page_num) catch return .duplicate_key;
    const num_cells = leafNodeNumCells(node);
    if (cursor.cell_num < num_cells) {
        const existing_key = leafNodeKey(node, cursor.cell_num);
        if (existing_key == key) {
            return .duplicate_key;
        }
    }

    leafNodeInsert(table, cursor.page_num, cursor.cell_num, key, row) catch return .duplicate_key;
    return .success;
}
