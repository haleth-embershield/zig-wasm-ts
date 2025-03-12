// renderer.zig
// Core rendering functionality

const std = @import("std");
const constants = @import("../utils/constants.zig");

// WASM imports for browser interaction
extern "env" fn clearCanvas() void;
extern "env" fn drawRect(x: f32, y: f32, width: f32, height: f32, r: u8, g: u8, b: u8) void;
extern "env" fn drawCircle(x: f32, y: f32, radius: f32, r: u8, g: u8, b: u8, fill: bool) void;
extern "env" fn drawLine(x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, r: u8, g: u8, b: u8) void;
extern "env" fn drawTriangle(x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32, r: u8, g: u8, b: u8, fill: bool) void;
extern "env" fn drawText(x: f32, y: f32, text_ptr: [*]const u8, text_len: usize, size: f32, r: u8, g: u8, b: u8) void;

/// Renderer for the game
pub const Renderer = struct {
    canvas_width: f32,
    canvas_height: f32,

    /// Initialize a new renderer
    pub fn init(width: f32, height: f32) Renderer {
        return Renderer{
            .canvas_width = width,
            .canvas_height = height,
        };
    }

    /// Clear the canvas
    pub fn clear(self: Renderer) void {
        _ = self;
        clearCanvas();
    }

    /// Draw the game grid
    pub fn drawGrid(self: Renderer) void {
        // Draw grid lines
        for (0..constants.GRID_COLS + 1) |i| {
            const x = @as(f32, @floatFromInt(i)) * constants.GRID_SIZE;
            self.drawLineShape(x, 0, x, self.canvas_height, 1, 20, 20, 20);
        }

        for (0..constants.GRID_ROWS + 1) |i| {
            const y = @as(f32, @floatFromInt(i)) * constants.GRID_SIZE;
            self.drawLineShape(0, y, self.canvas_width, y, 1, 20, 20, 20);
        }
    }

    /// Draw a rectangle
    pub fn drawRectShape(self: Renderer, x: f32, y: f32, width: f32, height: f32, r: u8, g: u8, b: u8) void {
        _ = self;
        drawRect(x, y, width, height, r, g, b);
    }

    /// Draw a circle
    pub fn drawCircleShape(self: Renderer, x: f32, y: f32, radius: f32, r: u8, g: u8, b: u8, fill: bool) void {
        _ = self;
        drawCircle(x, y, radius, r, g, b, fill);
    }

    /// Draw a line
    pub fn drawLineShape(self: Renderer, x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, r: u8, g: u8, b: u8) void {
        _ = self;
        drawLine(x1, y1, x2, y2, thickness, r, g, b);
    }

    /// Draw a triangle
    pub fn drawTriangleShape(self: Renderer, x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32, r: u8, g: u8, b: u8, fill: bool) void {
        _ = self;
        drawTriangle(x1, y1, x2, y2, x3, y3, r, g, b, fill);
    }

    /// Draw text
    pub fn drawTextString(self: Renderer, x: f32, y: f32, text: []const u8, size: f32, r: u8, g: u8, b: u8) void {
        _ = self;
        drawText(x, y, text.ptr, text.len, size, r, g, b);
    }

    /// Draw tower placement preview
    pub fn drawTowerPreview(self: Renderer, x: f32, y: f32, can_place: bool, range: f32) void {
        _ = self;
        if (x < 0 or y < 0) return;

        // Draw tower placement indicator
        drawCircle(x, y, 20, if (can_place) 0 else 255, if (can_place) 255 else 0, if (can_place) 238 else 0, false);

        // Draw tower range indicator if placement is valid
        if (can_place and range > 0) {
            drawCircle(x, y, range, 0, 255, 238, false);
        }

        if (!can_place) {
            // Draw X
            drawLine(x - 15, y - 15, x + 15, y + 15, 2, 255, 0, 0);
            drawLine(x + 15, y - 15, x - 15, y + 15, 2, 255, 0, 0);
        }
    }
};
