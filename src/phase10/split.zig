//! Phase 10: Leaf Node Splitting

const std = @import("std");
const phase08 = @import("phase08");
const phase03 = @import("phase03");

const btree = phase08.btree;
const pager = phase08.pager;

pub fn leafNodeSplitAndInsert(
    table: *pager.Table,
    page_num: u32,
    cell_num: u32,
    key: u32,
    row: *const phase03.Row,
) !void {
    const old_node = try table.pager.getPage(page_num);
    const new_page_num = table.pager.getUnusedPageNum();
    const new_node = try table.pager.getPage(new_page_num);

    btree.initializeLeafNode(new_node);
    btree.setLeafNodeNextLeaf(new_node, btree.leafNodeNextLeaf(old_node));
    btree.setLeafNodeNextLeaf(old_node, new_page_num);

    const left_count: u32 = @intCast(btree.LEAF_NODE_LEFT_SPLIT_COUNT);
    const right_count: u32 = @intCast(btree.LEAF_NODE_RIGHT_SPLIT_COUNT);
    const total: u32 = @intCast(btree.LEAF_NODE_MAX_CELLS + 1);

    // Process from right to left
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
        return error.NotImplemented;
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

    const left_max = getMaxKey(left_child);
    setInternalNodeKey(root, 0, left_max);
    setInternalNodeRightChild(root, right_child_page_num);

    btree.setParentPointer(left_child, table.root_page_num);

    const right_child = try table.pager.getPage(right_child_page_num);
    btree.setParentPointer(right_child, table.root_page_num);
}

// Internal Node Layout
pub const INTERNAL_NODE_NUM_KEYS_SIZE: usize = 4;
pub const INTERNAL_NODE_NUM_KEYS_OFFSET: usize = btree.COMMON_NODE_HEADER_SIZE;
pub const INTERNAL_NODE_RIGHT_CHILD_SIZE: usize = 4;
pub const INTERNAL_NODE_RIGHT_CHILD_OFFSET: usize = INTERNAL_NODE_NUM_KEYS_OFFSET + INTERNAL_NODE_NUM_KEYS_SIZE;
pub const INTERNAL_NODE_HEADER_SIZE: usize = btree.COMMON_NODE_HEADER_SIZE + INTERNAL_NODE_NUM_KEYS_SIZE + INTERNAL_NODE_RIGHT_CHILD_SIZE;
pub const INTERNAL_NODE_KEY_SIZE: usize = 4;
pub const INTERNAL_NODE_CHILD_SIZE: usize = 4;
pub const INTERNAL_NODE_CELL_SIZE: usize = INTERNAL_NODE_CHILD_SIZE + INTERNAL_NODE_KEY_SIZE;

pub fn initializeInternalNode(node: []u8) void {
    btree.setNodeType(node, .internal);
    btree.setNodeRoot(node, false);
    setInternalNodeNumKeys(node, 0);
}

pub fn getInternalNodeNumKeys(node: []u8) u32 {
    return std.mem.readInt(u32, node[INTERNAL_NODE_NUM_KEYS_OFFSET..][0..4], .little);
}

pub fn setInternalNodeNumKeys(node: []u8, num_keys: u32) void {
    std.mem.writeInt(u32, node[INTERNAL_NODE_NUM_KEYS_OFFSET..][0..4], num_keys, .little);
}

pub fn getInternalNodeRightChild(node: []u8) u32 {
    return std.mem.readInt(u32, node[INTERNAL_NODE_RIGHT_CHILD_OFFSET..][0..4], .little);
}

pub fn setInternalNodeRightChild(node: []u8, page_num: u32) void {
    std.mem.writeInt(u32, node[INTERNAL_NODE_RIGHT_CHILD_OFFSET..][0..4], page_num, .little);
}

fn internalNodeCell(node: []u8, cell_num: u32) []u8 {
    const offset = INTERNAL_NODE_HEADER_SIZE + cell_num * INTERNAL_NODE_CELL_SIZE;
    return node[offset..][0..INTERNAL_NODE_CELL_SIZE];
}

pub fn getInternalNodeChild(node: []u8, child_num: u32) u32 {
    const num_keys = getInternalNodeNumKeys(node);
    if (child_num > num_keys) unreachable;
    if (child_num == num_keys) return getInternalNodeRightChild(node);
    const cell = internalNodeCell(node, child_num);
    return std.mem.readInt(u32, cell[0..4], .little);
}

pub fn setInternalNodeChild(node: []u8, child_num: u32, page_num: u32) void {
    const cell = internalNodeCell(node, child_num);
    std.mem.writeInt(u32, cell[0..4], page_num, .little);
}

pub fn getInternalNodeKey(node: []u8, key_num: u32) u32 {
    const cell = internalNodeCell(node, key_num);
    return std.mem.readInt(u32, cell[4..8], .little);
}

pub fn setInternalNodeKey(node: []u8, key_num: u32, key: u32) void {
    const cell = internalNodeCell(node, key_num);
    std.mem.writeInt(u32, cell[4..8], key, .little);
}

pub fn getMaxKey(node: []u8) u32 {
    switch (btree.getNodeType(node)) {
        .internal => {
            const num_keys = getInternalNodeNumKeys(node);
            return getInternalNodeKey(node, num_keys - 1);
        },
        .leaf => {
            const num_cells = btree.leafNodeNumCells(node);
            return btree.leafNodeKey(node, num_cells - 1);
        },
    }
}
