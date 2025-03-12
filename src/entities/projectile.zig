// projectile.zig
// Projectile definitions and logic

const std = @import("std");
const constants = @import("../utils/constants.zig");
const math = @import("../utils/math.zig");
const Vector2 = math.Vector2;
const tower_module = @import("tower.zig");
const TowerType = tower_module.TowerType;

/// Projectile structure
pub const Projectile = struct {
    x: f32,
    y: f32,
    target_x: f32,
    target_y: f32,
    speed: f32,
    damage: f32,
    active: bool,
    tower_type: TowerType,
    prev_x: f32, // Track previous position for better collision detection
    prev_y: f32,

    /// Create a new projectile
    pub fn init(x: f32, y: f32, target_x: f32, target_y: f32, damage: f32, tower_type: TowerType) Projectile {
        return Projectile{
            .x = x,
            .y = y,
            .target_x = target_x,
            .target_y = target_y,
            .speed = constants.PROJECTILE_SPEED,
            .damage = damage,
            .active = true,
            .tower_type = tower_type,
            .prev_x = x,
            .prev_y = y,
        };
    }

    /// Update projectile position
    pub fn update(self: *Projectile, delta_time: f32) bool {
        if (!self.active) return false;

        // Store previous position
        self.prev_x = self.x;
        self.prev_y = self.y;

        const dx = self.target_x - self.x;
        const dy = self.target_y - self.y;
        const distance = @sqrt(dx * dx + dy * dy);

        if (distance < 5) {
            return true; // Hit target
        }

        const move_distance = self.speed * delta_time;
        const ratio = move_distance / distance;
        self.x += dx * ratio;
        self.y += dy * ratio;

        return false;
    }

    /// Check if projectile is off screen
    pub fn isOffScreen(self: Projectile, screen_width: f32, screen_height: f32) bool {
        return self.x < -20 or self.x > screen_width + 20 or
            self.y < -20 or self.y > screen_height + 20;
    }

    /// Get the position of the projectile as a Vector2
    pub fn getPosition(self: Projectile) Vector2 {
        return Vector2.init(self.x, self.y);
    }

    /// Get the previous position of the projectile as a Vector2
    pub fn getPrevPosition(self: Projectile) Vector2 {
        return Vector2.init(self.prev_x, self.prev_y);
    }

    /// Draw the projectile
    pub fn draw(self: Projectile) void {
        if (!self.active) return;

        // Draw projectile based on tower type
        switch (self.tower_type) {
            .Line => {
                drawCircle(self.x, self.y, 3, 0, 255, 255, true);
            },
            .Triangle => {
                drawCircle(self.x, self.y, 4, 255, 0, 255, true);
            },
            .Square => {
                drawCircle(self.x, self.y, 3, 255, 255, 0, true);
            },
            .Pentagon => {
                drawCircle(self.x, self.y, 5, 255, 0, 0, true);
            },
            .None => {},
        }
    }
};

/// Projectile Manager to handle multiple projectiles
pub const ProjectileManager = struct {
    projectiles: [constants.MAX_PROJECTILES]Projectile,
    count: usize,

    /// Initialize a new projectile manager
    pub fn init() ProjectileManager {
        return ProjectileManager{
            .projectiles = undefined,
            .count = 0,
        };
    }

    /// Add a new projectile
    pub fn addProjectile(self: *ProjectileManager, x: f32, y: f32, target_x: f32, target_y: f32, damage: f32, tower_type: TowerType) bool {
        if (self.count >= constants.MAX_PROJECTILES) return false;

        self.projectiles[self.count] = Projectile.init(x, y, target_x, target_y, damage, tower_type);
        self.count += 1;
        return true;
    }

    /// Update all projectiles
    pub fn update(self: *ProjectileManager, delta_time: f32, screen_width: f32, screen_height: f32) void {
        var i: usize = 0;
        while (i < self.count) {
            const hit = self.projectiles[i].update(delta_time);

            // Remove projectile if it hit its target or is off screen
            if (hit or self.projectiles[i].isOffScreen(screen_width, screen_height)) {
                self.projectiles[i] = self.projectiles[self.count - 1];
                self.count -= 1;
            } else {
                i += 1;
            }
        }
    }

    /// Draw all projectiles
    pub fn draw(self: ProjectileManager) void {
        for (self.projectiles[0..self.count]) |projectile| {
            projectile.draw();
        }
    }

    /// Check for collision with enemies
    pub fn checkCollisions(self: *ProjectileManager, enemy_manager: anytype, money: *u32) void {
        var i: usize = 0;
        while (i < self.count) {
            var hit_enemy = false;

            // Check for collision with enemies
            var j: usize = 0;
            while (j < enemy_manager.count) {
                const enemy = &enemy_manager.enemies[j];
                if (!enemy.active) {
                    j += 1;
                    continue;
                }

                // Check if projectile is close to enemy
                const dx = enemy.x - self.projectiles[i].x;
                const dy = enemy.y - self.projectiles[i].y;
                const distance = @sqrt(dx * dx + dy * dy);

                // Also check if projectile crossed over the enemy between frames
                const prev_dx = enemy.x - self.projectiles[i].prev_x;
                const prev_dy = enemy.y - self.projectiles[i].prev_y;
                const prev_distance = @sqrt(prev_dx * prev_dx + prev_dy * prev_dy);

                // If projectile is within enemy radius or crossed over enemy between frames
                if (distance < enemy.radius or
                    (distance < enemy.radius * 2 and prev_distance < enemy.radius * 2 and
                    distance + prev_distance < @sqrt((self.projectiles[i].x - self.projectiles[i].prev_x) * (self.projectiles[i].x - self.projectiles[i].prev_x) +
                    (self.projectiles[i].y - self.projectiles[i].prev_y) * (self.projectiles[i].y - self.projectiles[i].prev_y)) * 1.5))
                {
                    // Apply damage based on tower type
                    const damage = self.projectiles[i].damage;

                    // Triangle towers do area damage
                    if (self.projectiles[i].tower_type == TowerType.Triangle) {
                        // Apply area damage to all enemies within range
                        _ = enemy_manager.applyAreaDamage(self.projectiles[i].target_x, self.projectiles[i].target_y, constants.SPLASH_RADIUS, damage, money);
                    } else if (self.projectiles[i].tower_type == TowerType.Square) {
                        // Square towers slow enemies
                        enemy.speed *= constants.SLOW_EFFECT;
                        _ = enemy_manager.damageEnemy(j, damage, money);
                    } else {
                        // Normal damage for other tower types
                        _ = enemy_manager.damageEnemy(j, damage, money);
                    }

                    hit_enemy = true;
                    break;
                }
                j += 1;
            }

            // Remove projectile if it hit an enemy
            if (hit_enemy) {
                self.projectiles[i] = self.projectiles[self.count - 1];
                self.count -= 1;
            } else {
                i += 1;
            }
        }
    }
};

// External drawing functions
extern "env" fn drawCircle(x: f32, y: f32, radius: f32, r: u8, g: u8, b: u8, fill: bool) void;
