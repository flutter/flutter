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
  // 91 s on a Mac (504 tests: the accessibility bridge's there), where
  // small's 60 s stopped it at 364 (the Mac's T14).
  'common_cpp_unittests': 'medium',
  // The macOS shell's suite: 29 files of engine runs over the fixtures,
  // each test twice and shuffled (testRuns), on a Mac.
  'flutter_desktop_darwin_unittests': 'large',
  // 56 tests, each initializing a git repository and committing to it:
  // ~2 s a test, 54 of them inside small's 60 s on a machine building the
  // GPU backends at the same time.
  'licenses_cpp_testrunner': 'medium',
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
    this.macArgs,
  });

  final List<String> args;

  /// The arguments run_tests.py passes on a macOS host, where they differ
  /// from [args] (a Linux host's): a select() on the host's setting
  /// (host_os_is_mac). Null where the hosts agree.
  final List<String>? macArgs;

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
  // which a Linux host skips; a Mac runs it with the shuffle flags too.
  '//flutter/impeller:impeller_dart_unittests': TestRun(
    args: <String>['--enable_vulkan_validation', '--gtest_filter=*Metal'],
    macArgs: <String>[
      '--gtest_repeat=2',
      '--gtest_shuffle',
      '--enable_vulkan_validation',
      '--gtest_filter=*Metal',
    ],
    data: <String>[],
  ),
  // run_tests.py (macOS) runs impeller_unittests without the OpenGLES
  // variants ("covered in the golden tests") and with Vulkan validation,
  // under the Metal validation environment (flutter_display_test sets it
  // on a Mac) -- through gtest-parallel there, where a Linux host runs the
  // binary whole: the Bazel test runs it whole on both for now (the
  // per-process isolation and --repeat=2 of the Mac's run are a
  // divergence on record, research/20 §12). The second, interactive run of
  // the ColorWheel test under --enable_playground is not a Bazel test yet.
  '//flutter/impeller:impeller_unittests': TestRun(
    args: <String>[],
    macArgs: <String>['--gtest_filter=-*OpenGLES:*OpenGLESSDF', '--enable_vulkan_validation'],
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
  // run_tests.py (macOS) runs the macOS shell's suite whole, every test
  // twice and shuffled (shuffle_flags): "flutter_desktop_darwin_unittests
  // uses global state that isn't handled correctly by gtest-parallel"
  // (flutter/flutter#104789). It skips the suite on host_debug builds for
  // flakiness (flutter/flutter#127441); Bazel runs it in every
  // configuration -- the flakiness is the suite's to fix.
  '//flutter/shell/platform/darwin/macos:flutter_desktop_darwin_unittests': TestRun(
    args: <String>['--gtest_repeat=2', '--gtest_shuffle'],
    data: <String>[],
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
  // The iOS scenario app's platform_view.dart and locale_initialization.dart
  // import package:vector_math (the Mac's T29).
  '//flutter/testing/ios_scenario_app:ios_scenario_app_snapshot': <String, String>{
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
  '//third_party/cpu_features': '@cpu_features',
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
  // The target's gen_snapshot, as a dependency (the archives' deps): the
  // wrap's product, which an entry naming $root_out_dir/gen_snapshot
  // resolves to as well (buildOutputLabels).
  '//flutter/third_party/dart/runtime/bin:gen_snapshot':
      '//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot',
  // The target's analyze_snapshot (the root group lists it beside
  // gen_snapshot where the engine artifacts are built): the wrap's product
  // too, an aarch64 binary in the Linux arm64 cross build.
  '//flutter/third_party/dart/runtime/bin:analyze_snapshot':
      '//engine/src/flutter/build/bazel/dart_wrap:analyze_snapshot',
  // The same two named in the host toolchain (lib/snapshot's
  // generate_snapshot_bins, the Android shell's archives of them): the
  // wrap's host products, which in a cross build sit under the host
  // toolchain's directory and in the host's own build are the target's
  // files.
  r'//flutter/third_party/dart/runtime/bin:gen_snapshot($host_toolchain)':
      '//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot_host',
  r'//flutter/third_party/dart/runtime/bin:analyze_snapshot($host_toolchain)':
      '//engine/src/flutter/build/bazel/dart_wrap:analyze_snapshot_host',
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
  '//flutter/third_party/cpu_features': '@cpu_features',
  '//flutter/third_party/libjpeg-turbo': '@libjpeg-turbo',
  '//flutter/third_party/libpng': '@libpng',
  '//flutter/third_party/libwebp': '@libwebp',
  '//flutter/third_party/wuffs': '@wuffs',
  // OCMock (a Mac's; the Objective-C suites' mocks), engine GN in the
  // secondary tree over the synced tree.
  '//flutter/third_party/ocmock': '@ocmock',
  '//third_party/libpng': '@libpng',
  // The shader compiler's dependencies (research/08): engine GN in the
  // secondary tree over synced trees (inja, json, SPIRV-Cross, flatbuffers)
  // and SPIRV-Headers' own GN, each a fetch-time repository.
  '//third_party/inja': '@inja',
  // The secondary tree's //third_party/brotli (build/secondary), over the
  // synced tree, which FreeType names for WOFF2.
  '//third_party/brotli': '@brotli',
  '//flutter/third_party/json': '@json',
  '//third_party/spirv_cross_flutter': '@spirv-cross//:spirv_cross_flutter',
  '//flutter/third_party/flatbuffers': '@flatbuffers',
  '//flutter/third_party/vulkan-deps/spirv-headers/src': '@spirv-headers',
  '//flutter/third_party/vulkan-deps/spirv-tools/src': '@spirv-tools',
  '//flutter/third_party/vulkan-deps/glslang/src': '@glslang',
  // The Vulkan validation layer (the secondary tree's GN over the synced
  // tree) and the layer-settings library it links, each a fetch-time
  // repository; the Android embedding's debug jar packs the layer.
  '//third_party/vulkan_validation_layers': '@vulkan_validation_layers',
  '//flutter/third_party/vulkan-deps/vulkan-utility-libraries/src': '@vulkan-utility-libraries',
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

/// The views of a repository's headers under the engine's root-relative
/// spellings (`third_party/abseil-cpp/absl/...`,
/// `third_party/googletest/googletest/include/gtest/...`, which GN's root
/// include directories resolve beside the canonical ones the repository's
/// own build files expose), by the repository's label prefix: listed beside
/// every dependency into the repository, so that the engine's includes stay
/// as they are. Repositories with an overlay of the engine's own carry
/// their view in their libraries instead (ICU's root_includes).
const Map<String, List<String>> rootIncludeViews = <String, List<String>>{
  '@abseil-cpp//': <String>['@abseil_cpp_tree//:root_includes'],
  // The Vulkan headers under "third_party/vulkan-deps/vulkan-headers/src/
  // include/..." (the Android swapchain's spelling, through //flutter as an
  // include root).
  '@vulkan-headers//': <String>['@vulkan_deps_tree//:root_includes'],
  '@googletest//': <String>[
    '@googletest_tree//:root_includes',
    '@googletest_tree//:third_party_dir_includes',
  ],
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
  '//flutter/third_party/ocmock/': '@ocmock//',
  '//flutter/third_party/inja/': '@inja//',
  '//flutter/third_party/brotli/': '@brotli//',
  '//flutter/third_party/json/': '@json//',
  '//flutter/third_party/rapidjson/': '@rapidjson//',
  '//flutter/third_party/vulkan-deps/spirv-cross/src/': '@spirv-cross//',
  '//flutter/third_party/flatbuffers/': '@flatbuffers//',
  '//flutter/third_party/vulkan-deps/spirv-headers/src/': '@spirv-headers//',
  '//flutter/third_party/vulkan-deps/spirv-tools/src/': '@spirv-tools//',
  '//flutter/third_party/vulkan-deps/vulkan-validation-layers/src/': '@vulkan_validation_layers//',
  '//flutter/third_party/vulkan-deps/vulkan-utility-libraries/src/': '@vulkan-utility-libraries//',
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
  // The Android SDK and NDK (the files the overlay exports: android.jar, the
  // build tools' jars).
  '//flutter/third_party/android_tools/': '@android_tools//',
  // The JDK, whose javac and jar the Android embedding's actions run.
  '//flutter/third_party/java/openjdk/': '@openjdk//',
  // The embedding's compile-time dependencies (the AndroidX jars), its
  // classpath.
  '//flutter/third_party/android_embedding_dependencies/': '@android_embedding_dependencies//',
};

/// What an action's script imports beside itself (`from util import
/// build_utils`, `import jar` in build/android/gyp's scripts), by the
/// script's GN path: the action's inputs gain these, for the sandbox. A
/// script that imports nothing of its own needs no entry.
const Map<String, List<String>> scriptInputs = <String, List<String>>{
  '//build/android/gyp/javac.py': <String>['//engine/src/build:android_gyp_scripts'],
  '//build/android/gyp/create_flutter_jar.py': <String>['//engine/src/build:android_gyp_scripts'],
};

/// The platform a GN toolchain on an action's dependency edge stands for
/// (`deps += [ "//third_party/vulkan_validation_layers($apilevel26_toolchain)" ]`):
/// the dependency is built for it (gn_action's platform_deps, through a
/// transition), and its outputs sit under the toolchain's directory of the
/// build directory ([toolchainDirectories]).
const Map<String, String> toolchainPlatforms = <String, String>{
  '//build/toolchain/android:clang_arm64_apilevel26':
      '//engine/src/flutter/build/bazel/toolchains:android_arm64_api26',
};

/// The outputs of an action that are directories (GN declares a directory
/// output like a file: the Android embedding's javadoc tree, the sky_engine
/// package copied for release), by the action's GN label, each as its path
/// under `$target_gen_dir` -- or, for an output under the build directory
/// itself, under that: declared as directories (gn_action's output_dirs,
/// build_output_dirs).
const Map<String, Set<String>> actionDirectoryOutputs = <String, Set<String>>{
  '//flutter/shell/platform/android:gen_android_javadoc': <String>{'javadocs'},
  '//flutter/sky/dist:sky_engine': <String>{'dist/packages/sky_engine'},
};

/// Programs an action runs, which GN names by their absolute paths
/// (`rebase_path("//flutter/third_party/java/openjdk/bin/javac")`), each
/// with the files it loads at run time: the program is a tool of the rule
/// (gn_action's `tools`, built or taken for the execution platform), and so
/// are these, rather than an input.
const Map<String, List<String>> toolRuntimes = <String, List<String>>{
  '@openjdk//:bin/javac': <String>['@openjdk//:runtime'],
  '@openjdk//:bin/jar': <String>['@openjdk//:runtime'],
  '@openjdk//:bin/javadoc': <String>['@openjdk//:runtime'],
};

/// Generated include directories (`$root_gen_dir/flutter`) that are an
/// ancestor package's: Bazel's `includes` is package-relative, and the
/// target whose `includes` names that package's directory already covers
/// its twin in the output tree, so the directory is a dependency on it.
const Map<String, String> genDirIncludeTargets = <String, String>{
  '//': defaultIncludeDirsLabel,
  '//flutter': '//engine/src/flutter:config',
  // The darwin common package's generated directory, where its Swift
  // module's header lands (`InternalFlutterSwiftCommon/...h`): its
  // config("config") names it, and the macOS shell's Swift target takes
  // that config from across the file boundary.
  '//flutter/shell/platform/darwin/common':
      '//engine/src/flutter/shell/platform/darwin/common:config',
};

/// Include directories in another repository that a Bazel library of that
/// repository carries in its `includes`: GN's `include_dirs = [
/// "//flutter/third_party/angle/include" ]` cannot be written as a
/// package-relative `includes`, so the directory becomes a dependency on the
/// library, which puts the same `-I` on the same compiles. Keys are GN
/// paths as `//dir`.
const Map<String, String> includeDirLibraries = <String, String>{
  '//flutter/third_party/angle/include': '@angle//:headers',
  // SPIRV-Tools' root, which the Vulkan validation layer's GN names as an
  // include directory (build_overrides' vvl_glslang_dir): the appendix's
  // root_include library of @spirv-tools.
  '//flutter/third_party/vulkan-deps/spirv-tools/src': '@spirv-tools//:root_include',
  // ICU's source directories, which Skia's client-ICU bidi library names
  // as include directories (and as -isystem directories, which go: see
  // withoutSystemIncludeDirs): the overlay's headers library.
  '//flutter/third_party/icu/source/common': '@icu//:headers',
  '//flutter/third_party/icu/source/i18n': '@icu//:headers',
  // tonic's config: its headers as "tonic/..." and "third_party/tonic/...".
  '//flutter/third_party': '//engine/src/flutter/third_party:include_dir',
  '//flutter': '//engine/src/flutter:config',
  // The GLFW client wrapper's config: the core wrapper's headers as
  // siblings of its own (the merged layout clients build), a library of
  // the core wrapper's package (its manifest appendix) since `includes` is
  // package-relative.
  '//flutter/shell/platform/common/client_wrapper/include/flutter':
      '//engine/src/flutter/shell/platform/common/client_wrapper:relative_core_wrapper_headers',
  // The darwin frameworks' shared headers as siblings of the platform's
  // own (the layout a client sees): darwin/common's config
  // framework_relative_headers carries the directory; the macOS shell's
  // Swift target names it as an include directory.
  '//flutter/shell/platform/darwin/common/framework/Headers':
      '//engine/src/flutter/shell/platform/darwin/common:framework_relative_headers',
  // The accessibility tree's root, which its packages name as their
  // include directory (`#include "ax/..."`, `"base/..."`): the root's
  // config library carries it.
  '//flutter/third_party/accessibility':
      '//engine/src/flutter/third_party/accessibility:accessibility_config',
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
  // configuration of each target -- unless the table names the label in
  // its toolchain (the host's gen_snapshot in a cross build).
  var toolchain = '';
  final int paren = gnLabel.indexOf('(');
  if (paren > 0 && gnLabel.endsWith(')')) {
    toolchain = gnLabel.substring(paren);
    gnLabel = gnLabel.substring(0, paren);
  }
  if (gnLabel.startsWith(':')) {
    return gnLabel;
  }
  final String absolute = absoluteGnLabel(gnLabel, package: package);
  final String? override =
      (toolchain.isEmpty ? null : labelOverrides['$absolute$toolchain']) ??
      labelOverrides[absolute];
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
  if (absolute.startsWith('//flutter/') ||
      absolute.startsWith('//flutter:') ||
      absolute == '//flutter') {
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
  // The Vulkan headers' public config (the include directory and the
  // platform defines), which the validation layers list as a public config
  // of their own from the secondary tree's GN: @vulkan-headers' library of
  // the same name.
  '//flutter/third_party/vulkan-deps/vulkan-headers/src:vulkan_headers_config': ConfigDependency(
    '@vulkan-headers//:vulkan_headers_config',
  ),
  '//flutter:export_dynamic_symbols': ConfigDependency(
    '//engine/src/flutter:export_dynamic_symbols',
  ),
  '//flutter:export_dynamic_test_symbols': ConfigDependency(
    '//engine/src/flutter:export_dynamic_test_symbols',
  ),
  '//flutter/common:flutter_config': ConfigDependency('//engine/src/flutter/common:flutter_config'),
  // The accessibility tree's public config (its root as an include
  // directory; a Windows define), which its packages and the desktop
  // embeddings' bridge list: the root file's library of the same name.
  '//flutter/third_party/accessibility:accessibility_config': ConfigDependency(
    '//engine/src/flutter/third_party/accessibility:accessibility_config',
  ),
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
  // //build/config/compiler:no_rtti, a default config whose -fno-rtti is
  // the toolchain's; the Vulkan validation layer removes it and lists
  // :rtti, which is empty outside Windows (/GR): -frtti turns it back on.
  '//build/config/compiler:no_rtti': ConfigToolchain(removalCopts: <String>['-frtti']),
  // //build/config/gcc:symbol_visibility_hidden, a default config whose
  // -fvisibility=hidden and _LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS are the
  // toolchain's; OCMock removes it (its classes are mocked across the
  // suite's objects): visibility back to default, the define undone.
  // //build/config:symbol_visibility_hidden is empty ("present because this
  // is also present in other buildroots").
  '//build/config/gcc:symbol_visibility_hidden': ConfigToolchain(
    removalCopts: <String>['-fvisibility=default', '-U_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS'],
  ),
  '//build/config:symbol_visibility_hidden': ConfigImplied(),
  // //build/config/ios:ios_application_extension: -fapplication-extension
  // on the Objective-C compiles and the link (the iOS embedding is built
  // app-extension-safe): the flag inlined on the listing target's compiles
  // (every source of it, where GN gives it to the Objective-C ones -- the
  // targets are Objective-C), the link's through the library's linkopts.
  '//build/config/ios:ios_application_extension': ConfigDependency(
    '//engine/src/flutter/build/bazel:ios_application_extension',
    copts: <String>['-fapplication-extension'],
  ),
  '//build/config/compiler:rtti': ConfigCopts(<(Condition, List<String>)>[]),
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
/// The package of the web build's per-variant settings.
const String _webSettings = '//engine/src/flutter/build/bazel/web';

/// skia.gni's arguments the six wasm toolchains set per variant
/// (//flutter/third_party/canvaskit/BUILD.gn's extra_toolchain_args; the
/// list in build/bazel/web/BUILD.bazel): build settings, so that Skia's
/// fetch-time conversion carries select()s where GN reads them and a
/// variant's platform sets them (wasm_platform). wasm_use_workers and
/// wasm_prioritize_size are compiler flags in GN and features of the
/// emscripten toolchain here; no converted file reads them.
const List<String> webVariantArguments = <String>[
  'skia_use_icu',
  'skia_use_client_icu',
  'skia_use_libjpeg_turbo_decode',
  'skia_use_libpng_decode',
  'skia_use_libwebp_decode',
  'skia_use_no_png_encode',
  'skia_use_libpng_encode',
  'skia_enable_threadlocal_strikecache',
  // The CanvasKit toolchains' (the WebParagraph variant turns the text
  // stack off: no paragraph, shaper, HarfBuzz or FreeType, bidi from ICU's
  // library alone).
  'skia_use_bidi',
  'skia_canvaskit_enable_bidi',
  'skia_enable_skparagraph',
  'skia_canvaskit_enable_paragraph',
  'skia_enable_skshaper',
  'skia_use_harfbuzz',
  'skia_use_freetype',
  'flutter_use_freetype_woff2',
  'skia_enable_fontmgr_custom_embedded',
  'skia_enable_fontmgr_custom_empty',
  'skia_canvaskit_enable_font',
  'skia_canvaskit_enable_alias_font',
];

final Map<String, String> conditionSettings = Map<String, String>.unmodifiable(<String, String>{
  'is_android': '@platforms//os:android',
  'is_fuchsia': '@platforms//os:fuchsia',
  'is_ios': '@platforms//os:ios',
  'is_linux': '@platforms//os:linux',
  'is_mac': '@platforms//os:macos',
  'is_qnx': '@platforms//os:qnx',
  'is_wasm': '@platforms//os:emscripten',
  'is_win': '@platforms//os:windows',
  'is_debug': '//engine/src/flutter/build/bazel:unoptimized',
  // BUILDCONFIG.gn's is_asan (tools/gn --asan): the build-wide flag the
  // toolchains' asan feature selects on; the iOS shell copies clang's ASan
  // runtime beside the framework under it.
  'is_asan': '//engine/src/flutter/build/bazel:asan_enabled',
  // darwin_sdk.gni's use_ios_simulator (tools/gn --simulator; ios_use_simulator
  // is Skia's alias): the iOS platforms' environment constraint
  // (build/bazel:ios_environment), which holds on iOS alone -- as GN reads
  // it: the engine's files test it under is_ios.
  'use_ios_simulator': '//engine/src/flutter/build/bazel:ios_simulator_enabled',
  'ios_use_simulator': '//engine/src/flutter/build/bazel:ios_simulator_enabled',
  'slimpeller': '//engine/src/flutter/common:slimpeller_enabled',
  // GN's `current_toolchain == host_toolchain` with neither toolchain
  // assumed (gn_eval's hostToolchainPredicate): the OSes a host runs.
  'is_host_toolchain': '//engine/src/flutter/build/bazel:host_toolchain',
  // embedder.gni's embedder_for_target (tools/gn --embedder-for-target): the
  // embedder API built for the target too; a setting (build/bazel/BUILD.bazel).
  'embedder_for_target': '//engine/src/flutter/build/bazel:embedder_for_target_enabled',
  // testing.gni's default, `current_toolchain == host_toolchain || is_fuchsia
  // || is_mac`, read in Bazel terms (the group in //flutter/testing's
  // appendix).
  'enable_unittests': '//engine/src/flutter/testing:unittests_enabled',
  // testing.gni's enable_ios_unittests (`is_ios && flutter_runtime_mode ==
  // "debug"`): the iOS embedding's XCTest suite.
  'enable_ios_unittests': '//engine/src/flutter/testing:ios_unittests_enabled',
  // testing/rules/runtime_mode.gni's is_aot (`flutter_runtime_mode ==
  // "profile" || flutter_runtime_mode == "release"`, the AOT modes of the
  // Android and iOS test apps): the groups in //flutter/testing's appendix.
  'is_aot': '//engine/src/flutter/testing:aot_enabled',
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
  // The web build's per-variant arguments (the wasm toolchains'
  // extra_toolchain_args in //flutter/third_party/canvaskit/BUILD.gn):
  // build settings a variant's platform sets (build/bazel/web; research/12).
  for (final String argument in webVariantArguments) argument: '$_webSettings:${argument}_on',
  // runtime_args.gni's dart_dynamic_modules (tools/gn
  // --gn-args=dart_dynamic_modules=true, the `_ddm` builders): the Dart
  // wrap's flag, which the archives' names also read.
  'dart_dynamic_modules': '//engine/src/flutter/build/bazel/dart_wrap:dart_dynamic_modules_enabled',
  // runtime_args.gni's dart_disable_secure_socket (tools/gn
  // --no-dart-secure-socket, the size-experiment builders): the Dart wrap's
  // flag, which the archives' names read (`-size-exp`).
  'dart_disable_secure_socket':
      '//engine/src/flutter/build/bazel/dart_wrap:dart_disable_secure_socket_enabled',
  // common/config.gni's enable_backtrace and build_engine_artifacts, as
  // tools/gn and the formula set them by platform: //flutter/common's
  // appendix. BUILDCONFIG.gn's use_flutter_cxx: build/bazel's group, the
  // same one the toolchains' cxx_runtime selects on.
  'enable_backtrace': '//engine/src/flutter/common:backtrace_enabled',
  'build_engine_artifacts': '//engine/src/flutter/common:engine_artifacts',
  'use_flutter_cxx': '//engine/src/flutter/build/bazel:flutter_cxx',
  // build/toolchain/clang.gni's stripped_symbols (tools/gn: on unless
  // --no-stripped; off for Android): build/bazel's `stripped` flag, which
  // the aspect that places binaries reads (D9).
  'stripped_symbols': '//engine/src/flutter/build/bazel:stripped_enabled',
  // shell/config.gni's backend arguments, as its defaults and tools/gn set
  // them by platform: the groups in //flutter/shell's appendix.
  'shell_enable_gl': '//engine/src/flutter/shell:enable_gl',
  'shell_enable_metal': '//engine/src/flutter/shell:enable_metal',
  'shell_enable_software': '//engine/src/flutter/shell:enable_software',
  'shell_enable_vulkan': '//engine/src/flutter/shell:enable_vulkan',
  'test_enable_gl': '//engine/src/flutter/shell:test_enable_gl',
  'test_enable_metal': '//engine/src/flutter/shell:test_enable_metal',
  'test_enable_software': '//engine/src/flutter/shell:test_enable_software',
  'test_enable_vulkan': '//engine/src/flutter/shell:test_enable_vulkan',
});

/// The config_setting that holds exactly when a GN predicate is *false*, for
/// the denied terms of a conjunction (`impeller_enable_opengles && !is_wasm`
/// becomes a `config_setting_group(match_all)`, which needs a setting per
/// term). On its own a denial needs none: its `select()` has the key empty
/// and the default carrying the branch. The OS predicates exclude each other,
/// so each complement is the group of the other seven (build/bazel/BUILD.bazel).
final Map<String, String> negatedSettings = Map<String, String>.unmodifiable(<String, String>{
  'is_android': '//engine/src/flutter/build/bazel:not_android',
  'embedder_for_target': '//engine/src/flutter/build/bazel:embedder_for_target_disabled',
  'is_fuchsia': '//engine/src/flutter/build/bazel:not_fuchsia',
  'is_ios': '//engine/src/flutter/build/bazel:not_ios',
  'is_linux': '//engine/src/flutter/build/bazel:not_linux',
  'is_mac': '//engine/src/flutter/build/bazel:not_mac',
  'is_qnx': '//engine/src/flutter/build/bazel:not_qnx',
  'is_wasm': '//engine/src/flutter/build/bazel:not_wasm',
  'is_win': '//engine/src/flutter/build/bazel:not_win',
  'is_asan': '//engine/src/flutter/build/bazel:asan_disabled',
  // The JIT modes (debug, jit_release).
  'is_aot': '//engine/src/flutter/testing:aot_disabled',
  // Not the simulator: a device, or not iOS at all.
  'use_ios_simulator': '//engine/src/flutter/build/bazel:ios_simulator_disabled',
  'ios_use_simulator': '//engine/src/flutter/build/bazel:ios_simulator_disabled',
  // The host's own build, denied: the OSes only a target runs.
  'is_host_toolchain': '//engine/src/flutter/build/bazel:not_host_toolchain',
  'use_flutter_cxx': '//engine/src/flutter/build/bazel:not_flutter_cxx',
  for (final String argument in webVariantArguments) argument: '$_webSettings:${argument}_off',
  'enable_backtrace': '//engine/src/flutter/common:backtrace_disabled',
  // The shell's backends, denied (software is everywhere: no complement).
  'shell_enable_gl': '//engine/src/flutter/shell:not_enable_gl',
  'shell_enable_metal': '//engine/src/flutter/shell:not_enable_metal',
  'shell_enable_vulkan': '//engine/src/flutter/shell:not_enable_vulkan',
  'test_enable_gl': '//engine/src/flutter/shell:not_enable_gl',
  'test_enable_metal': '//engine/src/flutter/shell:not_enable_metal',
  'test_enable_vulkan': '//engine/src/flutter/shell:not_enable_vulkan',
  // A flag's denial has a setting of its own where a conjunction needs one
  // (`!dart_dynamic_modules && flutter_runtime_mode == "debug"`: the
  // archives' names).
  'dart_dynamic_modules':
      '//engine/src/flutter/build/bazel/dart_wrap:dart_dynamic_modules_disabled',
  'dart_disable_secure_socket':
      '//engine/src/flutter/build/bazel/dart_wrap:dart_disable_secure_socket_disabled',
  'stripped_symbols': '//engine/src/flutter/build/bazel:stripped_disabled',
});

/// The Bazel config_setting for `variable == "value"`, by variable and value.
/// `target_os == "wasm"` (fml) is the OS predicate's constraint.
final Map<String, Map<String, String>> comparisonSettings =
    Map<String, Map<String, String>>.unmodifiable(<String, Map<String, String>>{
      'flutter_runtime_mode': <String, String>{
        'debug': '//engine/src/flutter/common:runtime_mode_debug',
        'profile': '//engine/src/flutter/common:runtime_mode_profile',
        'release': '//engine/src/flutter/common:runtime_mode_release',
        'jit_release': '//engine/src/flutter/common:runtime_mode_jit_release',
      },
      'target_os': _osNameSettings,
      'current_os': _osNameSettings,
      'target_cpu': _cpuNameSettings,
      // The CPU of the toolchain evaluating the file (libpng's NEON sources):
      // the configuration's, which for a tool built for the host is the
      // execution platform's, as a select() on a CPU constraint reads.
      'current_cpu': _cpuNameSettings,
      'full_target_platform_name': _targetPlatformSettings,
      // The OS of the machine that builds (`host_os == "mac"`: the text
      // tests' fixtures take a Mac's emoji font), a setting of the whole
      // build from @host_platform (//engine/src/flutter/build/bazel). A
      // comparison reaches here where a file's assumptions make host_os a
      // cased value ([hostOsCases]); elsewhere host_os is the generation's
      // host, a string.
      'host_os': _hostOsSettings,
    });

/// The host OSes GN's files compare `host_os` with, to the settings that
/// hold when the machine building is that OS.
const Map<String, String> _hostOsSettings = <String, String>{
  'linux': '//engine/src/flutter/build/bazel:host_os_is_linux',
  'mac': '//engine/src/flutter/build/bazel:host_os_is_mac',
  'win': '//engine/src/flutter/build/bazel:host_os_is_win',
};

/// `host_os` as a value with a case per host OS, for a file whose
/// `host_os == "..."` branches the generated file carries as select()s on
/// the host's setting ([comparisonSettings]) rather than evaluated for the
/// generation's host: the test fixtures that copy a file of the machine
/// (txt, impeller/fixtures: a Mac's emoji font, see [hostFiles]). Not the
/// generation's own assumption, since the strings GN builds from host_os
/// (the prebuilt SDK's directory, the artifacts' names) are the host's
/// constants of @host_platform at their use sites (research/20 §8).
const Map<String, GnValue> hostOsCases = <String, GnValue>{
  // The hosts the Bazel build runs on: Linux and a Mac. A Windows host's
  // branches (`.exe`, `.dll`) are no case, as a Windows host is no
  // platform of the build.
  'host_os': GnCasedValue('host_os', <String, String>{'linux': 'linux', 'mac': 'mac'}),
};

/// The assumptions of a file that only a Mac builds (the macOS shell): the
/// host is a Mac, and the host's platform name (`full_platform_name`, the
/// archives' `darwin-<cpu>`) is the target's -- the shell is built for the
/// Mac that builds it (tools/gn's --mac-cpu is the bot's own CPU on every
/// builder of mac_host_engine.json), so the name follows the target CPU's
/// setting.
const Map<String, GnValue> macHostAssumptions = <String, GnValue>{
  'host_os': GnStringValue('mac'),
  'platform_name': GnStringValue('darwin'),
  'full_platform_name': hostPlatformNameCases,
};

/// config.gni's `full_platform_name` (`<platform_name>-<host_cpu>`, the
/// host's own name for the artifacts it ships) as a value cased over the
/// target platform's setting, for a file that names the host's artifacts
/// by it (the embedder's and the macOS shell's framework archives): the
/// hosts the build runs on build their own platform -- a Linux x64 host
/// linux-x64, a Mac darwin-<its cpu> (tools/gn's --mac-cpu is the bot's
/// own on every builder) -- so the host's name is the target's there; a
/// cross build (Android from Linux) has no case, and names nothing by it.
const GnValue hostPlatformNameCases = GnCasedValue('full_target_platform_name', <String, String>{
  'linux-x64': 'linux-x64',
  'darwin-arm64': 'darwin-arm64',
  'darwin-x64': 'darwin-x64',
});

/// The `metadata` of engine targets whose GN files the converter does not
/// read (hand-written Bazel packages), for generated_file's metadata walk
/// ([starlark_emitter]'s): by label, each key's lines. lib/snapshot's
/// generate_snapshot_bin names gen_snapshot for the macOS artifacts'
/// entitlements list. An engine target the walk reaches that is neither
/// readable nor here is an error, so that a list never silently loses a
/// line; targets outside the engine's tree (the Dart tree's, the
/// third-party trees') carry none of the engine's keys and contribute
/// nothing.
const Map<String, Map<String, List<String>>> unreadMetadata = <String, Map<String, List<String>>>{
  '//flutter/lib/snapshot:generate_snapshot_bin': <String, List<String>>{
    'entitlement_file_path': <String>['gen_snapshot'],
  },
};

/// The engine packages the converter does not read whose targets the walk
/// may reach: every target of theirs with metadata is in [unreadMetadata],
/// the rest carry none (lib/snapshot's snapshot libraries and actions).
const Set<String> unreadMetadataPackages = <String>{'//flutter/lib/snapshot'};

/// Targets of the hand-written Bazel packages that a builder's ninja targets
/// may name (ci/builders/*.json), by GN directory, with the file-level
/// condition each exists under (null for always): the builders' installs
/// resolve ninja targets against the converted files' targets, and these
/// stand in for a package the converter does not generate. lib/snapshot's
/// create_macos_gen_snapshots is the Mac's gen_snapshot builders' one
/// target (ci/host_debug_gen_snapshot and its kin); generate_snapshot_bins
/// the iOS builders' (with the framework), the filegroup over the core
/// snapshot and the host's gen_snapshot.
const Map<String, Map<String, String?>> handWrittenNinjaTargets = <String, Map<String, String?>>{
  '//flutter/lib/snapshot': <String, String?>{
    'create_macos_gen_snapshots': 'is_mac',
    'generate_snapshot_bins': null,
  },
};

/// Files of the machine that builds, which GN's files name by absolute
/// path (a Mac's `/System/Library/Fonts/Apple Color Emoji.ttc`, the text
/// tests' fixture under `host_os == "mac"`): each is a file of the
/// `@host_files` repository (build_defs/repositories/host_files.bzl) at the
/// path less its leading slash, present on a machine that has it.
const Set<String> hostFiles = <String>{'/System/Library/Fonts/Apple Color Emoji.ttc'};

/// The label of a host file (see [hostFiles]).
String hostFileLabel(String path) => '@host_files//:${path.substring(1)}';

/// The values a string around an enumerated variable is expanded over, where
/// not every value with a setting is one the engine builds: the CPUs, less
/// the ones third-party files merely test for (mips, ppc).
const Map<String, List<String>> enumeratedValues = <String, List<String>>{
  'target_cpu': <String>['arm', 'arm64', 'riscv64', 'wasm', 'x64', 'x86'],
  'current_cpu': <String>['arm', 'arm64', 'riscv64', 'wasm', 'x64', 'x86'],
};

/// BUILDCONFIG.gn's CPU names, as `target_cpu` and `current_cpu` spell them,
/// to the CPU constraints.
const Map<String, String> _cpuNameSettings = <String, String>{
  'arm': '@platforms//cpu:armv7',
  'arm64': '@platforms//cpu:aarch64',
  // The CPUs the engine never builds for but third-party files test
  // (cpu_features' chain over current_cpu): keys no platform of the build
  // sets.
  'mips': '@platforms//cpu:mips64',
  'ppc': '@platforms//cpu:ppc',
  'riscv64': '@platforms//cpu:riscv64',
  'wasm': '@platforms//cpu:wasm32',
  'x64': '@platforms//cpu:x86_64',
  'x86': '@platforms//cpu:x86_32',
};

/// config.gni's full_target_platform_name values the engine builds
/// (tools/gn's --target-os/--<os>-cpu pairs), each to the group of its OS and
/// CPU constraints in //flutter/common's appendix (`platform_<name>`, the
/// dash an underscore).
final Map<String, String> _targetPlatformSettings = Map<String, String>.unmodifiable(
  <String, String>{
    for (final String name in targetPlatformNames)
      name: '//engine/src/flutter/common:platform_${name.replaceAll('-', '_')}',
  },
);

/// The `<target_platform_name>-<target_cpu>` pairs tools/gn builds.
const List<String> targetPlatformNames = <String>[
  'android-arm',
  'android-arm64',
  'android-riscv64',
  'android-x64',
  'android-x86',
  'darwin-arm64',
  'darwin-x64',
  'fuchsia-arm64',
  'fuchsia-x64',
  'ios-arm64',
  'ios-x64',
  'linux-arm64',
  'linux-x64',
  'wasm-wasm',
  'windows-arm64',
  'windows-x64',
];

/// The config_setting that holds exactly when `variable != "value"` does,
/// for the denied comparisons of a conjunction: the OS names' complements,
/// and the CPU names' (skcms: `target_cpu != "x64" || target_os ==
/// "android"`).
const Map<String, Map<String, String>> comparisonNegatedSettings = <String, Map<String, String>>{
  'target_os': _osNameNegatedSettings,
  'current_os': _osNameNegatedSettings,
  'target_cpu': _cpuNameNegatedSettings,
  'current_cpu': _cpuNameNegatedSettings,
  // The host's complement (`host_os != "mac"`: the branch a Mac's overrides,
  // in the archives' file names).
  'host_os': <String, String>{
    'linux': '//engine/src/flutter/build/bazel:host_os_is_not_linux',
    'mac': '//engine/src/flutter/build/bazel:host_os_is_not_mac',
    'win': '//engine/src/flutter/build/bazel:host_os_is_not_win',
  },
  // zip_bundle.gni's android_zip_archive_dir, a scalar grown under
  // `flutter_runtime_mode != "debug"` and read in a conjunction.
  'flutter_runtime_mode': <String, String>{
    'debug': '//engine/src/flutter/common:not_runtime_mode_debug',
    'profile': '//engine/src/flutter/common:not_runtime_mode_profile',
    'release': '//engine/src/flutter/common:not_runtime_mode_release',
    'jit_release': '//engine/src/flutter/common:not_runtime_mode_jit_release',
  },
};

/// The complements of the CPU constraints (//engine/src/flutter/build/bazel's
/// `not_cpu_<name>`: any of the other CPUs).
const Map<String, String> _cpuNameNegatedSettings = <String, String>{
  'arm': '//engine/src/flutter/build/bazel:not_cpu_arm',
  'arm64': '//engine/src/flutter/build/bazel:not_cpu_arm64',
  'mips': '//engine/src/flutter/build/bazel:not_cpu_mips',
  'ppc': '//engine/src/flutter/build/bazel:not_cpu_ppc',
  'riscv64': '//engine/src/flutter/build/bazel:not_cpu_riscv64',
  'wasm': '//engine/src/flutter/build/bazel:not_cpu_wasm',
  'x64': '//engine/src/flutter/build/bazel:not_cpu_x64',
  'x86': '//engine/src/flutter/build/bazel:not_cpu_x86',
};

const Map<String, String> _osNameSettings = <String, String>{
  'android': '@platforms//os:android',
  'fuchsia': '@platforms//os:fuchsia',
  'ios': '@platforms//os:ios',
  'linux': '@platforms//os:linux',
  'mac': '@platforms//os:macos',
  'qnx': '@platforms//os:qnx',
  'wasm': '@platforms//os:emscripten',
  'win': '@platforms//os:windows',
};

const Map<String, String> _osNameNegatedSettings = <String, String>{
  'android': '//engine/src/flutter/build/bazel:not_android',
  'fuchsia': '//engine/src/flutter/build/bazel:not_fuchsia',
  'ios': '//engine/src/flutter/build/bazel:not_ios',
  'linux': '//engine/src/flutter/build/bazel:not_linux',
  'mac': '//engine/src/flutter/build/bazel:not_mac',
  'qnx': '//engine/src/flutter/build/bazel:not_qnx',
  'wasm': '//engine/src/flutter/build/bazel:not_wasm',
  'win': '//engine/src/flutter/build/bazel:not_win',
};

/// The external variables that are predicates: the OS predicates and every
/// argument with a config_setting ([conditionSettings]). Read as a value
/// (`enable_software = test_enable_software` in gpu.gni's invocations) one
/// is the predicate itself, not a list of flags.
final Set<String> knownBooleanVariables = Set<String>.unmodifiable(<String>{
  'is_android',
  'is_apple',
  'is_clang',
  'is_component_build',
  'is_fuchsia',
  'is_ios',
  'is_linux',
  'is_mac',
  'is_minimal_linux',
  'is_official_build',
  'is_qnx',
  'is_wasm',
  'is_win',
  ...conditionSettings.keys,
});

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
  'is_asan',
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
  'use_flutter_cxx',
  // //flutter/common/config.gni's names of the target, read in strings
  // (the archives' prefixes); the emitter enumerates their values
  // (comparisonSettings).
  'full_target_platform_name',
  // //build/config/android/config.gni's SDK paths (assumed: the defaults).
  'android_sdk_root',
  'android_sdk',
  'android_sdk_jar',
  'android_sdk_build_tools',
  'android_app_abi',
  // //build/toolchain/clang.gni
  'stripped_symbols',
  // //flutter/build/dart/dart.gni
  'dart_src',
  // //flutter/common/config.gni
  'build_engine_artifacts',
  'enable_backtrace',
  'enable_unittests',
  // //flutter/shell/platform/embedder/embedder.gni (a setting; see conditionSettings)
  'embedder_for_target',
  // //flutter/testing/testing.gni (iOS only; assumed off)
  'enable_ios_unittests',
  // //flutter/testing/rules/runtime_mode.gni (a setting; see conditionSettings)
  'is_aot',
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
  // skia.gni's arguments the wasm toolchains set per variant: the web
  // build's settings (webVariantArguments, conditionSettings).
  ...webVariantArguments,
  // $dart_src/runtime/runtime_args.gni (known through zip_bundle.gni): the
  // Dart wrap's flags (conditionSettings).
  'dart_dynamic_modules',
  'dart_disable_secure_socket',
  // //build/config/darwin/darwin_sdk.gni (known): the Xcode SDK's paths,
  // which the darwin packages' configs read -- the Swift libraries'
  // directories (a reference constant flutter_swift_library supplies) and
  // the platform's path (a constant of @macos_sdk); the testing deployment
  // target is assumed.
  'mac_swift_lib_paths',
  'mac_platform_path',
  'mac_testing_deployment_target',
  // ... and iOS's: the Swift library directories (flutter_swift_library's
  // to supply, as the Mac's), the simulator predicate (and Skia's alias of
  // it; conditionSettings), and the platform and SDK paths per
  // environment -- ios_platform_path and ios_sdk_path are assumed as a
  // reference per case of use_ios_simulator (generationAssumptions), each
  // a constant of @macos_sdk.
  'ios_swift_lib_paths',
  'use_ios_simulator',
  'ios_use_simulator',
  'ios_simulator_platform_path',
  'ios_device_platform_path',
  'ios_simulator_sdk_path',
  'ios_device_sdk_path',
};

/// darwin_sdk.gni's mac_swift_lib_paths and ios_swift_lib_paths: the GN
/// variables `lib_dirs` may hold -- the SDK's and the toolchain's Swift
/// library directories, which flutter_swift_library's objects carry as link
/// flags (build_defs/cc/swift_library.bzl's MACOS_SWIFT_LIBRARY_DIRS, and
/// iOS's per environment), so the emitter drops the listing.
const Set<String> swiftLibraryDirsVariables = <String>{
  'mac_swift_lib_paths',
  'ios_swift_lib_paths',
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

const String _coptsBzl = '//build_defs/cc:copts.bzl';

/// The `.bzl` the @engine_version repository writes at fetch time
/// (build_defs/repositories/extensions.bzl): the four arguments of
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
  // The host toolchain's gen_snapshot and analyze_snapshot in a cross build
  // (get_label_info(..., "root_out_dir") of a host-toolchain label), the
  // wrap's host products.
  '//@out/clang_x64/gen_snapshot': '//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot_host',
  '//@out/clang_x64/analyze_snapshot':
      '//engine/src/flutter/build/bazel/dart_wrap:analyze_snapshot_host',
  // The iOS scenario app's AOT assembly (flutter_snapshot, a template whose
  // output the converter cannot enumerate): GN writes it under the `ios/`
  // subdirectory of the app's gen dir -- the ios package's own directory,
  // where the app's package cannot declare a file -- so the macro declares
  // it as `<name>.snapshot_assembly.S` of the app's package, and the ios
  // package's App.framework dylib names it through this row.
  '//@gen/flutter/testing/ios_scenario_app/ios/snapshot_assembly.S':
      '//engine/src/flutter/testing/ios_scenario_app:ios_scenario_app_snapshot.snapshot_assembly.S',
  // The Android shell's assembly of icudtl.dat (bin_to_assembly, a template
  // whose output the converter cannot enumerate), which the embedder's
  // Android sources name by path ([buildOutputCompilerInputs] has what its
  // compile reads).
  '//@out/gen/flutter/shell/platform/android/flutter/third_party/icu/flutter/icudtl.dat.S':
      '//engine/src/flutter/shell/platform/android:icudtl_asm',
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

/// What the compile of a generated source of [buildOutputLabels] reads
/// besides the source, as `additional_compiler_inputs`: bin_to_assembly's
/// output `.incbin`s its input by path (the embedder's Android sources list
/// the Android shell's icudtl.dat.S; the shell's own `get_target_outputs()`
/// route reads the input off the producer).
const Map<String, List<String>> buildOutputCompilerInputs = <String, List<String>>{
  '//@out/gen/flutter/shell/platform/android/flutter/third_party/icu/flutter/icudtl.dat.S':
      <String>['@icu//:flutter/icudtl.dat'],
};

/// A directory a zip_bundle entry names as its source (zip.py walks it):
/// the target of its files and the directory's path relative to its
/// repository's root, which are zip_tree's `srcs` and `root`
/// (build_defs/dist/zip_bundle.bzl).
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
  // The Flutter GPU package, which flutter_gpu.zip (lib/gpu/dist) ships as
  // the directory is, BUILD files and tests included, as zip.py's walk takes
  // it: the package's files and its dist subpackage's (the appendices).
  '//flutter/lib/gpu': DirectorySource(
    '//engine/src/flutter/lib/gpu:all_files',
    root: 'engine/src/flutter/lib/gpu',
  ),
  // impellerc's shader library (GLSL sources), which artifacts.zip ships
  // beside the compiler; the packages' files, BUILD files included, as
  // zip.py's walk takes them.
  '//flutter/impeller/compiler/shader_lib': DirectorySource(
    '//engine/src/flutter/impeller/compiler/shader_lib:all_files',
    root: 'engine/src/flutter/impeller/compiler/shader_lib',
  ),
  // The prebuilt Dart SDK, which dart-sdk-<platform>.zip is: GN's
  // prebuilt_dart_sdk, the target's -- a target selecting the SDK of the
  // target CPU (the host's, or linux-arm64's in the Linux arm64 cross
  // build; dart_wrap/BUILD.bazel), as config.gni's formula does.
  '//flutter/prebuilts/linux-x64/dart-sdk': DirectorySource(
    '//engine/src/flutter/build/bazel/dart_wrap:prebuilt_dart_sdk',
    root: '',
  ),
  // The web engine's source directories web_sdk's sdk_rewriter reads (the
  // filegroups are the root package's appendix and third_party's BUILD):
  // dart:ui's sources without the engine under src/, the engine without
  // skwasm, skwasm's two halves, and the two packages of third_party.
  '//flutter/lib/web_ui/lib': DirectorySource(
    '//engine/src/flutter/lib/web_ui:web_ui_sources',
    root: 'engine/src/flutter/lib/web_ui/lib',
  ),
  '//flutter/lib/web_ui/lib/src/engine': DirectorySource(
    '//engine/src/flutter/lib/web_ui:web_engine_sources',
    root: 'engine/src/flutter/lib/web_ui/lib/src/engine',
  ),
  '//flutter/lib/web_ui/lib/src/engine/skwasm/skwasm_stub': DirectorySource(
    '//engine/src/flutter/lib/web_ui:skwasm_stub_sources',
    root: 'engine/src/flutter/lib/web_ui/lib/src/engine/skwasm/skwasm_stub',
  ),
  '//flutter/lib/web_ui/lib/src/engine/skwasm/skwasm_impl': DirectorySource(
    '//engine/src/flutter/lib/web_ui:skwasm_impl_sources',
    root: 'engine/src/flutter/lib/web_ui/lib/src/engine/skwasm/skwasm_impl',
  ),
  '//flutter/third_party/web_test_fonts/lib/web_test_fonts': DirectorySource(
    '//engine/src/flutter/third_party:web_test_fonts_sources',
    root: 'engine/src/flutter/third_party/web_test_fonts/lib/web_test_fonts',
  ),
  '//flutter/third_party/web_locale_keymap/lib/web_locale_keymap': DirectorySource(
    '//engine/src/flutter/third_party:web_locale_keymap_sources',
    root: 'engine/src/flutter/third_party/web_locale_keymap/lib/web_locale_keymap',
  ),
};

/// Starlark constants for GN references that have a Bazel-side value.
const Map<String, ReferenceConstant> referenceConstants = <String, ReferenceConstant>{
  'flutter_cflags_objc': ReferenceConstant(_coptsBzl, 'FLUTTER_CFLAGS_OBJC'),
  // darwin_sdk.gni's paths of the host's Xcode (see knownExternalVariables).
  'mac_swift_lib_paths': ReferenceConstant(
    '//build_defs/cc:swift_library.bzl',
    'MACOS_SWIFT_LIBRARY_DIRS',
  ),
  'mac_platform_path': ReferenceConstant('@macos_sdk//:sdk.bzl', 'MACOS_PLATFORM_PATH'),
  'ios_simulator_platform_path': ReferenceConstant(
    '@macos_sdk//:sdk.bzl',
    'IPHONESIMULATOR_PLATFORM_PATH',
  ),
  'ios_device_platform_path': ReferenceConstant('@macos_sdk//:sdk.bzl', 'IPHONEOS_PLATFORM_PATH'),
  'ios_simulator_sdk_path': ReferenceConstant('@macos_sdk//:sdk.bzl', 'IPHONESIMULATOR_SDK_PATH'),
  'ios_device_sdk_path': ReferenceConstant('@macos_sdk//:sdk.bzl', 'IPHONEOS_SDK_PATH'),
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
  /// which become the path tokens of build_defs/gn.
  pathString,

  /// Plain strings and `rebase_path()` results side by side (a wasm
  /// module's ldflags: `--js-library` and the file's path): a result
  /// becomes `$(execpath <label>)` and its file joins the attribute the
  /// rule expands the strings against ([TemplateArgument.inputs]).
  pathStrings,

  /// A scope of booleans and strings (a wasm toolchain's
  /// extra_toolchain_args), which becomes a dictionary.
  scope,

  /// A helper variable of the invocation the template never reads
  /// (`fixtures = rebase_path(...)` feeding a string of the same block).
  ignored,

  /// A directory that names a package (`dest = "$root_gen_dir/flutter/lib/ui"`),
  /// which becomes the package's label.
  package,

  /// A source directory (`input_dir = "//flutter/lib/web_ui/lib/"`, or a
  /// `rebase_path()` of one), which becomes its path relative to the
  /// repository root -- and, with [TemplateArgument.inputs], the filegroup
  /// over its files ([directorySources]) in that attribute, since a rule
  /// of another package cannot glob them.
  sourceDirectory,

  /// `{ source, destination }` scopes naming an archive's entries (a
  /// zip_bundle's `files`): the macro's dictionary of destination to the
  /// label of the file placed there, each source resolved to the target
  /// that produces it (see `_archiveEntriesText` in starlark_emitter.dart).
  archiveEntries,

  /// A path under the build directory as GN wrote it (`output_dir =
  /// "$root_gen_dir/dart-pkg/sky_engine/lib/ui_web/"`), passed on as such
  /// for the rule to place its outputs by (BuildDirectoryInfo).
  buildPath,

  /// An action's `args` as gn_action takes them: each `rebase_path()`
  /// result a path token (`$(built FlutterMacOS.framework)`, `$(built .)`),
  /// for a rule that reads the arguments GN's script would (the
  /// xcframework's bundle and location).
  actionArgs,
}

/// One argument of a known template: the macro attribute it becomes and how.
final class TemplateArgument {
  const TemplateArgument(this.attribute, this.kind, {this.appliedUnder, this.inputs});

  final String attribute;
  final TemplateArgumentKind kind;

  /// For [TemplateArgumentKind.pathStrings]: the attribute that lists the
  /// files the strings name (`link_inputs`).
  final String? inputs;

  /// The predicate under which alone the macro reads the argument
  /// (impeller_shaders applies gles_exclusions to the GLES backend): a
  /// condition that predicate implies says nothing more there, and the
  /// emitter drops it, so that the macro gets a list rather than a select().
  final String? appliedUnder;
}

/// zip_bundle's and zip_bundle_from_file's arguments.
const Map<String, TemplateArgument> _zipBundleArguments = <String, TemplateArgument>{
  'output': TemplateArgument('output', TemplateArgumentKind.scalar),
  'files': TemplateArgument('files', TemplateArgumentKind.archiveEntries),
  // The entries' labels carry the archive's inputs; the deps -- the targets
  // whose outputs the entries are, in GN -- are the rule's `deps` so that an
  // install of the archive lays what their closure places, as ninja's build
  // of the archive leaves every output of those targets in the build
  // directory (the core snapshot's four files, two of which artifacts.zip
  // packs). Where the entries are a directory of the build directory
  // (build_directory_tree), the deps are the tree's srcs as well.
  'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
  'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
  // The invocations' helpers for their names and paths (`exe`, `prefix`,
  // `zip_out_dir`) are read by the strings of their own blocks, which
  // is how the converter tells them from arguments (GnTarget.readVariables).
};

/// The arguments of a link in a wasm toolchain (wasm_lib, and an executable
/// with `output_extension = "js"`), shared by their mappings.
const Map<String, TemplateArgument> _wasmLinkArguments = <String, TemplateArgument>{
  'sources': TemplateArgument('srcs', TemplateArgumentKind.files),
  'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
  'public_configs': TemplateArgument('deps', TemplateArgumentKind.configs),
  'defines': TemplateArgument('defines', TemplateArgumentKind.strings),
  'cflags': TemplateArgument('copts', TemplateArgumentKind.strings),
  // The ldflags name files (`--js-library` and its JavaScript library,
  // `--pre-js` and its script, by rebase_path()), which the rule reads as
  // link_inputs.
  'ldflags': TemplateArgument('linkopts', TemplateArgumentKind.pathStrings, inputs: 'link_inputs'),
  'inputs': TemplateArgument('link_inputs', TemplateArgumentKind.files),
  'export_name': TemplateArgument('export_name', TemplateArgumentKind.scalar),
  'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
  'visibility': TemplateArgument('visibility', TemplateArgumentKind.ignored),
};

/// The key of [templateMappings] for an `executable()` whose
/// `output_extension` is `"js"`: a link in a wasm toolchain, as GN's wasm
/// toolchain treats any executable (its link_outputs are the .js, .wasm and
/// .js.symbols), which the emitter converts through the mapping rather than
/// as a cc_binary.
const String wasmExecutableRule = 'executable(output_extension = "js")';

/// The `.gni` templates the converter knows, with the Bazel macro for each
/// (`load` label and symbol) and the arguments it accepts.
final class TemplateMapping {
  const TemplateMapping(
    this.bzl,
    this.symbol,
    this.arguments, {
    this.innerTargets = const <String>[],
    this.files = false,
    this.compiles = false,
  });

  final String bzl;
  final String symbol;
  final Map<String, TemplateArgument> arguments;

  /// Whether the macro compiles the target's sources itself (the wasm links:
  /// wasm_module, wasm_executable), so that the rule gets the compiler
  /// options a cc rule gets -- the copts constant GN's configs amount to and
  /// what its dependencies' public configs hand it -- besides the cflags
  /// the invocation names.
  final bool compiles;

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
/// build_defs/impeller mirror them.
const List<String> impellerShaderBackends = <String>['gles', 'gles3', 'vk'];

const Map<String, TemplateMapping> templateMappings = <String, TemplateMapping>{
  'test_fixtures': TemplateMapping(
    '//build_defs/testing:testing.bzl',
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
    '//build_defs/impeller:shaders.bzl',
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
  'impellerc': TemplateMapping('//build_defs/impeller:shaders.bzl', 'impellerc', <
    String,
    TemplateArgument
  >{
    'shaders': TemplateArgument('shaders', TemplateArgumentKind.files),
    'shader_target_flags': TemplateArgument('shader_target_flags', TemplateArgumentKind.strings),
    'sl_file_extension': TemplateArgument('sl_file_extension', TemplateArgumentKind.scalar),
    'intermediates_subdir': TemplateArgument('intermediates_subdir', TemplateArgumentKind.scalar),
    'iplr': TemplateArgument('iplr', TemplateArgumentKind.scalar),
    'json': TemplateArgument('json', TemplateArgumentKind.scalar),
    'shader_bundle': TemplateArgument('shader_bundle', TemplateArgumentKind.pathString),
    'shader_bundle_output': TemplateArgument('shader_bundle_output', TemplateArgumentKind.scalar),
    'gles_language_version': TemplateArgument('gles_language_version', TemplateArgumentKind.scalar),
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
  }, files: true),
  // testing.gni's dart_snapshot_kernel and dart_snapshot_aot: a Dart entry
  // point to kernel with the test modes' arguments, and a kernel to an AOT
  // ELF snapshot.
  'dart_snapshot_kernel': TemplateMapping(
    '//build_defs/testing:testing.bzl',
    'flutter_dart_snapshot_kernel',
    <String, TemplateArgument>{
      'dart_main': TemplateArgument('dart_main', TemplateArgumentKind.file),
      'dart_kernel': TemplateArgument('dart_kernel', TemplateArgumentKind.file),
    },
    files: true,
  ),
  'dart_snapshot_aot': TemplateMapping(
    '//build_defs/testing:testing.bzl',
    'flutter_dart_snapshot_aot',
    <String, TemplateArgument>{
      'dart_kernel': TemplateArgument('dart_kernel', TemplateArgumentKind.file),
      'dart_elf_filename': TemplateArgument('dart_elf_filename', TemplateArgumentKind.scalar),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
    },
    files: true,
  ),
  // build/dart/internal/flutter_snapshot.gni's flutter_snapshot: a Flutter
  // app's kernel (flutter_frontend_server) and its gen_snapshot snapshot --
  // the JIT application snapshot, or the AOT assembly on iOS -- as the
  // macro's `_<name>_kernel`, `_<name>_jit_snapshot`/`_<name>_aot_snapshot`
  // and the `_<name>_snapshot` alias (build_defs/dart/flutter_snapshot.bzl).
  'flutter_snapshot': TemplateMapping(
    '//build_defs/dart:flutter_snapshot.bzl',
    'flutter_snapshot',
    <String, TemplateArgument>{
      'main_dart': TemplateArgument('main_dart', TemplateArgumentKind.file),
      'package_config': TemplateArgument('package_config', TemplateArgumentKind.file),
      'product': TemplateArgument('product', TemplateArgumentKind.scalar),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    files: true,
  ),
  // The Dart tree's copy_tree (build/dart/copy_tree.gni): a directory's
  // files into the build directory, as a gn_copy placing each at its path
  // under `dest` (build_defs/gn/gn_action.bzl's gn_copy_tree).
  'copy_tree': TemplateMapping(
    '//build_defs/gn:gn_action.bzl',
    'gn_copy_tree',
    <String, TemplateArgument>{
      'source': TemplateArgument('source', TemplateArgumentKind.scalar),
      'dest': TemplateArgument('dest', TemplateArgumentKind.buildPath),
      'exclude': TemplateArgument('exclude', TemplateArgumentKind.scalar),
      'visibility': TemplateArgument('visibility', TemplateArgumentKind.ignored),
      'testonly': TemplateArgument('testonly', TemplateArgumentKind.scalar),
    },
    files: true,
  ),
  // build/secondary/flutter/third_party/flatbuffers/flatbuffers.gni: flatc
  // over the schemas, the generated headers as a library.
  'flatbuffers': TemplateMapping(
    '//build_defs/flatbuffers:flatbuffers.bzl',
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
  // build/toolchain/wasm.gni's wasm_toolchain: a gcc_toolchain over emcc
  // with extra_toolchain_args, the arguments GN re-evaluates Skia and the
  // engine's libraries under in that toolchain; a platform here, whose
  // flags set the web build's settings and the emscripten toolchain's
  // features (wasm_platform; research/12).
  'wasm_toolchain': TemplateMapping(
    '//build_defs/web:wasm.bzl',
    'wasm_platform',
    <String, TemplateArgument>{
      'extra_toolchain_args': TemplateArgument('extra_toolchain_args', TemplateArgumentKind.scope),
    },
  ),
  // build/toolchain/wasm.gni's wasm_lib: an executable in a wasm toolchain
  // with the module's flags (`-s MAIN_MODULE=1`, `-s EXPORT_NAME=<name>`),
  // which the emsdk toolchain's wasm_module rule compiles and links under
  // the wasm platform a dependent names (GN's `label(:toolchain)` edge, the
  // web SDK's copies; the module_platform flag of build/bazel/web) by a
  // transition, so that a module can be named from any build (skwasm's
  // three variants).
  'wasm_lib': TemplateMapping(
    '//build_defs/web:wasm.bzl',
    'wasm_module',
    _wasmLinkArguments,
    files: true,
    compiles: true,
  ),
  // An executable() in a wasm toolchain with `output_extension = "js"`
  // (CanvasKit's, flutter/skia/modules/canvaskit): the same link without
  // wasm_lib's flags, which the target passes itself. Not a GN template:
  // the emitter maps such an executable here ([wasmExecutableMapping]).
  wasmExecutableRule: TemplateMapping(
    '//build_defs/web:wasm.bzl',
    'wasm_executable',
    <String, TemplateArgument>{
      ..._wasmLinkArguments,
      'output_name': TemplateArgument('output_name', TemplateArgumentKind.scalar),
      // What marks the executable as a wasm one; the rule's outputs are
      // the toolchain's (.js, .wasm, .js.symbols).
      'output_extension': TemplateArgument('output_extension', TemplateArgumentKind.ignored),
      'check_includes': TemplateArgument('check_includes', TemplateArgumentKind.ignored),
    },
    files: true,
    compiles: true,
  ),
  'impeller_shaders': TemplateMapping(
    '//build_defs/impeller:shaders.bzl',
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
      'gles_exclusions': TemplateArgument(
        'gles_exclusions',
        TemplateArgumentKind.files,
        appliedUnder: 'impeller_enable_opengles',
      ),
      'vulkan_exclusions': TemplateArgument(
        'vulkan_exclusions',
        TemplateArgumentKind.files,
        appliedUnder: 'impeller_enable_vulkan',
      ),
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
  // (build_defs/dist/zip_bundle.bzl runs the same script). GN's `deps` name the
  // targets whose outputs the entries are, which is how a source under the
  // build directory is resolved; under Bazel the entries' labels carry the
  // dependency, so the list itself is not written.
  'zip_bundle': TemplateMapping(
    '//build_defs/dist:zip_bundle.bzl',
    'zip_bundle',
    _zipBundleArguments,
    files: true,
  ),
  // build/bin_to_obj.gni's bin_to_assembly: a symbol over a file's bytes, as
  // assembly (the Android shell's icudtl_asm; //flutter/lib/snapshot's
  // linkables are hand-written over the same rule). The rule takes the
  // target OS and CPU from the platform; `deps` orders nothing a label does
  // not (the input is the dependency).
  'bin_to_assembly': TemplateMapping(
    '//build_defs/dart:snapshot.bzl',
    'bin_to_assembly',
    <String, TemplateArgument>{
      'input': TemplateArgument('src', TemplateArgumentKind.file),
      'symbol': TemplateArgument('symbol', TemplateArgumentKind.scalar),
      'size_symbol': TemplateArgument('size_symbol', TemplateArgumentKind.scalar),
      'executable': TemplateArgument('executable', TemplateArgumentKind.scalar),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
    },
    files: true,
  ),
  // zip_bundle.gni's other template: the same archive from a file listing
  // the entries (the web SDK's), without zip_bundle's license file.
  'zip_bundle_from_file': TemplateMapping(
    '//build_defs/dist:zip_bundle.bzl',
    'zip_bundle_from_file',
    _zipBundleArguments,
    files: true,
  ),
  // web_sdk.gni's wrapper of sdk_rewriter for dart:ui_web: the macro spells
  // out the template's fixed arguments (the library, its API file, the input
  // directory) and takes the invoker's output directory. GN expands it to a
  // prebuilt_dart_action, which is an action under the invocation's name.
  'web_ui_ui_web_with_output': TemplateMapping(
    '//build_defs/web:web_sdk.bzl',
    'web_ui_ui_web_with_output',
    <String, TemplateArgument>{
      'output_dir': TemplateArgument('output_dir', TemplateArgumentKind.buildPath),
    },
    files: true,
  ),
  // web_sdk.gni's sdk_rewriter itself (the web SDK's seven libraries): the
  // input directory's files are the rule's srcs, from a filegroup of the
  // package that owns them (directorySources).
  'sdk_rewriter': TemplateMapping(
    '//build_defs/web:web_sdk.bzl',
    'sdk_rewriter',
    <String, TemplateArgument>{
      'input_dir': TemplateArgument(
        'input_dir',
        TemplateArgumentKind.sourceDirectory,
        inputs: 'srcs',
      ),
      'exclude_pattern': TemplateArgument('exclude', TemplateArgumentKind.sourceDirectory),
      'output_dir': TemplateArgument('output_dir', TemplateArgumentKind.buildPath),
      'library_name': TemplateArgument('library_name', TemplateArgumentKind.scalar),
      'api_file': TemplateArgument('api_file', TemplateArgumentKind.file),
      'ui': TemplateArgument('ui', TemplateArgumentKind.scalar),
      'is_public': TemplateArgument('public', TemplateArgumentKind.scalar),
    },
    files: true,
  ),
  // web_sdk/BUILD.gn's own templates over the prebuilt SDK's kernel_worker
  // and dartdevc (the file defines them; the mappings stand for their
  // bodies, which read the web engine libraries through the staged tree,
  // web_sdk.bzl).
  '_compile_platform': TemplateMapping(
    '//build_defs/web:web_sdk.bzl',
    'web_platform_dill',
    <String, TemplateArgument>{
      'kernel_target': TemplateArgument('kernel_target', TemplateArgumentKind.scalar),
      'summary_only': TemplateArgument('summary_only', TemplateArgumentKind.scalar),
      'null_environment': TemplateArgument('null_environment', TemplateArgumentKind.scalar),
      'output_dill': TemplateArgument('output_dill', TemplateArgumentKind.buildPath),
    },
    files: true,
  ),
  '_compile_ddc_sdk': TemplateMapping(
    '//build_defs/web:web_sdk.bzl',
    'ddc_sdk',
    <String, TemplateArgument>{'canary': TemplateArgument('canary', TemplateArgumentKind.scalar)},
    files: true,
  ),
  // build/esbuild/esbuild.gni: the prebuilt esbuild over an entry point
  // (flutter.js), which the copy of the sources it imports provides.
  'esbuild': TemplateMapping('//build_defs/web:esbuild.bzl', 'esbuild', <String, TemplateArgument>{
    'entry_point': TemplateArgument('entry_point', TemplateArgumentKind.buildPath),
    'output_bundle': TemplateArgument('output_bundle', TemplateArgumentKind.buildPath),
    'bundle': TemplateArgument('bundle', TemplateArgumentKind.scalar),
    'minify': TemplateArgument('minify', TemplateArgumentKind.scalar),
    'sourcemap': TemplateArgument('sourcemap', TemplateArgumentKind.scalar),
    'public_deps': TemplateArgument('srcs', TemplateArgumentKind.labels),
  }, files: true),
};

/// GN actions known by the script they run, converted as a template
/// invocation would be: the action's variables are the macro's arguments.
/// dart_pkg.py (sky/packages/sky_engine's `action("sky_engine")`) assembles
/// a Dart package directory in the build directory from the package's own
/// files and the SDK extension sources; its `args` are the same variables
/// rebased, and its outputs a stamp. package_framework.py (the embedder's
/// and the macOS shell's `action("generate_symlinks")`) makes a framework
/// bundle's symlinks (`Versions/Current -> A`, the top-level links into
/// it) and a stamp: its `args` name the bundle, the version, the contents
/// and the stamp, which the rule declares as its outputs -- symlink outputs,
/// kept as the links they are -- so GN's `outputs` go unread.
const Map<String, TemplateMapping> scriptMappings = <String, TemplateMapping>{
  '//flutter/build/dart/tools/dart_pkg.py': TemplateMapping(
    '//build_defs/dart:dart_pkg.bzl',
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
  '//build/config/mac/package_framework.py': TemplateMapping(
    '//build_defs/dist:framework.bzl',
    'framework_symlinks',
    <String, TemplateArgument>{
      'args': TemplateArgument('args', TemplateArgumentKind.strings),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'script': TemplateArgument('script', TemplateArgumentKind.ignored),
      'outputs': TemplateArgument('outputs', TemplateArgumentKind.ignored),
    },
    files: true,
  ),
  // create_xcframework.py (the macOS shell's `action("flutter_framework")`)
  // runs `xcrun xcodebuild -create-xcframework` over the assembled bundle:
  // the rule lays the bundle out from what the deps place in the build
  // directory (a sandbox holds links, not the bundle) and declares the
  // xcframework, a directory, from the arguments' `--name` and
  // `--location`; GN's `outputs` go unread.
  '//flutter/sky/tools/create_xcframework.py': TemplateMapping(
    '//build_defs/dist:framework.bzl',
    'xcframework',
    <String, TemplateArgument>{
      'args': TemplateArgument('args', TemplateArgumentKind.actionArgs),
      'deps': TemplateArgument('deps', TemplateArgumentKind.labels),
      'script': TemplateArgument('script', TemplateArgumentKind.ignored),
      'outputs': TemplateArgument('outputs', TemplateArgumentKind.ignored),
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
    // android_zip_archive_dir, the Android archives' directory
    // (`android-$target_cpu`, with the runtime mode and the Dart flags in
    // its name), a scalar over the enumerated variables; the zip_bundle
    // template it defines is mapped (templateMappings).
    '//flutter/build/zip_bundle.gni',
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
    // Declares build_embedder_examples (off: tools/gn's
    // --build-embedder-examples turns it on for one builder), which the root
    // file reads for the example embedders.
    '//flutter/examples/examples.gni',
    // Declares enable_desktop_embeddings (on: tools/gn's
    // --disable-desktop-embeddings turns it off for no Linux builder), which
    // the platform shells' group reads.
    '//flutter/shell/platform/config.gni',
    '//flutter/third_party/glfw/glfw_args.gni',
    // The engine's answers to the Khronos trees' build_overrides (where
    // SPIRV-Headers and SPIRV-Tools are, build_with_chromium = false) and
    // their own argument files.
    '//build_overrides/build.gni',
    '//build_overrides/spirv_tools.gni',
    '//build_overrides/glslang.gni',
    '//build_overrides/vulkan_headers.gni',
    '//build_overrides/vulkan_utility_libraries.gni',
    '//build_overrides/vulkan_validation_layers.gni',
    '//flutter/third_party/vulkan-deps/',
    // The Dart SDK's library source lists (<library>_sources.gni) and
    // dart:ui's (dart_ui.gni), which sky/packages/sky_engine copies into the
    // sky_engine package.
    '//flutter/third_party/dart/sdk/lib/',
    '//flutter/lib/ui/dart_ui.gni',
    // flutter.js's source list (flutter_js_source_list), which its copy and
    // the web SDK's archive read.
    '//flutter/lib/web_ui/flutter_js/sources.gni',
    // The Flutter frameworks' shared headers (framework_common_headers), a
    // list the darwin packages' targets read.
    '//flutter/shell/platform/darwin/common/framework_common.gni',
  },
  known: <String>{
    // The Dart package templates (dart_pkg); sky_engine writes its action
    // out by hand and the converter maps it by its script (scriptMappings).
    '//flutter/build/dart/rules.gni',
    // The web SDK's templates (sdk_rewriter, web_ui_ui_web_with_output),
    // in templateMappings; web_sdk.gni's dart_sdk_package_config is the
    // rules' default.
    '//flutter/web_sdk/web_sdk.gni',
    // The esbuild template (templateMappings); its argument is the prebuilt
    // esbuild's path, which the rule knows.
    '//flutter/build/esbuild/esbuild.gni',
    // The Dart tree's dart_action templates (prebuilt_dart_action), which
    // web_sdk.gni and web_sdk/BUILD.gn import; the templates built on them
    // are mapped.
    '//flutter/third_party/dart/build/dart/dart_action.gni',
    '//flutter/build/dart/dart.gni',
    '//flutter/common/config.gni',
    '//flutter/impeller/tools/shaders.gni',
    '//flutter/shell/config.gni',
    // Declares embedder_for_target (whether the embedder's shared library is
    // built for the target as well as the host): a setting, read by the
    // embedder's own file (knownExternalVariables, conditionSettings).
    '//flutter/shell/platform/embedder/embedder.gni',
    // Declares the version arguments and asserts they are set; nothing
    // converted reads them (impeller/compiler imports it without use).
    '//flutter/shell/version/version.gni',
    '//flutter/testing/testing.gni',
    // The Dart runtime's arguments (dart_dynamic_modules, a setting;
    // dart_disable_secure_socket, assumed off), which zip_bundle.gni reads.
    '//flutter/third_party/dart/runtime/runtime_args.gni',
    // The Android SDK and NDK arguments (android_api_level, android_sdk_root,
    // ...), which the Android shell imports; the converted targets read none
    // (the Java targets that do are skipped).
    '//build/config/android/config.gni',
    // The bin_to_assembly template (templateMappings).
    '//flutter/build/bin_to_obj.gni',
    // The Dart tree's copy_tree and copy_trees templates: copy_tree in
    // templateMappings (the iOS scenario app's project), copy_trees imported
    // by the root file without invoking.
    '//flutter/third_party/dart/build/dart/copy_tree.gni',
    // testing/rules/runtime_mode.gni: is_aot (a setting; conditionSettings).
    '//flutter/testing/rules/runtime_mode.gni',
    // gen_snapshot.gni: the gen_snapshot templates of the AOT archives, whose
    // invocations are skipped.
    '//flutter/lib/snapshot/gen_snapshot.gni',
    // The compiled_action template, which lib/ui's shader fixture
    // directories import without invoking (impellerc() does).
    '//build/compiled_action.gni',
    // Declares the arm toolchains' arguments (arm_version, arm_use_neon,
    // arm_optionally_use_neon, ...); libjpeg-turbo imports it where
    // `current_cpu == "arm"` and reads them only in a Fuchsia branch.
    '//build/config/arm.gni',
    // Declares use_clang_type_profiler, enable_lto, enable_coverage and
    // stripped_symbols; the embedder imports it and reads none of them.
    '//build/toolchain/clang.gni',
    // Declares buildtools_path (assumed: tools/gn's //flutter/buildtools)
    // and concurrent_toolchain_jobs; the iOS shell imports it for the
    // ASan runtime's path under buildtools.
    '//build/toolchain/toolchain.gni',
    // Declares disable_vma_stl_shared_mutex (above).
    '//flutter/flutter_vma/config.gni',
    // Declares enable_vulkan_validation_layers; nothing converted reads it.
    '//flutter/vulkan/config.gni',
    // The native_activity_apk template, invoked under is_android alone.
    '//flutter/testing/android/native_activity/native_activity.gni',
    // The wasm toolchain's templates (wasm_toolchain, wasm_lib) and
    // arguments; wasm_lib is in templateMappings.
    '//build/toolchain/wasm.gni',
    '//flutter/third_party/flatbuffers/flatbuffers.gni',
    '//flutter/tools/fuchsia/gn-sdk/src/gn_configs.gni',
    // The Xcode SDK's paths (mac_sdk_path, mac_platform_path,
    // mac_swift_lib_paths, ...), which it asks xcrun for (build/mac/
    // darwin_sdk.py): assumed, as [darwinSdkAssumptions] has them -- the
    // Swift library directories are flutter_swift_library's to supply,
    // the rest reach the generated files from @macos_sdk where a rule
    // needs them.
    '//build/config/darwin/darwin_sdk.gni',
  },
);

/// build/config/android/config.gni's android_app_abi: the ABI name by
/// `current_cpu`, which the Android embedding's artifact names and
/// create_flutter_jar.py's `--android_abi` carry.
const GnCasedValue _androidAppAbi = GnCasedValue('current_cpu', <String, String>{
  'x86': 'x86',
  'arm': 'armeabi-v7a',
  'x64': 'x86_64',
  'arm64': 'arm64-v8a',
  'riscv64': 'riscv64',
});

/// skia.gni's skia_gl_standard as tools/gn passes it: "gles" for Android
/// (and iOS), "webgl" for the web (to_gn_wasm_args), "" for a host -- the
/// host runs its GLES tests under SwiftShader and must not assume GL. The
/// Skia wrapper's config turns it into SK_ASSUME_GL_ES=1 / SK_ASSUME_WEBGL=1.
/// (skia.gni's own default would give the web its value and "" to the rest,
/// which is wrong for Android: the argument is tools/gn's, not a derivation.)
const GnCasedValue _skiaGlStandard = GnCasedValue('target_os', <String, String>{
  'android': 'gles',
  'linux': '',
  'wasm': 'webgl',
});

/// The assumptions the checked-in files are generated under: the Linux x64
/// host's ([linuxHostAssumptions]) less everything GN derives from the
/// target -- the target OS and CPU, the toolchains, the names of the target,
/// and the arguments BUILDCONFIG.gn and the engine's .gni files compute from
/// them -- so that the generated files carry the Linux and wasm branches as
/// select()s (decision 168's web scope; landed 2026-10-20 on the user's
/// call). What stays assumed is the host itself (a Linux x64 host, its
/// platform names, the prebuilt Dart SDK), the OSes the engine never builds
/// for from this scope, and the arguments tools/gn passes in, which GN
/// derives from nothing: at the host's value where tools/gn's web build
/// passes the same or none, and as a formula over the OS where the two
/// builds differ ([perTargetOsArguments]).
/// The Apple platforms as a condition: BUILDCONFIG.gn's `is_apple`
/// (`is_ios || is_mac`), both conditions since the iOS port's converter
/// flip (10-27; is_mac's since the macOS port). Where a thing exists on the
/// Apple platforms alone whatever its listing says -- an Objective-C
/// compile, which GN's other toolchains have no tool for and skip -- this is
/// its compatibility.
final Condition applePlatforms = const ConditionVariable('is_ios')
    .or(const ConditionVariable('is_mac'));

/// darwin_sdk.gni's iOS arguments and derivations, as the generation scope
/// (and the host's, for the tests' invariant) assumes them: the deployment
/// targets (declare_args defaults tools/gn leaves alone); the paths of the
/// iOS platform and SDK in use -- the simulator's or the device's by
/// use_ios_simulator, each a constant of @macos_sdk (referenceConstants);
/// and the Swift target triple's parts, the CPU's name (`x86_64` for x64)
/// and `-simulator` on the simulator.
const Map<String, GnValue> _iosSdkAssumptions = <String, GnValue>{
  'ios_deployment_target': GnStringValue('15.0'),
  'ios_testing_deployment_target': GnStringValue('15.0'),
  'ios_platform_path': GnPredicateCases(
    'use_ios_simulator',
    whenTrue: GnReference('ios_simulator_platform_path'),
    whenFalse: GnReference('ios_device_platform_path'),
  ),
  'ios_sdk_path': GnPredicateCases(
    'use_ios_simulator',
    whenTrue: GnReference('ios_simulator_sdk_path'),
    whenFalse: GnReference('ios_device_sdk_path'),
  ),
  'darwin_target_arch': GnCasedValue('current_cpu', <String, String>{
    'arm64': 'arm64',
    'x64': 'x86_64',
  }),
  'darwin_target_sim': GnPredicateCases(
    'use_ios_simulator',
    whenTrue: GnStringValue('-simulator'),
    whenFalse: GnStringValue(''),
  ),
};

Assumptions generationAssumptions() {
  const isWasm = ConditionVariable('is_wasm');
  const isMac = ConditionVariable('is_mac');
  const isIos = ConditionVariable('is_ios');
  return Assumptions(<String, GnValue>{
    'default_library_type': const GnStringValue('static_library'),
    'host_cpu': const GnStringValue('x64'),
    'host_os': const GnStringValue('linux'),
    // Not here: is_mac, a condition since the macOS port (10-26,
    // research/20), and is_ios since the iOS port's (10-27, research/21):
    // the macOS and iOS platforms select their branches, as Android's and
    // the web's do theirs. is_apple is BUILDCONFIG.gn's `is_ios || is_mac`,
    // which the scope does not evaluate and so spells here
    // ([applePlatforms]).
    'is_apple': GnConditionValue(applePlatforms),
    // darwin_sdk.gni's mac_testing_deployment_target (its default), read
    // by darwin/common's test configs; iOS's deployment targets the same
    // (its declare_args defaults, which tools/gn leaves alone).
    'mac_testing_deployment_target': const GnStringValue('14.0'),
    ..._iosSdkAssumptions,
    'is_component_build': const GnBoolValue(false),
    'is_fuchsia': const GnBoolValue(false),
    // build/toolchain/toolchain.gni's buildtools_path, as tools/gn passes
    // it (the clang, gn and ninja under flutter/buildtools/<host>): read
    // by the iOS shell for the ASan runtime's path.
    'buildtools_path': const GnStringValue('//flutter/buildtools'),
    'is_minimal_linux': const GnBoolValue(false),
    'is_official_build': const GnBoolValue(true),
    // tools/gn's --wasm-use-dwarf (DWARF rather than source maps for a
    // debug web build's symbols), off unless asked; the source map a debug
    // link writes without it (`<module>.wasm.map`) is the branch this
    // leaves out, and the wasm_module rule does not write one yet.
    'wasm_use_dwarf': const GnBoolValue(false),
    'is_qnx': const GnBoolValue(false),
    'is_win': const GnBoolValue(false),
    'platform_name': const GnStringValue('linux'),
    'full_platform_name': const GnStringValue('linux-x64'),
    // //build/config/android/config.gni: the SDK's paths, from its defaults
    // (default_android_sdk_version 37.0, default_android_sdk_build_tools_version
    // 37.0.0, the SDK under //flutter/third_party/android_tools/sdk); the
    // NDK's version sits in @android_tools' overlay the same way.
    'android_sdk_root': const GnStringValue('//flutter/third_party/android_tools/sdk'),
    'android_sdk': const GnStringValue(
      '//flutter/third_party/android_tools/sdk/platforms/android-37.0',
    ),
    'android_sdk_jar': const GnStringValue(
      '//flutter/third_party/android_tools/sdk/platforms/android-37.0/android.jar',
    ),
    'android_sdk_build_tools': const GnStringValue(
      '//flutter/third_party/android_tools/sdk/build-tools/37.0.0',
    ),
    'android_app_abi': _androidAppAbi,
    'flutter_prebuilt_dart_sdk': const GnBoolValue(true),
    // The prebuilt Dart SDKs: the host's, which the tools that run at build
    // time come from, and the target's (config.gni's `prebuilt_dart_sdk`
    // outside the host toolchain, `target_prebuilt_dart_sdk`), which the
    // build ships as dart-sdk/ and dart-sdk-<platform>.zip. The target's is
    // written as the host's path here and mapped (directorySources) to a
    // target that selects the SDK of the target CPU -- linux-arm64's in the
    // Linux arm64 cross build -- as config.gni's formula does.
    'prebuilt_dart_sdk': const GnStringValue('//flutter/prebuilts/linux-x64/dart-sdk'),
    'host_prebuilt_dart_sdk': const GnStringValue('//flutter/prebuilts/linux-x64/dart-sdk'),
    'target_prebuilt_dart_sdk': const GnStringValue('//flutter/prebuilts/linux-x64/dart-sdk'),
    // Skia's arguments tools/gn passes for a Linux host and for the web
    // alike (or for the host alone, where skia.gni's default would differ
    // from it: skia_use_dng_sdk, skia_use_vma), and whose default would not
    // give the web build its value (skia_use_webgpu).
    // The Skia tree is converted when its repository is fetched, under
    // these. Not here: the arguments whose skia.gni default already yields
    // both builds' values (skia_use_gl, skia_use_wuffs, the Rust PNG
    // codecs), which stay derivations. skia_gl_standard is tools/gn's, per
    // target OS (_skiaGlStandard).
    'skia_gl_standard': _skiaGlStandard,
    'skia_enable_pdf': const GnBoolValue(false),
    'skia_use_dng_sdk': const GnBoolValue(false),
    'skia_use_vma': const GnBoolValue(false),
    'skia_use_webgpu': const GnBoolValue(false),
    'skia_use_x11': const GnBoolValue(false),
    'skia_use_xps': const GnBoolValue(false),
    // Not here either: CanvasKit's arguments (modules/canvaskit/
    // canvaskit.gni), read by the module's file alone (flutter/skia/
    // modules/canvaskit): the ones a toolchain sets are settings
    // (webVariantArguments), the one whose default tools/gn overrides for
    // the web is a formula (perTargetOsArguments:
    // skia_canvaskit_enable_webgl), and the rest keep canvaskit.gni's
    // defaults, which are the web build's values.
    // Not here: the arguments the wasm toolchains set per variant
    // (webVariantArguments: skia_use_icu, the codec decoders, ...), which
    // are build settings with the host's defaults. The one path among
    // them, the client ICU's bidi library, is the directory the toolchains
    // name (a dependency under skia_use_client_icu).
    'skia_icu_bidi_third_party_dir': const GnStringValue(
      '//flutter/third_party/canvaskit/icu_bidi',
    ),
    // The arguments tools/gn passes differently for the web, for a Mac and
    // for iOS (research/12, research/20, research/21): the host's value
    // elsewhere.
    for (final MapEntry<String, ({bool host, bool web, bool mac, bool ios})> argument
        in perTargetOsArguments.entries)
      argument.key: GnConditionValue(
        _perOsCondition(argument.value, isWasm: isWasm, isMac: isMac, isIos: isIos),
      ),
  });
}

/// `(is_wasm && web) || (is_mac && mac) || (is_ios && ios) || (!is_wasm &&
/// !is_mac && !is_ios && host)`, with the constants folded: the OS condition
/// under which an argument of [perTargetOsArguments] holds.
Condition _perOsCondition(
  ({bool host, bool web, bool mac, bool ios}) value, {
  required Condition isWasm,
  required Condition isMac,
  required Condition isIos,
}) {
  final holds = <Condition>[
    if (value.web) isWasm,
    if (value.mac) isMac,
    if (value.ios) isIos,
    if (value.host) isWasm.negated.and(isMac.negated).and(isIos.negated),
  ];
  if (holds.isEmpty) {
    return Condition.never;
  }
  return holds.reduce((Condition a, Condition b) => a.or(b));
}

/// The arguments `tools/gn` passes with one value for a Linux host build and
/// another for the web build (`to_gn_wasm_args`) or for a Mac (the darwin
/// branches of `to_gn_args`), which GN derives from nothing and the
/// generation scope takes as formulas over the OS, so that `if
/// (skia_use_vulkan)` renders as a select() on the platform: what GN's
/// builds say, with no flag (NEED_DECISION D4, design A). The arguments the
/// six wasm toolchains set per variant (`skia_use_icu`, the codec decoders,
/// ...) are not here: those are the variants' flags. An Android or Fuchsia
/// build takes the host's values, as tools/gn gives them; an iOS build
/// (tools/gn --ios, from a Mac) the host's but for what its branches set.
const Map<String, ({bool host, bool web, bool mac, bool ios})> perTargetOsArguments =
    <String, ({bool host, bool web, bool mac, bool ios})>{
      // Vulkan everywhere but the Apple targets (`target_os not in ['ios',
      // 'mac']`).
      'skia_use_vulkan': (host: true, web: false, mac: false, ios: false),
      'skia_use_expat': (host: true, web: false, mac: true, ios: true),
      'skia_use_libjpeg_turbo_encode': (host: true, web: false, mac: true, ios: true),
      'skia_use_no_jpeg_encode': (host: false, web: true, mac: false, ios: false),
      'skia_use_libwebp_encode': (host: true, web: false, mac: true, ios: true),
      'skia_use_no_webp_encode': (host: false, web: true, mac: false, ios: false),
      'skia_enable_skottie': (host: true, web: false, mac: true, ios: true),
      'skia_enable_fontmgr_custom_directory': (host: true, web: false, mac: true, ios: true),
      // CanvasKit's WebGL binding (canvaskit.gni's default is off; tools/gn
      // turns it on for the web), read by the module's file alone.
      'skia_canvaskit_enable_webgl': (host: false, web: true, mac: false, ios: false),
      // tools/gn on a Mac (`sys.platform == 'darwin'` and an Apple target):
      // Skia's Metal, and deprecated API calls allowed (OpenGL's); Vulkan is
      // not turned on for the Apple targets, so skia_use_vma stays skia.gni's
      // default there. The shell's backends (shell_enable_*) and fontconfig
      // are settings, not here: //flutter/shell's groups by platform, txt's
      // flag.
      'allow_deprecated_api_calls': (host: false, web: false, mac: true, ios: true),
      'skia_use_metal': (host: false, web: false, mac: true, ios: true),
      // iOS alone (tools/gn's `target_os == 'ios'` branch): no OpenGL in
      // Skia (skia.gni's default is on). VMA without std::shared_mutex,
      // which the same branch sets, is flutter_vma's setting by platform.
      'skia_use_gl': (host: true, web: true, mac: true, ios: false),
    };

/// Which assumptions describe the Linux x64 host build (the values
/// `tools/gn` gives these arguments for it, as in `out/host_debug*/args.gn`):
/// what the oracle (tool/gn_desc_diff.dart) compares GN's host build
/// against, and the tests' default. The generated files take
/// [generationAssumptions], a subset. Everything not fixed here stays a
/// select(): `is_debug`, the runtime mode and slimpeller in particular,
/// which are Bazel flags.
/// The assumptions of one GN out directory, for the oracle
/// (tool/gn_desc_diff.dart): [linuxHostAssumptions] overlaid with the
/// directory's own arguments -- every name the Linux assumptions fix that
/// `gn args --list` reports takes the directory's value (is_debug, the
/// Skia, Impeller and shell arguments, use_ios_simulator, the deployment
/// targets; the runtime mode stays a select, as it is not fixed there) --
/// and with what BUILDCONFIG.gn, common/config.gni and testing.gni derive
/// from target_os, target_cpu, host_os and host_cpu: the OS predicates, the
/// toolchain labels, the platform and prebuilt SDK names, enable_unittests,
/// enable_ios_unittests, build_engine_artifacts, use_flutter_cxx -- and
/// with the directory's values of the settings the generated files select
/// on (is_debug, use_ios_simulator, the backends) and of the runtime mode,
/// so that the comparison covers the branch the directory builds. So the
/// oracle reads an iOS simulator or a Mac host directory as it reads a
/// Linux one.
Assumptions outDirectoryAssumptions(Map<String, GnValue> args) {
  final Assumptions base = linuxHostAssumptions();
  // The directory decides what the generated files select on, too: the
  // settings (is_debug, use_ios_simulator, the backends) and the runtime
  // mode, so that the comparison covers the branch the directory builds.
  // An empty string is GN's "unset" for an argument a .gni computes when
  // args.gn leaves it (darwin_sdk.gni's SDK paths, which exec_script fills
  // in): the base value (a reference constant) stands.
  bool unset(GnValue? value) => value == null || (value is GnStringValue && value.value.isEmpty);
  final values = <String, GnValue>{
    for (final String name in <String>{
      ...base.names,
      ...conditionSettings.keys,
      'is_debug',
      'flutter_runtime_mode',
    })
      if (!unset(args[name])) name: args[name]!,
  };
  String string(String name, String fallback) {
    final GnValue? value = args[name];
    return value is GnStringValue && value.value.isNotEmpty ? value.value : fallback;
  }

  bool flag(String name, bool fallback) {
    final GnValue? value = args[name];
    return value is GnBoolValue ? value.value : fallback;
  }

  final String hostOs = string('host_os', 'linux');
  final String hostCpu = string('host_cpu', 'x64');
  final String targetOs = string('target_os', hostOs);
  final String targetCpu = string('target_cpu', hostCpu);
  final isLinux = targetOs == 'linux';
  final isMac = targetOs == 'mac';
  final isIos = targetOs == 'ios';
  final isAndroid = targetOs == 'android';
  final isWin = targetOs == 'win';
  final isWasm = targetOs == 'wasm';
  final bool simulator = flag('use_ios_simulator', false);
  final hostToolchain = '//build/toolchain/$hostOs:clang_$hostCpu';
  final defaultToolchain = isIos
      ? (simulator
            ? (targetCpu == 'arm64'
                  ? '//build/toolchain/mac:ios_clang_arm_sim'
                  : '//build/toolchain/mac:ios_clang_x64_sim')
            : '//build/toolchain/mac:ios_clang_arm')
      : isWasm
      ? '//build/toolchain/wasm'
      : '//build/toolchain/$targetOs:clang_$targetCpu';
  final hostBuild = defaultToolchain == hostToolchain;
  final String runtimeMode = string('flutter_runtime_mode', 'debug');
  String osName(String os) => switch (os) {
    'mac' => 'macos',
    'win' => 'windows',
    _ => os,
  };
  String platformName(String os) => switch (os) {
    'mac' => 'darwin',
    'win' => 'windows',
    _ => os,
  };
  final hostPrebuilts = '//flutter/prebuilts/${osName(hostOs)}-$hostCpu';
  final targetPrebuilts = '//flutter/prebuilts/${osName(targetOs)}-$targetCpu';
  // config.gni: the host's SDK for the host's own build and the cross
  // builds whose target runs no SDK (Android, iOS, wasm).
  final bool hostSdk = hostBuild || isAndroid || isIos || isWasm;
  values.addAll(<String, GnValue>{
    'current_cpu': GnStringValue(targetCpu),
    'current_os': GnStringValue(targetOs),
    'target_cpu': GnStringValue(targetCpu),
    'target_os': GnStringValue(targetOs),
    'host_cpu': GnStringValue(hostCpu),
    'host_os': GnStringValue(hostOs),
    'current_toolchain': GnStringValue(defaultToolchain),
    'default_toolchain': GnStringValue(defaultToolchain),
    'host_toolchain': GnStringValue(hostToolchain),
    'is_android': GnBoolValue(isAndroid),
    'is_apple': GnBoolValue(isMac || isIos),
    'is_ios': GnBoolValue(isIos),
    'is_linux': GnBoolValue(isLinux),
    'is_mac': GnBoolValue(isMac),
    'is_wasm': GnBoolValue(isWasm),
    'is_win': GnBoolValue(isWin),
    // BUILDCONFIG.gn's use_flutter_cxx.
    'use_flutter_cxx': GnBoolValue(isLinux || isAndroid || isMac || isIos),
    // testing.gni, and its iOS suite.
    'enable_unittests': GnBoolValue(hostBuild || isMac),
    'enable_ios_unittests': GnBoolValue(isIos && runtimeMode == 'debug'),
    // config.gni.
    'build_engine_artifacts': GnBoolValue(
      flag('flutter_build_engine_artifacts', true) &&
          !isAndroid &&
          (hostBuild || (isLinux && targetCpu != 'arm') || isMac || isWin),
    ),
    'platform_name': GnStringValue(platformName(hostOs)),
    'full_platform_name': GnStringValue('${platformName(hostOs)}-$hostCpu'),
    'target_platform_name': GnStringValue(platformName(targetOs)),
    'full_target_platform_name': GnStringValue('${platformName(targetOs)}-$targetCpu'),
    'host_prebuilt_dart_sdk': GnStringValue('$hostPrebuilts/dart-sdk'),
    'target_prebuilt_dart_sdk': GnStringValue('$targetPrebuilts/dart-sdk'),
    'prebuilt_dart_sdk': GnStringValue('${hostSdk ? hostPrebuilts : targetPrebuilts}/dart-sdk'),
  });
  return base.withValues(values);
}

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
    'buildtools_path': GnStringValue('//flutter/buildtools'),
    'is_ios': GnBoolValue(false),
    'enable_ios_unittests': GnBoolValue(false),
    'is_linux': GnBoolValue(true),
    'is_mac': GnBoolValue(false),
    'mac_testing_deployment_target': GnStringValue('14.0'),
    ..._iosSdkAssumptions,
    // BUILDCONFIG.gn's default; tools/gn sets it only for the Dart SDK's
    // own configuration (the wrap's args).
    'is_minimal_linux': GnBoolValue(false),
    'is_official_build': GnBoolValue(true),
    'wasm_use_dwarf': GnBoolValue(false),
    'is_qnx': GnBoolValue(false),
    'is_wasm': GnBoolValue(false),
    'is_win': GnBoolValue(false),
    // BUILDCONFIG.gn: clang on Linux links the engine's own libc++.
    'use_flutter_cxx': GnBoolValue(true),
    // //flutter/common/config.gni
    'enable_backtrace': GnBoolValue(true),
    'enable_unittests': GnBoolValue(true),
    // //flutter/shell/platform/embedder/embedder.gni: off for the host.
    'embedder_for_target': GnBoolValue(false),
    // The artifact names (config.gni computes them from host_os, host_cpu,
    // target_os and target_cpu), and whether the host builds the SDK's
    // artifacts at all: on a Linux x64 host, yes.
    'platform_name': GnStringValue('linux'),
    'full_platform_name': GnStringValue('linux-x64'),
    'android_sdk_root': GnStringValue('//flutter/third_party/android_tools/sdk'),
    'android_sdk': GnStringValue('//flutter/third_party/android_tools/sdk/platforms/android-37.0'),
    'android_sdk_jar': GnStringValue(
      '//flutter/third_party/android_tools/sdk/platforms/android-37.0/android.jar',
    ),
    'android_sdk_build_tools': GnStringValue(
      '//flutter/third_party/android_tools/sdk/build-tools/37.0.0',
    ),
    'android_app_abi': _androidAppAbi,
    'target_platform_name': GnStringValue('linux'),
    'full_target_platform_name': GnStringValue('linux-x64'),
    'build_engine_artifacts': GnBoolValue(true),
    // tools/gn's --prebuilt-dart-sdk, which every host builder passes and
    // `et` defaults to: the engine's Dart tooling comes from the prebuilt
    // SDK under flutter/prebuilts. The one build without it
    // (host_debug_no_prebuilt_dart_sdk, --no-prebuilt-dart-sdk) is the Dart
    // wrap's flutter_prebuilt_dart_sdk setting (build/bazel/dart_wrap), which the
    // hand-written files that stand for the GN sites reading the argument
    // select on -- the wrap builds the SDK, flutter_frontend_server takes
    // its snapshot -- so the generated files assume the prebuilt (the
    // archives and the web SDK are built by no builder without it).
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
    // tools/gn on a Mac alone (research/20): off for a Linux host.
    'allow_deprecated_api_calls': GnBoolValue(false),
    'skia_use_metal': GnBoolValue(false),
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
    // skia.gni's defaults as they come out on a Linux host, for the
    // arguments the web build passes differently (perTargetOsArguments), so
    // that the generation scope's formulas can be held against the host's
    // values by name.
    'skia_use_webgpu': GnBoolValue(false),
    'skia_use_libjpeg_turbo_encode': GnBoolValue(true),
    'skia_use_no_jpeg_encode': GnBoolValue(false),
    'skia_use_libwebp_encode': GnBoolValue(true),
    'skia_use_no_webp_encode': GnBoolValue(false),
    'skia_enable_skottie': GnBoolValue(true),
    'skia_enable_fontmgr_custom_directory': GnBoolValue(true),
    'skia_canvaskit_enable_webgl': GnBoolValue(false),
    'skia_icu_bidi_third_party_dir': GnStringValue('//flutter/third_party/canvaskit/icu_bidi'),
  });
}
