//! Phase 01: Input Buffer Module
//!
//! This module provides the core input handling for the REPL.
//! It exports InputBuffer and related functions that will be
//! reused by all subsequent phases.

const std = @import("std");

/// Maximum size of input buffer
pub const MAX_INPUT_SIZE: usize = 1024;

/// InputBuffer stores the state needed for reading user input.
pub const InputBuffer = struct {
    buffer: []u8,
    input_length: usize,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Creates a new InputBuffer with allocated memory
    pub fn init(allocator: std.mem.Allocator) !Self {
        const buffer = try allocator.alloc(u8, MAX_INPUT_SIZE);
        return Self{
            .buffer = buffer,
            .input_length = 0,
            .allocator = allocator,
        };
    }

    /// Frees the allocated buffer memory
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.buffer);
    }

    /// Returns the current input as a slice
    pub fn getInput(self: *const Self) []const u8 {
        return self.buffer[0..self.input_length];
    }

    /// Clears the input buffer
    pub fn clear(self: *Self) void {
        self.input_length = 0;
    }
};

/// Prints the REPL prompt to stdout
pub fn printPrompt() void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    stdout.print("db > ", .{}) catch {};
}

/// Reads a line of input from stdin into the InputBuffer.
/// Returns error on I/O failure, sets input_length to 0 on EOF.
pub fn readInput(input_buffer: *InputBuffer) !void {
    const stdin = std.fs.File.stdin().deprecatedReader();

    const line = stdin.readUntilDelimiterOrEof(input_buffer.buffer, '\n') catch |err| {
        return err;
    };

    if (line) |l| {
        input_buffer.input_length = l.len;
    } else {
        // EOF received
        input_buffer.input_length = 0;
    }
}

/// Runs the basic REPL loop. Calls the provided handler for each input line.
/// Returns when handler returns false (e.g., on .exit command).
pub fn runRepl(
    allocator: std.mem.Allocator,
    handler: fn (input: []const u8) bool,
) !void {
    var input_buffer = try InputBuffer.init(allocator);
    defer input_buffer.deinit();

    while (true) {
        printPrompt();

        readInput(&input_buffer) catch |err| {
            std.debug.print("Error reading input: {}\n", .{err});
            return err;
        };

        const input = input_buffer.getInput();

        // Call handler; if it returns false, exit the loop
        if (!handler(input)) {
            break;
        }
    }
}
