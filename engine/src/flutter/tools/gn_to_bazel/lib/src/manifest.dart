// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The GN files whose `BUILD.bazel` the converter generates, with what each
/// one needs beyond the mechanical conversion.
///
/// `dart bin/gn_to_bazel.dart` with no arguments regenerates the checked-in
/// files ([convertedFiles]); `--check` verifies that they are what the
/// converter produces, which is the presubmit. The files of
/// [fetchTimeFiles] are generated into external repositories by Bazel
/// itself (`synced_repository` in build/bazel/repositories.bzl) and are not
/// checked in; they are listed for what they need.
library;

import 'bazel_mapping.dart';
import 'mirrored_lists.dart';

/// One generated file.
final class ConvertedFile {
  const ConvertedFile(
    this.gnPackage, {
    this.skip = const <String, String>{},
    this.appendix,
    this.implicitDeps = const <String>[],
  });

  /// The GN directory (`//flutter/fml`); the input is its `BUILD.gn`.
  final String gnPackage;

  /// Targets not to convert, with the reason for each. These are the
  /// targets whose dependencies have no Bazel build yet, or which use a
  /// template the converter does not know; the list shrinks as the
  /// migration proceeds.
  final Map<String, String> skip;

  /// Starlark appended verbatim to the generated file: what the GN file has
  /// no way to express.
  final String? appendix;

  /// Bazel labels added to the `deps` of every target of the file that
  /// compiles something: what GN leaves implicit. GN does not track the
  /// headers a compilation reads; Bazel requires every one of them to be
  /// declared by the target or its dependencies, so a tree whose GN lists
  /// do not carry its headers along its dependency edges (Skia's) gets them
  /// from one library of all its headers.
  final List<String> implicitDeps;
}

const List<ConvertedFile> convertedFiles = <ConvertedFile>[
  // GN's config("flutter_config") is feature_defines_list, which copts.bzl
  // keeps as FLUTTER_FEATURE_DEFINES over the flags below: the Bazel side
  // of config.gni's arguments, which no GN file declares as targets.
  ConvertedFile(
    '//flutter/common',
    appendix: '''
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag", "string_flag")

# GN's `flutter_runtime_mode` argument. Orthogonal to Bazel's compilation
# mode, exactly as in GN: host_debug_unopt is `-c dbg`, host_debug is
# `-c opt`, and host_release is `-c opt --//engine/src/flutter/common:runtime_mode=release`.
string_flag(
    name = "runtime_mode",
    build_setting_default = "debug",
    values = [
        "debug",
        "profile",
        "release",
        "jit_release",
    ],
)

[
    config_setting(
        name = "runtime_mode_" + mode,
        flag_values = {":runtime_mode": mode},
    )
    for mode in [
        "debug",
        "profile",
        "release",
        "jit_release",
    ]
]

# GN's `slimpeller` argument: build without the Skia-backed rendering paths.
bool_flag(
    name = "slimpeller",
    build_setting_default = False,
)

config_setting(
    name = "slimpeller_enabled",
    flag_values = {":slimpeller": "True"},
)

# config("export_dynamic_symbols") and config("export_dynamic_test_symbols")
# in //flutter/BUILD.gn read these.
exports_files([
    "exported_symbols.sym",
    "exported_symbols_mac.sym",
    "exported_test_symbols.sym",
    "exported_test_symbols_mac.sym",
])
''',
  ),
  ConvertedFile('//flutter/fml'),
  // The benchmark library (google/benchmark through @benchmark) and the
  // engine's wrapper of it, for the benchmark executables run_tests.py
  // --type benchmarks runs (benchmarkRuns).
  ConvertedFile('//flutter/benchmarking'),
  ConvertedFile(
    '//flutter/testing',
    // The fixtures macro in testing.bzl compiles this file into every
    // fixtures library, from whichever package declares one.
    //
    // GN's `enable_unittests` (testing.gni: `current_toolchain ==
    // host_toolchain || is_fuchsia || is_mac`, which no builder overrides)
    // read in Bazel terms: a configuration counts when its OS is one the
    // engine's tests run on. The exec configuration is the host's platform,
    // so tools see it enabled as GN's host toolchain does; an Android, iOS
    // or wasm target configuration does not.
    appendix: '''
load("@bazel_skylib//lib:selects.bzl", "selects")

exports_files([
    "fixtures_location.cc",
    # The display wrapper of flutter_display_test (testing.bzl).
    "xvfb_run.sh",
    # The gtest-parallel wrapper of flutter_cc_test (testing.bzl).
    "gtest_parallel_run.sh",
])

selects.config_setting_group(
    name = "unittests_enabled",
    match_any = [
        "@platforms//os:fuchsia",
        "@platforms//os:linux",
        "@platforms//os:macos",
        "@platforms//os:windows",
    ],
)

# The goldens and other resources testing/run_tests.py hands suites with
# --golden-dir (flow_unittests).
filegroup(
    name = "resources",
    srcs = glob(["resources/**"]),
)
''',
  ),
  // Impeller's group, its own suite (impeller_unittests, which links every
  // suite source_set below) and the Flutter GPU one.
  ConvertedFile('//flutter/impeller'),
  // The per-component suites (base_unittests, geometry_unittests, ...) are
  // source_sets GN links into the one impeller_unittests binary above, and
  // shell/profiling's into shell_unittests; they ran as binaries of their
  // own here until those converted.
  ConvertedFile('//flutter/impeller/base'),
  ConvertedFile('//flutter/impeller/geometry'),
  ConvertedFile('//flutter/display_list'),
  // The shader compiler, impellerc, and what it needs of Impeller
  // (research/08, step 3).
  ConvertedFile('//flutter/impeller/core'),
  ConvertedFile('//flutter/impeller/runtime_stage'),
  ConvertedFile('//flutter/impeller/shader_bundle'),
  ConvertedFile('//flutter/impeller/compiler'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib/flutter'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib/impeller'),
  // The shader pipeline's users (research/08, step 4): impeller_shaders()
  // invocations become the macro in build/bazel/impeller.
  ConvertedFile('//flutter/impeller/shader_archive'),
  ConvertedFile('//flutter/impeller/tessellator'),
  ConvertedFile('//flutter/impeller/renderer'),
  // The gmock doubles of the renderer's interfaces, which the core and
  // other suites test against.
  ConvertedFile('//flutter/impeller/renderer/testing'),
  // The playground (a GLFW window, or none, over each backend; Dear ImGui
  // widgets) and the test helpers on it; the screenshotter and golden
  // digests beside it.
  ConvertedFile('//flutter/impeller/testing'),
  // The golden-test helpers the renderer and display_list suites link (the
  // Metal screenshotter and the golden binary are macOS-only).
  ConvertedFile('//flutter/impeller/golden_tests'),
  // The interop toolkit (the Impeller SDK's C API) and its suite; the SDK
  // bundle is packaging, and the static library a GN artifact
  // (complete_static_lib) Bazel's cc_library does not stand for.
  ConvertedFile(
    '//flutter/impeller/toolkit/interop',
    skip: <String, String>{
      'sdk': 'zip_bundle: artifact packaging',
      'static_library': 'complete_static_lib: an artifact of the GN build',
      'example_mtl': 'Objective-C and Metal: macOS',
    },
  ),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend'),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend/gles'),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend/vulkan'),
  ConvertedFile('//flutter/impeller/playground/image'),
  ConvertedFile('//flutter/impeller/playground/imgui'),
  ConvertedFile('//flutter/impeller/playground'),
  // The test fixtures: two shader libraries, the runtime stages and shader
  // bundles (impellerc invoked directly) and the files, with the Dart entry
  // point of the Flutter GPU tests.
  ConvertedFile(
    '//flutter/impeller/fixtures',
    // lib/ui's shader fixtures compile shaders of this directory
    // (`//flutter/impeller/fixtures/ink_sparkle.frag`, the Flutter GPU ones).
    appendix: '''
exports_files(glob([
    "*.frag",
    "*.vert",
    "ordering/*.frag",
]))
''',
  ),
  ConvertedFile('//flutter/impeller/typographer'),
  ConvertedFile('//flutter/impeller/entity'),
  // The display_list_unittests chain (research/08, step 5): the text stack
  // and Impeller's display list.
  ConvertedFile('//flutter/impeller/typographer/backends/skia'),
  ConvertedFile('//flutter/impeller/display_list'),
  // The desktop embeddings' shared code: the public headers, the input
  // model, the isolate scope, the engine switches, the core (path
  // utilities, windowing) with its tests -- the first converted test to
  // link the Dart VM from the wrap -- and, on the embedder and the client
  // wrapper, common_cpp (the JSON codecs, the message dispatcher) with its
  // suite. The accessibility bridge (common_cpp_accessibility) and the tree
  // it builds on, //flutter/third_party/accessibility, are the Windows and
  // macOS embedders': on a Linux host neither compiles under GN either
  // (gfx::NativeWindow is defined for those two alone; the bridge fails on
  // a deprecation warning), and nothing CI builds there reaches them --
  // they wait for those hosts' build.
  ConvertedFile('//flutter/shell/geometry'),
  ConvertedFile(
    '//flutter/shell/platform/common',
    skip: <String, String>{
      'common_cpp_accessibility':
          'needs //flutter/third_party/accessibility, which compiles on Windows and macOS alone',
    },
  ),
  // The C++ client wrapper (plugin API) the desktop embeddings build on,
  // with its suite; its file lists come from core_wrapper_files.gni. The
  // GLFW wrapper's headers include the core wrapper's as siblings (the
  // merged layout clients see), through a config whose include directory
  // is this package's include/flutter: the library below carries it
  // (includeDirLibraries).
  ConvertedFile(
    '//flutter/shell/platform/common/client_wrapper',
    appendix: '''
# The include/flutter directory as an include path, for the platform
# wrappers' configs (//flutter/shell/platform/glfw/client_wrapper:
# relative_core_wrapper_headers).
cc_library(
    name = "relative_core_wrapper_headers",
    includes = ["include/flutter"],
)

# What publish_client_wrapper_core (publish.gni) copies from here into the
# platform wrappers' cpp_client_wrapper_<platform>: core_wrapper_files.gni's
# lists -- the public headers, the internal headers, the sources and the
# shim -- and the README; the glob is exactly those.
exports_files(["README"] + glob(
    [
        "*.cc",
        "*.h",
        "include/flutter/*.h",
    ],
    exclude = ["*_unittests.cc"],
))
''',
  ),
  // The GLFW shell (the desktop embedding's reference implementation on
  // Linux hosts) and its client wrapper, with their suites; the X11 config
  // it lists is //flutter/shell/platform/linux/config's (hand-written).
  ConvertedFile('//flutter/shell/platform/glfw'),
  ConvertedFile('//flutter/shell/platform/glfw/client_wrapper'),
  // The GTK shell (the Linux embedding) with its suite, which runs under a
  // display with GLib's criticals fatal as run_tests.py runs it; its
  // system libraries are //flutter/shell/platform/linux/config's.
  ConvertedFile(
    '//flutter/shell/platform/linux',
    skip: <String, String>{'flutter_gtk': 'zip_bundle: artifact packaging'},
  ),
  // The Android embedding's host-testable pieces (the JNI facade with its
  // mock, the native window, the context, the surfaces, the external view
  // embedder, the platform view delegate) with the three suites
  // run_tests.py runs on every non-Windows host.
  // android_rendering_selector.h, an enum of the parent directory that no
  // GN target lists (the shell's source set could not carry it for them:
  // its visibility excludes these packages), comes from the hand-written
  // parent package.
  ConvertedFile('//flutter/shell/platform/android/jni'),
  ConvertedFile(
    '//flutter/shell/platform/android/context',
    implicitDeps: <String>['//engine/src/flutter/shell/platform/android:rendering_selector'],
  ),
  ConvertedFile('//flutter/shell/platform/android/surface'),
  ConvertedFile(
    '//flutter/shell/platform/android/external_view_embedder',
    implicitDeps: <String>['//engine/src/flutter/shell/platform/android:rendering_selector'],
  ),
  ConvertedFile('//flutter/shell/platform/android/platform_view_android_delegate'),
  // flutter_tester, the host runner of the engine's Dart tests
  // (testing/dart through run_tests.py), and its OpenGL ES variant.
  ConvertedFile('//flutter/shell/testing'),
  // txt_unittests' embedded test font. The rest of the file is the Dart
  // runtime glue, which needs tonic, lib/snapshot and the shell.
  ConvertedFile('//flutter/runtime'),
  ConvertedFile(
    '//flutter/txt',
    // The fonts are fixtures of other packages' tests (display_list's).
    appendix: '''
exports_files(glob(["third_party/fonts/*"]))
''',
  ),
  ConvertedFile(
    '//flutter/display_list/testing',
    // display_list_rendertests' source, which //flutter/display_list/BUILD.gn
    // lists across the package boundary.
    appendix: '''
exports_files(["dl_rendering_unittests.cc"])
''',
  ),
  ConvertedFile('//flutter/assets'),
  // The four defines take their values from @engine_version//:version.bzl
  // (referenceConstants), the Bazel side of what tools/gn computes.
  ConvertedFile('//flutter/shell/version'),
  ConvertedFile('//flutter/common/graphics'),
  ConvertedFile('//flutter/vulkan/procs'),
  // flutter_vma/config.gni's disable_vma_stl_shared_mutex: tools/gn sets it
  // where the C++ library has no std::shared_mutex (iOS; Windows hosts),
  // read in Bazel terms as those target platforms.
  ConvertedFile(
    '//flutter/flutter_vma',
    appendix: '''
load("@bazel_skylib//lib:selects.bzl", "selects")

selects.config_setting_group(
    name = "without_stl_shared_mutex",
    match_any = [
        "@platforms//os:ios",
        "@platforms//os:windows",
    ],
)
''',
  ),
  // Impeller's rendering backends (what //flutter/impeller's group and
  // //flutter/flow need) and their test suites, on the playground.
  ConvertedFile('//flutter/impeller/renderer/backend/gles'),
  ConvertedFile('//flutter/impeller/renderer/backend/vulkan'),
  ConvertedFile('//flutter/impeller/renderer/backend'),
  ConvertedFile('//flutter/flow'),
  // The Dart bindings library (engine-owned third_party), on the way to
  // lib/ui and runtime; its tests need the Dart snapshot and libdart.
  // tonic's suite lists one source of the parent package.
  ConvertedFile(
    '//flutter/third_party/tonic',
    appendix: '''
exports_files(["file_loader/file_loader_unittests.cc"])
''',
  ),
  ConvertedFile('//flutter/third_party/tonic/tests'),
  // dart:ui's bindings and their suite (on the Dart snapshot, libdart, the
  // shell's test fixtures and the shader fixtures below).
  ConvertedFile(
    '//flutter/lib/ui',
    // dart_ui.gni's dart_ui_files: the dart:ui sources, which the platform
    // compile in lib/snapshot reads through lib/snapshot/libraries.json.
    // The fixture files themselves, which the Dart tests of testing/dart
    // read from the source root (flutter/lib/ui/fixtures/...), besides the
    // copies in assets/.
    appendix: '''
filegroup(
    name = "dart_ui",
    srcs = glob(["*.dart"]),
)

filegroup(
    name = "fixture_sources",
    srcs = glob(["fixtures/*"]),
)
''',
  ),
  // The shader fixtures of lib/ui: impellerc() invoked directly, with each
  // directory's test_fixtures destined for lib/ui's assets (`dest`).
  ConvertedFile(
    '//flutter/lib/ui/fixtures/shaders',
    // The compiled shaders at their build paths (each package's fixtures,
    // and the two targets GN's fixtures depend on without listing their
    // outputs, besides the copies in lib/ui's assets): fragment_shader_test
    // lists the directories under $FLUTTER_BUILD_DIRECTORY/gen as GN lays
    // them out, and reads ink_sparkle_web's JSON from iplr-json/.
    appendix: '''
filegroup(
    name = "compiled",
    testonly = True,
    srcs = [
        ":fixtures",
        ":ink_sparkle_web",
        ":sampler_order_fixture",
        "//engine/src/flutter/lib/ui/fixtures/shaders/general_shaders:fixtures",
        "//engine/src/flutter/lib/ui/fixtures/shaders/supported_glsl_op_shaders:fixtures",
        "//engine/src/flutter/lib/ui/fixtures/shaders/supported_op_shaders:fixtures",
        "//engine/src/flutter/lib/ui/fixtures/shaders/uniforms:fixtures",
    ],
)
''',
  ),
  ConvertedFile('//flutter/lib/ui/fixtures/shaders/general_shaders'),
  ConvertedFile('//flutter/lib/ui/fixtures/shaders/supported_glsl_op_shaders'),
  ConvertedFile('//flutter/lib/ui/fixtures/shaders/supported_op_shaders'),
  ConvertedFile('//flutter/lib/ui/fixtures/shaders/uniforms'),
  ConvertedFile('//flutter/lib/io'),
  ConvertedFile('//flutter/vulkan'),
  // The GPU surfaces and their suite (on SwiftShader's static library and
  // the Impeller fixtures).
  ConvertedFile('//flutter/shell/gpu'),
  // The sampling profiler; GN links its suite into shell_unittests.
  ConvertedFile('//flutter/shell/profiling'),
  ConvertedFile(
    '//flutter/lib/gpu',
    skip: <String, String>{
      'gpu_unittests_fixtures': 'with gpu_unittests',
      // The suite converts and links (it did, once), and its GN binary
      // and Bazel binary fail identically: FlutterGpuCommandBufferTest
      // constructs a ref-counted CommandBuffer on the stack, which trips
      // fml's adoption check in debug builds. testing/run_tests.py does
      // not run it on any platform.
      'gpu_unittests':
          'crashes at this revision in debug builds '
          '(FlutterGpuCommandBufferTest, fml adoption check); run_tests.py does not run it',
    },
    // The Flutter GPU Dart library, which impeller/fixtures' entry point
    // imports by relative path (templateAttributeOverrides).
    appendix: '''
filegroup(
    name = "dart_sources",
    srcs = glob(["lib/**/*.dart"]),
)
''',
  ),
  // The shell proper needs the Dart runtime glue (lib/ui, runtime, tonic)
  // and the GPU surfaces; what converts now is what //flutter/common/graphics
  // and the shell's own small libraries need.
  ConvertedFile('//flutter/shell/common'),
  // The embedder API: its libraries, its shared library and its three suites.
  // What stays out is the artifact side -- the header copied into the build
  // root, the group and the zip bundle CI archives -- which is a later
  // phase's (the Linux artifacts).
  ConvertedFile(
    '//flutter/shell/platform/embedder',
    skip: <String, String>{
      'copy_headers': 'the artifact copy into the build root, a later phase',
      'flutter_engine': 'the artifact group, a later phase',
      'embedder-archive': 'zip_bundle: artifact packaging, a later phase',
    },
  ),
];

/// The files generated into `@skia` at fetch time: the engine's GN for Skia
/// (`//flutter/skia`, a fork of Skia's BUILD.gn over Skia's `gn/*.gni`
/// source lists) laid out over Skia's synced tree (research/07).
const List<ConvertedFile> fetchTimeFiles = <ConvertedFile>[
  ConvertedFile(
    '//flutter/skia',
    implicitDeps: <String>['@skia//:skia_headers'],
    // Skia's generated source lists carry each target's own headers, but a
    // target reads the headers of targets that depend on it (an opts
    // library includes src/core/SkOpts.h), which GN never minds and Bazel's
    // sandbox cannot see. Every target in the repository gets all of
    // Skia's headers (implicitDeps above); the engine includes them as
    // `third_party/skia/...`, hence the prefix. Files Skia includes
    // textually (.inc, the generated SkSL modules) are textual headers.
    // A glob stops at a package boundary, so the packages below export
    // their own headers.
    //
    // Engine code also includes Skia as `flutter/third_party/skia/...`,
    // its path under the engine's source root, which GN's `-I//` resolves
    // on disk. That root is @flutter//engine/src:include_root, which
    // carries the same headers under the second prefix; this way Skia's
    // own compiles do not stage the symlinks only the engine uses.
    appendix: '''
filegroup(
    name = "headers",
    srcs = glob([
        "include/**/*.h",
        "modules/**/*.h",
        "src/**/*.h",
    ]),
)

cc_library(
    name = "skia_headers",
    hdrs = [":headers"],
    include_prefix = "third_party/skia",
    textual_hdrs = glob([
        "src/**/*.inc",
        "src/sksl/generated/*.sksl",
    ]),
    deps = ["//modules/skcms:skcms_headers"],
)

cc_library(
    name = "engine_root_headers",
    hdrs = [":headers"],
    include_prefix = "flutter/third_party/skia",
    visibility = ["@flutter//engine/src:__pkg__"],
    deps = ["//modules/skparagraph:engine_root_headers"],
)

# tools/Resources.h, which modules/skparagraph/utils/TestFontCollection.cpp
# (test-only, check_includes off; txt_benchmarks links it) includes and does
# not use; for that package alone, not the headers above (which every
# compile in the tree stages).
cc_library(
    name = "tools_resources_header",
    hdrs = ["tools/Resources.h"],
    visibility = ["//modules/skparagraph:__pkg__"],
)

# Skia's test images, which the engine's Dart tests read from the source
# root (flutter/third_party/skia/resources/images/...; see
# @flutter//engine/src/flutter/third_party:skia_resources).
filegroup(
    name = "resources_images",
    srcs = glob(["resources/images/*"]),
)
''',
  ),
  ConvertedFile(
    '//flutter/skia/modules/skcms',
    implicitDeps: <String>['@skia//:skia_headers'],
    // Transform_inl.h is in none of skcms's source lists (Skia's Bazel
    // build has it as a textual header, which the lists leave out). The
    // prefix is the engine's path for the module (include_prefix replaces
    // the package's own path).
    appendix: '''
cc_library(
    name = "skcms_headers",
    hdrs = glob(["**/*.h"]),
    include_prefix = "third_party/skia/modules/skcms",
)
''',
  ),
  // Skia's text modules (research/08, step 5): the engine's GN over Skia's
  // module source lists, like //flutter/skia itself. Each is a package, so
  // the root's glob stops at it: each exports its own headers under the
  // path engine code includes them by, as skcms does.
  ConvertedFile(
    '//flutter/skia/modules/skunicode',
    implicitDeps: <String>['@skia//:skia_headers', '@skia//modules/skunicode:skunicode_headers'],
    appendix: '''
cc_library(
    name = "skunicode_headers",
    hdrs = glob(["**/*.h"]),
    include_prefix = "third_party/skia/modules/skunicode",
)
''',
  ),
  ConvertedFile(
    '//flutter/skia/modules/skshaper',
    implicitDeps: <String>['@skia//:skia_headers', '@skia//modules/skshaper:skshaper_headers'],
    appendix: '''
cc_library(
    name = "skshaper_headers",
    hdrs = glob(["**/*.h"]),
    include_prefix = "third_party/skia/modules/skshaper",
)
''',
  ),
  ConvertedFile(
    '//flutter/skia/modules/skparagraph',
    implicitDeps: <String>[
      '@skia//:skia_headers',
      '@skia//:tools_resources_header',
      '@skia//modules/skparagraph:skparagraph_headers',
    ],
    appendix: '''
cc_library(
    name = "skparagraph_headers",
    hdrs = glob(["**/*.h"]),
    include_prefix = "third_party/skia/modules/skparagraph",
)

# The engine-root spelling (`flutter/third_party/skia/modules/skparagraph/
# include/Paragraph.h`, the interop toolkit's), for the root's
# engine_root_headers; the root's glob stops at this package.
cc_library(
    name = "engine_root_headers",
    hdrs = glob(["include/*.h"]),
    include_prefix = "flutter/third_party/skia/modules/skparagraph",
    visibility = ["//:__pkg__"],
)
''',
  ),
  // Skia's own GN for the config that hides ICU's C++ API from skunicode.
  ConvertedFile('//flutter/third_party/skia/third_party/icu/config'),
  ConvertedFile(
    '//flutter/third_party/skia/src/partition_alloc',
    implicitDeps: <String>['@skia//:skia_headers'],
  ),
  // Skia's codec and font dependencies: small GN files (in the synced tree,
  // in the engine's secondary source tree, or in the engine itself over a
  // synced `src/`), each over a tree whose headers GN never declares.
  ConvertedFile(
    '//flutter/third_party/libpng',
    implicitDeps: <String>['@libpng//:libpng_headers'],
    appendix: '''
cc_library(
    name = "libpng_headers",
    hdrs = glob(["**/*.h"]),
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/libwebp',
    implicitDeps: <String>['@libwebp//:libwebp_headers'],
    appendix: '''
cc_library(
    name = "libwebp_headers",
    hdrs = glob(["**/*.h"]),
    # sharpyuv_cpu.c includes the CPU detection source.
    textual_hdrs = ["src/dsp/cpu.c"],
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/wuffs',
    implicitDeps: <String>['@wuffs//:wuffs_headers'],
    // Wuffs is a single-file library: its .c is the header its users
    // include, and what the `wuffs` target compiles with WUFFS_IMPLEMENTATION.
    appendix: '''
cc_library(
    name = "wuffs_headers",
    textual_hdrs = ["release/c/wuffs-v0.3.c"],
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/expat',
    implicitDeps: <String>['@expat//:expat_headers'],
    // expat_config comes from the secondary source tree, mirrored into the
    // repository beside the GN file; xmltok.c includes two .c files.
    appendix: '''
cc_library(
    name = "expat_headers",
    hdrs = glob([
        "expat/lib/*.h",
        "expat_config/*.h",
    ]),
    textual_hdrs = [
        "expat/lib/xmltok_impl.c",
        "expat/lib/xmltok_ns.c",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/freetype2',
    implicitDeps: <String>['@freetype2//:freetype2_headers'],
    // FreeType's amalgamated sources (ftbase.c, sfnt.c, ...) include the
    // other .c files of their directories.
    appendix: '''
cc_library(
    name = "freetype2_headers",
    hdrs = glob(["include/**/*.h"]),
    textual_hdrs = glob([
        "src/**/*.c",
        "src/**/*.h",
    ]),
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/libjpeg-turbo',
    implicitDeps: <String>['@libjpeg-turbo//:libjpeg_headers'],
    // jdcolor.c, jdhuff.c and friends include the .c files that hold their
    // colour-space and Huffman table variants.
    appendix: '''
cc_library(
    name = "libjpeg_headers",
    hdrs = glob(["src/**/*.h"]),
    textual_hdrs = glob(["src/*.c"]),
)
''',
  ),
  // The shader compiler's dependencies (research/08, step 1): the engine's
  // GN in the secondary source tree over synced trees it names by absolute
  // path (`$source_root/...`), and SPIRV-Headers' own GN.
  ConvertedFile('//third_party/inja'),
  ConvertedFile(
    '//flutter/third_party/json',
    implicitDeps: <String>['@json//:flutter_root_headers'],
    // Engine code includes json by its path under //flutter
    // ("third_party/json/include/nlohmann/json.hpp"), which GN's
    // //flutter:config resolves on disk. The view under that path travels
    // with the dependency: a target that includes it depends on json, as
    // `gn check` asks.
    appendix: '''
cc_library(
    name = "flutter_root_headers",
    hdrs = glob(["include/**/*.hpp"]),
    include_prefix = "third_party/json",
)
''',
  ),
  ConvertedFile('//third_party/spirv_cross_flutter'),
  ConvertedFile(
    '//flutter/third_party/flatbuffers',
    implicitDeps: <String>['@flatbuffers//:flatbuffers_headers'],
    // The GN lists leave out headers the sources include (src/idl_gen_text.h
    // and friends).
    appendix: '''
cc_library(
    name = "flatbuffers_headers",
    hdrs = glob([
        "grpc/src/compiler/*.h",
        "include/**/*.h",
        "src/*.h",
    ]),
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/vulkan-deps/spirv-headers/src',
    implicitDeps: <String>['@spirv-headers//:headers'],
    // The GN target lists eleven headers; SPIRV-Tools and glslang include
    // others (spirv.hpp11, the extended instruction set headers). The
    // actions of SPIRV-Tools read the grammars and the registry from here.
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
    ]),
    includes = ["include"],
    textual_hdrs = glob(["include/**/*.hpp11"]),
)

exports_files(glob(["include/**"]))
''',
  ),
  ConvertedFile(
    '//flutter/third_party/vulkan-deps/vulkan-headers/src',
    implicitDeps: <String>['@vulkan-headers//:headers'],
    // The GN target lists nineteen headers; vulkan.h includes the platform
    // headers the config's defines select (vulkan_xcb.h, vulkan_wayland.h)
    // and vulkan.hpp its generated companions, none of them listed.
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
    ]),
    includes = ["include"],
)
''',
  ),
  // The two Khronos trees whose GN runs scripts (tables and headers
  // generated from SPIRV-Headers' grammars; glslang's build info): their
  // action() targets become gn_action rules (research/08, step 2).
  ConvertedFile(
    '//flutter/third_party/vulkan-deps/spirv-tools/src',
    implicitDeps: <String>['@spirv-tools//:headers'],
    // Eight headers under source/ (val/instruction.h, the precompiled
    // header stubs, diff/) are in no GN list.
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
        "source/**/*.h",
    ]),
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/vulkan-deps/glslang/src',
    implicitDeps: <String>['@glslang//:headers'],
    // The GN lists leave out headers the sources include
    // (MachineIndependent/span.h, StandAlone/Worklist.h).
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "SPIRV/*.h",
        "StandAlone/*.h",
        "glslang/**/*.h",
    ]),
    textual_hdrs = glob(["SPIRV/*.hpp11"]),
)
''',
  ),
  // re2 as the engine builds it (secondary tree); the util/ headers its
  // sources include are in no list. Engine code includes re2 by its path
  // under the engine's source root ("flutter/third_party/re2/re2/re2.h"),
  // which GN's `-I//` resolves on disk; that view travels with the
  // dependency, as for json.
  ConvertedFile(
    '//flutter/third_party/re2',
    implicitDeps: <String>['@re2//:headers'],
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "re2/*.h",
        "util/*.h",
    ]),
    deps = [":engine_root_headers"],
)

cc_library(
    name = "engine_root_headers",
    hdrs = glob(["re2/*.h"]),
    include_prefix = "flutter/third_party/re2",
)
''',
  ),
  // shaderc as the engine builds it: the secondary tree's GN over the synced
  // tree, on glslang and SPIRV-Tools.
  ConvertedFile(
    '//third_party/shaderc_flutter',
    implicitDeps: <String>['@shaderc//:headers'],
    // The engine's lists leave out headers the sources include
    // (libshaderc_util/shader_stage.h).
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "libshaderc/include/**/*.h",
        "libshaderc/include/**/*.hpp",
        "libshaderc/src/*.h",
        "libshaderc_util/include/**/*.h",
        "libshaderc_util/src/*.h",
    ]),
    textual_hdrs = glob(["libshaderc_util/include/**/*.inc"]),
)
''',
  ),
  // harfbuzz as the engine builds it (secondary tree); its sources include
  // the .hh headers beside them, which no list names, and some include other
  // .cc files (hb-common.cc includes hb-static.cc; the amalgamation
  // harfbuzz.cc includes them all).
  ConvertedFile(
    '//flutter/third_party/harfbuzz',
    implicitDeps: <String>['@harfbuzz//:headers'],
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "src/**/*.h",
        "src/**/*.hh",
    ]),
    textual_hdrs = glob(["src/**/*.cc"]),
)
''',
  ),
  // google/benchmark as the engine builds it (secondary tree): the GN list
  // names src/ alone; the public headers under include/benchmark, which the
  // config's include directory serves, ride the dependency -- under their
  // path from the engine's source root too ("third_party/benchmark/include/
  // benchmark/benchmark.h", txt's benchmark runner's spelling), as for
  // libtess2.
  ConvertedFile(
    '//flutter/third_party/benchmark',
    implicitDeps: <String>['@benchmark//:headers'],
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob(["include/benchmark/*.h"]),
    deps = [":flutter_root_headers"],
)

cc_library(
    name = "flutter_root_headers",
    hdrs = glob(["include/benchmark/*.h"]),
    include_prefix = "third_party/benchmark",
)
''',
  ),
  // libtess2 as the engine builds it (secondary tree). Engine code includes
  // it by its path under //flutter ("third_party/libtess2/Include/
  // tesselator.h"); the view travels with the dependency, as for json.
  ConvertedFile(
    '//third_party/libtess2',
    implicitDeps: <String>['@libtess2//:flutter_root_headers'],
    appendix: '''
cc_library(
    name = "flutter_root_headers",
    hdrs = ["Include/tesselator.h"],
    include_prefix = "third_party/libtess2",
)
''',
  ),
  // VulkanMemoryAllocator: one header, listed by the secondary tree's GN;
  // its config's include directory and defines ride the dependency.
  ConvertedFile('//flutter/third_party/vulkan_memory_allocator'),
  // GLFW as the engine builds it (secondary tree): the platform sources
  // include internal headers no list names (internal.h, platform.h,
  // mappings.h, ...); the playground's GLES backend includes the public
  // header by its path under //flutter ("third_party/glfw/include/GLFW/
  // glfw3.h"), which rides the dependency as for libtess2.
  ConvertedFile(
    '//flutter/third_party/glfw',
    implicitDeps: <String>['@glfw//:headers'],
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob(["src/*.h"]),
    deps = [":flutter_root_headers"],
)

cc_library(
    name = "flutter_root_headers",
    hdrs = glob(["include/GLFW/*.h"]),
    include_prefix = "third_party/glfw",
)
''',
  ),
  // Dear ImGui as the engine builds it (secondary tree); the playground
  // includes it by its path under //flutter ("third_party/imgui/imgui.h",
  // "third_party/imgui/backends/imgui_impl_glfw.h"), and imgui.cpp includes
  // imconfig.h, which no list names.
  ConvertedFile(
    '//flutter/third_party/imgui',
    implicitDeps: <String>['@imgui//:headers'],
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "*.h",
        "backends/imgui_impl_glfw.h",
    ]),
    deps = [":flutter_root_headers"],
)

cc_library(
    name = "flutter_root_headers",
    hdrs = glob([
        "*.h",
        "backends/imgui_impl_glfw.h",
    ]),
    include_prefix = "third_party/imgui",
)
''',
  ),
];

/// The manifest entry for a GN directory, from either list.
ConvertedFile? manifestEntry(String gnPackage) {
  for (final file in <ConvertedFile>[...convertedFiles, ...fetchTimeFiles]) {
    if (file.gnPackage == gnPackage) {
      return file;
    }
  }
  return null;
}

/// The hand-written packages of the main repository whose files a generated
/// file may name (the generated packages are [convertedFiles]).
/// Hand-written files that repeat a list of their GN file: the Dart test
/// packages' `tests` (GN's `foreach` over it, which the evaluator does not
/// unroll). The converter checks that the two lists agree in every run
/// (mirroredListMismatches), so that a test added to GN's list is missed by
/// no one. GN package to the list's name.
const Map<String, MirroredList> mirroredLists = <String, MirroredList>{
  '//flutter/testing/dart': MirroredList('tests'),
  '//flutter/testing/dart/vm_service': MirroredList('tests'),
  '//flutter/testing/smoke_test_failure': MirroredList('tests'),
};

const Set<String> handWrittenPackages = <String>{
  'engine/src',
  'engine/src/flutter',
  'engine/src/flutter/impeller/tools',
  'engine/src/flutter/lib/snapshot',
  'engine/src/flutter/shell/vmservice',
  // The Dart tests under flutter_tester: GN's foreach over the test list and
  // run_tests.py's run matrix, which GN does not have.
  'engine/src/flutter/testing/dart',
  'engine/src/flutter/testing/dart/vm_service',
  // run_tests.py's smoke test (fail_test.dart), the same shape.
  'engine/src/flutter/testing/smoke_test_failure',
  // The Linux embeddings' system libraries: GN's foreach over pkg_config()
  // templates, each an exec_script of pkg-config against the sysroot, whose
  // answers the file holds.
  'engine/src/flutter/shell/platform/linux/config',
  // The Android shell, until its file converts: one header the converted
  // sub-packages include.
  'engine/src/flutter/shell/platform/android',
  'engine/src/flutter/third_party',
};

/// The main repository's layout: its packages are the generated ones and
/// [handWrittenPackages], so that a file of another package (a font under
/// //flutter/txt as a fixture of display_list) is labelled through it.
final OutputLayout mainRepositoryLayout = OutputLayout.main(
  packages: <String>{
    for (final ConvertedFile file in convertedFiles) 'engine/src/${file.gnPackage.substring(2)}',
    ...handWrittenPackages,
  },
);
