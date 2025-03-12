// tower.zig
// Tower definitions and logic

const std = @import("std");
const constants = @import("../utils/constants.zig");
const math = @import("../utils/math.zig");
const Vector2 = math.Vector2;
const logger = @import("../utils/logger.zig");

/// Tower types
pub const TowerType = enum {
    None,
    Line, // Straight line attack
    Triangle, // Area damage
    Square, // Slowing effect
    Pentagon, // High damage
};

/// Tower structure
pub const Tower = struct {
    x: f32,
    y: f32,
    type: TowerType,
    level: u32,
    cooldown: f32,
    cooldown_max: f32,
    range: f32,
    damage: f32,
    cost: u32,

    /// Create a new tower
    pub fn init(x: f32, y: f32, tower_type: TowerType) Tower {
        return switch (tower_type) {
            .None => unreachable,
            .Line => Tower{
                .x = x,
                .y = y,
                .type = tower_type,
                .level = 1,
                .cooldown = 0,
                .cooldown_max = constants.TOWER_COOLDOWN_LINE,
                .range = constants.TOWER_RANGE_LINE,
                .damage = constants.TOWER_DAMAGE_LINE,
                .cost = constants.TOWER_COST_LINE,
            },
            .Triangle => Tower{
                .x = x,
                .y = y,
                .type = tower_type,
                .level = 1,
                .cooldown = 0,
                .cooldown_max = constants.TOWER_COOLDOWN_TRIANGLE,
                .range = constants.TOWER_RANGE_TRIANGLE,
                .damage = constants.TOWER_DAMAGE_TRIANGLE,
                .cost = constants.TOWER_COST_TRIANGLE,
            },
            .Square => Tower{
                .x = x,
                .y = y,
                .type = tower_type,
                .level = 1,
                .cooldown = 0,
                .cooldown_max = constants.TOWER_COOLDOWN_SQUARE,
                .range = constants.TOWER_RANGE_SQUARE,
                .damage = constants.TOWER_DAMAGE_SQUARE,
                .cost = constants.TOWER_COST_SQUARE,
            },
            .Pentagon => Tower{
                .x = x,
                .y = y,
                .type = tower_type,
                .level = 1,
                .cooldown = 0,
                .cooldown_max = constants.TOWER_COOLDOWN_PENTAGON,
                .range = constants.TOWER_RANGE_PENTAGON,
                .damage = constants.TOWER_DAMAGE_PENTAGON,
                .cost = constants.TOWER_COST_PENTAGON,
            },
        };
    }

    /// Update tower cooldown
    pub fn update(self: *Tower, delta_time: f32) void {
        if (self.cooldown > 0) {
            self.cooldown -= delta_time;
            if (self.cooldown < 0) {
                self.cooldown = 0;
            }
        }
    }

    /// Check if tower can attack
    pub fn canAttack(self: Tower) bool {
        return self.cooldown <= 0;
    }

    /// Reset cooldown after attack
    pub fn resetCooldown(self: *Tower) void {
        self.cooldown = self.cooldown_max;
    }

    /// Check if a position is in range of this tower
    pub fn isInRange(self: Tower, target_x: f32, target_y: f32) bool {
        const dx = target_x - self.x;
        const dy = target_y - self.y;
        const distance = @sqrt(dx * dx + dy * dy);
        return distance <= self.range;
    }

    /// Get the position of the tower as a Vector2
    pub fn getPosition(self: Tower) Vector2 {
        return Vector2.init(self.x, self.y);
    }

    /// Draw the tower
    pub fn draw(self: Tower) void {
        const size: f32 = 15;

        // Draw tower based on type
        switch (self.type) {
            .Line => {
                // Draw line tower (vertical and horizontal lines)
                drawLine(self.x - size, self.y, self.x + size, self.y, 2, 0, 255, 255);
                drawLine(self.x, self.y - size, self.x, self.y + size, 2, 0, 255, 255);
            },
            .Triangle => {
                // Draw triangle tower
                drawTriangle(self.x, self.y - size, self.x - size, self.y + size, self.x + size, self.y + size, 255, 0, 255, false);
            },
            .Square => {
                // Draw square tower
                drawLine(self.x - size, self.y - size, self.x + size, self.y - size, 2, 255, 255, 0);
                drawLine(self.x + size, self.y - size, self.x + size, self.y + size, 2, 255, 255, 0);
                drawLine(self.x + size, self.y + size, self.x - size, self.y + size, 2, 255, 255, 0);
                drawLine(self.x - size, self.y + size, self.x - size, self.y - size, 2, 255, 255, 0);
            },
            .Pentagon => {
                // Draw pentagon tower (simplified as a circle for now)
                drawCircle(self.x, self.y, size, 255, 0, 0, false);
            },
            .None => {},
        }
    }
};

/// Tower Manager to handle multiple towers
pub const TowerManager = struct {
    towers: [constants.MAX_TOWERS]Tower,
    count: usize,
    selected_type: TowerType,

    /// Initialize a new tower manager
    pub fn init() TowerManager {
        return TowerManager{
            .towers = undefined,
            .count = 0,
            .selected_type = TowerType.Line,
        };
    }

    /// Add a tower if placement is valid
    pub fn addTower(self: *TowerManager, x: f32, y: f32, money: *u32, path: anytype) bool {
        if (self.count >= constants.MAX_TOWERS) return false;
        if (self.selected_type == TowerType.None) return false;

        const tower = Tower.init(x, y, self.selected_type);

        // Check if we can afford it
        if (money.* < tower.cost) return false;

        // Check if tower placement is valid (not on path)
        if (path.isTooCloseToPath(x, y, constants.GRID_SIZE)) return false;

        // Check if tower placement overlaps with another tower
        for (self.towers[0..self.count]) |other| {
            const dx = other.x - x;
            const dy = other.y - y;
            const distance = @sqrt(dx * dx + dy * dy);
            if (distance < constants.GRID_SIZE) return false;
        }

        self.towers[self.count] = tower;
        self.count += 1;
        money.* -= tower.cost;

        logger.logGameEvent("Tower placed: {s} at ({d:.1}, {d:.1})", .{ @tagName(self.selected_type), x, y });
        return true;
    }

    /// Update all towers
    pub fn update(self: *TowerManager, delta_time: f32) void {
        for (self.towers[0..self.count]) |*tower| {
            tower.update(delta_time);
        }
    }

    /// Draw all towers
    pub fn draw(self: TowerManager) void {
        for (self.towers[0..self.count]) |tower| {
            tower.draw();
        }
    }

    /// Select a tower type
    pub fn selectTowerType(self: *TowerManager, tower_type: u32) void {
        self.selected_type = switch (tower_type) {
            1 => TowerType.Line,
            2 => TowerType.Triangle,
            3 => TowerType.Square,
            4 => TowerType.Pentagon,
            else => TowerType.None,
        };

        logger.logGameEvent("Selected tower: {s}", .{@tagName(self.selected_type)});
    }

    /// Get the range of the currently selected tower type
    pub fn getSelectedTowerRange(self: TowerManager) f32 {
        if (self.selected_type == TowerType.None) return 0;

        const tower = Tower.init(0, 0, self.selected_type);
        return tower.range;
    }

    /// Check if a tower can be placed at the given coordinates
    pub fn canPlaceTower(self: TowerManager, x: f32, y: f32, money: u32, path: anytype) bool {
        if (self.selected_type == TowerType.None) return false;

        // Check if we can afford it
        const tower = Tower.init(x, y, self.selected_type);
        if (money < tower.cost) return false;

        // Check if tower placement is valid (not on path)
        if (path.isTooCloseToPath(x, y, constants.GRID_SIZE)) return false;

        // Check if tower placement overlaps with another tower
        for (self.towers[0..self.count]) |other| {
            const dx = other.x - x;
            const dy = other.y - y;
            const distance = @sqrt(dx * dx + dy * dy);
            if (distance < constants.GRID_SIZE) return false;
        }

        return true;
    }
};

// External drawing functions
extern "env" fn drawLine(x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, r: u8, g: u8, b: u8) void;
extern "env" fn drawCircle(x: f32, y: f32, radius: f32, r: u8, g: u8, b: u8, fill: bool) void;
extern "env" fn drawTriangle(x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32, r: u8, g: u8, b: u8, fill: bool) void;
