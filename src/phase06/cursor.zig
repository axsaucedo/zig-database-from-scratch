//! Phase 06: Cursor Abstraction
//!
//! A Cursor represents a location in the table.
//! It abstracts away the details of table navigation.

const std = @import("std");
const phase05 = @import("phase05");
const phase03 = @import("phase03");

pub const Cursor = struct {
    table: *phase05.Table,
    row_num: u32,
    end_of_table: bool,

    const Self = @This();

    /// Create a cursor at the beginning of the table
    pub fn tableStart(table: *phase05.Table) Self {
        return Self{
            .table = table,
            .row_num = 0,
            .end_of_table = table.num_rows == 0,
        };
    }

    /// Create a cursor at the end of the table (for inserts)
    pub fn tableEnd(table: *phase05.Table) Self {
        return Self{
            .table = table,
            .row_num = table.num_rows,
            .end_of_table = true,
        };
    }

    /// Get the memory location pointed to by this cursor
    pub fn value(self: *Self) ![]u8 {
        return self.table.rowSlot(self.row_num);
    }

    /// Advance the cursor to the next row
    pub fn advance(self: *Self) void {
        self.row_num += 1;
        if (self.row_num >= self.table.num_rows) {
            self.end_of_table = true;
        }
    }
};
