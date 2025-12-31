//! Phase 14: Splitting Internal Nodes
//!
//! The final major piece of B-Tree implementation.
//! When an internal node is full, we split it:
//! 1. Create a sibling node to store (n-1)/2 keys
//! 2. Move keys from original to sibling
//! 3. Update parent key to reflect new max
//! 4. Insert sibling into parent (may cause recursive split)

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

// Constants for internal node splitting
pub const INTERNAL_NODE_MAX_CELLS: u32 = 3; // Keep small for testing

pub const INVALID_PAGE_NUM: u32 = std.math.maxInt(u32);

/// Get maximum key in a node (recursive for internal nodes)
pub fn getNodeMaxKey(table_pager: *pager.Pager, node: []u8) u32 {
    if (getNodeType(node) == .leaf) {
        const num_cells = leafNodeNumCells(node);
        if (num_cells == 0) return 0;
        return leafNodeKey(node, num_cells - 1);
    }
    // For internal node, recursively find max in rightmost child
    const right_child_page = getInternalNodeRightChild(node);
    if (right_child_page == INVALID_PAGE_NUM) return 0;
    const right_child = table_pager.getPage(right_child_page) catch return 0;
    return getNodeMaxKey(table_pager, right_child);
}

/// Update the key for a child in an internal node
pub fn updateInternalNodeKey(node: []u8, old_key: u32, new_key: u32) void {
    const old_child_index = internalNodeFindChild(node, old_key);
    setInternalNodeKey(node, old_child_index, new_key);
}

/// Initialize internal node with invalid right child
pub fn initializeInternalNodeEmpty(node: []u8) void {
    btree.setNodeType(node, .internal);
    btree.setNodeRoot(node, false);
    setInternalNodeNumKeys(node, 0);
    setInternalNodeRightChild(node, INVALID_PAGE_NUM);
}

/// Split an internal node and insert a child
pub fn internalNodeSplitAndInsert(table: *pager.Table, parent_page_num: u32, child_page_num: u32) anyerror!void {
    var old_page_num = parent_page_num;
    var old_node = try table.pager.getPage(parent_page_num);
    const old_max = getNodeMaxKey(table.pager, old_node);

    const child = try table.pager.getPage(child_page_num);
    const child_max = getNodeMaxKey(table.pager, child);

    const new_page_num = table.pager.getUnusedPageNum();

    // Check if we're splitting the root
    const splitting_root = btree.isNodeRoot(old_node);

    var parent: []u8 = undefined;
    var new_node: []u8 = undefined;

    if (splitting_root) {
        try createNewRoot(table, new_page_num);
        parent = try table.pager.getPage(table.root_page_num);
        // old_node is now the left child of new root
        old_page_num = getInternalNodeChild(parent, 0);
        old_node = try table.pager.getPage(old_page_num);
    } else {
        parent = try table.pager.getPage(btree.getParentPointer(old_node));
        new_node = try table.pager.getPage(new_page_num);
        initializeInternalNodeEmpty(new_node);
    }

    // Move right child to new node first
    var old_num_keys = getInternalNodeNumKeys(old_node);
    var cur_page_num = getInternalNodeRightChild(old_node);
    var cur = try table.pager.getPage(cur_page_num);

    // Insert right child into new node
    try internalNodeInsert(table, new_page_num, cur_page_num);
    btree.setParentPointer(cur, new_page_num);
    setInternalNodeRightChild(old_node, INVALID_PAGE_NUM);

    // Move upper half of keys to new node
    var i: i32 = @intCast(INTERNAL_NODE_MAX_CELLS - 1);
    const mid: i32 = @intCast(INTERNAL_NODE_MAX_CELLS / 2);
    while (i > mid) : (i -= 1) {
        const idx: u32 = @intCast(i);
        cur_page_num = getInternalNodeChild(old_node, idx);
        cur = try table.pager.getPage(cur_page_num);

        try internalNodeInsert(table, new_page_num, cur_page_num);
        btree.setParentPointer(cur, new_page_num);

        old_num_keys = getInternalNodeNumKeys(old_node);
        setInternalNodeNumKeys(old_node, old_num_keys - 1);
    }

    // Set the right child of old node to the child before middle key
    old_num_keys = getInternalNodeNumKeys(old_node);
    setInternalNodeRightChild(old_node, getInternalNodeChild(old_node, old_num_keys - 1));
    setInternalNodeNumKeys(old_node, old_num_keys - 1);

    // Determine where to insert the new child
    const max_after_split = getNodeMaxKey(table.pager, old_node);
    const dest_page_num = if (child_max < max_after_split) old_page_num else new_page_num;

    try internalNodeInsert(table, dest_page_num, child_page_num);
    btree.setParentPointer(child, dest_page_num);

    updateInternalNodeKey(parent, old_max, getNodeMaxKey(table.pager, old_node));

    if (!splitting_root) {
        try internalNodeInsert(table, btree.getParentPointer(old_node), new_page_num);
        btree.setParentPointer(new_node, btree.getParentPointer(old_node));
    }
}

/// Insert a new child/key pair into a parent internal node
pub fn internalNodeInsert(table: *pager.Table, parent_page_num: u32, child_page_num: u32) anyerror!void {
    var parent = try table.pager.getPage(parent_page_num);
    const child = try table.pager.getPage(child_page_num);
    const child_max_key = getNodeMaxKey(table.pager, child);
    const index = internalNodeFindChild(parent, child_max_key);

    const original_num_keys = getInternalNodeNumKeys(parent);

    if (original_num_keys >= INTERNAL_NODE_MAX_CELLS) {
        try internalNodeSplitAndInsert(table, parent_page_num, child_page_num);
        return;
    }

    const right_child_page_num = getInternalNodeRightChild(parent);

    // Handle empty internal node
    if (right_child_page_num == INVALID_PAGE_NUM) {
        setInternalNodeRightChild(parent, child_page_num);
        return;
    }

    const right_child = try table.pager.getPage(right_child_page_num);

    // Re-fetch parent since pages might have been swapped during getPage
    parent = try table.pager.getPage(parent_page_num);

    if (child_max_key > getNodeMaxKey(table.pager, right_child)) {
        // New child becomes rightmost
        setInternalNodeChild(parent, original_num_keys, right_child_page_num);
        setInternalNodeKey(parent, original_num_keys, getNodeMaxKey(table.pager, right_child));
        setInternalNodeRightChild(parent, child_page_num);
    } else {
        // Shift cells to make room
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

/// Leaf node split that updates parent (may trigger internal node split)
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
    btree.setParentPointer(new_node, btree.getParentPointer(old_node));
    btree.setLeafNodeNextLeaf(new_node, btree.leafNodeNextLeaf(old_node));
    btree.setLeafNodeNextLeaf(old_node, new_page_num);

    const left_count: u32 = @intCast(btree.LEAF_NODE_LEFT_SPLIT_COUNT);
    const right_count: u32 = @intCast(btree.LEAF_NODE_RIGHT_SPLIT_COUNT);
    const total: u32 = @intCast(btree.LEAF_NODE_MAX_CELLS + 1);

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
        const parent_page_num = btree.getParentPointer(old_node);
        const new_max = getNodeMaxKey(table.pager, old_node);
        const parent = try table.pager.getPage(parent_page_num);

        updateInternalNodeKey(parent, old_max, new_max);
        try internalNodeInsert(table, parent_page_num, new_page_num);
    }
}

fn createNewRoot(table: *pager.Table, right_child_page_num: u32) !void {
    const root = try table.pager.getPage(table.root_page_num);
    const right_child = try table.pager.getPage(right_child_page_num);
    const left_child_page_num = table.pager.getUnusedPageNum();
    const left_child = try table.pager.getPage(left_child_page_num);

    // Initialize children if root was internal
    if (getNodeType(root) == .internal) {
        initializeInternalNodeEmpty(right_child);
        initializeInternalNodeEmpty(left_child);
    }

    // Copy root to left child
    @memcpy(left_child, root);
    btree.setNodeRoot(left_child, false);

    // Update children's parent pointers if left_child is internal
    if (getNodeType(left_child) == .internal) {
        const num_keys = getInternalNodeNumKeys(left_child);
        var i: u32 = 0;
        while (i < num_keys) : (i += 1) {
            const child_page = getInternalNodeChild(left_child, i);
            const child_node = try table.pager.getPage(child_page);
            btree.setParentPointer(child_node, left_child_page_num);
        }
        const right_page = getInternalNodeRightChild(left_child);
        if (right_page != INVALID_PAGE_NUM) {
            const right_node = try table.pager.getPage(right_page);
            btree.setParentPointer(right_node, left_child_page_num);
        }
    }

    // Initialize new root
    initializeInternalNodeEmpty(root);
    btree.setNodeRoot(root, true);
    setInternalNodeNumKeys(root, 1);
    setInternalNodeChild(root, 0, left_child_page_num);

    const left_max = getNodeMaxKey(table.pager, left_child);
    setInternalNodeKey(root, 0, left_max);
    setInternalNodeRightChild(root, right_child_page_num);

    btree.setParentPointer(left_child, table.root_page_num);
    btree.setParentPointer(right_child, table.root_page_num);
}

/// Insert with full B-Tree support including internal node splitting
pub fn leafNodeInsert(table: *pager.Table, page_num: u32, cell_num: u32, key: u32, row: *const phase03.Row) !void {
    const node = try table.pager.getPage(page_num);
    const num_cells = leafNodeNumCells(node);

    if (num_cells >= LEAF_NODE_MAX_CELLS) {
        try leafNodeSplitAndInsert(table, page_num, cell_num, key, row);
        return;
    }

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

/// Execute insert with full B-Tree support
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

/// Enhanced tree printing that handles empty internal nodes
pub fn printTreeSafe(table: *pager.Table, page_num: u32, indent: u32) !void {
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
            if (num_keys > 0) {
                i = 0;
                while (i < num_keys) : (i += 1) {
                    const child_page = getInternalNodeChild(node, i);
                    try printTreeSafe(table, child_page, indent + 1);
                    var j: u32 = 0;
                    while (j < indent + 1) : (j += 1) try stdout.print("  ", .{});
                    try stdout.print("- key {d}\n", .{getInternalNodeKey(node, i)});
                }
                const right_child = getInternalNodeRightChild(node);
                if (right_child != INVALID_PAGE_NUM) {
                    try printTreeSafe(table, right_child, indent + 1);
                }
            }
        },
    }
}
