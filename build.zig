const std = @import("std");
const builtin = @import("builtin");

// This is the build script for our generic WebAssembly project with TypeScript frontend
pub fn build(b: *std.Build) void {
    // Standard target options for WebAssembly
    const wasm_target = std.Target.Query{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    };

    // Standard optimization options
    const optimize = b.standardOptimizeOption(.{});

    // Create an executable that compiles to WebAssembly
    const exe = b.addExecutable(.{
        .name = "towerd",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(wasm_target),
        .optimize = optimize,
    });

    // Important WASM-specific settings
    exe.rdynamic = true;
    exe.entry = .disabled;

    // Install in the output directory
    b.installArtifact(exe);

    // Create necessary directories - this needs to happen first
    const make_dirs = b.addSystemCommand(if (builtin.os.tag == .windows)
        &[_][]const u8{ "cmd", "/c", "if", "not", "exist", "dist", "mkdir", "dist" }
    else
        &[_][]const u8{ "mkdir", "-p", "dist" });

    // Make sure directory creation happens before any other steps
    const install_step = b.getInstallStep();
    install_step.dependOn(&make_dirs.step);

    // Add TypeScript build step using Bun
    const bun_build_cmd = if (builtin.os.tag == .windows)
        &[_][]const u8{ "cmd", "/c", "bun", "run", "build" }
    else
        &[_][]const u8{ "bun", "run", "build" };

    const build_ts = b.addSystemCommand(bun_build_cmd);
    build_ts.step.dependOn(&make_dirs.step);

    // Create a step to copy the WASM file to the dist directory
    const copy_wasm = b.addInstallFile(exe.getEmittedBin(), "../dist/towerd.wasm");
    copy_wasm.step.dependOn(install_step);
    copy_wasm.step.dependOn(&build_ts.step);

    // Create a step to copy all files from web/public to the dist directory
    const copy_public = b.addInstallDirectory(.{
        .source_dir = b.path("web/public"),
        .install_dir = .{ .custom = "../dist" },
        .install_subdir = "",
    });
    copy_public.step.dependOn(&make_dirs.step);

    // Create a step to copy index.html to the dist directory
    const copy_html = b.addInstallFile(b.path("web/index.html"), "../dist/index.html");
    copy_html.step.dependOn(&make_dirs.step);

    // Create a step to copy CSS files to the dist directory
    const copy_css = b.addInstallDirectory(.{
        .source_dir = b.path("web/styles"),
        .install_dir = .{ .custom = "../dist/css" },
        .install_subdir = "",
    });
    copy_css.step.dependOn(&make_dirs.step);

    // Add a run step to start Bun's development server
    const bun_serve_cmd = if (builtin.os.tag == .windows)
        &[_][]const u8{ "cmd", "/c", "bun", "run", "dev" }
    else
        &[_][]const u8{ "bun", "run", "dev" };

    const run_cmd = b.addSystemCommand(bun_serve_cmd);
    run_cmd.step.dependOn(&copy_wasm.step);
    run_cmd.step.dependOn(&copy_public.step);
    run_cmd.step.dependOn(&copy_html.step);
    run_cmd.step.dependOn(&copy_css.step);

    const run_step = b.step("run", "Build, deploy, and start Bun development server");
    run_step.dependOn(&run_cmd.step);

    // Add a deploy step that only copies the files without starting the server
    const deploy_step = b.step("deploy", "Build and copy files to dist directory");
    deploy_step.dependOn(&copy_wasm.step);
    deploy_step.dependOn(&copy_public.step);
    deploy_step.dependOn(&copy_html.step);
    deploy_step.dependOn(&copy_css.step);
}
