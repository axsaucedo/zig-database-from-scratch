const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const phase01_mod = b.addModule("phase01", .{ .root_source_file = b.path("src/phase01/input.zig"), .target = target, .optimize = optimize });
    const phase02_mod = b.addModule("phase02", .{ .root_source_file = b.path("src/phase02/parser.zig"), .target = target, .optimize = optimize });
    const phase03_mod = b.addModule("phase03", .{ .root_source_file = b.path("src/phase03/lib.zig"), .target = target, .optimize = optimize });
    const phase05_mod = b.addModule("phase05", .{ .root_source_file = b.path("src/phase05/pager.zig"), .target = target, .optimize = optimize });
    phase05_mod.addImport("phase03", phase03_mod);
    const phase08_mod = b.addModule("phase08", .{ .root_source_file = b.path("src/phase08/lib.zig"), .target = target, .optimize = optimize });
    phase08_mod.addImport("phase03", phase03_mod);

    const test_step = b.step("test", "Run all tests");

    // Phase 01
    const exe01 = b.addExecutable(.{ .name = "db_phase01", .root_module = b.createModule(.{ .root_source_file = b.path("src/phase01/main.zig"), .target = target, .optimize = optimize }) });
    b.installArtifact(exe01);
    b.step("run-phase01", "Run Phase 01").dependOn(&b.addRunArtifact(exe01).step);
    const t01 = b.addTest(.{ .root_module = b.createModule(.{ .root_source_file = b.path("src/phase01/tests.zig"), .target = target, .optimize = optimize }) });
    test_step.dependOn(&b.addRunArtifact(t01).step);

    // Phase 02
    const m02 = b.createModule(.{ .root_source_file = b.path("src/phase02/main.zig"), .target = target, .optimize = optimize });
    m02.addImport("phase01", phase01_mod);
    const exe02 = b.addExecutable(.{ .name = "db_phase02", .root_module = m02 });
    b.installArtifact(exe02);
    b.step("run-phase02", "Run Phase 02").dependOn(&b.addRunArtifact(exe02).step);
    const t02 = b.addTest(.{ .root_module = b.createModule(.{ .root_source_file = b.path("src/phase02/tests.zig"), .target = target, .optimize = optimize }) });
    test_step.dependOn(&b.addRunArtifact(t02).step);

    // Phase 03
    const m03 = b.createModule(.{ .root_source_file = b.path("src/phase03/main.zig"), .target = target, .optimize = optimize });
    m03.addImport("phase01", phase01_mod);
    m03.addImport("phase02", phase02_mod);
    const exe03 = b.addExecutable(.{ .name = "db_phase03", .root_module = m03 });
    b.installArtifact(exe03);
    b.step("run-phase03", "Run Phase 03").dependOn(&b.addRunArtifact(exe03).step);
    const t03 = b.addTest(.{ .root_module = b.createModule(.{ .root_source_file = b.path("src/phase03/tests.zig"), .target = target, .optimize = optimize }) });
    test_step.dependOn(&b.addRunArtifact(t03).step);

    // Phase 04
    const m04 = b.createModule(.{ .root_source_file = b.path("src/phase04/main.zig"), .target = target, .optimize = optimize });
    m04.addImport("phase01", phase01_mod);
    m04.addImport("phase02", phase02_mod);
    m04.addImport("phase03", phase03_mod);
    const exe04 = b.addExecutable(.{ .name = "db_phase04", .root_module = m04 });
    b.installArtifact(exe04);
    b.step("run-phase04", "Run Phase 04").dependOn(&b.addRunArtifact(exe04).step);
    const tm04 = b.createModule(.{ .root_source_file = b.path("src/phase04/tests.zig"), .target = target, .optimize = optimize });
    tm04.addImport("phase03", phase03_mod);
    const t04 = b.addTest(.{ .root_module = tm04 });
    test_step.dependOn(&b.addRunArtifact(t04).step);

    // Phase 05
    const m05 = b.createModule(.{ .root_source_file = b.path("src/phase05/main.zig"), .target = target, .optimize = optimize });
    m05.addImport("phase01", phase01_mod);
    m05.addImport("phase02", phase02_mod);
    m05.addImport("phase03", phase03_mod);
    const exe05 = b.addExecutable(.{ .name = "db_phase05", .root_module = m05 });
    b.installArtifact(exe05);
    const r05 = b.addRunArtifact(exe05);
    if (b.args) |args| r05.addArgs(args);
    b.step("run-phase05", "Run Phase 05").dependOn(&r05.step);
    const tm05 = b.createModule(.{ .root_source_file = b.path("src/phase05/tests.zig"), .target = target, .optimize = optimize });
    tm05.addImport("phase03", phase03_mod);
    const t05 = b.addTest(.{ .root_module = tm05 });
    test_step.dependOn(&b.addRunArtifact(t05).step);

    // Phase 06
    const m06 = b.createModule(.{ .root_source_file = b.path("src/phase06/main.zig"), .target = target, .optimize = optimize });
    m06.addImport("phase01", phase01_mod);
    m06.addImport("phase02", phase02_mod);
    m06.addImport("phase03", phase03_mod);
    m06.addImport("phase05", phase05_mod);
    const exe06 = b.addExecutable(.{ .name = "db_phase06", .root_module = m06 });
    b.installArtifact(exe06);
    const r06 = b.addRunArtifact(exe06);
    if (b.args) |args| r06.addArgs(args);
    b.step("run-phase06", "Run Phase 06").dependOn(&r06.step);
    const tm06 = b.createModule(.{ .root_source_file = b.path("src/phase06/tests.zig"), .target = target, .optimize = optimize });
    tm06.addImport("phase03", phase03_mod);
    tm06.addImport("phase05", phase05_mod);
    const t06 = b.addTest(.{ .root_module = tm06 });
    test_step.dependOn(&b.addRunArtifact(t06).step);

    // Phase 08
    const m08 = b.createModule(.{ .root_source_file = b.path("src/phase08/main.zig"), .target = target, .optimize = optimize });
    m08.addImport("phase01", phase01_mod);
    m08.addImport("phase02", phase02_mod);
    m08.addImport("phase03", phase03_mod);
    const exe08 = b.addExecutable(.{ .name = "db_phase08", .root_module = m08 });
    b.installArtifact(exe08);
    const r08 = b.addRunArtifact(exe08);
    if (b.args) |args| r08.addArgs(args);
    b.step("run-phase08", "Run Phase 08").dependOn(&r08.step);
    const tm08 = b.createModule(.{ .root_source_file = b.path("src/phase08/tests.zig"), .target = target, .optimize = optimize });
    tm08.addImport("phase03", phase03_mod);
    const t08 = b.addTest(.{ .root_module = tm08 });
    test_step.dependOn(&b.addRunArtifact(t08).step);

    // Phase 09
    const m09 = b.createModule(.{ .root_source_file = b.path("src/phase09/main.zig"), .target = target, .optimize = optimize });
    m09.addImport("phase01", phase01_mod);
    m09.addImport("phase02", phase02_mod);
    m09.addImport("phase03", phase03_mod);
    m09.addImport("phase08", phase08_mod);
    const exe09 = b.addExecutable(.{ .name = "db_phase09", .root_module = m09 });
    b.installArtifact(exe09);
    const r09 = b.addRunArtifact(exe09);
    if (b.args) |args| r09.addArgs(args);
    b.step("run-phase09", "Run Phase 09").dependOn(&r09.step);
    const tm09 = b.createModule(.{ .root_source_file = b.path("src/phase09/tests.zig"), .target = target, .optimize = optimize });
    tm09.addImport("phase03", phase03_mod);
    tm09.addImport("phase08", phase08_mod);
    const t09 = b.addTest(.{ .root_module = tm09 });
    test_step.dependOn(&b.addRunArtifact(t09).step);

    // Phase 10
    const phase10_mod = b.addModule("phase10", .{ .root_source_file = b.path("src/phase10/lib.zig"), .target = target, .optimize = optimize });
    phase10_mod.addImport("phase03", phase03_mod);
    phase10_mod.addImport("phase08", phase08_mod);
    const m10 = b.createModule(.{ .root_source_file = b.path("src/phase10/main.zig"), .target = target, .optimize = optimize });
    m10.addImport("phase01", phase01_mod);
    m10.addImport("phase02", phase02_mod);
    m10.addImport("phase03", phase03_mod);
    m10.addImport("phase08", phase08_mod);
    const exe10 = b.addExecutable(.{ .name = "db_phase10", .root_module = m10 });
    b.installArtifact(exe10);
    const r10 = b.addRunArtifact(exe10);
    if (b.args) |args| r10.addArgs(args);
    b.step("run-phase10", "Run Phase 10").dependOn(&r10.step);
    const tm10 = b.createModule(.{ .root_source_file = b.path("src/phase10/tests.zig"), .target = target, .optimize = optimize });
    tm10.addImport("phase03", phase03_mod);
    tm10.addImport("phase08", phase08_mod);
    const t10 = b.addTest(.{ .root_module = tm10 });
    test_step.dependOn(&b.addRunArtifact(t10).step);

    // Phase 11
    const phase11_mod = b.addModule("phase11", .{ .root_source_file = b.path("src/phase11/lib.zig"), .target = target, .optimize = optimize });
    phase11_mod.addImport("phase03", phase03_mod);
    phase11_mod.addImport("phase08", phase08_mod);
    phase11_mod.addImport("phase10", phase10_mod);
    const m11 = b.createModule(.{ .root_source_file = b.path("src/phase11/main.zig"), .target = target, .optimize = optimize });
    m11.addImport("phase01", phase01_mod);
    m11.addImport("phase02", phase02_mod);
    m11.addImport("phase03", phase03_mod);
    m11.addImport("phase08", phase08_mod);
    m11.addImport("phase10", phase10_mod);
    const exe11 = b.addExecutable(.{ .name = "db_phase11", .root_module = m11 });
    b.installArtifact(exe11);
    const r11 = b.addRunArtifact(exe11);
    if (b.args) |args| r11.addArgs(args);
    b.step("run-phase11", "Run Phase 11").dependOn(&r11.step);
    const tm11 = b.createModule(.{ .root_source_file = b.path("src/phase11/tests.zig"), .target = target, .optimize = optimize });
    tm11.addImport("phase03", phase03_mod);
    tm11.addImport("phase08", phase08_mod);
    tm11.addImport("phase10", phase10_mod);
    tm11.addImport("phase11", phase11_mod);
    const t11 = b.addTest(.{ .root_module = tm11 });
    test_step.dependOn(&b.addRunArtifact(t11).step);

    // Phase 12
    const phase12_mod = b.addModule("phase12", .{ .root_source_file = b.path("src/phase12/lib.zig"), .target = target, .optimize = optimize });
    phase12_mod.addImport("phase03", phase03_mod);
    phase12_mod.addImport("phase08", phase08_mod);
    phase12_mod.addImport("phase10", phase10_mod);
    phase12_mod.addImport("phase11", phase11_mod);
    const m12 = b.createModule(.{ .root_source_file = b.path("src/phase12/main.zig"), .target = target, .optimize = optimize });
    m12.addImport("phase01", phase01_mod);
    m12.addImport("phase02", phase02_mod);
    m12.addImport("phase03", phase03_mod);
    m12.addImport("phase08", phase08_mod);
    m12.addImport("phase10", phase10_mod);
    m12.addImport("phase11", phase11_mod);
    const exe12 = b.addExecutable(.{ .name = "db_phase12", .root_module = m12 });
    b.installArtifact(exe12);
    const r12 = b.addRunArtifact(exe12);
    if (b.args) |args| r12.addArgs(args);
    b.step("run-phase12", "Run Phase 12").dependOn(&r12.step);
    const tm12 = b.createModule(.{ .root_source_file = b.path("src/phase12/tests.zig"), .target = target, .optimize = optimize });
    tm12.addImport("phase03", phase03_mod);
    tm12.addImport("phase08", phase08_mod);
    tm12.addImport("phase10", phase10_mod);
    tm12.addImport("phase11", phase11_mod);
    tm12.addImport("phase12", phase12_mod);
    const t12 = b.addTest(.{ .root_module = tm12 });
    test_step.dependOn(&b.addRunArtifact(t12).step);

    // Phase 13
    const phase13_mod = b.addModule("phase13", .{ .root_source_file = b.path("src/phase13/lib.zig"), .target = target, .optimize = optimize });
    phase13_mod.addImport("phase03", phase03_mod);
    phase13_mod.addImport("phase08", phase08_mod);
    phase13_mod.addImport("phase10", phase10_mod);
    phase13_mod.addImport("phase11", phase11_mod);
    phase13_mod.addImport("phase12", phase12_mod);
    const m13 = b.createModule(.{ .root_source_file = b.path("src/phase13/main.zig"), .target = target, .optimize = optimize });
    m13.addImport("phase01", phase01_mod);
    m13.addImport("phase02", phase02_mod);
    m13.addImport("phase03", phase03_mod);
    m13.addImport("phase08", phase08_mod);
    m13.addImport("phase10", phase10_mod);
    m13.addImport("phase11", phase11_mod);
    m13.addImport("phase12", phase12_mod);
    const exe13 = b.addExecutable(.{ .name = "db_phase13", .root_module = m13 });
    b.installArtifact(exe13);
    const r13 = b.addRunArtifact(exe13);
    if (b.args) |args| r13.addArgs(args);
    b.step("run-phase13", "Run Phase 13").dependOn(&r13.step);
    const tm13 = b.createModule(.{ .root_source_file = b.path("src/phase13/tests.zig"), .target = target, .optimize = optimize });
    tm13.addImport("phase03", phase03_mod);
    tm13.addImport("phase08", phase08_mod);
    tm13.addImport("phase10", phase10_mod);
    tm13.addImport("phase11", phase11_mod);
    tm13.addImport("phase12", phase12_mod);
    tm13.addImport("phase13", phase13_mod);
    const t13 = b.addTest(.{ .root_module = tm13 });
    test_step.dependOn(&b.addRunArtifact(t13).step);

    // Phase 14
    const phase14_mod = b.addModule("phase14", .{ .root_source_file = b.path("src/phase14/lib.zig"), .target = target, .optimize = optimize });
    phase14_mod.addImport("phase03", phase03_mod);
    phase14_mod.addImport("phase08", phase08_mod);
    phase14_mod.addImport("phase10", phase10_mod);
    phase14_mod.addImport("phase11", phase11_mod);
    phase14_mod.addImport("phase12", phase12_mod);
    const m14 = b.createModule(.{ .root_source_file = b.path("src/phase14/main.zig"), .target = target, .optimize = optimize });
    m14.addImport("phase01", phase01_mod);
    m14.addImport("phase02", phase02_mod);
    m14.addImport("phase03", phase03_mod);
    m14.addImport("phase08", phase08_mod);
    m14.addImport("phase10", phase10_mod);
    m14.addImport("phase11", phase11_mod);
    m14.addImport("phase12", phase12_mod);
    const exe14 = b.addExecutable(.{ .name = "db_phase14", .root_module = m14 });
    b.installArtifact(exe14);
    const r14 = b.addRunArtifact(exe14);
    if (b.args) |args| r14.addArgs(args);
    b.step("run-phase14", "Run Phase 14").dependOn(&r14.step);
    const tm14 = b.createModule(.{ .root_source_file = b.path("src/phase14/tests.zig"), .target = target, .optimize = optimize });
    tm14.addImport("phase03", phase03_mod);
    tm14.addImport("phase08", phase08_mod);
    tm14.addImport("phase10", phase10_mod);
    tm14.addImport("phase11", phase11_mod);
    tm14.addImport("phase12", phase12_mod);
    tm14.addImport("phase14", phase14_mod);
    const t14 = b.addTest(.{ .root_module = tm14 });
    test_step.dependOn(&b.addRunArtifact(t14).step);
}
