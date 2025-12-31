const std = @import("std");
const testing = std.testing;
const validation = @import("validation.zig");

test "prepareInsert valid" {
    var stmt: validation.Statement = undefined;
    try testing.expectEqual(validation.PrepareResult.success, validation.prepareInsert("insert 1 user user@test.com", &stmt));
    try testing.expectEqual(@as(u32, 1), stmt.row_to_insert.id);
}

test "prepareInsert negative" {
    var stmt: validation.Statement = undefined;
    try testing.expectEqual(validation.PrepareResult.negative_id, validation.prepareInsert("insert -1 user user@test.com", &stmt));
}

test "prepareInsert too long" {
    var stmt: validation.Statement = undefined;
    try testing.expectEqual(validation.PrepareResult.string_too_long, validation.prepareInsert("insert 1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa user@test.com", &stmt));
}
