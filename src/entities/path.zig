// path.zig
// Path system for enemy movement

const std = @import("std");
const constants = @import("../utils/constants.zig");
const math = @import("../utils/math.zig");
const Vector2 = math.Vector2;

/// A point on the enemy path
pub const PathPoint = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) PathPoint {
        return PathPoint{ .x = x, .y = y };
    }

    pub fn toVector2(self: PathPoint) Vector2 {
        return Vector2.init(self.x, self.y);
    }
};

/// Path system for enemy movement
pub const Path = struct {
    points: [constants.MAX_PATH_POINTS]PathPoint,
    length: usize,

    /// Initialize a default path
    pub fn init() Path {
        var path = Path{
            .points = undefined,
            .length = 0,
        };

        // Initialize default path
        path.points[0] = PathPoint.init(0, 120);
        path.points[1] = PathPoint.init(200, 120);
        path.points[2] = PathPoint.init(200, 280);
        path.points[3] = PathPoint.init(400, 280);
        path.points[4] = PathPoint.init(400, 120);
        path.points[5] = PathPoint.init(600, 120);
        path.points[6] = PathPoint.init(600, 400);
        path.points[7] = PathPoint.init(800, 400);
        path.length = 8;

        return path;
    }

    /// Add a point to the path
    pub fn addPoint(self: *Path, x: f32, y: f32) bool {
        if (self.length >= constants.MAX_PATH_POINTS) {
            return false;
        }

        self.points[self.length] = PathPoint.init(x, y);
        self.length += 1;
        return true;
    }

    /// Get a slice of the path points
    pub fn getPoints(self: Path) []const PathPoint {
        return self.points[0..self.length];
    }

    /// Check if a position is too close to the path
    pub fn isTooCloseToPath(self: Path, x: f32, y: f32, min_distance: f32) bool {
        for (self.points[0..self.length]) |point| {
            const dx = point.x - x;
            const dy = point.y - y;
            const distance = @sqrt(dx * dx + dy * dy);
            if (distance < min_distance) {
                return true;
            }
        }
        return false;
    }

    /// Draw the path
    pub fn draw(self: Path) void {
        // Draw path segments
        for (1..self.length) |i| {
            const start = self.points[i - 1];
            const end = self.points[i];
            drawLine(start.x, start.y, end.x, end.y, 20, 30, 30, 80);
        }

        // Draw path points
        for (self.points[0..self.length]) |point| {
            drawCircle(point.x, point.y, 10, 40, 40, 120, true);
        }
    }
};

// External drawing functions
extern "env" fn drawLine(x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, r: u8, g: u8, b: u8) void;
extern "env" fn drawCircle(x: f32, y: f32, radius: f32, r: u8, g: u8, b: u8, fill: bool) void;
