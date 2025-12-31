//! Phase 08: B-Tree Leaf Node Format
//!
//! This phase introduces the B-Tree node format.
//! - Nodes replace the simple row array
//! - Each node fits in one page
//! - Leaf nodes store key/value pairs

pub const btree = @import("btree.zig");
pub const pager = @import("pager.zig");
pub const cursor = @import("cursor.zig");

// Re-export key types
pub const NodeType = btree.NodeType;
pub const Pager = pager.Pager;
pub const Table = pager.Table;
pub const Cursor = cursor.Cursor;

// Re-export key constants
pub const PAGE_SIZE = btree.PAGE_SIZE;
pub const LEAF_NODE_MAX_CELLS = btree.LEAF_NODE_MAX_CELLS;
pub const LEAF_NODE_CELL_SIZE = btree.LEAF_NODE_CELL_SIZE;
pub const COMMON_NODE_HEADER_SIZE = btree.COMMON_NODE_HEADER_SIZE;
pub const LEAF_NODE_HEADER_SIZE = btree.LEAF_NODE_HEADER_SIZE;

// Re-export key functions
pub const getNodeType = btree.getNodeType;
pub const leafNodeNumCells = btree.leafNodeNumCells;
pub const leafNodeKey = btree.leafNodeKey;
pub const leafNodeValue = btree.leafNodeValue;
pub const setLeafNodeKey = btree.setLeafNodeKey;
pub const setLeafNodeNumCells = btree.setLeafNodeNumCells;
pub const leafNodeCell = btree.leafNodeCell;
pub const initializeLeafNode = btree.initializeLeafNode;
pub const printLeafNode = btree.printLeafNode;
pub const printConstants = btree.printConstants;
