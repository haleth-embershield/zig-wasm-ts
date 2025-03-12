// math.zig
// Math utilities for game calculations

const std = @import("std");

/// Vector2 structure for 2D positions and directions
pub const Vector2 = struct {
    x: f32,
    y: f32,

    /// Create a new Vector2
    pub fn init(x: f32, y: f32) Vector2 {
        return Vector2{ .x = x, .y = y };
    }

    /// Add two vectors
    pub fn add(self: Vector2, other: Vector2) Vector2 {
        return Vector2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    /// Subtract other vector from this one
    pub fn sub(self: Vector2, other: Vector2) Vector2 {
        return Vector2{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    /// Multiply vector by scalar
    pub fn scale(self: Vector2, scalar: f32) Vector2 {
        return Vector2{
            .x = self.x * scalar,
            .y = self.y * scalar,
        };
    }

    /// Calculate distance between two vectors
    pub fn distance(self: Vector2, other: Vector2) f32 {
        const dx = other.x - self.x;
        const dy = other.y - self.y;
        return @sqrt(dx * dx + dy * dy);
    }

    /// Calculate squared distance (faster than distance when only comparing)
    pub fn distanceSquared(self: Vector2, other: Vector2) f32 {
        const dx = other.x - self.x;
        const dy = other.y - self.y;
        return dx * dx + dy * dy;
    }

    /// Calculate magnitude (length) of vector
    pub fn magnitude(self: Vector2) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    /// Normalize vector (make it length 1)
    pub fn normalize(self: Vector2) Vector2 {
        const mag = self.magnitude();
        if (mag == 0) return self;
        return Vector2{
            .x = self.x / mag,
            .y = self.y / mag,
        };
    }

    /// Linear interpolation between two vectors
    pub fn lerp(self: Vector2, other: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = self.x + (other.x - self.x) * t,
            .y = self.y + (other.y - self.y) * t,
        };
    }
};

/// Check if a point is inside a circle
pub fn pointInCircle(point_x: f32, point_y: f32, circle_x: f32, circle_y: f32, radius: f32) bool {
    const dx = point_x - circle_x;
    const dy = point_y - circle_y;
    return (dx * dx + dy * dy) <= (radius * radius);
}

/// Check if two circles overlap
pub fn circlesOverlap(x1: f32, y1: f32, r1: f32, x2: f32, y2: f32, r2: f32) bool {
    const dx = x1 - x2;
    const dy = y1 - y2;
    const distance_squared = dx * dx + dy * dy;
    const radius_sum = r1 + r2;
    return distance_squared <= (radius_sum * radius_sum);
}

/// Check if a line segment intersects a circle
pub fn lineCircleIntersection(line_start_x: f32, line_start_y: f32, line_end_x: f32, line_end_y: f32, circle_x: f32, circle_y: f32, radius: f32) bool {
    // Vector from line start to end
    const line_vec_x = line_end_x - line_start_x;
    const line_vec_y = line_end_y - line_start_y;

    // Vector from line start to circle center
    const circle_vec_x = circle_x - line_start_x;
    const circle_vec_y = circle_y - line_start_y;

    // Length of line segment squared
    const line_length_squared = line_vec_x * line_vec_x + line_vec_y * line_vec_y;

    // Dot product of the two vectors
    const dot_product = circle_vec_x * line_vec_x + circle_vec_y * line_vec_y;

    // Projection of circle center onto line
    const projection = if (line_length_squared == 0) 0 else dot_product / line_length_squared;

    // Find closest point on line segment to circle center
    var closest_x: f32 = undefined;
    var closest_y: f32 = undefined;

    if (projection <= 0) {
        // Closest point is line start
        closest_x = line_start_x;
        closest_y = line_start_y;
    } else if (projection >= 1) {
        // Closest point is line end
        closest_x = line_end_x;
        closest_y = line_end_y;
    } else {
        // Closest point is on the line segment
        closest_x = line_start_x + projection * line_vec_x;
        closest_y = line_start_y + projection * line_vec_y;
    }

    // Check if closest point is within circle radius
    const dx = closest_x - circle_x;
    const dy = closest_y - circle_y;
    const distance_squared = dx * dx + dy * dy;

    return distance_squared <= (radius * radius);
}

/// Snap a position to grid
pub fn snapToGrid(x: f32, y: f32, grid_size: f32) Vector2 {
    const grid_x = @floor(x / grid_size) * grid_size + grid_size / 2;
    const grid_y = @floor(y / grid_size) * grid_size + grid_size / 2;
    return Vector2.init(grid_x, grid_y);
}
