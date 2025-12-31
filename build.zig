const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // =========================================================================
    // Module Definitions (for cross-phase imports)
    // =========================================================================

    // Phase 01 module - no dependencies
    const phase01_mod = b.addModule("phase01", .{
        .root_source_file = b.path("src/phase01/input.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Phase 02 module - depends on phase01
    const phase02_mod = b.addModule("phase02", .{
        .root_source_file = b.path("src/phase02/parser.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Phase 03 module - re-exports row and table
    const phase03_mod = b.addModule("phase03", .{
        .root_source_file = b.path("src/phase03/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Phase 04 module - depends on phase03
    const phase04_mod = b.addModule("phase04", .{
        .root_source_file = b.path("src/phase04/validation.zig"),
        .target = target,
        .optimize = optimize,
    });
    phase04_mod.addImport("phase03", phase03_mod);

    // =========================================================================
    // Phase 01 Executable and Tests
    // =========================================================================
    const phase01_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/phase01/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const phase01_exe = b.addExecutable(.{
        .name = "db_phase01",
        .root_module = phase01_exe_mod,
    });
    b.installArtifact(phase01_exe);

    const run_phase01 = b.addRunArtifact(phase01_exe);
    run_phase01.step.dependOn(b.getInstallStep());
    const run_phase01_step = b.step("run-phase01", "Run Phase 01 demo");
    run_phase01_step.dependOn(&run_phase01.step);

    const phase01_test_mod = b.createModule(.{
        .root_source_file = b.path("src/phase01/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    const phase01_tests = b.addTest(.{
        .root_module = phase01_test_mod,
    });
    const run_phase01_tests = b.addRunArtifact(phase01_tests);

    // =========================================================================
    // Phase 02 Executable and Tests
    // =========================================================================
    const phase02_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/phase02/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    phase02_exe_mod.addImport("phase01", phase01_mod);

    const phase02_exe = b.addExecutable(.{
        .name = "db_phase02",
        .root_module = phase02_exe_mod,
    });
    b.installArtifact(phase02_exe);

    const run_phase02 = b.addRunArtifact(phase02_exe);
    run_phase02.step.dependOn(b.getInstallStep());
    const run_phase02_step = b.step("run-phase02", "Run Phase 02 demo");
    run_phase02_step.dependOn(&run_phase02.step);

    const phase02_test_mod = b.createModule(.{
        .root_source_file = b.path("src/phase02/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    const phase02_tests = b.addTest(.{
        .root_module = phase02_test_mod,
    });
    const run_phase02_tests = b.addRunArtifact(phase02_tests);

    // =========================================================================
    // Phase 03 Executable and Tests
    // =========================================================================
    const phase03_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/phase03/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    phase03_exe_mod.addImport("phase01", phase01_mod);
    phase03_exe_mod.addImport("phase02", phase02_mod);

    const phase03_exe = b.addExecutable(.{
        .name = "db_phase03",
        .root_module = phase03_exe_mod,
    });
    b.installArtifact(phase03_exe);

    const run_phase03 = b.addRunArtifact(phase03_exe);
    run_phase03.step.dependOn(b.getInstallStep());
    const run_phase03_step = b.step("run-phase03", "Run Phase 03 demo");
    run_phase03_step.dependOn(&run_phase03.step);

    const phase03_test_mod = b.createModule(.{
        .root_source_file = b.path("src/phase03/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    const phase03_tests = b.addTest(.{
        .root_module = phase03_test_mod,
    });
    const run_phase03_tests = b.addRunArtifact(phase03_tests);

    // =========================================================================
    // Phase 04 Executable and Tests
    // =========================================================================
    const phase04_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/phase04/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    phase04_exe_mod.addImport("phase01", phase01_mod);
    phase04_exe_mod.addImport("phase02", phase02_mod);
    phase04_exe_mod.addImport("phase03", phase03_mod);

    const phase04_exe = b.addExecutable(.{
        .name = "db_phase04",
        .root_module = phase04_exe_mod,
    });
    b.installArtifact(phase04_exe);

    const run_phase04 = b.addRunArtifact(phase04_exe);
    run_phase04.step.dependOn(b.getInstallStep());
    const run_phase04_step = b.step("run-phase04", "Run Phase 04 demo");
    run_phase04_step.dependOn(&run_phase04.step);

    const phase04_test_mod = b.createModule(.{
        .root_source_file = b.path("src/phase04/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    phase04_test_mod.addImport("phase03", phase03_mod);
    const phase04_tests = b.addTest(.{
        .root_module = phase04_test_mod,
    });
    const run_phase04_tests = b.addRunArtifact(phase04_tests);

    // =========================================================================
    // Combined Test Step
    // =========================================================================
    const test_step = b.step("test", "Run all phase tests");
    test_step.dependOn(&run_phase01_tests.step);
    test_step.dependOn(&run_phase02_tests.step);
    test_step.dependOn(&run_phase03_tests.step);
    test_step.dependOn(&run_phase04_tests.step);

    // Individual phase test steps
    const test_phase01_step = b.step("test-phase01", "Run Phase 01 tests");
    test_phase01_step.dependOn(&run_phase01_tests.step);

    const test_phase02_step = b.step("test-phase02", "Run Phase 02 tests");
    test_phase02_step.dependOn(&run_phase02_tests.step);

    const test_phase03_step = b.step("test-phase03", "Run Phase 03 tests");
    test_phase03_step.dependOn(&run_phase03_tests.step);

    const test_phase04_step = b.step("test-phase04", "Run Phase 04 tests");
    test_phase04_step.dependOn(&run_phase04_tests.step);
}
