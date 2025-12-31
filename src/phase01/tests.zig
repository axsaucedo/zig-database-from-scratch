const std = @import("std");
const testing = std.testing;
const input = @import("input.zig");

test "InputBuffer init and deinit" {
    var buf = try input.InputBuffer.init(testing.allocator);
    defer buf.deinit();
    try testing.expectEqual(@as(usize, 0), buf.getInput().len);
}

test "InputBuffer clear" {
    var buf = try input.InputBuffer.init(testing.allocator);
    defer buf.deinit();
    try buf.buffer.append(testing.allocator, 't');
    try testing.expectEqual(@as(usize, 1), buf.getInput().len);
    buf.clear();
    try testing.expectEqual(@as(usize, 0), buf.getInput().len);
}
