// logger.zig
// Logging utilities for debugging and information

const std = @import("std");

// WASM import for console logging
extern "env" fn consoleLog(ptr: [*]const u8, len: usize) void;

/// Log a string message to the browser console
pub fn log(msg: []const u8) void {
    consoleLog(msg.ptr, msg.len);
}

/// Format and log a message with arguments
pub fn logFmt(comptime fmt: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, fmt, args) catch {
        log("Error formatting log message");
        return;
    };
    log(message);
}

/// Log an error message
pub fn logError(msg: []const u8) void {
    var buf: [256]u8 = undefined;
    const error_msg = std.fmt.bufPrint(&buf, "ERROR: {s}", .{msg}) catch "ERROR";
    log(error_msg);
}

/// Log a debug message (only in debug builds)
pub fn logDebug(comptime fmt: []const u8, args: anytype) void {
    if (@import("builtin").mode == .Debug) {
        var buf: [256]u8 = undefined;
        const message = std.fmt.bufPrint(&buf, "DEBUG: " ++ fmt, args) catch "DEBUG: Error formatting";
        log(message);
    }
}

/// Log a game event
pub fn logGameEvent(comptime fmt: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const message = std.fmt.bufPrint(&buf, "GAME: " ++ fmt, args) catch "GAME: Error formatting";
    log(message);
}
