// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// How GN's vocabulary maps onto the Bazel workspace: labels, configs,
/// conditions and the variables of GN's built-in rules.
///
/// These tables are the converter's knowledge of the engine. Everything that
/// is not in them is an error at conversion time; adding to them is how the
/// converter's coverage grows.
library;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'gn_ast.dart';
import 'gn_eval.dart';

/// Where the engine's GN root (`//`) lives in the Bazel workspace.
const String bazelRootPackage = '//engine/src';

/// The main repository's apparent name (`module(name = "flutter")` in
/// MODULE.bazel), as it must be written from an external repository that
/// the engine's module extension generates: such repositories see the root
/// module's repository mapping, in which the module's own name is itself.
const String mainRepositoryName = '@flutter';

/// The GN config engine code is compiled with (`-Wunreachable-code`, the
/// engine include roots); what tells engine code from the third-party trees
/// the engine describes with GN (Skia, the codecs), which get
/// `chromium_code` alone.
const String flutterConfigLabel = '//flutter:config';

/// What stands for GN's `//build/config/compiler:default_include_dirs`
/// (`-I//`, the source root), which BUILDCONFIG.gn applies to every target
/// and engine code relies on for its `flutter/...` includes. Every compiled
/// target of the main repository depends on it privately; the third-party
/// trees the engine describes with GN never use it.
const String defaultIncludeDirsLabel = '//engine/src:include_root';

/// The C++ standard library GN's BUILDCONFIG.gn links into every executable
/// and shared library (its default deps). The root `.bazelrc` attaches it to
/// executables through `--@bazel_tools//tools/cpp:link_extra_libs`, which
/// does not reach shared binaries; the converter lists it in their deps.
const String cxxRuntimeLabel = '//engine/src/flutter/build/bazel/toolchains:cxx_runtime';

/// The `size` of a generated `cc_test`. GN has no notion of it; the engine's
/// suites are small unless listed in [testSizes].
const String defaultTestSize = 'small';

/// Test targets (by GN name) that need more than the default size.
const Map<String, String> testSizes = <String, String>{
  // 50 s on the host: the performance overlay goldens.
  'flow_unittests': 'medium',
  // The benchmarks run_tests.py --type benchmarks runs (benchmarkRuns),
  // timed as GN's unoptimized binaries on the host, where google-benchmark
  // runs each case until its timing settles: 10 s (fml), 23 s (geometry),
  // 34 s (display_list_builder), 16 s (txt), 31 s (shell); lib/ui's one
  // case completes a 3 MB platform message in a Dart isolate per iteration
  // outside the timed region, 1,087 s unoptimized (CI runs the benchmarks
  // in host_release only).
  'fml_benchmarks': 'medium',
  'geometry_benchmarks': 'medium',
  'display_list_builder_benchmarks': 'medium',
  'txt_benchmarks': 'medium',
  'shell_benchmarks': 'medium',
  'ui_benchmarks': 'enormous',
  // 40 s on the host (208 tests, the shell on ANGLE and SwiftShader).
  'shell_unittests': 'medium',
  // 11 s as a GN binary (85 tests; run_tests.py allows it 90 s).
  'ui_unittests': 'medium',
  // 24 s alone (46 renders through the software and GPU backends); timed
  // out at small's 60 s on a machine running the other suites.
  'display_list_rendertests': 'medium',
  // 77 s alone (195 tests: the embedder on the software, GL and Vulkan
  // surfaces, each a Dart VM).
  'embedder_unittests': 'medium',
  // 4,795 tests (3,120 run, the Metal variants skipped), the playgrounds
  // rendering through SwiftShader with validation on: 3,266 s serial on the
  // host, sharded (testShardCounts).
  'impeller_unittests': 'large',
  // Under gtest-parallel (gtestParallelSuites: a process per test, twice,
  // eight workers): 559 tests, 48 s beside the other suites, against
  // small's 60 s.
  'display_list_unittests': 'medium',
  // 855 tests, each process initializing GTK under the display and the
  // session bus: past small's 60 s under gtest-parallel (54 s with a
  // worker per core, alone).
  'flutter_linux_unittests': 'medium',
};

/// Test targets (by GN name) split into shards (`shard_count`), with the
/// count. testing/run_tests.py runs every suite through gtest-parallel, one
/// process per core; a shard is Bazel's form of that parallelism, and the
/// in-tree googletest shards by test index when the wrapper of a
/// flutter_display_test hands it Bazel's shard variables (testing/xvfb_run.sh).
/// Plain cc_test suites have no wrapper and cannot be listed here.
const Map<String, int> testShardCounts = <String, int>{
  // 3,266 s serial; sixteen shards of ~3.5 min on a 24-core host.
  'impeller_unittests': 16,
};

/// How a suite is run: the arguments testing/run_tests.py passes it, the
/// files those arguments name, which become the `cc_test`'s `args` and
/// `data`, and the environment it sets (`env`). GN's executable has no words
/// for how it is run; the runner has. Paths in [args] are relative to the
/// runfiles root, where Bazel starts a test (`engine/src/flutter/...`).
final class TestRun {
  const TestRun({
    required this.args,
    required this.data,
    this.env = const <String, String>{},
    this.runnerArgs = const <String>[],
  });

  final List<String> args;

  /// Bazel labels of the files and filegroups the arguments name.
  final List<String> data;

  /// run_tests.py's `extra_env` for the suite.
  final Map<String, String> env;

  /// gtest-parallel's own options for the suite (what run_tests.py passes
  /// ahead of `--`: ui_unittests' `--timeout=90`), for a suite of
  /// [gtestParallelSuites].
  final List<String> runnerArgs;
}

/// The suites testing/run_tests.py runs through gtest-parallel (its
/// run_cc_tests, on a Linux host): each becomes a flutter_cc_test
/// (testing.bzl) -- or, in [displayTests], a flutter_display_test with
/// `gtest_parallel` -- which puts the binary through the same runner with
/// the same flags: a process per test, every test twice (`--repeat=2`), a
/// worker per core. The Impeller suites are not here: their builder
/// (`--type impeller` on macOS, host_debug_unopt_impeller_tests on Linux)
/// runs the binaries whole. GN labels, `//dir:name`.
const Set<String> gtestParallelSuites = <String>{
  '//flutter/assets:assets_unittests',
  '//flutter/shell/platform/glfw/client_wrapper:client_wrapper_glfw_unittests',
  '//flutter/shell/platform/common/client_wrapper:client_wrapper_unittests',
  '//flutter/shell/platform/common:common_cpp_core_unittests',
  '//flutter/shell/platform/common:common_cpp_unittests',
  '//flutter/runtime:dart_plugin_registrant_unittests',
  '//flutter/display_list:display_list_rendertests',
  '//flutter/display_list:display_list_unittests',
  '//flutter/shell/platform/embedder:embedder_a11y_unittests',
  '//flutter/shell/platform/embedder:embedder_proctable_unittests',
  '//flutter/shell/platform/embedder:embedder_unittests',
  '//flutter/fml:fml_unittests',
  '//flutter/shell/geometry:geometry_unittests',
  '//flutter/shell/gpu:gpu_surface_unittests',
  '//flutter/runtime:no_dart_plugin_registrant_unittests',
  '//flutter/runtime:runtime_unittests',
  '//flutter/testing:testing_unittests',
  '//flutter/third_party/tonic/tests:tonic_unittests',
  '//flutter/lib/ui:ui_unittests',
  // Every host but Windows.
  '//flutter/shell/platform/android/external_view_embedder:android_external_view_embedder_unittests',
  '//flutter/shell/platform/android/jni:jni_unittests',
  '//flutter/shell/platform/android/platform_view_android_delegate:platform_view_android_delegate_unittests',
  '//flutter/shell/common:shell_unittests',
  // Linux.
  '//flutter/flow:flow_unittests',
  '//flutter/shell/platform/glfw:flutter_glfw_unittests',
  '//flutter/shell/platform/linux:flutter_linux_unittests',
  '//flutter/txt:txt_unittests',
};

/// Suites run with arguments, by GN label (`//dir:name`).
const Map<String, TestRun> testRuns = <String, TestRun>{
  // run_tests.py (Linux): the performance overlay goldens and the font the
  // golden was rendered with.
  '//flutter/flow:flow_unittests': TestRun(
    args: <String>[
      '--golden-dir=engine/src/flutter/testing/resources',
      '--font-file=engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
    ],
    data: <String>[
      '//engine/src/flutter/testing:resources',
      '//engine/src/flutter/txt:third_party/fonts/Roboto-Regular.ttf',
    ],
  ),
  // run_tests.py: the Flutter GPU suite runs with Vulkan validation and,
  // for now, the Metal variants alone (flutter/flutter#145036, #142642),
  // which a Linux host skips.
  '//flutter/impeller:impeller_dart_unittests': TestRun(
    args: <String>['--enable_vulkan_validation', '--gtest_filter=*Metal'],
    data: <String>[],
  ),
  // The embedder suite's JIT snapshot tests read the core snapshot's four
  // files by the paths its embedder_jit_snapshot_setup config compiles in
  // (relative to GetSourcePath(); see the emitter's _defineText); GN finds
  // them in the build directory, Bazel needs them in the runfiles.
  '//flutter/shell/platform/embedder:embedder_unittests': TestRun(
    args: <String>[],
    data: <String>[
      '//engine/src/flutter/lib/snapshot:isolate_snapshot.bin',
      '//engine/src/flutter/lib/snapshot:isolate_snapshot_instructions.bin',
      '//engine/src/flutter/lib/snapshot:vm_isolate_snapshot.bin',
      '//engine/src/flutter/lib/snapshot:vm_snapshot_instructions.bin',
    ],
  ),
  // run_tests.py --type impeller (Linux CI's host_debug_unopt_impeller_tests)
  // runs impeller_unittests whole and with no arguments of its own: the
  // Vulkan validation layer comes from the environment
  // (vulkan_validation_env), which flutter_display_test sets. The ColorWheel
  // playground run (--enable_playground, flutter/flutter#134852) is macOS's.
  //
  // run_tests.py (Linux): the GTK shell's suite runs with GLib's criticals
  // fatal, so that a g_critical in the shell fails the test.
  '//flutter/shell/platform/linux:flutter_linux_unittests': TestRun(
    args: <String>[],
    data: <String>[],
    env: <String, String>{'G_DEBUG': 'fatal-criticals'},
  ),
  // run_tests.py: "the image release unit test can take a while on slow
  // machines" -- gtest-parallel's timeout for the suite's processes.
  '//flutter/lib/ui:ui_unittests': TestRun(
    args: <String>[],
    data: <String>[],
    runnerArgs: <String>['--timeout=90'],
  ),
  // run_tests.py (Linux) passes txt_unittests ICU's data file; the suite's
  // main (txt_run_all_unittests.cc) reads no such flag, so the argument is
  // carried for the day it does, with the file it names.
  '//flutter/txt:txt_unittests': TestRun(
    args: <String>['--icu-data-file-path=../+synced_deps+icu/common/icudtl.dat'],
    data: <String>['@icu//:icudata'],
  ),
};

/// The benchmark executables testing/run_tests.py runs (`--type benchmarks`,
/// run_engine_benchmarks on a Linux host; CI's host_release_test), each
/// with ICU's data file, by GN label. GN makes them binaries (testonly, not
/// named `*tests`); for the runner's sake each becomes a `cc_test` with
/// `tags = ["benchmark", "manual"]` -- a wildcard `bazel test` leaves them
/// out, as every CI builder but host_release_test does, and
/// `//engine/src/flutter/testing:benchmarks` runs them all -- with these
/// arguments and data. The other benchmark executables of the tree
/// (display_list_benchmarks, primitive_rendering_benchmarks, ...) are built
/// by that builder and run by no one; they stay binaries.
const Map<String, TestRun> benchmarkRuns = <String, TestRun>{
  '//flutter/shell/common:shell_benchmarks': _benchmarkRun,
  '//flutter/fml:fml_benchmarks': _benchmarkRun,
  '//flutter/lib/ui:ui_benchmarks': _benchmarkRun,
  '//flutter/display_list:display_list_builder_benchmarks': _benchmarkRun,
  '//flutter/impeller/geometry:geometry_benchmarks': _benchmarkRun,
  '//flutter/txt:txt_benchmarks': _benchmarkRun,
};

/// run_engine_benchmarks' one argument, ICU's data file (icu_flags).
const TestRun _benchmarkRun = TestRun(
  args: <String>['--icu-data-file-path=../+synced_deps+icu/common/icudtl.dat'],
  data: <String>['@icu//:icudata'],
);

/// The suites that open a window -- the Impeller playground's, GLFW on
/// X11 -- by GN label. run_tests.py starts an Xvfb for the Linux suites;
/// these become flutter_display_test (testing.bzl), which runs the binary
/// under the environment's DISPLAY or an Xvfb of its own. As with
/// gpuBackendTests, the converter cannot follow the dependency to the
/// playground from one file, so the list is kept here. A suite here that is
/// not in [gpuBackendTests] runs without run_tests.py's Vulkan validation
/// environment, which names the backends next to the binary.
const Set<String> displayTests = <String>{
  '//flutter/impeller:impeller_dart_unittests',
  '//flutter/impeller:impeller_unittests',
  // GTK opens the display at initialization (gtk_init), before any test.
  '//flutter/shell/platform/linux:flutter_linux_unittests',
};

/// The display tests whose binaries also need a D-Bus session bus
/// (flutter_display_test's `session_bus`): GTK's accessibility bridge asks
/// it for the accessibility bus, and without one a view's AtkPlug has no
/// id -- an Atk assertion the Linux shell's suite fails in its first test,
/// fatal under its G_DEBUG. run_tests.py's run inherits the bus of the
/// session it runs in (a bot's systemd user session); the sandbox has none,
/// so testing/xvfb_run.sh starts one for these, as it starts the display.
const Set<String> sessionBusTests = <String>{
  '//flutter/shell/platform/linux:flutter_linux_unittests',
};

/// The suites that render through the GPU test backends -- ANGLE on
/// SwiftShader (//flutter/testing:opengl), SwiftShader through the Vulkan
/// loader (:vulkan) -- by GN label. GN's data_deps put the backends'
/// libraries and ICD manifest in the build directory, next to every
/// executable, and ANGLE and the test utilities look for them next to the
/// running binary; each of these suites gets a copy in its own package
/// (flutter_gpu_test_backends in testing.bzl) as `data`. The converter sees
/// one file at a time and cannot follow the dependency to the backends, so
/// the list is kept here; it is what `gn desc <out> <suite> runtime_deps`
/// names libvk_swiftshader.so for. An executable that is not a test
/// (flutter_tester_opengles, ANGLE over SwiftShader for the Dart suites)
/// carries them as runfiles for the tests that run it; flutter_tester links
/// SwiftShader statically and needs none.
const Set<String> gpuBackendTests = <String>{
  '//flutter/impeller:impeller_dart_unittests',
  '//flutter/impeller:impeller_unittests',
  '//flutter/lib/ui:ui_unittests',
  '//flutter/runtime:runtime_unittests',
  '//flutter/shell/common:shell_unittests',
  '//flutter/shell/gpu:gpu_surface_unittests',
  '//flutter/shell/platform/embedder:embedder_a11y_unittests',
  '//flutter/shell/platform/embedder:embedder_unittests',
  '//flutter/shell/testing:flutter_tester_opengles',
};

/// The name of the flutter_gpu_test_backends target the converter declares
/// in a package with suites of [gpuBackendTests].
const String gpuBackendsTargetName = 'gpu_test_backends';

/// Attributes the generated macro calls get besides what the GN invocation
/// says, by GN label (`//dir:name`) and attribute, as Starlark text: what
/// GN discovers after the fact and Bazel must declare. The one case so far
/// is a fixture's Dart entry point importing another package's sources
/// (the frontend server's depfile tells GN; the kernel rule needs them as
/// inputs).
const Map<String, Map<String, String>> templateAttributeOverrides = <String, Map<String, String>>{
  // dart_tests.dart imports ../../lib/gpu/lib/gpu.dart, which imports
  // package:vector_math (a synced tree, @vector_math).
  '//flutter/impeller/fixtures:flutter_gpu_fixtures': <String, String>{
    'dart_srcs': 'glob(["*.dart"]) + ["//engine/src/flutter/lib/gpu:dart_sources"]',
    'dart_packages':
        '{"@vector_math//:dart_sources": "engine/src/flutter/third_party/pkg/vector_math"}',
  },
};

/// GN labels with a Bazel home that is not the mechanical translation.
///
/// Keys are GN labels as written (without the implicit `:name` for
/// directory labels); values are Bazel labels.
const Map<String, String> labelOverrides = <String, String>{
  // Synced dependencies with overlay BUILD files.
  '//flutter/third_party/icu': '@icu',
  '//flutter/third_party/icu:icu': '@icu',
  '//flutter/third_party/icu:icuuc': '@icu//:icuuc',
  '//flutter/third_party/icu:icui18n': '@icu//:icui18n',
  '//flutter/third_party/zlib': '@zlib',
  '//flutter/third_party/zlib:zlib': '@zlib',
  '//flutter/third_party/googletest:gtest': '@googletest//:gtest',
  '//flutter/third_party/googletest:gtest_main': '@googletest//:gtest_main',
  '//flutter/third_party/googletest:gmock': '@googletest//:gtest',
  '//flutter/third_party/googletest:gtest_prod': '@googletest//:gtest_prod',
  // The secondary tree's forwarders.
  '//third_party/icu': '@icu',
  '//third_party/icu:icuuc': '@icu//:icuuc',
  '//third_party/zlib': '@zlib',
  '//third_party/freetype2': '@freetype2',
  '//third_party/boringssl': '//engine/src/flutter/third_party/boringssl',
  '//third_party/googletest:gtest': '@googletest//:gtest',
  '//third_party/googletest:gmock': '@googletest//:gtest',
  // The secondary tree's fontconfig (build/secondary/third_party/BUILD.gn):
  // the sysroot's system library, as a hand-written facade.
  '//third_party:fontconfig': '//engine/src/flutter/third_party:fontconfig',
  // The Dart SDK, built by gn_build.
  '//flutter/third_party/dart/runtime:dart_api': '@dart//:dart_api_headers',
  '//flutter/third_party/dart/runtime:libdart_jit':
      '//engine/src/flutter/build/bazel/dart_wrap:libdart_jit',
  '//flutter/third_party/dart/runtime:libdart_aotruntime':
      '//engine/src/flutter/build/bazel/dart_wrap:libdart_aotruntime',
  '//flutter/third_party/dart/runtime/bin:common_embedder_dart_io':
      '//engine/src/flutter/build/bazel/dart_wrap:common_embedder_dart_io',
  '//flutter/third_party/dart/runtime/bin:elf_loader':
      '//engine/src/flutter/build/bazel/dart_wrap:elf_loader',
  '//flutter/third_party/dart/runtime/bin:native_assets_api':
      '//engine/src/flutter/build/bazel/dart_wrap:native_assets_api',
  '//flutter/third_party/dart/third_party/double-conversion/src:libdouble_conversion':
      '//engine/src/flutter/build/bazel/dart_wrap:libdouble_conversion',
  '//flutter/third_party/dart/third_party/perfetto:libprotozero':
      '//engine/src/flutter/build/bazel/dart_wrap:libprotozero',
  '//third_party/perfetto:libprotozero': '//engine/src/flutter/build/bazel/dart_wrap:libprotozero',
  // Skia, generated into @skia at fetch time from the engine's GN over the
  // synced tree (research/07), and Skia's codec and font dependencies, each
  // generated the same way from its own small GN file.
  '//flutter/skia': '@skia',
  '//flutter/skia:skia': '@skia',
  '//flutter/third_party/expat': '@expat',
  '//flutter/third_party/freetype2': '@freetype2',
  '//flutter/third_party/libjpeg-turbo': '@libjpeg-turbo',
  '//flutter/third_party/libpng': '@libpng',
  '//flutter/third_party/libwebp': '@libwebp',
  '//flutter/third_party/wuffs': '@wuffs',
  '//third_party/libpng': '@libpng',
  // The shader compiler's dependencies (research/08): engine GN in the
  // secondary tree over synced trees (inja, json, SPIRV-Cross, flatbuffers)
  // and SPIRV-Headers' own GN, each a fetch-time repository.
  '//third_party/inja': '@inja',
  '//flutter/third_party/json': '@json',
  '//third_party/spirv_cross_flutter': '@spirv-cross//:spirv_cross_flutter',
  '//flutter/third_party/flatbuffers': '@flatbuffers',
  '//flutter/third_party/vulkan-deps/spirv-headers/src': '@spirv-headers',
  '//flutter/third_party/vulkan-deps/spirv-tools/src': '@spirv-tools',
  '//flutter/third_party/vulkan-deps/glslang/src': '@glslang',
  '//third_party/shaderc_flutter': '@shaderc//:shaderc_flutter',
  '//flutter/third_party/re2': '@re2',
  '//third_party/libtess2': '@libtess2',
  '//flutter/third_party/harfbuzz': '@harfbuzz',
  // google/benchmark (the secondary tree's GN over the synced tree), for
  // //flutter/benchmarking and the benchmark executables.
  '//flutter/third_party/benchmark': '@benchmark',
  // The engine's libc++, which the toolchain links into every binary
  // (toolchains:cxx_runtime) and a complete static library archives
  // (BUILDCONFIG.gn's use_flutter_cxx).
  '//flutter/third_party/libcxx': '@libcxx',
  '//flutter/third_party/libcxx:libcxx': '@libcxx',
  // The Impeller playground's window and UI libraries (secondary tree).
  '//flutter/third_party/glfw': '@glfw',
  '//flutter/third_party/imgui': '@imgui',
  '//flutter/third_party/imgui:imgui_glfw': '@imgui//:imgui_glfw',
  // The desktop embeddings' JSON (header-only; its own GN in the synced tree).
  '//flutter/third_party/rapidjson': '@rapidjson',
  // The Vulkan headers (header-only; the tree's own GN).
  '//flutter/third_party/vulkan-deps/vulkan-headers/src': '@vulkan-headers',
  // VulkanMemoryAllocator (header-only; the secondary tree's GN).
  '//flutter/third_party/vulkan_memory_allocator': '@vulkan_memory_allocator',
  // The GPU test backends, built by gn_build (build/bazel/gl_wrap): ANGLE's
  // two static libraries are one archive behind one facade, and
  // SwiftShader's group of runtime files is the other.
  '//flutter/third_party/angle:libEGL_static': '//engine/src/flutter/build/bazel/gl_wrap:angle',
  '//flutter/third_party/angle:libGLESv2_static': '//engine/src/flutter/build/bazel/gl_wrap:angle',
  '//flutter/third_party/swiftshader': '//engine/src/flutter/build/bazel/gl_wrap:swiftshader',
  '//flutter/third_party/swiftshader/src/Vulkan:swiftshader_libvulkan_static':
      '//engine/src/flutter/build/bazel/gl_wrap:swiftshader_static',
};

/// Label prefixes that map to external repositories: `//third_party/abseil-cpp/absl/x:y`
/// becomes `@abseil-cpp//absl/x:y`.
const Map<String, String> labelRepositoryPrefixes = <String, String>{
  '//third_party/abseil-cpp/': '@abseil-cpp//',
  // The engine's GN for Skia (`//flutter/skia/...`) and Skia's own tree
  // (`//flutter/third_party/skia/...`) both land in @skia.
  '//flutter/skia/': '@skia//',
  '//flutter/third_party/skia/': '@skia//',
  '//flutter/third_party/expat/': '@expat//',
  '//flutter/third_party/freetype2/': '@freetype2//',
  '//flutter/third_party/libjpeg-turbo/': '@libjpeg-turbo//',
  '//flutter/third_party/libpng/': '@libpng//',
  '//flutter/third_party/libwebp/': '@libwebp//',
  '//flutter/third_party/wuffs/': '@wuffs//',
  '//flutter/third_party/inja/': '@inja//',
  '//flutter/third_party/json/': '@json//',
  '//flutter/third_party/rapidjson/': '@rapidjson//',
  '//flutter/third_party/vulkan-deps/spirv-cross/src/': '@spirv-cross//',
  '//flutter/third_party/flatbuffers/': '@flatbuffers//',
  '//flutter/third_party/vulkan-deps/spirv-headers/src/': '@spirv-headers//',
  '//flutter/third_party/vulkan-deps/spirv-tools/src/': '@spirv-tools//',
  '//flutter/third_party/vulkan-deps/glslang/src/': '@glslang//',
  '//flutter/third_party/vulkan-deps/vulkan-headers/src/': '@vulkan-headers//',
  '//flutter/third_party/vulkan_memory_allocator/': '@vulkan_memory_allocator//',
  // ANGLE's headers (the overlay); the GLES backend lists two among its
  // sources.
  '//flutter/third_party/angle/': '@angle//',
  '//flutter/third_party/shaderc/': '@shaderc//',
  '//flutter/third_party/re2/': '@re2//',
  '//flutter/third_party/libtess2/': '@libtess2//',
  '//flutter/third_party/harfbuzz/': '@harfbuzz//',
  '//flutter/third_party/glfw/': '@glfw//',
  '//flutter/third_party/imgui/': '@imgui//',
  // ICU's data files (the interop toolkit embeds flutter/icudtl.dat).
  '//flutter/third_party/icu/': '@icu//',
};

/// Repositories whose files the generated rules name but whose targets are
/// not converted (their labels go through [labelOverrides], one by one):
/// a source file under one of these prefixes is the file of that
/// repository, which exports it. The Dart tree's core library sources,
/// which sky/packages/sky_engine copies into the sky_engine package.
const Map<String, String> fileRepositoryPrefixes = <String, String>{
  '//flutter/third_party/dart/': '@dart//',
};

/// Generated include directories (`$root_gen_dir/flutter`) that are an
/// ancestor package's: Bazel's `includes` is package-relative, and the
/// target whose `includes` names that package's directory already covers
/// its twin in the output tree, so the directory is a dependency on it.
const Map<String, String> genDirIncludeTargets = <String, String>{
  '//': defaultIncludeDirsLabel,
  '//flutter': '//engine/src/flutter:config',
};

/// Include directories in another repository that a Bazel library of that
/// repository carries in its `includes`: GN's `include_dirs = [
/// "//flutter/third_party/angle/include" ]` cannot be written as a
/// package-relative `includes`, so the directory becomes a dependency on the
/// library, which puts the same `-I` on the same compiles. Keys are GN
/// paths as `//dir`.
const Map<String, String> includeDirLibraries = <String, String>{
  '//flutter/third_party/angle/include': '@angle//:headers',
  // tonic's config: its headers as "tonic/..." and "third_party/tonic/...".
  '//flutter/third_party': '//engine/src/flutter/third_party:include_dir',
  '//flutter': '//engine/src/flutter:config',
  // The GLFW client wrapper's config: the core wrapper's headers as
  // siblings of its own (the merged layout clients build), a library of
  // the core wrapper's package (its manifest appendix) since `includes` is
  // package-relative.
  '//flutter/shell/platform/common/client_wrapper/include/flutter':
      '//engine/src/flutter/shell/platform/common/client_wrapper:relative_core_wrapper_headers',
};

/// A Bazel label taken apart: `@repo//package:name`.
@immutable
final class BazelLabel {
  const BazelLabel(this.repository, this.package, this.name);

  /// Parses `@repo//pkg:name`, `//pkg:name`, `//pkg` (name = last segment),
  /// `@repo` (`@repo//:repo`) and `:name` (in [package] of [repository]).
  factory BazelLabel.parse(String label, {String repository = '', String package = ''}) {
    var rest = label;
    var repo = repository;
    if (rest.startsWith('@')) {
      final int slashes = rest.indexOf('//');
      if (slashes < 0) {
        return BazelLabel(rest, '', rest.substring(1));
      }
      repo = rest.substring(0, slashes);
      rest = rest.substring(slashes);
    }
    if (rest.startsWith('//')) {
      rest = rest.substring(2);
      final int colon = rest.indexOf(':');
      if (colon < 0) {
        return BazelLabel(repo, rest, rest.substring(rest.lastIndexOf('/') + 1));
      }
      return BazelLabel(repo, rest.substring(0, colon), rest.substring(colon + 1));
    }
    if (rest.startsWith(':')) {
      return BazelLabel(repo, package, rest.substring(1));
    }
    throw ArgumentError.value(label, 'label', 'not a label');
  }

  /// `@skia` or the empty string for the main repository.
  final String repository;
  final String package;
  final String name;

  /// How to write this label from [package] of [repository]: `:name` within
  /// the package, `//pkg:name` within the repository, the full form
  /// elsewhere; the name is dropped when it repeats the package's last
  /// segment (`@icu` for `@icu//:icu`). From an external repository, the
  /// main repository is [mainRepositoryName].
  String relativeTo({required String repository, required String package}) {
    if (this.repository == repository && this.package == package) {
      return ':$name';
    }
    final String last = this.package.substring(this.package.lastIndexOf('/') + 1);
    if (this.repository == repository) {
      return '//${this.package}${name == last && this.package.isNotEmpty ? '' : ':$name'}';
    }
    final String repo = this.repository.isEmpty ? mainRepositoryName : this.repository;
    if (this.package.isEmpty) {
      return name == repo.substring(1) ? repo : '$repo//:$name';
    }
    return '$repo//${this.package}${name == last ? '' : ':$name'}';
  }

  @override
  bool operator ==(Object other) =>
      other is BazelLabel &&
      other.repository == repository &&
      other.package == package &&
      other.name == name;

  @override
  int get hashCode => Object.hash(repository, package, name);

  @override
  String toString() => '$repository//$package:$name';
}

/// Where a generated file lives: in the main repository (an engine package
/// such as `//engine/src/flutter/fml`), or in an external repository made
/// from a synced tree at fetch time (`@skia`, whose root is the GN directory
/// `//flutter/third_party/skia`).
@immutable
final class OutputLayout {
  /// The main repository; [packages] are the Bazel packages that exist in
  /// it (`engine/src/flutter/fml`), for files of another package.
  const OutputLayout.main({this.packages = const <String>{}})
    : repository = '',
      repositoryGnRoot = '//',
      pathPrefix = 'engine/src/',
      secondarySource = null;

  const OutputLayout.repository(
    this.repository, {
    required this.repositoryGnRoot,
    this.packages = const <String>{''},
    this.secondarySource,
  }) : pathPrefix = '';

  /// `@skia`, or the empty string for the main repository.
  final String repository;

  /// The GN directory that is the repository's root: files under it are
  /// repository-relative.
  final String repositoryGnRoot;

  /// What precedes a GN-root-relative path in the repository: the GN root
  /// is `engine/src` of the main repository.
  final String pathPrefix;

  /// The Bazel packages that exist in the repository (repository-relative
  /// directories; `''` is the root), so that a file in a subpackage is
  /// labelled through its own package.
  final Set<String> packages;

  /// GN's secondary source root (`//flutter/build/secondary`), when the
  /// repository's build files live there: files beside them (`expat`'s
  /// `expat_config` directory) are mirrored into the repository by the
  /// repository rule, so their GN paths map into it too.
  final String? secondarySource;

  bool get isMain => repository.isEmpty;

  /// The repository-relative path of a GN directory or file under the root,
  /// or null when it is outside.
  String? relativePath(String gnPath) {
    final String? secondary = secondarySource;
    if (secondary != null && gnPath.startsWith(secondary + repositoryGnRoot.substring(1))) {
      return relativePath('/${gnPath.substring(secondary.length)}');
    }
    final root = repositoryGnRoot == '//' ? '//' : '$repositoryGnRoot/';
    if (gnPath == repositoryGnRoot) {
      return pathPrefix.isEmpty ? '' : pathPrefix.substring(0, pathPrefix.length - 1);
    }
    if (!gnPath.startsWith(root)) {
      return null;
    }
    return '$pathPrefix${gnPath.substring(root.length)}';
  }

  /// The package (from [packages]) that owns a repository-relative path, or
  /// null when none does (in an external repository the root always does).
  String? owningPackage(String relativePath) {
    String? best;
    for (final String package in packages) {
      if (package.isEmpty || relativePath == package || relativePath.startsWith('$package/')) {
        if (best == null || package.length > best.length) {
          best = package;
        }
      }
    }
    return best;
  }
}

/// A GN label as written (`//a/b:c`, `//a/b`, `:c`, `modules/skcms`,
/// `../base`, `../../:skia_private`) made absolute, [package] being the GN
/// directory of the file it was written in. A relative label is a
/// directory, possibly with a name after the colon, relative to that
/// directory; the two parts are resolved apart so that `../../:x` is
/// `//grandparent:x`. With [implicitName], `//a/b` is `//a/b:b`.
String absoluteGnLabel(String gnLabel, {required String package, bool implicitName = false}) {
  String label;
  if (gnLabel.startsWith(':')) {
    label = '$package$gnLabel';
  } else if (gnLabel.startsWith('//')) {
    label = gnLabel;
  } else {
    final int colon = gnLabel.indexOf(':');
    final String directory = colon < 0 ? gnLabel : gnLabel.substring(0, colon);
    final String name = colon < 0 ? '' : gnLabel.substring(colon);
    final String normalized = p.posix.normalize('${package.substring(2)}/$directory');
    label = '//${normalized == '.' ? '' : normalized}$name';
  }
  if (implicitName && !label.contains(':')) {
    label = '$label:${label.substring(label.lastIndexOf('/') + 1)}';
  }
  return label;
}

/// Translates a GN label to a Bazel label.
///
/// [package] is the GN directory of the file being converted (`//flutter/fml`),
/// for `:local` labels; [location] is where the label was written, for the
/// error when it has no Bazel home.
String bazelLabel(String gnLabel, {required String package, GnLocation? location}) {
  // `:x($default_toolchain)` is `:x` here: a Bazel build has one
  // configuration of each target.
  final int paren = gnLabel.indexOf('(');
  if (paren > 0 && gnLabel.endsWith(')')) {
    gnLabel = gnLabel.substring(0, paren);
  }
  if (gnLabel.startsWith(':')) {
    return gnLabel;
  }
  final String absolute = absoluteGnLabel(gnLabel, package: package);
  final String? override = labelOverrides[absolute];
  if (override != null) {
    return override;
  }
  // `//dir:name` where `//dir` is the root of an external repository.
  final int colon = absolute.indexOf(':');
  if (colon > 0) {
    final String? directory = labelOverrides[absolute.substring(0, colon)];
    if (directory != null && directory.startsWith('@') && !directory.contains('//')) {
      return '$directory//${absolute.substring(colon)}';
    }
  }
  for (final MapEntry<String, String> entry in labelRepositoryPrefixes.entries) {
    if (absolute.startsWith(entry.key)) {
      return entry.value + absolute.substring(entry.key.length);
    }
  }
  if (absolute.startsWith('//flutter/') || absolute == '//flutter') {
    return '$bazelRootPackage${absolute.substring(1)}';
  }
  throw GnError(location ?? GnLocation(package, 0, 0), 'no Bazel home for label $gnLabel');
}

/// What a GN config contributes to the target that lists it.
sealed class ConfigEffect {
  const ConfigEffect();
}

/// The config is a dependency on a Bazel target carrying its defines and
/// include directories, plus the compiler flags it applies ([copts]), which
/// no dependency can carry and the listing target gets inlined.
final class ConfigDependency extends ConfigEffect {
  const ConfigDependency(this.label, {this.copts = const <String>[]});

  final String label;
  final List<String> copts;
}

/// The config is implied by something else (a dependency that already
/// carries it) and needs nothing.
final class ConfigImplied extends ConfigEffect {
  const ConfigImplied();
}

/// The config selects the warning set: `chromium_code` or not.
final class ConfigWarningSet extends ConfigEffect {
  const ConfigWarningSet({required this.chromiumCode});

  final bool chromiumCode;
}

/// The config is compiler flags alone (no defines, no include directories),
/// from a file the converter does not convert: they are inlined into the
/// listing target's `copts`, each group under the GN condition the config
/// sets it in, as no dependency could carry them. Only private listings are
/// supported: a public one would hand the flags on along dependency edges,
/// which the dependents derive from the owner's GN file
/// (dependency_resolver.dart), not from this table.
final class ConfigCopts extends ConfigEffect {
  const ConfigCopts(this.copts);

  /// The flags, each group with the condition under which the config sets
  /// it.
  final List<(Condition, List<String>)> copts;
}

/// The config is one GN's BUILDCONFIG.gn applies to every target and the
/// Bazel toolchain carries for every compile: listing it adds nothing, and a
/// target that removes it (`configs -= [...]`) gets the flags that undo it.
final class ConfigToolchain extends ConfigEffect {
  const ConfigToolchain({required this.removalCopts});

  /// The flags that take the config's effect back on one target.
  final List<String> removalCopts;
}

/// The configs the engine's build files mention, outside their own package.
const Map<String, ConfigEffect> configEffects = <String, ConfigEffect>{
  '//flutter:config': ConfigDependency('//engine/src/flutter:config'),
  '//flutter:export_dynamic_symbols': ConfigDependency(
    '//engine/src/flutter:export_dynamic_symbols',
  ),
  '//flutter:export_dynamic_test_symbols': ConfigDependency(
    '//engine/src/flutter:export_dynamic_test_symbols',
  ),
  '//flutter/common:flutter_config': ConfigDependency('//engine/src/flutter/common:flutter_config'),
  '//flutter/impeller:impeller_public_config': ConfigDependency(
    '//engine/src/flutter/impeller:impeller_public_config',
  ),
  // The desktop embeddings' shared configs, which the client wrapper lists
  // from its own file: FLUTTER_DESKTOP_LIBRARY (private) and the public
  // headers' include directory (its public config).
  '//flutter/shell/platform/common:desktop_library_implementation': ConfigDependency(
    '//engine/src/flutter/shell/platform/common:desktop_library_implementation',
  ),
  '//flutter/shell/platform/common:relative_flutter_library_headers': ConfigDependency(
    '//engine/src/flutter/shell/platform/common:relative_flutter_library_headers',
  ),
  // The GLFW shell's public headers' include directory, which its client
  // wrapper lists from its own file.
  '//flutter/shell/platform/glfw:relative_flutter_glfw_headers': ConfigDependency(
    '//engine/src/flutter/shell/platform/glfw:relative_flutter_glfw_headers',
  ),
  // The Linux embeddings' pkg_config() configs (hand-written package: see
  // its BUILD.bazel): what pkg-config says of each package against the
  // sysroot, as libraries that link it (and, for gtk, carry its include
  // directories through the sysroot repository).
  '//flutter/shell/platform/linux/config:x11': ConfigDependency(
    '//engine/src/flutter/shell/platform/linux/config:x11',
  ),
  '//flutter/shell/platform/linux/config:gtk': ConfigDependency(
    '//engine/src/flutter/shell/platform/linux/config:gtk',
  ),
  '//flutter/shell/platform/linux/config:egl': ConfigDependency(
    '//engine/src/flutter/shell/platform/linux/config:egl',
  ),
  '//flutter/shell/platform/linux/config:epoxy': ConfigDependency(
    '//engine/src/flutter/shell/platform/linux/config:epoxy',
  ),
  '//flutter/shell/platform/linux/config:wayland_client': ConfigDependency(
    '//engine/src/flutter/shell/platform/linux/config:wayland_client',
  ),
  '//flutter/shell/platform/linux/config:wayland_egl': ConfigDependency(
    '//engine/src/flutter/shell/platform/linux/config:wayland_egl',
  ),
  '//flutter/third_party/icu:icu_config': ConfigImplied(),
  // Skia's text modules list //flutter/skia's private config from their own
  // files (`configs += [ "../../:skia_private" ]`); its library carries
  // SK_GAMMA_APPLY_TO_A8, which the dependency makes public where GN's
  // private config kept it to the module (decision 14's kind of delta;
  // nothing outside Skia reads it).
  '//flutter/skia:skia_private': ConfigDependency('@skia//:skia_private'),
  // skunicode hides ICU's C++ API with Skia's own config (private, so an
  // implementation dependency: txt, downstream, uses that API).
  '//flutter/third_party/skia/third_party/icu/config:no_cxx': ConfigDependency(
    '@skia//third_party/icu/config:no_cxx',
  ),
  // shaderc lists SPIRV-Tools' public config itself (`configs +=`).
  '//flutter/third_party/vulkan-deps/spirv-tools/src:spvtools_public_config': ConfigDependency(
    '@spirv-tools//:spvtools_public_config',
  ),
  '//build/config/compiler:chromium_code': ConfigWarningSet(chromiumCode: true),
  '//build/config/compiler:no_chromium_code': ConfigWarningSet(chromiumCode: false),
  // //build/config/clang:extra_warnings, part of BUILDCONFIG.gn's default
  // configs and of the toolchain's flags (cc_toolchain_config.bzl); the one
  // target that removes it (//flutter/testing:opengl) turns its two warnings
  // back off. Its define (_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS, libc++'s
  // annotations) stays: the removal is about the warnings.
  '//build/config/clang:extra_warnings': ConfigToolchain(
    removalCopts: <String>['-Wno-string-conversion', '-Wno-newline-eof'],
  ),
  // ANGLE's configs (build/bazel/gl_wrap builds ANGLE; the overlay @angle
  // carries its headers and this define-only config).
  '//flutter/third_party/angle:external_config': ConfigDependency('@angle//:headers'),
  '//flutter/third_party/angle:gl_prototypes': ConfigDependency('@angle//:gl_prototypes'),
  // SwiftShader's config, which the test utilities list privately: -Wno-shadow
  // under clang, and -Os in an optimized build on anything but Windows.
  '//flutter/third_party/swiftshader:swiftshader_config': ConfigCopts(<(Condition, List<String>)>[
    (Condition.always, <String>['-Wno-shadow']),
    (
      ConditionAnd(<Condition>[
        ConditionNot(ConditionVariable('is_win')),
        ConditionNot(ConditionVariable('is_debug')),
      ]),
      <String>['-Os'],
    ),
  ]),
  // The Dart runtime's own config, which lib/io lists privately: its
  // defines ride the overlay's library (@dart//:dart_config); its flags are
  // the ones below under every host configuration (dart_debug is false
  // unless tools/gn is given --dart-debug, so the runtime, and this one
  // file of the engine, compile with -O2 even in an unoptimized build).
  '//flutter/third_party/dart/runtime:dart_config': ConfigDependency(
    '@dart//:dart_config',
    copts: <String>[
      '-Wno-unused-parameter',
      '-Wno-unused-private-field',
      '-Wnon-virtual-dtor',
      '-Wvla',
      '-Woverloaded-virtual',
      '-Wno-comments',
      '-g3',
      '-ggdb3',
      '-fno-rtti',
      '-fno-exceptions',
      '-Wnewline-eof',
      '-Wimplicit-fallthrough',
      '-fno-strict-vtable-pointers',
      '-O2',
    ],
  ),
};

/// The Bazel config_setting (or constraint) for a GN boolean predicate.
const Map<String, String> conditionSettings = <String, String>{
  'is_android': '@platforms//os:android',
  'is_fuchsia': '@platforms//os:fuchsia',
  'is_ios': '@platforms//os:ios',
  'is_linux': '@platforms//os:linux',
  'is_mac': '@platforms//os:macos',
  'is_qnx': '@platforms//os:qnx',
  'is_wasm': '@platforms//os:emscripten',
  'is_win': '@platforms//os:windows',
  'is_debug': '//engine/src/flutter/build/bazel:unoptimized',
  'slimpeller': '//engine/src/flutter/common:slimpeller_enabled',
  // GN's `current_toolchain == host_toolchain` with neither toolchain
  // assumed (gn_eval's hostToolchainPredicate): the OSes a host runs.
  'is_host_toolchain': '//engine/src/flutter/build/bazel:host_toolchain',
  // testing.gni's default, `current_toolchain == host_toolchain || is_fuchsia
  // || is_mac`, read in Bazel terms (the group in //flutter/testing's
  // appendix).
  'enable_unittests': '//engine/src/flutter/testing:unittests_enabled',
  // impeller/tools/args.gni's backend arguments: flags whose defaults GN
  // derives from the platform (impeller/tools/BUILD.bazel).
  'impeller_enable_metal': '//engine/src/flutter/impeller/tools:metal',
  'impeller_enable_opengles': '//engine/src/flutter/impeller/tools:opengles',
  'impeller_enable_vulkan': '//engine/src/flutter/impeller/tools:vulkan',
  // flutter_vma/config.gni's argument, which tools/gn derives from the host
  // (iOS and Windows): the group in //flutter/flutter_vma's appendix.
  'disable_vma_stl_shared_mutex': '//engine/src/flutter/flutter_vma:without_stl_shared_mutex',
  // tools/gn's --enable-fontconfig, which sets //flutter/txt's
  // flutter_use_fontconfig and Skia's skia_use_fontconfig together (the
  // Linux desktop builders pass it; the host builders do not): one flag, in
  // //flutter/txt's appendix, where GN declares the engine's argument.
  'flutter_use_fontconfig': '//engine/src/flutter/txt:fontconfig',
  'skia_use_fontconfig': '//engine/src/flutter/txt:fontconfig',
  // runtime_args.gni's dart_dynamic_modules (tools/gn
  // --gn-args=dart_dynamic_modules=true, the `_ddm` builders): the Dart
  // wrap's flag, which the archives' names also read.
  'dart_dynamic_modules': '//engine/src/flutter/build/bazel/dart_wrap:dart_dynamic_modules_enabled',
};

/// The config_setting that holds exactly when a GN predicate is *false*, for
/// the denied terms of a conjunction (`impeller_enable_opengles && !is_wasm`
/// becomes a `config_setting_group(match_all)`, which needs a setting per
/// term). On its own a denial needs none: its `select()` has the key empty
/// and the default carrying the branch. The OS predicates exclude each other,
/// so each complement is the group of the other seven (build/bazel/BUILD.bazel).
const Map<String, String> negatedSettings = <String, String>{
  'is_android': '//engine/src/flutter/build/bazel:not_android',
  'is_fuchsia': '//engine/src/flutter/build/bazel:not_fuchsia',
  'is_ios': '//engine/src/flutter/build/bazel:not_ios',
  'is_linux': '//engine/src/flutter/build/bazel:not_linux',
  'is_mac': '//engine/src/flutter/build/bazel:not_mac',
  'is_qnx': '//engine/src/flutter/build/bazel:not_qnx',
  'is_wasm': '//engine/src/flutter/build/bazel:not_wasm',
  'is_win': '//engine/src/flutter/build/bazel:not_win',
  // The host's own build, denied: the OSes only a target runs.
  'is_host_toolchain': '//engine/src/flutter/build/bazel:not_host_toolchain',
  // A flag's denial has a setting of its own where a conjunction needs one
  // (`!dart_dynamic_modules && flutter_runtime_mode == "debug"`: the
  // archives' names).
  'dart_dynamic_modules':
      '//engine/src/flutter/build/bazel/dart_wrap:dart_dynamic_modules_disabled',
};

/// The Bazel config_setting for `variable == "value"`, by variable and value.
const Map<String, Map<String, String>> comparisonSettings = <String, Map<String, String>>{
  'flutter_runtime_mode': <String, String>{
    'debug': '//engine/src/flutter/common:runtime_mode_debug',
    'profile': '//engine/src/flutter/common:runtime_mode_profile',
    'release': '//engine/src/flutter/common:runtime_mode_release',
    'jit_release': '//engine/src/flutter/common:runtime_mode_jit_release',
  },
};

/// GN variables an imported `.gni` defines and that build files may read or
/// test. Reads become references that [referenceConstants] resolve.
const Set<String> knownExternalVariables = <String>{
  // //build/config/BUILDCONFIG.gn
  'current_cpu',
  'current_os',
  'current_toolchain',
  'default_library_type',
  'default_toolchain',
  'host_cpu',
  'host_os',
  'host_toolchain',
  'is_android',
  'is_apple',
  'is_clang',
  'is_component_build',
  'is_debug',
  'is_fuchsia',
  'is_ios',
  'is_linux',
  'is_mac',
  'is_minimal_linux',
  'is_official_build',
  'is_qnx',
  'is_wasm',
  'is_win',
  'target_cpu',
  'target_os',
  // //flutter/build/dart/dart.gni
  'dart_src',
  // //flutter/common/config.gni
  'enable_backtrace',
  'enable_unittests',
  'feature_defines_list',
  'flutter_cflags_objc',
  'flutter_cflags_objcc',
  'flutter_runtime_mode',
  'slimpeller',
  // //flutter/shell/config.gni
  'shell_enable_gl',
  'shell_enable_metal',
  'shell_enable_software',
  'shell_enable_vulkan',
  'test_enable_gl',
  'test_enable_metal',
  'test_enable_software',
  'test_enable_vulkan',
  // //flutter/shell/version/version.gni: set by tools/gn from git and DEPS;
  // Bazel-side constants of @engine_version (referenceConstants).
  'content_hash',
  'dart_version',
  'engine_version',
  'skia_version',
  // //flutter/flutter_vma/config.gni: tools/gn sets it for iOS and Windows
  // hosts, where the C++ library lacks std::shared_mutex (a setting in
  // //flutter/flutter_vma's appendix).
  'disable_vma_stl_shared_mutex',
  // //flutter/tools/fuchsia/gn-sdk/src/gn_configs.gni
  'fuchsia_arch_root',
  'fuchsia_sdk',
  // //flutter/impeller/tools/args.gni (evaluated): the backend arguments are
  // Bazel flags, so declare_args() keeps their names rather than GN's
  // per-platform default formulas.
  'impeller_enable_metal',
  'impeller_enable_opengles',
  'impeller_enable_vulkan',
  // //flutter/txt/BUILD.gn's own declare_args() and Skia's skia.gni
  // (evaluated): tools/gn's --enable-fontconfig, one Bazel flag
  // (conditionSettings).
  'flutter_use_fontconfig',
  'skia_use_fontconfig',
  // $dart_src/runtime/runtime_args.gni (known through zip_bundle.gni): the
  // Dart wrap's flag (conditionSettings).
  'dart_dynamic_modules',
};

/// A Starlark constant the Bazel side keeps for a GN variable the converter
/// does not evaluate: the symbol and the `.bzl` file that defines it.
final class ReferenceConstant {
  const ReferenceConstant(this.file, this.symbol);

  /// The label of the `.bzl` file to load.
  final String file;

  /// The symbol it defines.
  final String symbol;
}

const String _coptsBzl = '//engine/src/flutter/build/bazel:copts.bzl';

/// The `.bzl` the @engine_version repository writes at fetch time
/// (build/bazel/extensions.bzl): the four arguments of
/// shell/version/version.gni, which tools/gn computes from git and DEPS
/// when it generates a GN build.
const String _versionBzl = '@engine_version//:version.bzl';

/// The build outputs a zip_bundle's entries may name that no converted GN
/// file produces -- the wrapped and hand-written trees' -- each as the
/// Bazel label of the file: GN's path under the build directory
/// (`//@out/...` for `$root_out_dir`, `//@gen/...` for `$root_gen_dir`) to
/// the label. An entry whose producer is a converted file needs no row: the
/// emitter reads the producer's outputs (`_buildOutputs`).
const Map<String, String> buildOutputLabels = <String, String>{
  // The Dart SDK's gen_snapshot, out of the wrapped GN build of the Dart
  // tree (build/bazel/dart_wrap).
  '//@out/gen_snapshot': '//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot',
  // //flutter/lib/snapshot (hand-written): the core snapshot and the
  // platform kernels.
  '//@gen/flutter/lib/snapshot/isolate_snapshot.bin':
      '//engine/src/flutter/lib/snapshot:isolate_snapshot.bin',
  '//@gen/flutter/lib/snapshot/vm_isolate_snapshot.bin':
      '//engine/src/flutter/lib/snapshot:vm_isolate_snapshot.bin',
  '//@out/flutter_patched_sdk/platform_strong.dill':
      '//engine/src/flutter/lib/snapshot:flutter_patched_sdk/platform_strong.dill',
  '//@out/flutter_patched_sdk/vm_outline_strong.dill':
      '//engine/src/flutter/lib/snapshot:flutter_patched_sdk/vm_outline_strong.dill',
};

/// A directory a zip_bundle entry names as its source (zip.py walks it):
/// the target of its files and the directory's path relative to its
/// repository's root, which are zip_tree's `srcs` and `root`
/// (build/bazel/zip_bundle.bzl).
final class DirectorySource {
  const DirectorySource(this.label, {required this.root});

  /// A filegroup over the directory's files.
  final String label;

  /// The directory, relative to the root of the repository its files are
  /// in; empty for the repository root itself.
  final String root;
}

/// The directories zip_bundle entries name, by GN path.
const Map<String, DirectorySource> directorySources = <String, DirectorySource>{
  // impellerc's shader library (GLSL sources), which artifacts.zip ships
  // beside the compiler; the packages' files, BUILD files included, as
  // zip.py's walk takes them.
  '//flutter/impeller/compiler/shader_lib': DirectorySource(
    '//engine/src/flutter/impeller/compiler/shader_lib:all_files',
    root: 'engine/src/flutter/impeller/compiler/shader_lib',
  ),
  // The prebuilt Dart SDK, which dart-sdk-<platform>.zip is.
  '//flutter/prebuilts/linux-x64/dart-sdk': DirectorySource(
    '@dart_sdk_linux_x64//:all_files',
    root: '',
  ),
};

/// Starlark constants for GN references that have a Bazel-side value.
const Map<String, ReferenceConstant> referenceConstants = <String, ReferenceConstant>{
  'flutter_cflags_objc': ReferenceConstant(_coptsBzl, 'FLUTTER_CFLAGS_OBJC'),
  'flutter_cflags_objcc': ReferenceConstant(_coptsBzl, 'FLUTTER_CFLAGS_OBJCC'),
  'feature_defines_list': ReferenceConstant(_coptsBzl, 'FLUTTER_FEATURE_DEFINES'),
  'engine_version': ReferenceConstant(_versionBzl, 'ENGINE_VERSION'),
  'content_hash': ReferenceConstant(_versionBzl, 'CONTENT_HASH'),
  'skia_version': ReferenceConstant(_versionBzl, 'SKIA_VERSION'),
  'dart_version': ReferenceConstant(_versionBzl, 'DART_VERSION'),
};

/// How a template argument translates to a macro attribute.
enum TemplateArgumentKind {
  /// Files of the package (`fixtures`, `flatbuffers`), and the outputs of
  /// other targets (`get_target_outputs`), which become the macro's
  /// `<attribute>_targets` dictionary of label to patterns.
  files,

  /// One file (`dart_main`).
  file,

  /// Labels (`deps`).
  labels,

  /// Configs, which become labels of their config libraries.
  configs,

  /// A scalar (`testonly`).
  scalar,

  /// Plain strings (`shader_target_flags`).
  strings,

  /// One string holding `rebase_path()` results (a shader bundle's JSON),
  /// which become the path tokens of build/bazel/gn_action.
  pathString,

  /// A helper variable of the invocation the template never reads
  /// (`fixtures = rebase_path(...)` feeding a string of the same block).
  ignored,

  /// A directory that names a package (`dest = "$root_gen_dir/flutter/lib/ui"`),
  /// which becomes the package's label.
  package,

  /// `{ source, destination }` scopes naming an archive's entries (a
  /// zip_bundle's `files`): the macro's dictionary of destination to the
  /// label of the file placed there, each source resolved to the target
  /// that produces it (see `_archiveEntriesText` in starlark_emitter.dart).
  archiveEntries,

  /// A path under the build directory as GN wrote it (`output_dir =
  /// "$root_gen_dir/dart-pkg/sky_engine/lib/ui_web/"`), passed on as such
  /// for the rule to place its outputs by (BuildDirectoryInfo).
  buildPath,
}

/// One argument of a known template: the macro attribute it becomes and how.
final class TemplateArgument {
  const TemplateArgument(this.attribute, this.kind);

  final String attribute;
  final TemplateArgumentKind kind;
}

/// The `.gni` templates the converter knows, with the Bazel macro for each
/// (`load` label and symbol) and the arguments it accepts.
final class TemplateMapping {
  const TemplateMapping(
    this.bzl,
    this.symbol,
    this.arguments, {
    this.innerTargets = const <String>[],
    this.files = false,
  });

  final String bzl;
  final String symbol;
  final Map<String, TemplateArgument> arguments;

  /// The other targets an invocation expands to in GN, as patterns over the
  /// invocation's name (`flatc_{name}`) and, for the shader templates, the
  /// backend (`impellerc_{backend}_{name}` over [impellerShaderBackends]),
  /// besides those GN's convention prefixes with `_`. The macro's business;
  /// the oracle expects them.
  final List<String> innerTargets;

  /// Whether the macro's target is files (an action's outputs) rather than
  /// a library: a compiled target's dependency on one, which in GN orders
  /// the action before a binary that reads the files at run time (the test
  /// fixtures' AOT snapshot of the VM service, a `public_deps` entry of
  /// //flutter/testing:fixture_test in the profile mode), is `data` here,
  /// as a dependency on a `copy()` is.
  final bool files;

  /// [innerTargets] expanded for [name].
  Iterable<String> innerTargetsOf(String name) sync* {
    for (final String pattern in innerTargets) {
      final String named = pattern.replaceAll('{name}', name);
      if (named.contains('{backend}')) {
        yield* impellerShaderBackends.map((String b) => named.replaceAll('{backend}', b));
      } else {
        yield named;
      }
    }
  }
}

/// The backends impeller/tools/shaders.gni expands to on a Linux host
/// (GLES 2, GLES 3, Vulkan; no Metal), as the shader rules in
/// build/bazel/impeller mirror them.
const List<String> impellerShaderBackends = <String>['gles', 'gles3', 'vk'];

const Map<String, TemplateMapping> templateMappings = <String, TemplateMapping>{
  'test_fixtures': TemplateMapping(
    '//engine/src/flutter/testing:testing.bzl',
    'flutter_test_fixtures',
    <String, TemplateArgument>{
      'fixtures': TemplateArgument('fixtures', TemplateArgumentKind.files),
      'dart_main': TemplateArgument('dart_main', TemplateArgumentKind.file),
      'use_target_as_artifact_prefix': TemplateArgument(
        'use_target_as_artifact_prefix',
        TemplateArgumentKind.scalar,
      ),
      // The copy's ordering dependencies (the targets whose outputs are
      // among the fixtures); runfiles of the library here.
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      // The directory whose assets receive the fixtures (lib/ui's shader
      // fixtures): the package, whose own test_fixtures copies them.
      'dest': TemplateArgument('dest', TemplateArgumentKind.package),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
  ),
  // impeller/tools/embed_blob.gni's embed_blob, invoked directly (the
  // interop toolkit's ICU data): a file's bytes as a C++ array behind a
  // library.
  'embed_blob': TemplateMapping(
    '//engine/src/flutter/build/bazel/impeller:shaders.bzl',
    'embed_blob_library',
    <String, TemplateArgument>{
      'symbol_name': TemplateArgument('symbol_name', TemplateArgumentKind.scalar),
      'blob': TemplateArgument('blob', TemplateArgumentKind.file),
      // Outputs under the target_gen_dir: the package's own files here.
      'hdr': TemplateArgument('hdr', TemplateArgumentKind.file),
      'cc': TemplateArgument('cc', TemplateArgumentKind.file),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    // The template's xxd.py action, which the macro declares by the same
    // name.
    innerTargets: <String>['gen_blob_{name}'],
  ),
  // impeller/tools/compiler.gni's impellerc, invoked directly by the test
  // fixtures: runtime stages and shader bundles.
  'impellerc': TemplateMapping(
    '//engine/src/flutter/build/bazel/impeller:shaders.bzl',
    'impellerc',
    <String, TemplateArgument>{
      'shaders': TemplateArgument('shaders', TemplateArgumentKind.files),
      'shader_target_flags': TemplateArgument('shader_target_flags', TemplateArgumentKind.strings),
      'sl_file_extension': TemplateArgument('sl_file_extension', TemplateArgumentKind.scalar),
      'intermediates_subdir': TemplateArgument('intermediates_subdir', TemplateArgumentKind.scalar),
      'iplr': TemplateArgument('iplr', TemplateArgumentKind.scalar),
      'json': TemplateArgument('json', TemplateArgumentKind.scalar),
      'shader_bundle': TemplateArgument('shader_bundle', TemplateArgumentKind.pathString),
      'shader_bundle_output': TemplateArgument('shader_bundle_output', TemplateArgumentKind.scalar),
      'gles_language_version': TemplateArgument(
        'gles_language_version',
        TemplateArgumentKind.scalar,
      ),
      'metal_version': TemplateArgument('metal_version', TemplateArgumentKind.scalar),
      'use_half_textures': TemplateArgument('use_half_textures', TemplateArgumentKind.scalar),
      'require_framebuffer_fetch': TemplateArgument(
        'require_framebuffer_fetch',
        TemplateArgumentKind.scalar,
      ),
      'entry_point_prefix': TemplateArgument('entry_point_prefix', TemplateArgumentKind.scalar),
      'defines': TemplateArgument('defines', TemplateArgumentKind.strings),
      'mnemonic': TemplateArgument('mnemonic', TemplateArgumentKind.scalar),
      // The invocations' helper for the bundle's paths.
      'fixtures': TemplateArgument('fixtures', TemplateArgumentKind.ignored),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    files: true,
  ),
  // testing.gni's dart_snapshot_kernel and dart_snapshot_aot: a Dart entry
  // point to kernel with the test modes' arguments, and a kernel to an AOT
  // ELF snapshot.
  'dart_snapshot_kernel': TemplateMapping(
    '//engine/src/flutter/testing:testing.bzl',
    'flutter_dart_snapshot_kernel',
    <String, TemplateArgument>{
      'dart_main': TemplateArgument('dart_main', TemplateArgumentKind.file),
      'dart_kernel': TemplateArgument('dart_kernel', TemplateArgumentKind.file),
    },
    files: true,
  ),
  'dart_snapshot_aot': TemplateMapping(
    '//engine/src/flutter/testing:testing.bzl',
    'flutter_dart_snapshot_aot',
    <String, TemplateArgument>{
      'dart_kernel': TemplateArgument('dart_kernel', TemplateArgumentKind.file),
      'dart_elf_filename': TemplateArgument('dart_elf_filename', TemplateArgumentKind.scalar),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
    },
    files: true,
  ),
  // build/secondary/flutter/third_party/flatbuffers/flatbuffers.gni: flatc
  // over the schemas, the generated headers as a library.
  'flatbuffers': TemplateMapping(
    '//engine/src/flutter/build/bazel/flatbuffers:flatbuffers.bzl',
    'flatbuffers',
    <String, TemplateArgument>{
      'flatbuffers': TemplateArgument('flatbuffers', TemplateArgumentKind.files),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'public_deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'public_configs': TemplateArgument('deps', TemplateArgumentKind.configs),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    innerTargets: <String>['flatc_{name}'],
  ),
  // impeller/tools/shaders.gni: impellerc per shader per backend, the
  // archives, the embedded blobs and the reflection libraries. GN's `name`
  // is the library name (`entity` in `entity_shaders_vk`); Bazel's is the
  // target's.
  'impeller_shaders': TemplateMapping(
    '//engine/src/flutter/build/bazel/impeller:shaders.bzl',
    'impeller_shaders',
    <String, TemplateArgument>{
      'name': TemplateArgument('library_name', TemplateArgumentKind.scalar),
      'shaders': TemplateArgument('shaders', TemplateArgumentKind.files),
      'analyze': TemplateArgument('analyze', TemplateArgumentKind.scalar),
      'enable_opengles': TemplateArgument('enable_opengles', TemplateArgumentKind.scalar),
      'gles_language_version': TemplateArgument(
        'gles_language_version',
        TemplateArgumentKind.scalar,
      ),
      'vulkan_language_version': TemplateArgument(
        'vulkan_language_version',
        TemplateArgumentKind.scalar,
      ),
      'metal_version': TemplateArgument('metal_version', TemplateArgumentKind.scalar),
      'use_half_textures': TemplateArgument('use_half_textures', TemplateArgumentKind.scalar),
      'require_framebuffer_fetch': TemplateArgument(
        'require_framebuffer_fetch',
        TemplateArgumentKind.scalar,
      ),
      'gles_exclusions': TemplateArgument('gles_exclusions', TemplateArgumentKind.files),
      'vulkan_exclusions': TemplateArgument('vulkan_exclusions', TemplateArgumentKind.files),
      'entry_point_prefix': TemplateArgument('entry_point_prefix', TemplateArgumentKind.scalar),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    innerTargets: <String>[
      '{backend}_{name}',
      'impellerc_{backend}_{name}',
      'genlib_{backend}_{name}',
      'gen_blob_embed_{backend}_{name}',
      'embed_{backend}_{name}',
      'embed_embed_{backend}_{name}',
      'reflect_{backend}_{name}',
      'reflect_reflect_{backend}_{name}',
      'analyze_{backend}_{name}',
    ],
  ),
  // build/zip_bundle.gni: an archive under zip_archives/ made by build/zip.py
  // from `{ source, destination }` scopes, a generated LICENSE first
  // (build/bazel/zip_bundle.bzl runs the same script). GN's `deps` name the
  // targets whose outputs the entries are, which is how a source under the
  // build directory is resolved; under Bazel the entries' labels carry the
  // dependency, so the list itself is not written.
  'zip_bundle': TemplateMapping(
    '//engine/src/flutter/build/bazel:zip_bundle.bzl',
    'zip_bundle',
    <String, TemplateArgument>{
      'output': TemplateArgument('output', TemplateArgumentKind.scalar),
      'files': TemplateArgument('files', TemplateArgumentKind.archiveEntries),
      'deps': TemplateArgument('deps', TemplateArgumentKind.ignored),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
      // The invocations' helpers for their names and paths (`exe`, `prefix`,
      // `zip_out_dir`) are read by the strings of their own blocks, which
      // is how the converter tells them from arguments (GnTarget.readVariables).
    },
    files: true,
  ),
  // web_sdk.gni's wrapper of sdk_rewriter for dart:ui_web: the macro spells
  // out the template's fixed arguments (the library, its API file, the input
  // directory) and takes the invoker's output directory. GN expands it to a
  // prebuilt_dart_action, which is an action under the invocation's name.
  'web_ui_ui_web_with_output': TemplateMapping(
    '//engine/src/flutter/web_sdk:web_sdk.bzl',
    'web_ui_ui_web_with_output',
    <String, TemplateArgument>{
      'output_dir': TemplateArgument('output_dir', TemplateArgumentKind.buildPath),
    },
    files: true,
  ),
};

/// GN actions known by the script they run, converted as a template
/// invocation would be: the action's variables are the macro's arguments.
/// dart_pkg.py (sky/packages/sky_engine's `action("sky_engine")`) assembles
/// a Dart package directory in the build directory from the package's own
/// files and the SDK extension sources; its `args` are the same variables
/// rebased, and its outputs a stamp.
const Map<String, TemplateMapping> scriptMappings = <String, TemplateMapping>{
  '//flutter/build/dart/tools/dart_pkg.py': TemplateMapping(
    '//engine/src/flutter/build/bazel/dart:dart_pkg.bzl',
    'dart_pkg',
    <String, TemplateArgument>{
      'package_name': TemplateArgument('package', TemplateArgumentKind.scalar),
      'sources': TemplateArgument('srcs', TemplateArgumentKind.files),
      'sdk_ext_files': TemplateArgument('sdk_ext', TemplateArgumentKind.files),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      // The script's own arguments and bookkeeping, which the rule supplies.
      'script': TemplateArgument('script', TemplateArgumentKind.ignored),
      'args': TemplateArgument('args', TemplateArgumentKind.ignored),
      'inputs': TemplateArgument('inputs', TemplateArgumentKind.ignored),
      'outputs': TemplateArgument('outputs', TemplateArgumentKind.ignored),
      'pkg_directory': TemplateArgument('pkg_directory', TemplateArgumentKind.ignored),
      'stamp_file': TemplateArgument('stamp_file', TemplateArgumentKind.ignored),
      // GN's sdk_ext_directories: a generated directory nothing writes
      // ($root_gen_dir/sky/bindings), which the script walks as empty.
      'sdk_ext_directory': TemplateArgument('sdk_ext_directory', TemplateArgumentKind.ignored),
    },
    files: true,
  ),
};

/// Which imported `.gni` files the converter evaluates (Skia's lists,
/// arguments and templates; the engine's Skia wrapper files; Impeller's
/// arguments and its `impeller_component` template) and which it takes as
/// known through the tables above (the engine's own configuration files,
/// whose variables are [knownExternalVariables] and whose templates are
/// [templateMappings]; Impeller's shader templates, until something
/// converted invokes them).
const ImportPolicy engineImportPolicy = ImportPolicy(
  evaluatedPrefixes: <String>{
    '//flutter/third_party/skia/',
    '//flutter/skia/',
    '//flutter/impeller/tools/impeller.gni',
    '//flutter/impeller/tools/args.gni',
    '//flutter/impeller/tools/component.gni',
    // The shell_gpu_configuration template: a group over the GPU surfaces
    // and a config of SHELL_ENABLE_* defines, chosen by the invoker's
    // booleans.
    '//flutter/shell/gpu/gpu.gni',
    // Declares embedder_for_target (false: the embedder's shared library is
    // a host artifact), which the embedder's own file reads.
    '//flutter/shell/platform/embedder/embedder.gni',
    // The client wrapper's file lists (the sources and headers of the
    // package, by absolute path), which its own file reads.
    '//flutter/shell/platform/common/client_wrapper/core_wrapper_files.gni',
    // The publish_client_wrapper templates: copies of the wrapper's files
    // into the build directory's cpp_client_wrapper[_<platform>] (the
    // artifact clients compile), which the platform wrappers invoke.
    '//flutter/shell/platform/common/client_wrapper/publish.gni',
    // Declares build_glfw_shell (a Linux host builds the GLFW shell beside
    // the GTK one), which the Linux shell's file reads.
    '//flutter/shell/platform/glfw/config.gni',
    '//flutter/third_party/glfw/glfw_args.gni',
    // The engine's answers to the Khronos trees' build_overrides (where
    // SPIRV-Headers and SPIRV-Tools are, build_with_chromium = false) and
    // their own argument files.
    '//build_overrides/build.gni',
    '//build_overrides/spirv_tools.gni',
    '//build_overrides/glslang.gni',
    '//build_overrides/vulkan_headers.gni',
    '//flutter/third_party/vulkan-deps/',
    // The Dart SDK's library source lists (<library>_sources.gni) and
    // dart:ui's (dart_ui.gni), which sky/packages/sky_engine copies into the
    // sky_engine package.
    '//flutter/third_party/dart/sdk/lib/',
    '//flutter/lib/ui/dart_ui.gni',
  },
  known: <String>{
    // The Dart package templates (dart_pkg); sky_engine writes its action
    // out by hand and the converter maps it by its script (scriptMappings).
    '//flutter/build/dart/rules.gni',
    // The web SDK's templates; web_ui_ui_web_with_output is in templateMappings.
    '//flutter/web_sdk/web_sdk.gni',
    '//flutter/build/dart/dart.gni',
    '//flutter/common/config.gni',
    '//flutter/impeller/tools/shaders.gni',
    '//flutter/shell/config.gni',
    // Declares the version arguments and asserts they are set; nothing
    // converted reads them (impeller/compiler imports it without use).
    '//flutter/shell/version/version.gni',
    '//flutter/testing/testing.gni',
    // The zip_bundle template (artifact packaging); its one invocation in
    // converted files, the interop toolkit's SDK bundle, is skipped.
    '//flutter/build/zip_bundle.gni',
    // The compiled_action template, which lib/ui's shader fixture
    // directories import without invoking (impellerc() does).
    '//build/compiled_action.gni',
    // Declares use_clang_type_profiler, enable_lto, enable_coverage and
    // stripped_symbols; the embedder imports it and reads none of them.
    '//build/toolchain/clang.gni',
    // Declares disable_vma_stl_shared_mutex (above).
    '//flutter/flutter_vma/config.gni',
    // Declares enable_vulkan_validation_layers; nothing converted reads it.
    '//flutter/vulkan/config.gni',
    // The native_activity_apk template, invoked under is_android alone.
    '//flutter/testing/android/native_activity/native_activity.gni',
    '//flutter/third_party/flatbuffers/flatbuffers.gni',
    '//flutter/tools/fuchsia/gn-sdk/src/gn_configs.gni',
  },
);

/// Which assumptions describe the Linux x64 host build (the values
/// `tools/gn` gives these arguments for it, as in `out/host_debug*/args.gn`).
/// Everything not fixed here stays a select(): `is_debug`, the runtime mode
/// and slimpeller in particular, which are Bazel flags.
Assumptions linuxHostAssumptions() {
  return Assumptions(const <String, GnValue>{
    // //build/config/BUILDCONFIG.gn
    'current_cpu': GnStringValue('x64'),
    'current_os': GnStringValue('linux'),
    'current_toolchain': GnStringValue('//build/toolchain/linux:clang_x64'),
    'default_library_type': GnStringValue('static_library'),
    'default_toolchain': GnStringValue('//build/toolchain/linux:clang_x64'),
    'host_cpu': GnStringValue('x64'),
    'host_os': GnStringValue('linux'),
    'host_toolchain': GnStringValue('//build/toolchain/linux:clang_x64'),
    'target_cpu': GnStringValue('x64'),
    'target_os': GnStringValue('linux'),
    'is_android': GnBoolValue(false),
    'is_apple': GnBoolValue(false),
    // is_clang, dart_src: build invariants (gn_eval's buildInvariants).
    'is_component_build': GnBoolValue(false),
    'is_fuchsia': GnBoolValue(false),
    'is_ios': GnBoolValue(false),
    'is_linux': GnBoolValue(true),
    'is_mac': GnBoolValue(false),
    // BUILDCONFIG.gn's default; tools/gn sets it only for the Dart SDK's
    // own configuration (the wrap's args).
    'is_minimal_linux': GnBoolValue(false),
    'is_official_build': GnBoolValue(true),
    'is_qnx': GnBoolValue(false),
    'is_wasm': GnBoolValue(false),
    'is_win': GnBoolValue(false),
    // BUILDCONFIG.gn: clang on Linux links the engine's own libc++.
    'use_flutter_cxx': GnBoolValue(true),
    // //flutter/common/config.gni
    'enable_backtrace': GnBoolValue(true),
    'enable_unittests': GnBoolValue(true),
    // The artifact names (config.gni computes them from host_os, host_cpu,
    // target_os and target_cpu), and whether the host builds the SDK's
    // artifacts at all: on a Linux x64 host, yes.
    'platform_name': GnStringValue('linux'),
    'full_platform_name': GnStringValue('linux-x64'),
    'target_platform_name': GnStringValue('linux'),
    'full_target_platform_name': GnStringValue('linux-x64'),
    'build_engine_artifacts': GnBoolValue(true),
    // tools/gn's --prebuilt-dart-sdk, which every host builder passes and
    // `et` defaults to: the engine's Dart tooling comes from the prebuilt
    // SDK under flutter/prebuilts (host_debug_no_prebuilt_dart_sdk is the
    // one config that builds it, from the Dart tree).
    'flutter_prebuilt_dart_sdk': GnBoolValue(true),
    'prebuilt_dart_sdk': GnStringValue('//flutter/prebuilts/linux-x64/dart-sdk'),
    'host_prebuilt_dart_sdk': GnStringValue('//flutter/prebuilts/linux-x64/dart-sdk'),
    'target_prebuilt_dart_sdk': GnStringValue('//flutter/prebuilts/linux-x64/dart-sdk'),
    // //flutter/shell/config.gni
    'shell_enable_gl': GnBoolValue(true),
    'shell_enable_metal': GnBoolValue(false),
    'shell_enable_software': GnBoolValue(true),
    'shell_enable_vulkan': GnBoolValue(true),
    'test_enable_gl': GnBoolValue(true),
    'test_enable_metal': GnBoolValue(false),
    'test_enable_software': GnBoolValue(true),
    'test_enable_vulkan': GnBoolValue(true),
    // //flutter/flutter_vma/config.gni: a Linux host has std::shared_mutex.
    'disable_vma_stl_shared_mutex': GnBoolValue(false),
    // //flutter/impeller/tools/args.gni, as its defaults come out on Linux.
    'impeller_enable_metal': GnBoolValue(false),
    'impeller_enable_opengles': GnBoolValue(true),
    'impeller_enable_vulkan': GnBoolValue(true),
    // Skia's arguments as tools/gn sets them for a Linux host; the rest take
    // the defaults of //flutter/third_party/skia/gn/skia.gni.
    // skia_use_fontconfig is not here: tools/gn sets it from
    // --enable-fontconfig, which is a Bazel flag (conditionSettings).
    'skia_enable_pdf': GnBoolValue(false),
    'skia_gl_standard': GnStringValue(''),
    'skia_use_dng_sdk': GnBoolValue(false),
    'skia_use_expat': GnBoolValue(true),
    'skia_use_gl': GnBoolValue(true),
    'skia_use_icu': GnBoolValue(true),
    'skia_use_libpng_decode': GnBoolValue(true),
    'skia_use_libpng_encode': GnBoolValue(true),
    'skia_use_rust_png_decode': GnBoolValue(false),
    'skia_use_rust_png_encode': GnBoolValue(false),
    'skia_use_vma': GnBoolValue(false),
    'skia_use_vulkan': GnBoolValue(true),
    'skia_use_wuffs': GnBoolValue(true),
    'skia_use_x11': GnBoolValue(false),
    'skia_use_xps': GnBoolValue(false),
  });
}
