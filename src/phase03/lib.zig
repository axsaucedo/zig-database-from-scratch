//! Phase 03: Module Root
//!
//! This file serves as the module root for phase03.
//! It re-exports all public types and functions from the phase.

pub const row = @import("row.zig");
pub const table = @import("table.zig");

// Re-export Row types and functions
pub const Row = row.Row;
pub const ROW_SIZE = row.ROW_SIZE;
pub const COLUMN_USERNAME_SIZE = row.COLUMN_USERNAME_SIZE;
pub const COLUMN_EMAIL_SIZE = row.COLUMN_EMAIL_SIZE;
pub const serializeRow = row.serializeRow;
pub const deserializeRow = row.deserializeRow;
pub const printRow = row.printRow;

// Re-export Table types and functions
pub const Table = table.Table;
pub const TABLE_MAX_ROWS = table.TABLE_MAX_ROWS;
pub const PAGE_SIZE = table.PAGE_SIZE;
pub const ROWS_PER_PAGE = table.ROWS_PER_PAGE;
