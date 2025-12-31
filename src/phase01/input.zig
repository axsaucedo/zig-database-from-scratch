const std = @import("std");

pub const InputBuffer = struct {
    buffer: std.ArrayListUnmanaged(u8),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .buffer = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.buffer.deinit(self.allocator);
    }

    pub fn getInput(self: *const Self) []const u8 {
        return self.buffer.items;
    }

    pub fn clear(self: *Self) void {
        self.buffer.clearRetainingCapacity();
    }
};

pub fn printPrompt() void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    stdout.print("db > ", .{}) catch {};
}

pub fn readInput(input_buffer: *InputBuffer) !void {
    input_buffer.clear();
    const stdin = std.fs.File.stdin().deprecatedReader();
    
    while (true) {
        const byte = stdin.readByte() catch |err| {
            if (err == error.EndOfStream) {
                if (input_buffer.buffer.items.len == 0) return error.EndOfStream;
                return;
            }
            return err;
        };
        if (byte == '\n') return;
        try input_buffer.buffer.append(input_buffer.allocator, byte);
    }
}
