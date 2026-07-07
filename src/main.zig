const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 800;

pub fn main(_: std.process.Init) !void {
    rl.setConfigFlags(.{ .vsync_hint = true });

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "breakout");
    defer rl.closeWindow();

    rl.setTargetFPS(120);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.init(150, 190, 220, 255));

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
    }
}
