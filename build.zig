const std = @import("std");

fn compileInkcpp(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, options: Options) !*std.Build.Step.Compile {
    const inkcpp = if (options.shared)
        b.addSharedLibrary(.{
            .name = "inkcpp",
            .target = target,
            .optimize = optimize,
        })
    else
        b.addStaticLibrary(.{
            .name = "inkcpp",
            .target = target,
            .optimize = optimize,
        });

    inkcpp.addIncludePath(b.path("inkcpp/include"));
    inkcpp.addIncludePath(b.path("inkcpp_c/include"));
    inkcpp.addIncludePath(b.path("inkcpp_compiler/include"));
    inkcpp.addIncludePath(b.path("shared/private"));
    inkcpp.addIncludePath(b.path("shared/public"));
    inkcpp.linkLibCpp();

    // header.cpp triggers the undefined behavior sanitizer
    inkcpp.root_module.sanitize_c = false;

    inkcpp.root_module.addCSourceFiles(.{
        .files = &.{
            "inkcpp_compiler/json_compiler.cpp",
            "inkcpp_compiler/compiler.cpp",
            "inkcpp_compiler/emitter.cpp",
            "inkcpp_compiler/reporter.cpp",
            "inkcpp_compiler/binary_emitter.cpp",
            "inkcpp_compiler/command.cpp",
            "inkcpp_compiler/binary_stream.cpp",
            "inkcpp_compiler/list_data.cpp",
            "inkcpp/string_operations.cpp",
            "inkcpp/story_impl.cpp",
            "inkcpp/globals_impl.cpp",
            "inkcpp/header.cpp",
            "inkcpp/choice.cpp",
            "inkcpp/container_operations.cpp",
            "inkcpp/stack.cpp",
            "inkcpp/output.cpp",
            "inkcpp/list_table.cpp",
            "inkcpp/value.cpp",
            "inkcpp/system.cpp",
            "inkcpp/list_operations.cpp",
            "inkcpp/numeric_operations.cpp",
            "inkcpp/runner_impl.cpp",
            "inkcpp/string_table.cpp",
            "inkcpp/list_impl.cpp",
            "inkcpp/functional.cpp",
            "inkcpp/snapshot_impl.cpp",
            "inkcpp/functions.cpp",
            "inkcpp/collections/restorable.cpp",
            "inkcpp/story_ptr.cpp",
        },
        .flags = &.{"-std=c++17"},
    });

    inkcpp.root_module.addCSourceFile(.{ .file = b.path("inkcpp_c/inkcpp.cpp"), .flags = &.{"-DINK_BUILD_CLIB"} });

    return inkcpp;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = try compileInkcpp(b, target, optimize, Options.getOptions(b));
    lib.installHeader(b.path("inkcpp_c/include/inkcpp.h"), "inkcpp.h");

    b.installArtifact(lib);
}

pub const Options = struct {
    shared: bool = false,

    const defaults = Options{};

    pub fn getOptions(b: *std.Build) Options {
        return .{
            .shared = b.option(bool, "shared", "Compile as shared library") orelse defaults.shared,
        };
    }
};
