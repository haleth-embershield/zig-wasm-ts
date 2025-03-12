// main.zig
// Entry point for the Neon Geometry Tower Defense game

const std = @import("std");
const logger = @import("utils/logger.zig");
const Game = @import("game.zig").Game;

// Global state
var canvas_width: f32 = 800;
var canvas_height: f32 = 600;
var game: Game = undefined;

// Initialize the WASM module
export fn init(width: f32, height: f32) void {
    canvas_width = width;
    canvas_height = height;

    // Initialize game
    game = Game.init(width, height);

    logger.log("Tower Defense initialized");
}

// Start or reset the game
export fn resetGame() void {
    game.reset();
}

// Update animation frame
export fn update(delta_time: f32) void {
    game.update(delta_time);
}

// Handle mouse click
export fn handleClick(x: f32, y: f32) void {
    game.handleClick(x, y);
}

// Select tower type
export fn selectTowerType(tower_type: u32) void {
    game.selectTowerType(tower_type);
}

// Check if a tower can be placed at the given coordinates
export fn canPlaceTower(x: f32, y: f32) bool {
    return game.canPlaceTower(x, y);
}

// Get the range of the currently selected tower type
export fn getTowerRange() f32 {
    return game.getSelectedTowerRange();
}
