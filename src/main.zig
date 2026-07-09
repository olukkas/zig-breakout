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

    pub fn checkCollisionWithPaddle(self: *Ball, paddle_rect: *const rl.Rectangle) void {
        if (!rl.checkCollisionCircleRec(self.position, Ball.RADIUS, paddle_rect.*)) return;
        
        var collision_normal: rl.Vector2 = .zero();

        if (self.position.y < paddle_rect.y + paddle_rect.height) {
            collision_normal = collision_normal.add(.init(0, -1));
            self.position.y = paddle_rect.y - Ball.RADIUS;
        }

        if (self.position.y > paddle_rect.y + paddle_rect.height) {
            collision_normal = collision_normal.add(.init(0, 1));
            self.position.y = paddle_rect.y + paddle_rect.height + Ball.RADIUS;
        }

        if (self.position.x < paddle_rect.x) {
            collision_normal = collision_normal.add(.init(-1, 0));
        }

        if (self.position.x > paddle_rect.x + paddle_rect.width) {
            collision_normal = collision_normal.add(.init(1, 0));
        }

        self.position = reflect(self.position, collision_normal);
    }
};

var started = false;

fn restart(paddle: *Paddle, ball: *Ball) void {
    paddle.position_x = SCREEN_SIZE / 2 - Paddle.WIDTH / 2;
    ball.position = .init(SCREEN_SIZE / 2, Ball.START_Y);
    started = false;
}

fn reflect(dir: rl.Vector2, normal: rl.Vector2) rl.Vector2 {
    const new_dir: rl.Vector2 = dir.reflect(normal.normalize());
    return new_dir.normalize();
}

pub fn main(_: std.process.Init) !void {
    rl.setConfigFlags(.{ .vsync_hint = true });

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "breakout");
    defer rl.closeWindow();

    rl.setTargetFPS(120);

    var paddle = Paddle{};
    var ball = Ball{};

    restart(&paddle, &ball);

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

        ball.position.x = ball.position.x + (ball.direction.x * Ball.SPEED * dt);
        ball.position.y = ball.position.y + (ball.direction.y * Ball.SPEED * dt);
        paddle.move_velocity = 0;

        if (rl.isKeyDown(.left)) {
            paddle.move_velocity -= Paddle.SPEED;
        }

        if (rl.isKeyDown(.right)) {
            paddle.move_velocity += Paddle.SPEED;
        }

        paddle.position_x += paddle.move_velocity * dt;
        paddle.position_x = std.math.clamp(paddle.position_x, 0, SCREEN_SIZE - Paddle.WIDTH);

        const paddle_rect = rl.Rectangle{ .x = paddle.position_x, .y = Paddle.POSITION_Y, .width = Paddle.WIDTH, .height = Paddle.HEIGHT };

        ball.checkCollisionWithPaddle(&paddle_rect);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.init(150, 190, 220, 255));

        const camera_zoom = @as(f32, @floatFromInt(rl.getScreenHeight())) / @as(f32, @floatFromInt(SCREEN_SIZE));
        const camera = rl.Camera2D{ .offset = .zero(), .rotation = 0, .target = .zero(), .zoom = camera_zoom };
        camera.begin();
        defer camera.end();

        rl.drawRectangleRec(paddle_rect, Paddle.COLOR);
        rl.drawCircleV(ball.position, Ball.RADIUS, Ball.COLOR);
    }
}
