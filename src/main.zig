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
};

var started = false;

fn restart(paddle: *Paddle, ball: *Ball) void {
    paddle.position_x = SCREEN_SIZE / 2 - Paddle.WIDTH / 2;
    ball.position = .init(SCREEN_SIZE / 2, Ball.START_Y);
    started = false;
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
            const cos: f32 = @floatCast(std.math.cos(rl.getTime()));
            ball.position.x = (SCREEN_SIZE / 2) + cos;

            if (rl.isKeyPressed(.space)) {
                ball.direction = .init(0, 1);
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

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.init(150, 190, 220, 255));

        const camera = rl.Camera2D{ 
            .offset = .zero(),
            .rotation = 0,
            .target = .zero(),
            .zoom = @as(f32, @floatFromInt(rl.getScreenHeight())) / @as(f32, @floatFromInt(SCREEN_SIZE))
        };
        camera.begin();
        defer camera.end();

        const paddle_rect = rl.Rectangle{ .x = paddle.position_x, .y = Paddle.POSITION_Y, .width = Paddle.WIDTH, .height = Paddle.HEIGHT };
        rl.drawRectangleRec(paddle_rect, Paddle.COLOR);
        rl.drawCircleV(ball.position, Ball.RADIUS, Ball.COLOR);
    }
}
