const std = @import("std");
const phase01 = @import("phase01");
const parser = @import("parser.zig");

pub const MetaCommandResult = parser.MetaCommandResult;
pub const PrepareResult = parser.PrepareResult;
pub const StatementType = parser.StatementType;
pub const Statement = parser.Statement;
pub const isMetaCommand = parser.isMetaCommand;
pub const doMetaCommand = parser.doMetaCommand;
pub const prepareStatement = parser.prepareStatement;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 02: SQL Compiler\n\n", .{});

    var input_buffer = try phase01.InputBuffer.init(allocator);
    defer input_buffer.deinit();
    const stdout = std.fs.File.stdout().deprecatedWriter();

    while (true) {
        phase01.printPrompt();
        phase01.readInput(&input_buffer) catch |err| {
            if (err == error.EndOfStream) return;
            return err;
        };
        const input = input_buffer.getInput();

        if (isMetaCommand(input)) {
            if (doMetaCommand(input) == .success) return;
            stdout.print("Unrecognized command '{s}'\n", .{input}) catch {};
            continue;
        }

        var stmt: Statement = undefined;
        if (prepareStatement(input, &stmt) != .success) {
            stdout.print("Unrecognized keyword.\n", .{}) catch {};
            continue;
        }
        stdout.print("Executed.\n", .{}) catch {};
    }
}

test { _ = @import("tests.zig"); }
