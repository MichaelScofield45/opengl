const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("zgl");

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

var verts = [_]f32{
    0.5,  0.5,  0.0, 0.0, 0.0, 1.0,
    0.5,  -0.5, 0.0, 1.0, 1.0, 0.0,
    -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
    -0.5, 0.5,  0.0, 0.0, 1.0, 0.0,
};

const indices = [_]u32{
    0, 1, 3,
    1, 2, 3,
};

const WIDTH = 800;
const HEIGHT = 600;

const vert_shader = @embedFile("./shaders/main.vert");
const frag_shader = @embedFile("./shaders/main.frag");

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{ .platform = .x11 })) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(WIDTH, HEIGHT, "opengl", null, null, .{}) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try gl.loadExtensions(.{}, glGetProcAdress);
    window.setFramebufferSizeCallback(frameResizeCallback);

    gl.viewport(0, 0, WIDTH, HEIGHT);

    var vbo = gl.Buffer.create();
    defer vbo.delete();

    var vao = gl.VertexArray.create();
    defer vao.delete();

    var ebo = gl.Buffer.create();
    defer ebo.delete();

    // Filling all data needed
    vao.bind();
    vbo.bind(.array_buffer);
    gl.bufferData(.array_buffer, f32, &verts, .static_draw);
    ebo.bind(.element_array_buffer);
    gl.bufferData(.element_array_buffer, u32, &indices, .dynamic_draw);

    // position
    gl.vertexAttribPointer(0, 3, .float, false, 6 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    // color
    gl.vertexAttribPointer(1, 3, .float, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
    gl.enableVertexAttribArray(1);

    var vert_shader_obj = gl.Shader.create(.vertex);
    defer vert_shader_obj.delete();
    vert_shader_obj.source(1, &.{vert_shader});
    vert_shader_obj.compile();

    var frag_shader_obj = gl.Shader.create(.fragment);
    defer frag_shader_obj.delete();
    frag_shader_obj.source(1, &.{frag_shader});
    frag_shader_obj.compile();

    var shader_program = gl.Program.create();
    defer shader_program.delete();

    shader_program.attach(vert_shader_obj);
    shader_program.attach(frag_shader_obj);
    shader_program.link();

    var text_buf: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&text_buf);
    std.debug.print("{s}", .{try shader_program.getCompileLog(fba.allocator())});

    // Wait for the user to close the window.
    while (!window.shouldClose()) {

        // input
        if (window.getKey(.escape) == .press)
            window.setShouldClose(true);

        const mouse = blk: {
            const curr_pos = window.getCursorPos();
            break :blk .{
                .x = @as(f32, @floatCast(curr_pos.xpos)),
                .y = @as(f32, @floatCast(curr_pos.ypos)),
            };
        };

        const norm = .{
            .x = mouse.x / WIDTH,
            .y = mouse.y / HEIGHT,
        };

        // TODO: get the size of the rectangle right
        const new_pos = blk: {
            var copy = verts;
            copy[0..][0..6][0] = -(norm.x * 2.0 - 1.0);
            copy[6..][0..6][0] = -(norm.x * 2.0 - 1.0);
            break :blk copy;
        };

        vbo.bind(.array_buffer);
        gl.bufferData(.array_buffer, f32, &new_pos, .dynamic_draw);

        // rendering
        gl.clearColor(norm.x, norm.x, norm.x, 1.0);
        gl.clear(.{ .color = true });

        shader_program.use();

        vao.bind();
        gl.drawElements(.triangles, 6, .u32, 0);
        gl.bindVertexArray(.invalid);

        // swap buffers
        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn glGetProcAdress(p: @TypeOf(.{}), proc: [:0]const u8) ?*const anyopaque {
    _ = p;
    return glfw.getProcAddress(proc);
}

fn frameResizeCallback(win: glfw.Window, w: u32, h: u32) void {
    _ = win;
    return gl.viewport(0, 0, w, h);
}
