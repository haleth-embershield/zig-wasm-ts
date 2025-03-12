// ui.zig
// UI rendering functionality

const std = @import("std");
const constants = @import("../utils/constants.zig");
const renderer_module = @import("renderer.zig");
const Renderer = renderer_module.Renderer;
const tower_module = @import("../entities/tower.zig");
const TowerType = tower_module.TowerType;

/// Game state enum
pub const GameState = enum {
    Menu,
    Playing,
    Paused,
    GameOver,
};

/// UI Manager for rendering game UI
pub const UIManager = struct {
    renderer: *Renderer,

    /// Initialize a new UI manager
    pub fn init(renderer: *Renderer) UIManager {
        return UIManager{
            .renderer = renderer,
        };
    }

    /// Draw the game UI
    pub fn drawUI(self: UIManager, money: u32, lives: u32, wave: u32, selected_tower_type: TowerType) void {
        // Draw money
        var money_text_buf: [32]u8 = undefined;
        const money_text = std.fmt.bufPrint(&money_text_buf, "Money: {d}", .{money}) catch "Money: ???";
        self.renderer.drawTextString(10, 20, money_text, 16, 255, 255, 0);

        // Draw lives
        var lives_text_buf: [32]u8 = undefined;
        const lives_text = std.fmt.bufPrint(&lives_text_buf, "Lives: {d}", .{lives}) catch "Lives: ???";
        self.renderer.drawTextString(10, 40, lives_text, 16, 0, 255, 0);

        // Draw wave
        var wave_text_buf: [32]u8 = undefined;
        const wave_text = std.fmt.bufPrint(&wave_text_buf, "Wave: {d}", .{wave}) catch "Wave: ???";
        self.renderer.drawTextString(10, 60, wave_text, 16, 0, 255, 255);

        // Draw selected tower info
        if (selected_tower_type != TowerType.None) {
            var tower_text_buf: [64]u8 = undefined;
            const tower_cost = switch (selected_tower_type) {
                .Line => constants.TOWER_COST_LINE,
                .Triangle => constants.TOWER_COST_TRIANGLE,
                .Square => constants.TOWER_COST_SQUARE,
                .Pentagon => constants.TOWER_COST_PENTAGON,
                .None => 0,
            };
            const tower_text = std.fmt.bufPrint(&tower_text_buf, "Selected: {s} (Cost: {d})", .{ @tagName(selected_tower_type), tower_cost }) catch "Selected Tower";
            self.renderer.drawTextString(self.renderer.canvas_width - 300, 20, tower_text, 16, 255, 255, 255);
        }
    }

    /// Draw the wave countdown timer
    pub fn drawWaveTimer(self: UIManager, wave_timer: f32) void {
        if (wave_timer > 0) {
            var timer_text_buf: [32]u8 = undefined;
            const time_left = constants.WAVE_COOLDOWN - wave_timer;
            const timer_text = std.fmt.bufPrint(&timer_text_buf, "Next wave in: {d:.1}", .{time_left}) catch "Next wave soon";
            self.renderer.drawTextString(self.renderer.canvas_width / 2 - 100, 30, timer_text, 20, 255, 255, 255);
        }
    }

    /// Draw the menu screen
    pub fn drawMenu(self: UIManager) void {
        // Clear canvas
        self.renderer.clear();

        // Draw title
        const title_text = "NEON GEOMETRY TOWER DEFENSE";
        self.renderer.drawTextString(self.renderer.canvas_width / 2 - 250, self.renderer.canvas_height / 2 - 50, title_text, 30, 0, 255, 255);

        // Draw start instruction
        const start_text = "Click to Start";
        self.renderer.drawTextString(self.renderer.canvas_width / 2 - 80, self.renderer.canvas_height / 2 + 50, start_text, 20, 255, 255, 255);
    }

    /// Draw the game over screen
    pub fn drawGameOver(self: UIManager) void {
        const game_over_text = "GAME OVER - Click to restart";
        self.renderer.drawTextString(self.renderer.canvas_width / 2 - 150, self.renderer.canvas_height / 2, game_over_text, 30, 255, 0, 0);
    }

    /// Draw the pause screen overlay
    pub fn drawPaused(self: UIManager) void {
        const paused_text = "PAUSED - Click to resume";
        self.renderer.drawTextString(self.renderer.canvas_width / 2 - 150, self.renderer.canvas_height / 2, paused_text, 30, 255, 255, 0);
    }
};
