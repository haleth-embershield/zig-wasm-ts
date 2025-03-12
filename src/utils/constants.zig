// constants.zig
// Game constants and configuration settings

// Grid and map constants
pub const GRID_SIZE: f32 = 40;
pub const GRID_COLS: u32 = 20;
pub const GRID_ROWS: u32 = 15;

// Tower costs
pub const TOWER_COST_LINE: u32 = 50;
pub const TOWER_COST_TRIANGLE: u32 = 100;
pub const TOWER_COST_SQUARE: u32 = 75;
pub const TOWER_COST_PENTAGON: u32 = 150;

// Tower ranges
pub const TOWER_RANGE_LINE: f32 = 150;
pub const TOWER_RANGE_TRIANGLE: f32 = 100;
pub const TOWER_RANGE_SQUARE: f32 = 120;
pub const TOWER_RANGE_PENTAGON: f32 = 200;

// Tower damage values
pub const TOWER_DAMAGE_LINE: f32 = 10;
pub const TOWER_DAMAGE_TRIANGLE: f32 = 15;
pub const TOWER_DAMAGE_SQUARE: f32 = 5;
pub const TOWER_DAMAGE_PENTAGON: f32 = 30;

// Tower cooldown times
pub const TOWER_COOLDOWN_LINE: f32 = 0.5;
pub const TOWER_COOLDOWN_TRIANGLE: f32 = 1.0;
pub const TOWER_COOLDOWN_SQUARE: f32 = 0.8;
pub const TOWER_COOLDOWN_PENTAGON: f32 = 1.5;

// Game settings
pub const INITIAL_MONEY: u32 = 250;
pub const INITIAL_LIVES: u32 = 20;
pub const WAVE_COOLDOWN: f32 = 5.0;
pub const ENEMY_SPAWN_INTERVAL: f32 = 1.0;

// Enemy settings
pub const ENEMY_BASE_HEALTH: f32 = 20.0;
pub const ENEMY_HEALTH_SCALING: f32 = 5.0;
pub const ENEMY_BASE_SPEED: f32 = 50.0;
pub const ENEMY_SPEED_SCALING: f32 = 2.0;
pub const ENEMY_BASE_VALUE: u32 = 5;
pub const ENEMY_RADIUS: f32 = 15;
pub const ENEMY_HIT_FLASH_DURATION: f32 = 0.2;

// Projectile settings
pub const PROJECTILE_SPEED: f32 = 300;
pub const SPLASH_RADIUS: f32 = 50.0;
pub const SLOW_EFFECT: f32 = 0.8;

// Array size limits
pub const MAX_TOWERS: usize = 100;
pub const MAX_ENEMIES: usize = 100;
pub const MAX_PROJECTILES: usize = 200;
pub const MAX_PATH_POINTS: usize = 20;
