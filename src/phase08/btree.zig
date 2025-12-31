//! Phase 08: B-Tree Node Format
//!
//! Defines the binary layout of B-Tree nodes (leaf and internal).
//! Each node fits in exactly one page (4096 bytes).

const std = @import("std");
const phase03 = @import("phase03");

pub const PAGE_SIZE: usize = 4096;

// Node types
pub const NodeType = enum(u8) {
    internal = 0,
    leaf = 1,
};

// Common Node Header Layout
pub const NODE_TYPE_SIZE: usize = 1;
pub const NODE_TYPE_OFFSET: usize = 0;
pub const IS_ROOT_SIZE: usize = 1;
pub const IS_ROOT_OFFSET: usize = NODE_TYPE_SIZE;
pub const PARENT_POINTER_SIZE: usize = 4;
pub const PARENT_POINTER_OFFSET: usize = IS_ROOT_OFFSET + IS_ROOT_SIZE;
pub const COMMON_NODE_HEADER_SIZE: usize = NODE_TYPE_SIZE + IS_ROOT_SIZE + PARENT_POINTER_SIZE;

// Leaf Node Header Layout
pub const LEAF_NODE_NUM_CELLS_SIZE: usize = 4;
pub const LEAF_NODE_NUM_CELLS_OFFSET: usize = COMMON_NODE_HEADER_SIZE;
pub const LEAF_NODE_NEXT_LEAF_SIZE: usize = 4;
pub const LEAF_NODE_NEXT_LEAF_OFFSET: usize = LEAF_NODE_NUM_CELLS_OFFSET + LEAF_NODE_NUM_CELLS_SIZE;
pub const LEAF_NODE_HEADER_SIZE: usize = COMMON_NODE_HEADER_SIZE + LEAF_NODE_NUM_CELLS_SIZE + LEAF_NODE_NEXT_LEAF_SIZE;

// Leaf Node Body Layout
pub const LEAF_NODE_KEY_SIZE: usize = 4;
pub const LEAF_NODE_KEY_OFFSET: usize = 0;
pub const LEAF_NODE_VALUE_SIZE: usize = phase03.ROW_SIZE;
pub const LEAF_NODE_VALUE_OFFSET: usize = LEAF_NODE_KEY_OFFSET + LEAF_NODE_KEY_SIZE;
pub const LEAF_NODE_CELL_SIZE: usize = LEAF_NODE_KEY_SIZE + LEAF_NODE_VALUE_SIZE;
pub const LEAF_NODE_SPACE_FOR_CELLS: usize = PAGE_SIZE - LEAF_NODE_HEADER_SIZE;
pub const LEAF_NODE_MAX_CELLS: usize = LEAF_NODE_SPACE_FOR_CELLS / LEAF_NODE_CELL_SIZE;

// Splitting constants
pub const LEAF_NODE_RIGHT_SPLIT_COUNT: usize = (LEAF_NODE_MAX_CELLS + 1) / 2;
pub const LEAF_NODE_LEFT_SPLIT_COUNT: usize = (LEAF_NODE_MAX_CELLS + 1) - LEAF_NODE_RIGHT_SPLIT_COUNT;

/// Get node type
pub fn getNodeType(node: []u8) NodeType {
    return @enumFromInt(node[NODE_TYPE_OFFSET]);
}

/// Set node type
pub fn setNodeType(node: []u8, node_type: NodeType) void {
    node[NODE_TYPE_OFFSET] = @intFromEnum(node_type);
}

/// Check if node is root
pub fn isNodeRoot(node: []u8) bool {
    return node[IS_ROOT_OFFSET] != 0;
}

/// Set root flag
pub fn setNodeRoot(node: []u8, is_root: bool) void {
    node[IS_ROOT_OFFSET] = if (is_root) 1 else 0;
}

/// Get parent pointer
pub fn getParentPointer(node: []u8) u32 {
    return std.mem.readInt(u32, node[PARENT_POINTER_OFFSET..][0..4], .little);
}

/// Set parent pointer
pub fn setParentPointer(node: []u8, parent: u32) void {
    std.mem.writeInt(u32, node[PARENT_POINTER_OFFSET..][0..4], parent, .little);
}

/// Get number of cells in leaf node
pub fn leafNodeNumCells(node: []u8) u32 {
    return std.mem.readInt(u32, node[LEAF_NODE_NUM_CELLS_OFFSET..][0..4], .little);
}

/// Set number of cells in leaf node
pub fn setLeafNodeNumCells(node: []u8, num_cells: u32) void {
    std.mem.writeInt(u32, node[LEAF_NODE_NUM_CELLS_OFFSET..][0..4], num_cells, .little);
}

/// Get next leaf pointer (for traversal)
pub fn leafNodeNextLeaf(node: []u8) u32 {
    return std.mem.readInt(u32, node[LEAF_NODE_NEXT_LEAF_OFFSET..][0..4], .little);
}

/// Set next leaf pointer
pub fn setLeafNodeNextLeaf(node: []u8, next_leaf: u32) void {
    std.mem.writeInt(u32, node[LEAF_NODE_NEXT_LEAF_OFFSET..][0..4], next_leaf, .little);
}

/// Get pointer to cell at index
pub fn leafNodeCell(node: []u8, cell_num: u32) []u8 {
    const offset = LEAF_NODE_HEADER_SIZE + cell_num * LEAF_NODE_CELL_SIZE;
    return node[offset..][0..LEAF_NODE_CELL_SIZE];
}

/// Get key at cell index
pub fn leafNodeKey(node: []u8, cell_num: u32) u32 {
    const cell = leafNodeCell(node, cell_num);
    return std.mem.readInt(u32, cell[0..4], .little);
}

/// Set key at cell index
pub fn setLeafNodeKey(node: []u8, cell_num: u32, key: u32) void {
    const cell = leafNodeCell(node, cell_num);
    std.mem.writeInt(u32, cell[0..4], key, .little);
}

/// Get value (row data) at cell index
pub fn leafNodeValue(node: []u8, cell_num: u32) []u8 {
    const cell = leafNodeCell(node, cell_num);
    return cell[LEAF_NODE_KEY_SIZE..][0..LEAF_NODE_VALUE_SIZE];
}

/// Initialize an empty leaf node
pub fn initializeLeafNode(node: []u8) void {
    setNodeType(node, .leaf);
    setNodeRoot(node, false);
    setLeafNodeNumCells(node, 0);
    setLeafNodeNextLeaf(node, 0); // 0 = no sibling
}

/// Initialize root node
pub fn initializeRootNode(node: []u8) void {
    initializeLeafNode(node);
    setNodeRoot(node, true);
}

/// Print leaf node for debugging
pub fn printLeafNode(node: []u8) void {
    const num_cells = leafNodeNumCells(node);
    std.debug.print("leaf (size {d})\n", .{num_cells});
    var i: u32 = 0;
    while (i < num_cells) : (i += 1) {
        const key = leafNodeKey(node, i);
        std.debug.print("  - {d} : {d}\n", .{ i, key });
    }
}

/// Print constants for debugging
pub fn printConstants() void {
    std.debug.print("ROW_SIZE: {d}\n", .{phase03.ROW_SIZE});
    std.debug.print("COMMON_NODE_HEADER_SIZE: {d}\n", .{COMMON_NODE_HEADER_SIZE});
    std.debug.print("LEAF_NODE_HEADER_SIZE: {d}\n", .{LEAF_NODE_HEADER_SIZE});
    std.debug.print("LEAF_NODE_CELL_SIZE: {d}\n", .{LEAF_NODE_CELL_SIZE});
    std.debug.print("LEAF_NODE_SPACE_FOR_CELLS: {d}\n", .{LEAF_NODE_SPACE_FOR_CELLS});
    std.debug.print("LEAF_NODE_MAX_CELLS: {d}\n", .{LEAF_NODE_MAX_CELLS});
}
