const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const phase03 = @import("phase03");
const validation = @import("validation.zig");

pub const PrepareResult = validation.PrepareResult;
pub const Statement = validation.Statement;
pub const prepareStatement = validation.prepareStatement;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 04: Validation\n\n", .{});

    var tbl = phase03.Table.init(allocator);
    defer tbl.deinit();

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

        if (phase02.isMetaCommand(input)) {
            if (phase02.doMetaCommand(input) == .success) return;
            stdout.print("Unrecognized command.\n", .{}) catch {};
            continue;
        }

        var stmt: Statement = undefined;
        switch (prepareStatement(input, &stmt)) {
            .success => {},
            .negative_id => { stdout.print("ID must be positive.\n", .{}) catch {}; continue; },
            .string_too_long => { stdout.print("String too long.\n", .{}) catch {}; continue; },
            .syntax_error => { stdout.print("Syntax error.\n", .{}) catch {}; continue; },
            .unrecognized_statement => { stdout.print("Unrecognized.\n", .{}) catch {}; continue; },
        }

        switch (stmt.statement_type) {
            .insert => {
                const slot = tbl.rowSlot(tbl.num_rows) catch { stdout.print("Table full.\n", .{}) catch {}; continue; };
                phase03.serializeRow(&stmt.row_to_insert, slot);
                tbl.num_rows += 1;
            },
            .select => {
                var i: u32 = 0;
                while (i < tbl.num_rows) : (i += 1) {
                    var r: phase03.Row = undefined;
                    const slot = tbl.rowSlot(i) catch continue;
                    phase03.deserializeRow(slot, &r);
                    stdout.print("({d}, {s}, {s})\n", .{ r.id, r.getUsernameSlice(), r.getEmailSlice() }) catch {};
                }
            },
        }
        stdout.print("Executed.\n", .{}) catch {};
    }
}

test { _ = @import("tests.zig"); }
