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
''',
  ),
  ConvertedFile(
    '//flutter/fml',
    skip: <String, String>{'fml_benchmarks': 'needs //flutter/benchmarking'},
  ),
  ConvertedFile(
    '//flutter/testing',
    skip: <String, String>{
      'dart': 'needs //flutter/runtime',
      'vmservice_kernel': 'dart_snapshot_kernel template',
      'vmservice_snapshot': 'dart_snapshot_aot template',
      'fixture_test': 'needs //flutter/runtime',
      'vulkan': 'needs //flutter/vulkan',
      'test_swiftshader_utils': 'needs //flutter/third_party/swiftshader',
      'test_swangle_utils': 'needs //flutter/third_party/angle',
      'opengl': 'needs //flutter/third_party/angle',
    },
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

exports_files(["fixtures_location.cc"])

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
  ConvertedFile(
    '//flutter/impeller',
    skip: <String, String>{
      'impeller_unittesting': 'needs //flutter/impeller/testing',
      'impeller_unittests': 'needs the Impeller test suites',
      'impeller_dart_unittests': 'needs //flutter/impeller/renderer',
    },
    // The shader and image fixtures under fixtures/ are read by the suites
    // of other packages (impeller/compiler's) until impeller/fixtures/BUILD.gn
    // converts and the directory becomes a package of its own.
    appendix: '''
exports_files(glob(["fixtures/*"]))
''',
  ),
  ConvertedFile(
    '//flutter/impeller/base',
    // GN links base_unittests (a source_set of suites) into the one
    // impeller_unittests binary of //flutter/impeller, which needs every
    // Impeller suite; until those exist, the suite runs on its own with
    // the engine's gtest main and an empty fixtures library (the binary's
    // compiled-in paths; GN's come from //flutter/impeller/fixtures).
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "impeller_base_fixtures")

cc_test(
    name = "impeller_base_unittests",
    deps = [
        ":base_unittests",
        ":impeller_base_fixtures",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/impeller/geometry',
    skip: <String, String>{'geometry_benchmarks': 'needs //flutter/impeller/entity'},
    // As for //flutter/impeller/base: the suite runs on its own until
    // impeller_unittests has all of them.
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "impeller_geometry_fixtures")

cc_test(
    name = "impeller_geometry_unittests",
    deps = [
        ":geometry_unittests",
        ":impeller_geometry_fixtures",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/display_list',
    skip: <String, String>{
      'display_list_builder_benchmarks': 'needs //flutter/benchmarking',
      'display_list_region_benchmarks': 'needs //flutter/benchmarking',
      'display_list_transform_benchmarks': 'needs //flutter/benchmarking',
      'display_list_benchmarks_source': 'needs //flutter/benchmarking',
      'display_list_benchmarks': 'needs display_list_benchmarks_source',
      'primitive_rendering_benchmarks': 'needs display_list_benchmarks_source',
    },
  ),
  // The shader compiler, impellerc, and what it needs of Impeller
  // (research/08, step 3).
  ConvertedFile(
    '//flutter/impeller/core',
    // As for //flutter/impeller/base: the suite runs on its own until
    // GN's impeller_unittests converts.
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "impeller_core_fixtures")

cc_test(
    name = "impeller_core_unittests",
    deps = [
        ":allocator_unittests",
        ":impeller_core_fixtures",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/impeller/runtime_stage',
    skip: <String, String>{'runtime_stage_unittests': 'needs //flutter/impeller/playground'},
  ),
  ConvertedFile('//flutter/impeller/shader_bundle'),
  ConvertedFile(
    '//flutter/impeller/compiler',
    // The compiler's suite on its own, as for //flutter/impeller/base, with
    // the shader fixtures it reads from //flutter/impeller/fixtures (GN's
    // file_fixtures there, minus the images, fonts and generated runtime
    // stages the other suites use; the tests write their intermediates next
    // to them). The list goes when impeller/fixtures/BUILD.gn converts.
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(
    name = "impeller_compiler_fixtures",
    fixtures = ["//engine/src/flutter/impeller:fixtures/" + f for f in [
        "array_assignment.frag",
        "array_initialization_without_initializer.frag",
        "array_initializer_with_constants.frag",
        "array_initializer_with_variables.frag",
        "check_gles_definition.frag",
        "check_gles_unflipped_definition.frag",
        "flutter_gpu_instanced.frag",
        "flutter_gpu_instanced.vert",
        "flutter_gpu_texture.frag",
        "flutter_gpu_texture.vert",
        "flutter_gpu_unlit.frag",
        "flutter_gpu_unlit.vert",
        "mat2_test.frag",
        "multiple_stages.hlsl",
        "resources_limit.vert",
        "sa%m#ple.vert",
        "sample.comp",
        "sample.frag",
        "sample.vert",
        "sample_with_binding.vert",
        "sample_with_positioned_uniforms.frag",
        "sample_with_uniforms.frag",
        "simple.vert.hlsl",
        "stage1.comp",
        "stage2.comp",
        "struct_def_bug.vert",
        "struct_internal.frag",
        "test_texture.frag",
        "texture_lookup.frag",
        "types.h",
        "y_flip_early_return.vert",
    ]],
)

cc_test(
    name = "impeller_compiler_unittests",
    deps = [
        ":compiler_unittests",
        ":impeller_compiler_fixtures",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  ConvertedFile('//flutter/impeller/compiler/shader_lib'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib/flutter'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib/impeller'),
  // The shader pipeline's users (research/08, step 4): impeller_shaders()
  // invocations become the macro in build/bazel/impeller.
  ConvertedFile(
    '//flutter/impeller/shader_archive',
    // The suite on its own, as for //flutter/impeller/base.
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "impeller_shader_archive_fixtures")

cc_test(
    name = "impeller_shader_archive_unittests",
    deps = [
        ":impeller_shader_archive_fixtures",
        ":shader_archive_unittests",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/impeller/tessellator',
    skip: <String, String>{'tessellator_unittests': 'needs //flutter/impeller/playground'},
  ),
  ConvertedFile(
    '//flutter/impeller/renderer',
    skip: <String, String>{
      'renderer_unittests': 'needs //flutter/impeller/playground',
      'renderer_unittests_golden': 'needs //flutter/impeller/playground',
      'renderer_dart_unittests': 'needs //flutter/lib/gpu',
    },
  ),
  // The gmock doubles of the renderer's interfaces, which the core and
  // other suites test against.
  ConvertedFile('//flutter/impeller/renderer/testing'),
  ConvertedFile(
    '//flutter/impeller/typographer',
    skip: <String, String>{'typographer_unittests': 'needs //flutter/impeller/playground'},
  ),
  ConvertedFile(
    '//flutter/impeller/entity',
    skip: <String, String>{
      'entity_test_helpers': 'needs //flutter/impeller/playground',
      'entity_unittests': 'needs //flutter/impeller/playground',
    },
  ),
  // The display_list_unittests chain (research/08, step 5): the text stack
  // and Impeller's display list.
  ConvertedFile('//flutter/impeller/typographer/backends/skia'),
  ConvertedFile(
    '//flutter/impeller/display_list',
    skip: <String, String>{
      'display_list_unittests': 'needs //flutter/impeller/playground',
      'display_list_unittests_golden': 'needs //flutter/impeller/playground',
      'aiks_playground': 'needs //flutter/impeller/playground',
      'aiks_unittests': 'needs //flutter/impeller/playground',
      'aiks_unittests_golden': 'needs //flutter/impeller/playground',
    },
    // The skia_conversions suite on its own, as for //flutter/impeller/base.
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "impeller_skia_conversions_fixtures")

cc_test(
    name = "impeller_skia_conversions_unittests",
    deps = [
        ":impeller_skia_conversions_fixtures",
        ":skia_conversions_unittests",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  // The desktop embeddings' shared code, as far as it reaches today: the
  // public headers, the input model, the isolate scope, the engine
  // switches and the core (path utilities, windowing), with the core's
  // tests -- the first converted test to link the Dart VM from the wrap.
  ConvertedFile('//flutter/shell/geometry'),
  ConvertedFile(
    '//flutter/shell/platform/common',
    skip: <String, String>{
      'common_cpp_accessibility': 'needs //flutter/third_party/accessibility and the embedder',
      'common_cpp': 'needs the embedder, the client wrapper and rapidjson',
      'common_cpp_fixtures': 'with common_cpp_unittests',
      'common_cpp_unittests': 'needs :common_cpp',
    },
  ),
  // txt_unittests' embedded test font. The rest of the file is the Dart
  // runtime glue, which needs tonic, lib/snapshot and the shell.
  ConvertedFile(
    '//flutter/runtime',
    skip: <String, String>{
      'libdart': 'needs //flutter/lib/snapshot',
      'runtime_fixtures': 'Dart fixtures (dart_main) are not supported yet',
      'runtime_unittests': 'needs :runtime',
      'no_plugin_registrant': 'Dart fixtures (dart_main) are not supported yet',
      'no_dart_plugin_registrant_unittests': 'needs //flutter/lib/snapshot',
      'plugin_registrant': 'Dart fixtures (dart_main) are not supported yet',
      'dart_plugin_registrant_unittests': 'needs //flutter/lib/snapshot',
    },
  ),
  ConvertedFile(
    '//flutter/txt',
    skip: <String, String>{'txt_benchmarks': 'needs //flutter/third_party/benchmark'},
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
  // //flutter/flow need); their test suites wait on impeller/playground.
  ConvertedFile(
    '//flutter/impeller/renderer/backend/gles',
    skip: <String, String>{
      'mock_gles': 'with gles_unittests',
      'gles_unittests': 'needs //flutter/impeller/playground:playground_test',
    },
  ),
  ConvertedFile(
    '//flutter/impeller/renderer/backend/vulkan',
    skip: <String, String>{
      'mock_vulkan': 'with vulkan_unittests (it includes a SwiftShader header the GN never names)',
      'vulkan_unittests': 'needs //flutter/impeller/playground:playground_test',
    },
  ),
  ConvertedFile('//flutter/impeller/renderer/backend'),
  ConvertedFile('//flutter/flow'),
  // The Dart bindings library (engine-owned third_party), on the way to
  // lib/ui and runtime; its tests need the Dart snapshot and libdart.
  ConvertedFile('//flutter/third_party/tonic'),
  // dart:ui's bindings as a library; its suites and benchmarks need the
  // Dart snapshot (//flutter/lib/snapshot), libdart and the shell's test
  // fixtures.
  ConvertedFile(
    '//flutter/lib/ui',
    skip: <String, String>{
      'ui_unittests_fixtures': 'Dart fixtures (dart_main) are not supported yet',
      'ui_benchmarks': 'needs //flutter/lib/snapshot and //flutter/benchmarking',
      'ui_unittests': 'needs //flutter/lib/snapshot and the shell test fixtures',
      'display_list_deferred_image_unittests': 'with ui_unittests',
      'ui_testing_mocks': 'with ui_unittests',
    },
  ),
  ConvertedFile('//flutter/lib/io'),
  ConvertedFile('//flutter/vulkan'),
  // The GPU surfaces; the suite needs //flutter/testing:vulkan, SwiftShader
  // and the Dart runtime, and its executable the Impeller fixtures.
  ConvertedFile(
    '//flutter/shell/gpu',
    skip: <String, String>{
      'gpu_surface_vulkan_unittests':
          'needs //flutter/testing:vulkan, //flutter/third_party/swiftshader and the Dart runtime',
      'gpu_surface_unittests':
          'needs //flutter/impeller/fixtures and :gpu_surface_vulkan_unittests',
    },
  ),
  // The sampling profiler; GN links its suite into shell_unittests, which
  // waits on the Dart snapshot, so it runs on its own meanwhile.
  ConvertedFile(
    '//flutter/shell/profiling',
    appendix: '''
load("@rules_cc//cc:defs.bzl", "cc_test")
load("//engine/src/flutter/testing:testing.bzl", "flutter_test_fixtures")

flutter_test_fixtures(name = "shell_profiling_fixtures")

# The profiler calls the Dart API (Dart_SetThreadName); GN's shell_unittests
# links libdart, so this binary does too.
cc_test(
    name = "shell_profiling_unittests",
    deps = [
        ":profiling_unittests",
        ":shell_profiling_fixtures",
        "//engine/src/flutter/build/bazel/dart_wrap:libdart_jit",
        "//engine/src/flutter/testing",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/lib/gpu',
    skip: <String, String>{
      'gpu_unittests_fixtures': 'with gpu_unittests',
      'gpu_unittests': 'needs //flutter/testing:dart (the Dart runtime)',
    },
  ),
  // The shell proper needs the Dart runtime glue (lib/ui, runtime, tonic)
  // and the GPU surfaces; what converts now is what //flutter/common/graphics
  // and the shell's own small libraries need.
  ConvertedFile(
    '//flutter/shell/common',
    skip: <String, String>{
      'shell_unittests_gpu_configuration': 'needs //flutter/shell/gpu',
      'shell_unittests_fixtures': 'Dart fixtures (dart_main) are not supported yet',
      'shell_benchmarks': 'needs :common and //flutter/benchmarking',
      'shell_test_fixture_sources': 'needs :common',
      'shell_unittests': 'needs :common',
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
      '@skia//modules/skparagraph:skparagraph_headers',
    ],
    appendix: '''
cc_library(
    name = "skparagraph_headers",
    hdrs = glob(["**/*.h"]),
    include_prefix = "third_party/skia/modules/skparagraph",
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
const Set<String> handWrittenPackages = <String>{
  'engine/src',
  'engine/src/flutter',
  'engine/src/flutter/impeller/tools',
  'engine/src/flutter/lib/snapshot',
  'engine/src/flutter/shell/platform/embedder',
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
