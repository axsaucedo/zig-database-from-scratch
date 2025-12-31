//! Phase 01: REPL Demo
//!
//! This is the main entry point for Phase 01.
//! It demonstrates the basic REPL with .exit handling.
//!
//! Run: zig build run-phase01

const std = @import("std");
const input = @import("input.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 01: Basic REPL\n", .{});
    std.debug.print("Type '.exit' to quit, anything else shows unrecognized message.\n\n", .{});

    var input_buffer = try input.InputBuffer.init(allocator);
    defer input_buffer.deinit();

    const stdout = std.fs.File.stdout().deprecatedWriter();

    while (true) {
        input.printPrompt();

        input.readInput(&input_buffer) catch |err| {
            std.debug.print("Error reading input: {}\n", .{err});
            return err;
        };

        const user_input = input_buffer.getInput();

        // Handle .exit command
        if (std.mem.eql(u8, user_input, ".exit")) {
            return;
        }

        // Show unrecognized message for anything else
        stdout.print("Unrecognized command '{s}'.\n", .{user_input}) catch {};
    }
}

// Re-export for testing
pub const InputBuffer = input.InputBuffer;
pub const printPrompt = input.printPrompt;
pub const readInput = input.readInput;

test {
    // Include all tests from the tests module
    _ = @import("tests.zig");
}
