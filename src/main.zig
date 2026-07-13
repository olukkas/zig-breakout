const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 800;
const SCREEN_SIZE = 320;

const Paddle = struct {
    const WIDTH = 50;
    const HEIGHT = 6;
    const POSITION_Y = 260;
    const COLOR: rl.Color = .init(50, 150, 90, 255);
    const SPEED = 200;

    position_x: f32 = 0,
    move_velocity: f32 = 0,

    pub fn handle_movement(self: *Paddle, delta: f32) void {
        // resets each frame so it doesnot accumulate.
        self.move_velocity = 0;

        if (rl.isKeyDown(.left)) {
            self.move_velocity -= SPEED;
        }

        if (rl.isKeyDown(.right)) {
            self.move_velocity += SPEED;
        }

        self.position_x += self.move_velocity * delta;
        self.position_x = std.math.clamp(self.position_x, 0, SCREEN_SIZE - WIDTH);
    }
};

const Ball = struct {
    const SPEED = 260;
    const RADIUS = 4;
    const START_Y = 160;
    const COLOR: rl.Color = .init(200, 90, 20, 255);

    position: rl.Vector2 = .zero(),
    direction: rl.Vector2 = .zero(),

    pub fn dropTowardsPaddle(self: *Ball, paddle: *const Paddle) void {
        const paddle_middle = rl.Vector2{ .x = paddle.position_x + Paddle.WIDTH / 2, .y = Paddle.POSITION_Y };
        const ball_to_paddle = paddle_middle.subtract(self.position);
        self.direction = ball_to_paddle.normalize();
    }

    pub fn reflectWithPaddleOnCollision(self: *Ball, paddle: *const rl.Rectangle) void {
        // early return if no collision has happend.
        if (!rl.checkCollisionCircleRec(self.position, RADIUS, paddle.*)) return;

        var collision_normal: rl.Vector2 = .zero();

        if (self.position.y < paddle.y + paddle.height) {
            collision_normal = collision_normal.add(.init(0, -1));
            self.position.y = paddle.y - RADIUS;
        }

        if (self.position.y > paddle.y + paddle.height) {
            collision_normal = collision_normal.add(.init(0, 1));
            self.position.y = paddle.y + paddle.height + RADIUS;
        }

        if (self.position.x < paddle.x) {
            collision_normal = collision_normal.add(.init(-1, 0));
        }

        if (self.position.x > paddle.x + paddle.width) {
            collision_normal = collision_normal.add(.init(1, 0));
        }

        if (collision_normal.x != 0 or collision_normal.y != 0) {
            self.direction = reflect(self.direction, collision_normal);
        }
    }

    pub fn reflectOnCollisionWithBlocks(self: *Ball, wall: *BlockWall) void {
        outer: for (0..BlockWall.BLOCK_NUM_X - 1) |x| {
            for (0..BlockWall.BLOCK_NUM_Y - 1) |y| {
                if (!wall.blocks[x][y]) {
                    continue;
                }

                const block_rect = rl.Rectangle{
                    .x = @floatFromInt(20 + x * BlockWall.BLOCK_WIDTH),
                    .y = @floatFromInt(40 + y * BlockWall.BLOCK_HEIGHT),
                    .width = BlockWall.BLOCK_WIDTH,
                    .height = BlockWall.BLOCK_HEIGHT,
                };

                if (rl.checkCollisionCircleRec(self.position, Ball.RADIUS, block_rect)) {
                    var collision_normal: rl.Vector2 = .zero();

                    if (self.position.y < block_rect.y) {
                        collision_normal = collision_normal.add(.init(0, -1));
                    }

                    if (self.position.y > block_rect.y + block_rect.height) {
                        collision_normal = collision_normal.add(.init(0, 1));
                    }

                    if (self.position.x > block_rect.x + block_rect.width) {
                        collision_normal = collision_normal.add(.init(1, 0));
                    }

                    const x_normal: usize = @trunc(@abs(collision_normal.x));
                    const y_normal: usize = @trunc(@abs(collision_normal.y));
                    
                    if (wall.blockExists(x + x_normal, y)) {
                        collision_normal.x = 0;
                    }

                    if (wall.blockExists(x, y + y_normal)) {
                        collision_normal.y = 0;
                    }

                    if (collision_normal.x != 0 or collision_normal.y != 0) {
                        self.direction = reflect(self.direction, collision_normal);
                    }

                    wall.blocks[x][y] = false;
                    const row_color = BlockWall.ROW_COLORS[y];
                    score += BlockWall.COLOR_SCORE.get(row_color);
                    break :outer;
                }
            }
        }
    }

    pub fn reflectOnWallsWhenCollision(self: *Ball, dt: f32) void {
        self.position.x = self.position.x + (self.direction.x * SPEED * dt);
        self.position.y = self.position.y + (self.direction.y * SPEED * dt);

        const hits_right_wall = self.position.x + RADIUS > SCREEN_SIZE;
        if (hits_right_wall) {
            self.position.x = SCREEN_SIZE - RADIUS;
            self.direction = reflect(self.direction, .init(-1, 0));
        }

        const hits_left_wall = self.position.x - RADIUS < 0;
        if (hits_left_wall) {
            self.position.x = RADIUS;
            self.direction = reflect(self.direction, .init(1, 0));
        }

        const hits_top_wall = self.position.y - RADIUS < 0;
        if (hits_top_wall) {
            self.position.y = RADIUS;
            self.direction = reflect(self.direction, .init(0, 1));
        }

         const hits_bottom_wall = self.position.y > SCREEN_SIZE + RADIUS * 10;
        if (hits_bottom_wall and !game_over) {
            game_over = true;
        }
    }
};

const BlockWall = struct {
    const BLOCK_NUM_X = 10;
    const BLOCK_NUM_Y = 8;
    const BLOCK_WIDTH = 28;
    const BLOCK_HEIGHT = 10;

    const COLOR_VALUES: std.enums.EnumArray(Color, rl.Color) = .init(.{
        .Yellow = rl.Color{ .r = 253, .g = 249, .b = 150, .a = 255 },
        .Green = rl.Color{ .r = 180, .g = 254, .b = 190, .a = 255 },
        .Purple = rl.Color{ .r = 170, .g = 120, .b = 250, .a = 255 },
        .Red = rl.Color{ .r = 250, .g = 90, .b = 82, .a = 255 },
    });

    const COLOR_SCORE = std.enums.EnumArray(Color, i32).init(.{
        .Yellow = 2,
        .Green = 4,
        .Purple = 6,
        .Red = 8,
    });

    const ROW_COLORS: [BLOCK_NUM_Y]Color = .{
        .Red,
        .Red,
        .Purple,
        .Purple,
        .Green,
        .Green,
        .Yellow,
        .Yellow,
    };

    pub const Color = enum { Yellow, Green, Purple, Red };

    blocks: [BLOCK_NUM_X][BLOCK_NUM_Y]bool,

    pub fn init() BlockWall {
        const rows: [BLOCK_NUM_Y]bool = .{false} ** BLOCK_NUM_Y;
        const blocks: [BLOCK_NUM_X][BLOCK_NUM_Y]bool = .{rows} ** BLOCK_NUM_X;
        return .{ .blocks = blocks };
    }

    pub fn initAllBlocks(self: *BlockWall) void {
        for (0..BLOCK_NUM_X) |x| {
            for (0..BLOCK_NUM_Y) |y| {
                self.blocks[x][y] = true;
            }
        }
    }

    pub fn blockExists(self: *BlockWall, x: usize, y: usize) bool {
        if (x < 0 or y < 0 or x > BLOCK_NUM_X or y > BLOCK_NUM_Y) return false;
        return self.blocks[x][y];
    }
};

var started: bool = undefined;
var game_over: bool = undefined;
var score: i32 = 0;

fn restart(paddle: *Paddle, ball: *Ball, blocks: *BlockWall) void {
    paddle.position_x = SCREEN_SIZE / 2 - Paddle.WIDTH / 2;
    ball.position = .init(SCREEN_SIZE / 2, Ball.START_Y);
    started = false;
    game_over = false;
    score = 0;
    blocks.initAllBlocks();
}

fn reflect(dir: rl.Vector2, normal: rl.Vector2) rl.Vector2 {
    const new_dir: rl.Vector2 = dir.reflect(normal.normalize());
    return new_dir.normalize();
}

fn drawBlocks(wall: *BlockWall) void {
    for (0..BlockWall.BLOCK_NUM_X - 1) |x| {
        for (0..BlockWall.BLOCK_NUM_Y - 1) |y| {
            if (!wall.blocks[x][y]) {
                continue;
            }

            const block_rect = rl.Rectangle{
                .x = @floatFromInt(20 + x * BlockWall.BLOCK_WIDTH),
                .y = @floatFromInt(40 + y * BlockWall.BLOCK_HEIGHT),
                .width = BlockWall.BLOCK_WIDTH,
                .height = BlockWall.BLOCK_HEIGHT,
            };

            const top_left: rl.Vector2 = .init(block_rect.x, block_rect.y);
            const top_right: rl.Vector2 = .init(block_rect.x + block_rect.width, block_rect.y);
            const bottom_left: rl.Vector2 = .init(block_rect.x, block_rect.y + block_rect.height);
            const bottom_right: rl.Vector2 = .init(block_rect.x + block_rect.width, block_rect.y + block_rect.height);

            const color = BlockWall.COLOR_VALUES.get(BlockWall.ROW_COLORS[y]);
            rl.drawRectangleRec(block_rect, color);
            rl.drawLineEx(top_left, top_right, 1, .init(255, 255, 150, 100));
            rl.drawLineEx(bottom_left, bottom_right, 1, .init(255, 255, 150, 100));
            rl.drawLineEx(top_right, bottom_right, 1, .init(0, 0, 50, 100));
            rl.drawLineEx(bottom_left, bottom_right, 1, .init(0, 0, 50, 100));
        }
    }
}

pub fn main(_: std.process.Init) !void {
    rl.setConfigFlags(.{ .vsync_hint = true });

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "breakout");
    defer rl.closeWindow();

    rl.setTargetFPS(120);

    var paddle = Paddle{};
    var ball = Ball{};
    var block_wall = BlockWall.init();

    restart(&paddle, &ball, &block_wall);

    while (!rl.windowShouldClose()) {
        var dt: f32 = 0;
        if (!started) {
            const cos: f32 = @floatCast(std.math.cos(rl.getTime()) * SCREEN_SIZE / 2.5);
            ball.position.x = (SCREEN_SIZE / 2) + cos;

            if (rl.isKeyPressed(.space)) {
                ball.dropTowardsPaddle(&paddle);
                started = true;
            }
        } else {
            dt = rl.getFrameTime();
        }

        ball.reflectOnWallsWhenCollision(dt);
        paddle.handle_movement(dt);

        const paddle_rect = rl.Rectangle{ .x = paddle.position_x, .y = Paddle.POSITION_Y, .width = Paddle.WIDTH, .height = Paddle.HEIGHT };

        ball.reflectWithPaddleOnCollision(&paddle_rect);
        ball.reflectOnCollisionWithBlocks(&block_wall);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.init(150, 190, 220, 255));

        const camera_zoom = @as(f32, @floatFromInt(rl.getScreenHeight())) / @as(f32, @floatFromInt(SCREEN_SIZE));
        const camera = rl.Camera2D{ .offset = .zero(), .rotation = 0, .target = .zero(), .zoom = camera_zoom };
        camera.begin();
        defer camera.end();

        rl.drawRectangleRec(paddle_rect, Paddle.COLOR);
        rl.drawCircleV(ball.position, Ball.RADIUS, Ball.COLOR);
        drawBlocks(&block_wall);
    }
}
