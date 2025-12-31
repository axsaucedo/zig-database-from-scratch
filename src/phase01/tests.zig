//! Phase 01: Unit Tests for Input Module

const std = @import("std");
const testing = std.testing;
const input = @import("input.zig");

test "InputBuffer init allocates buffer" {
    var buffer = try input.InputBuffer.init(testing.allocator);
    defer buffer.deinit();

    try testing.expectEqual(@as(usize, input.MAX_INPUT_SIZE), buffer.buffer.len);
    try testing.expectEqual(@as(usize, 0), buffer.input_length);
}

test "InputBuffer getInput returns empty slice initially" {
    var buffer = try input.InputBuffer.init(testing.allocator);
    defer buffer.deinit();

    const slice = buffer.getInput();
    try testing.expectEqual(@as(usize, 0), slice.len);
}

test "InputBuffer getInput returns correct slice after setting length" {
    var buffer = try input.InputBuffer.init(testing.allocator);
    defer buffer.deinit();

    // Simulate input
    @memcpy(buffer.buffer[0..5], "hello");
    buffer.input_length = 5;

    const slice = buffer.getInput();
    try testing.expectEqualStrings("hello", slice);
}

test "InputBuffer clear resets input_length" {
    var buffer = try input.InputBuffer.init(testing.allocator);
    defer buffer.deinit();

    buffer.input_length = 42;
    buffer.clear();

    try testing.expectEqual(@as(usize, 0), buffer.input_length);
}
