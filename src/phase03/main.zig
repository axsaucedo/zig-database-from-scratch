const std = @import("std");
const phase01 = @import("phase01");
const phase02 = @import("phase02");
const row = @import("row.zig");
const table = @import("table.zig");

pub const Row = row.Row;
pub const Table = table.Table;
pub const ROW_SIZE = row.ROW_SIZE;
pub const COLUMN_USERNAME_SIZE = row.COLUMN_USERNAME_SIZE;
pub const COLUMN_EMAIL_SIZE = row.COLUMN_EMAIL_SIZE;
pub const serializeRow = row.serializeRow;
pub const deserializeRow = row.deserializeRow;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Phase 03: In-Memory Database\n\n", .{});

    var tbl = table.Table.init(allocator);
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

        if (input.len >= 6 and std.mem.eql(u8, input[0..6], "insert")) {
            var iter = std.mem.tokenizeScalar(u8, input, ' ');
            _ = iter.next();
            const id_str = iter.next() orelse { stdout.print("Syntax error.\n", .{}) catch {}; continue; };
            const id = std.fmt.parseInt(u32, id_str, 10) catch { stdout.print("Syntax error.\n", .{}) catch {}; continue; };
            const username = iter.next() orelse { stdout.print("Syntax error.\n", .{}) catch {}; continue; };
            const email = iter.next() orelse { stdout.print("Syntax error.\n", .{}) catch {}; continue; };

            var r = row.Row.init();
            r.id = id;
            r.setUsername(username);
            r.setEmail(email);

            const slot = tbl.rowSlot(tbl.num_rows) catch { stdout.print("Table full.\n", .{}) catch {}; continue; };
            row.serializeRow(&r, slot);
            tbl.num_rows += 1;
            stdout.print("Executed.\n", .{}) catch {};
        } else if (std.mem.eql(u8, input, "select")) {
            var i: u32 = 0;
            while (i < tbl.num_rows) : (i += 1) {
                var r: row.Row = undefined;
                const slot = tbl.rowSlot(i) catch continue;
                row.deserializeRow(slot, &r);
                stdout.print("({d}, {s}, {s})\n", .{ r.id, r.getUsernameSlice(), r.getEmailSlice() }) catch {};
            }
            stdout.print("Executed.\n", .{}) catch {};
        } else {
            stdout.print("Unrecognized.\n", .{}) catch {};
        }
    }
}

test { _ = @import("tests.zig"); }
