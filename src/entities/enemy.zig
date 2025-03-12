// enemy.zig
// Enemy definitions and logic

const std = @import("std");
const constants = @import("../utils/constants.zig");
const math = @import("../utils/math.zig");
const Vector2 = math.Vector2;
const path_module = @import("path.zig");
const PathPoint = path_module.PathPoint;

// Audio functions
extern "env" fn playEnemyHitSound() void;
extern "env" fn playEnemyExplosionSound() void;

/// Enemy structure
pub const Enemy = struct {
    x: f32,
    y: f32,
    radius: f32,
    health: f32,
    max_health: f32,
    speed: f32,
    value: u32,
    active: bool,
    path_index: usize,
    hit_flash: f32, // Visual indicator when enemy is hit

    /// Create a new enemy
    pub fn init(x: f32, y: f32, health: f32, speed: f32, value: u32) Enemy {
        return Enemy{
            .x = x,
            .y = y,
            .radius = constants.ENEMY_RADIUS,
            .health = health,
            .max_health = health,
            .speed = speed,
            .value = value,
            .active = true,
            .path_index = 0,
            .hit_flash = 0,
        };
    }

    /// Update enemy position along path
    pub fn update(self: *Enemy, delta_time: f32, path: []const PathPoint) bool {
        if (!self.active) return false;

        // Update hit flash effect
        if (self.hit_flash > 0) {
            self.hit_flash -= delta_time;
            if (self.hit_flash < 0) self.hit_flash = 0;
        }

        if (self.path_index >= path.len) {
            return true; // Reached end of path
        }

        const target = path[self.path_index];
        const dx = target.x - self.x;
        const dy = target.y - self.y;
        const distance = @sqrt(dx * dx + dy * dy);

        if (distance < 5) {
            // Reached waypoint, move to next
            self.path_index += 1;
            if (self.path_index >= path.len) {
                return true; // Reached end of path
            }
        } else {
            // Move toward waypoint
            const move_distance = self.speed * delta_time;
            const ratio = move_distance / distance;
            self.x += dx * ratio;
            self.y += dy * ratio;
        }

        return false;
    }

    /// Take damage and check if dead
    pub fn takeDamage(self: *Enemy, amount: f32) bool {
        self.health -= amount;
        self.hit_flash = constants.ENEMY_HIT_FLASH_DURATION;

        // Play enemy hit sound
        playEnemyHitSound();

        return self.health <= 0;
    }

    /// Get the position of the enemy as a Vector2
    pub fn getPosition(self: Enemy) Vector2 {
        return Vector2.init(self.x, self.y);
    }

    /// Draw the enemy
    pub fn draw(self: Enemy) void {
        if (!self.active) return;

        // Draw enemy circle - flash white when hit
        if (self.hit_flash > 0) {
            // Flash white when hit
            const flash_intensity = @as(u8, @intFromFloat(255.0 * (self.hit_flash / constants.ENEMY_HIT_FLASH_DURATION)));
            drawCircle(self.x, self.y, self.radius, 255, flash_intensity, flash_intensity, true);
        } else {
            // Normal red color
            drawCircle(self.x, self.y, self.radius, 255, 0, 0, true);
        }

        // Draw health bar background (black)
        const health_bar_width = self.radius * 2.0;
        const health_bar_height = 5.0;
        const health_x = self.x - self.radius;
        const health_y = self.y - self.radius - 10;
        drawRect(health_x, health_y, health_bar_width, health_bar_height, 0, 0, 0);

        // Draw health bar (green to red gradient based on health percentage)
        const health_percent = self.health / self.max_health;
        const health_width = health_bar_width * health_percent;

        // Color shifts from green to red as health decreases
        const r: u8 = @intFromFloat(255.0 * (1.0 - health_percent));
        const g: u8 = @intFromFloat(255.0 * health_percent);

        drawRect(health_x, health_y, health_width, health_bar_height, r, g, 0);

        // Draw health bar border
        drawLine(health_x, health_y, health_x + health_bar_width, health_y, 1, 255, 255, 255);
        drawLine(health_x + health_bar_width, health_y, health_x + health_bar_width, health_y + health_bar_height, 1, 255, 255, 255);
        drawLine(health_x + health_bar_width, health_y + health_bar_height, health_x, health_y + health_bar_height, 1, 255, 255, 255);
        drawLine(health_x, health_y + health_bar_height, health_x, health_y, 1, 255, 255, 255);
    }
};

/// Enemy Manager to handle multiple enemies
pub const EnemyManager = struct {
    enemies: [constants.MAX_ENEMIES]Enemy,
    count: usize,
    enemies_to_spawn: u32,
    spawn_timer: f32,
    wave: u32,

    /// Initialize a new enemy manager
    pub fn init() EnemyManager {
        return EnemyManager{
            .enemies = undefined,
            .count = 0,
            .enemies_to_spawn = 0,
            .spawn_timer = 0,
            .wave = 0,
        };
    }

    /// Start a new wave
    pub fn startWave(self: *EnemyManager) void {
        self.wave += 1;
        self.enemies_to_spawn = 5 + self.wave * 2;
        self.spawn_timer = 0;
    }

    /// Spawn a new enemy
    pub fn spawnEnemy(self: *EnemyManager, path: anytype) bool {
        if (self.count >= constants.MAX_ENEMIES) return false;
        if (self.enemies_to_spawn == 0) return false;

        const health = constants.ENEMY_BASE_HEALTH + @as(f32, @floatFromInt(self.wave)) * constants.ENEMY_HEALTH_SCALING;
        const speed = constants.ENEMY_BASE_SPEED + @as(f32, @floatFromInt(self.wave)) * constants.ENEMY_SPEED_SCALING;
        const value = constants.ENEMY_BASE_VALUE + self.wave;

        // Get the first point on the path
        const path_points = path.getPoints();
        if (path_points.len == 0) return false;

        const start_point = path_points[0];
        self.enemies[self.count] = Enemy.init(start_point.x, start_point.y, health, speed, value);
        self.count += 1;
        self.enemies_to_spawn -= 1;
        return true;
    }

    /// Update all enemies
    pub fn update(self: *EnemyManager, delta_time: f32, path: anytype, lives: *u32) void {
        // Update spawn timer
        if (self.enemies_to_spawn > 0) {
            self.spawn_timer += delta_time;
            if (self.spawn_timer > constants.ENEMY_SPAWN_INTERVAL) {
                self.spawn_timer = 0;
                _ = self.spawnEnemy(path);
            }
        }

        // Update existing enemies
        var i: usize = 0;
        while (i < self.count) {
            const reached_end = self.enemies[i].update(delta_time, path.getPoints());

            if (reached_end) {
                // Enemy reached the end, lose a life
                if (lives.* > 0) {
                    lives.* -= 1;
                }

                // Remove enemy
                self.enemies[i] = self.enemies[self.count - 1];
                self.count -= 1;
            } else {
                i += 1;
            }
        }
    }

    /// Draw all enemies
    pub fn draw(self: EnemyManager) void {
        for (self.enemies[0..self.count]) |enemy| {
            enemy.draw();
        }
    }

    /// Apply damage to an enemy
    pub fn damageEnemy(self: *EnemyManager, index: usize, damage: f32, money: *u32) bool {
        if (index >= self.count) return false;

        const killed = self.enemies[index].takeDamage(damage);
        if (killed) {
            // Play explosion sound
            playEnemyExplosionSound();

            // Add money for kill
            money.* += self.enemies[index].value;

            // Remove enemy
            self.enemies[index] = self.enemies[self.count - 1];
            self.count -= 1;
            return true;
        }
        return false;
    }

    /// Apply area damage to enemies within a radius
    pub fn applyAreaDamage(self: *EnemyManager, center_x: f32, center_y: f32, radius: f32, damage: f32, money: *u32) u32 {
        var enemies_hit: u32 = 0;
        var i: usize = 0;
        while (i < self.count) {
            const enemy = &self.enemies[i];
            const dx = enemy.x - center_x;
            const dy = enemy.y - center_y;
            const distance = @sqrt(dx * dx + dy * dy);

            if (distance < radius) {
                // Calculate damage based on distance from center (more damage at center)
                const scaled_damage = damage * (1.0 - distance / radius);
                const killed = enemy.takeDamage(scaled_damage);
                enemies_hit += 1;

                if (killed) {
                    // Play explosion sound
                    playEnemyExplosionSound();

                    // Add money for kill
                    money.* += enemy.value;

                    // Remove enemy
                    self.enemies[i] = self.enemies[self.count - 1];
                    self.count -= 1;
                    // Don't increment i since we've replaced this enemy
                } else {
                    i += 1;
                }
            } else {
                i += 1;
            }
        }
        return enemies_hit;
    }

    /// Apply slowing effect to an enemy
    pub fn slowEnemy(self: *EnemyManager, index: usize, slow_factor: f32) bool {
        if (index >= self.count) return false;

        self.enemies[index].speed *= slow_factor;
        return true;
    }

    /// Check if all enemies are defeated
    pub fn allEnemiesDefeated(self: EnemyManager) bool {
        return self.count == 0 and self.enemies_to_spawn == 0;
    }
};

// External drawing functions
extern "env" fn drawCircle(x: f32, y: f32, radius: f32, r: u8, g: u8, b: u8, fill: bool) void;
extern "env" fn drawRect(x: f32, y: f32, width: f32, height: f32, r: u8, g: u8, b: u8) void;
extern "env" fn drawLine(x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, r: u8, g: u8, b: u8) void;
