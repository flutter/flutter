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
    appendix: '''
exports_files(["fixtures_location.cc"])
''',
  ),
  ConvertedFile(
    '//flutter/impeller',
    skip: <String, String>{
      'impeller': 'needs //flutter/impeller/{entity,renderer,display_list}',
      'impeller_unittesting': 'needs //flutter/impeller/testing',
      'impeller_unittests': 'needs the Impeller test suites',
      'impeller_dart_unittests': 'needs //flutter/impeller/renderer',
    },
  ),
  ConvertedFile(
    '//flutter/impeller/base',
    skip: <String, String>{'base_unittests': 'needs //flutter/testing:testing_lib'},
  ),
  ConvertedFile(
    '//flutter/impeller/geometry',
    skip: <String, String>{
      'geometry_asserts': 'needs //flutter/testing:testing_lib',
      'geometry_unittests': 'needs //flutter/display_list/testing',
      'geometry_benchmarks': 'needs //flutter/impeller/entity',
    },
  ),
  ConvertedFile(
    '//flutter/display_list',
    skip: <String, String>{
      'display_list_fixtures': 'fixture in //flutter/txt/third_party/fonts, which has no package',
      'display_list_unittests': 'needs //flutter/display_list/testing',
      'display_list_rendertests': 'needs //flutter/display_list/testing',
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
    skip: <String, String>{'allocator_unittests': 'needs //flutter/testing:testing_lib'},
  ),
  ConvertedFile(
    '//flutter/impeller/runtime_stage',
    skip: <String, String>{'runtime_stage_unittests': 'needs //flutter/impeller/playground'},
  ),
  ConvertedFile('//flutter/impeller/shader_bundle'),
  ConvertedFile(
    '//flutter/impeller/compiler',
    skip: <String, String>{'compiler_unittests': 'needs //flutter/testing:testing_lib'},
  ),
  ConvertedFile('//flutter/impeller/compiler/shader_lib'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib/flutter'),
  ConvertedFile('//flutter/impeller/compiler/shader_lib/impeller'),
  // The shader pipeline's users (research/08, step 4): impeller_shaders()
  // invocations become the macro in build/bazel/impeller.
  ConvertedFile(
    '//flutter/impeller/shader_archive',
    skip: <String, String>{'shader_archive_unittests': 'needs //flutter/testing:testing_lib'},
  ),
  ConvertedFile(
    '//flutter/impeller/tessellator',
    skip: <String, String>{
      'tessellator_shared': 'shared_library() is not converted yet',
      'tessellator_unittests': 'needs //flutter/impeller/playground',
    },
  ),
  ConvertedFile(
    '//flutter/impeller/renderer',
    skip: <String, String>{
      'renderer_unittests': 'needs //flutter/impeller/playground',
      'renderer_unittests_golden': 'needs //flutter/impeller/playground',
      'renderer_dart_unittests': 'needs //flutter/lib/gpu',
    },
  ),
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
    // build has it as a textual header, which the lists leave out).
    appendix: '''
cc_library(
    name = "skcms_headers",
    hdrs = glob(["**/*.h"]),
    include_prefix = "third_party/skia",
)
''',
  ),
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
