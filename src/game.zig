// game.zig
// Game state and main loop

const std = @import("std");
const constants = @import("utils/constants.zig");
const logger = @import("utils/logger.zig");
const math = @import("utils/math.zig");
const Vector2 = math.Vector2;

const tower_module = @import("entities/tower.zig");
const Tower = tower_module.Tower;
const TowerManager = tower_module.TowerManager;
const TowerType = tower_module.TowerType;

const enemy_module = @import("entities/enemy.zig");
const Enemy = enemy_module.Enemy;
const EnemyManager = enemy_module.EnemyManager;

const projectile_module = @import("entities/projectile.zig");
const Projectile = projectile_module.Projectile;
const ProjectileManager = projectile_module.ProjectileManager;

const path_module = @import("entities/path.zig");
const Path = path_module.Path;
const PathPoint = path_module.PathPoint;

const renderer_module = @import("rendering/renderer.zig");
const Renderer = renderer_module.Renderer;

const ui_module = @import("rendering/ui.zig");
const UIManager = ui_module.UIManager;
const GameState = ui_module.GameState;

// Audio functions
extern "env" fn playLevelCompleteSound() void;
extern "env" fn playLevelFailSound() void;
extern "env" fn playTowerShootSound() void;

/// Game class to manage the game state and main loop
pub const Game = struct {
    state: GameState,
    tower_manager: TowerManager,
    enemy_manager: EnemyManager,
    projectile_manager: ProjectileManager,
    path: Path,
    money: u32,
    lives: u32,
    wave_timer: f32,
    renderer: Renderer,
    ui_manager: UIManager,
    canvas_width: f32,
    canvas_height: f32,

    /// Initialize a new game
    pub fn init(width: f32, height: f32) Game {
        const renderer = Renderer.init(width, height);

        var game = Game{
            .state = GameState.Menu,
            .tower_manager = TowerManager.init(),
            .enemy_manager = EnemyManager.init(),
            .projectile_manager = ProjectileManager.init(),
            .path = Path.init(),
            .money = constants.INITIAL_MONEY,
            .lives = constants.INITIAL_LIVES,
            .wave_timer = 0,
            .renderer = renderer,
            .ui_manager = undefined,
            .canvas_width = width,
            .canvas_height = height,
        };

        game.ui_manager = UIManager.init(&game.renderer);

        logger.log("Game initialized");
        return game;
    }

    /// Reset the game to initial state
    pub fn reset(self: *Game) void {
        self.state = GameState.Playing;
        self.tower_manager = TowerManager.init();
        self.enemy_manager = EnemyManager.init();
        self.projectile_manager = ProjectileManager.init();
        self.path = Path.init();
        self.money = constants.INITIAL_MONEY;
        self.lives = constants.INITIAL_LIVES;
        self.wave_timer = 0;

        logger.log("Game reset");
    }

    /// Update the game state for one frame
    pub fn update(self: *Game, delta_time: f32) void {
        switch (self.state) {
            .Menu => self.ui_manager.drawMenu(),
            .Playing => self.updatePlaying(delta_time),
            .Paused => {
                self.updatePlaying(0); // Draw but don't update
                self.ui_manager.drawPaused();
            },
            .GameOver => {
                self.updatePlaying(0); // Draw but don't update
                self.ui_manager.drawGameOver();
            },
        }
    }

    /// Update the game when in playing state
    fn updatePlaying(self: *Game, delta_time: f32) void {
        // Clear the canvas
        self.renderer.clear();

        // Draw grid and path
        self.renderer.drawGrid();
        self.path.draw();

        // Update wave timer and check for new wave
        if (self.enemy_manager.allEnemiesDefeated()) {
            // If this is the first frame after all enemies are defeated, play level complete sound
            if (self.wave_timer == 0 and self.enemy_manager.wave > 0) {
                playLevelCompleteSound();
            }

            self.wave_timer += delta_time;

            // Start next wave after cooldown
            if (self.wave_timer >= constants.WAVE_COOLDOWN) {
                logger.log("Starting next wave!");
                self.wave_timer = 0;
                self.enemy_manager.startWave();
            }
        }

        // Update game entities
        self.tower_manager.update(delta_time);
        self.enemy_manager.update(delta_time, &self.path, &self.lives);
        self.projectile_manager.update(delta_time, self.canvas_width, self.canvas_height);

        // Check for tower targeting and shooting
        self.updateTowerTargeting();

        // Check for projectile collisions
        self.projectile_manager.checkCollisions(&self.enemy_manager, &self.money);

        // Check for game over
        if (self.lives == 0) {
            self.state = GameState.GameOver;
            logger.log("Game Over!");
            playLevelFailSound();
        }

        // Draw game entities
        self.tower_manager.draw();
        self.enemy_manager.draw();
        self.projectile_manager.draw();

        // Draw UI
        self.ui_manager.drawUI(self.money, self.lives, self.enemy_manager.wave, self.tower_manager.selected_type);

        // Draw wave timer if between waves
        if (self.enemy_manager.allEnemiesDefeated()) {
            self.ui_manager.drawWaveTimer(self.wave_timer);
        }
    }

    /// Update tower targeting and shooting
    fn updateTowerTargeting(self: *Game) void {
        for (self.tower_manager.towers[0..self.tower_manager.count]) |*tower| {
            if (tower.canAttack()) {
                var closest_enemy: ?*Enemy = null;
                var closest_distance: f32 = tower.range;

                for (self.enemy_manager.enemies[0..self.enemy_manager.count]) |*enemy| {
                    if (!enemy.active) continue;

                    const dx = enemy.x - tower.x;
                    const dy = enemy.y - tower.y;
                    const distance = @sqrt(dx * dx + dy * dy);

                    if (distance < closest_distance) {
                        closest_enemy = enemy;
                        closest_distance = distance;
                    }
                }

                if (closest_enemy) |enemy| {
                    // Create projectile
                    _ = self.projectile_manager.addProjectile(tower.x, tower.y, enemy.x, enemy.y, tower.damage, tower.type);
                    tower.resetCooldown();

                    // Play tower shoot sound
                    playTowerShootSound();
                }
            }
        }
    }

    /// Handle mouse click
    pub fn handleClick(self: *Game, x: f32, y: f32) void {
        switch (self.state) {
            .Menu => {
                // Start game if in menu
                self.state = GameState.Playing;
            },
            .Paused => {
                // Resume game if paused
                self.state = GameState.Playing;
            },
            .GameOver => {
                // Reset game if game over
                self.reset();
            },
            .Playing => {
                // Handle tower placement
                if (self.tower_manager.selected_type != TowerType.None) {
                    // Snap to grid
                    const grid_pos = math.snapToGrid(x, y, constants.GRID_SIZE);

                    if (self.tower_manager.addTower(grid_pos.x, grid_pos.y, &self.money, &self.path)) {
                        logger.log("Tower placed");
                    } else {
                        logger.log("Cannot place tower here");
                    }
                }
            },
        }
    }

    /// Toggle pause state
    pub fn togglePause(self: *Game) void {
        if (self.state == GameState.Playing) {
            self.state = GameState.Paused;
            logger.log("Game paused");
        } else if (self.state == GameState.Paused) {
            self.state = GameState.Playing;
            logger.log("Game resumed");
        }
    }

    /// Select tower type
    pub fn selectTowerType(self: *Game, tower_type: u32) void {
        self.tower_manager.selectTowerType(tower_type);
    }

    /// Check if a tower can be placed at the given coordinates
    pub fn canPlaceTower(self: Game, x: f32, y: f32) bool {
        return self.tower_manager.canPlaceTower(x, y, self.money, &self.path);
    }

    /// Get the range of the currently selected tower type
    pub fn getSelectedTowerRange(self: Game) f32 {
        return self.tower_manager.getSelectedTowerRange();
    }
};
