const std = @import("std");
const input = @import("input.zig");

pub const InputBuffer = input.InputBuffer;
pub const printPrompt = input.printPrompt;
pub const readInput = input.readInput;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 01: Basic REPL\n", .{});
    std.debug.print("Type '.exit' to quit.\n\n", .{});

    var input_buffer = try InputBuffer.init(allocator);
    defer input_buffer.deinit();

    const stdout = std.fs.File.stdout().deprecatedWriter();

    while (true) {
        printPrompt();
        readInput(&input_buffer) catch |err| {
            if (err == error.EndOfStream) return;
            return err;
        };
        const line = input_buffer.getInput();
        if (std.mem.eql(u8, line, ".exit")) return;
        stdout.print("Unrecognized command '{s}'.\n", .{line}) catch {};
    }
}

test { _ = @import("tests.zig"); }
