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
/// itself (`synced_repository` in build_defs/repositories/repositories.bzl) and are not
/// checked in; they are listed for what they need.
library;

import 'bazel_mapping.dart';
import 'gn_eval.dart';
import 'mirrored_lists.dart';

/// One generated file.
final class ConvertedFile {
  const ConvertedFile(
    this.gnPackage, {
    this.skip = const <String, String>{},
    this.appendix,
    this.implicitDeps = const <String>[],
    this.condition,
    this.unconvertedDeps = const <String>[],
    this.filesGroups = const <String>{},
    this.assume = const <String, GnValue>{},
    this.targetConditions = const <String, String>{},
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

  /// The GN variable under which GN reaches the file at all, when no `if`
  /// of the file's own says so: impeller's Android toolkit, which only an
  /// `if (is_android)` dependency names. The file is evaluated as if inside
  /// that block, so its targets are incompatible elsewhere and a wildcard
  /// build of the tree skips them.
  final String? condition;

  /// GN labels (`//dir:name`) the file's groups depend on that have no Bazel
  /// counterpart yet -- targets of files not converted, or skipped in theirs
  /// -- left out of the generated groups and listed in the file's header. A
  /// group stands for what the build reaches, so a member missing is a gap
  /// on record, where a library's missing dependency would be a broken
  /// build; the converter rejects an entry nothing depends on, so the list
  /// shrinks with the migration.
  final List<String> unconvertedDeps;

  /// The file's groups that are groups of things to build, which nothing
  /// links against -- the root group `flutter` (GN's default target), the
  /// `unittests` group, and the groups between the root and the platform
  /// shells -- which become filegroups, and which a C++ target that lists
  /// one carries as data. Any other group is a cc_library forwarding its
  /// dependencies to link, as GN's groups do, with its actions and copies
  /// as sources and data.
  final Set<String> filesGroups;

  /// Assumptions for this file over the generation's (gn_eval's
  /// Assumptions.withValues): a platform whose branches of the file are
  /// deferred -- `is_mac` false where the macOS branch is a product of the
  /// Apple phase's (the entitlements lists, the dylib) that the macOS port
  /// has not reached, so that the file keeps converting for the others.
  final Map<String, GnValue> assume;

  /// The GN variable under which a target of the file is reached at all,
  /// when neither the file nor the target's block says so (as [condition]
  /// is for a whole file): shell/platform/common's accessibility bridge,
  /// defined outright but named only by the macOS and Windows shells and
  /// compiling for them alone. The target is evaluated as if inside
  /// `if (variable)`, so it is incompatible elsewhere.
  final Map<String, String> targetConditions;
}

/// The macOS branches of a file deferred to the Apple products' phase
/// (research/20, M4): evaluated as if `is_mac` were false, as before the
/// macOS port, so the file's Linux targets stay what they were.
const Map<String, GnValue> macosDeferred = <String, GnValue>{'is_mac': GnBoolValue(false)};

const List<ConvertedFile> convertedFiles = <ConvertedFile>[
  // The root: GN's default target `flutter` (what `ninja` with no target
  // builds, and the builders' `flutter` ninja target) and the `unittests`,
  // `archives` and `dist` groups, over what is converted; the deps with no
  // Bazel counterpart yet are on record below. The configs and everything
  // else the hand-written file had are the appendix.
  ConvertedFile(
    '//flutter',
    skip: <String, String>{
      'config': 'hand-written in the appendix (an include root above the package)',
      'export_dynamic_symbols': 'hand-written in the appendix (linker inputs)',
      'export_dynamic_test_symbols': 'hand-written in the appendix (linker inputs)',
    },
    filesGroups: <String>{'flutter', 'unittests', 'archives', 'dist'},
    unconvertedDeps: <String>[
      // The Dart SDK copy (copy_tree) and the Dart test fixtures.
      '//flutter/build/dart:dart_sdk',
      '//flutter/build/dart/test:gen_dartcli_call',
      '//flutter/build/dart/test:gen_executable_call',
      // Suites not converted in their files: Flutter GPU's (skipped in its
      // file: it crashes identically under GN and run_tests.py never runs
      // it), and the two Android APKs (GN's native_activity_apk; the
      // Android test phase -- their executables convert).
      '//flutter/lib/gpu:gpu_unittests',
      '//flutter/impeller/renderer/backend/vulkan:vulkan_android_apk_unittests',
      '//flutter/impeller/toolkit/android:apk_unittests',
      // The darwin frameworks' suites, skipped in their file (the Apple
      // test phase: XCTest, OCMock and the Testing framework from the
      // platform's Developer directory).
      '//flutter/shell/platform/darwin/common:framework_common_unittests',
      '//flutter/shell/platform/darwin/common:framework_common_swift_unittests',
      '//flutter/shell/platform/darwin/macos:flutter_desktop_darwin_unittests',
      '//flutter/shell/platform/darwin/macos:flutter_desktop_darwin_swift_unittests',
    ],
    appendix: r'''
load("@rules_cc//cc:defs.bzl", "cc_library")
load("//build_defs/testing:checkout_script_test.bzl", "checkout_script_test")
load("//build_defs/dist:local_engine.bzl", "local_engine")

# config("config"), config("export_dynamic_symbols") and
# config("export_dynamic_test_symbols") of BUILD.gn, by hand: the first is the
# two include roots engine code is written against (engine/src and this
# directory), which the converter's `includes` cannot say for a directory
# above the package; the other two carry linker inputs that the converter's
# configs do not yet. Every engine library depends on :config.

# config("config") in BUILD.gn: the two include roots engine code is written
# against -- engine/src ("flutter/fml/...") and this directory
# ("impeller/...", "fml/..."). Every engine library depends on it; the
# accompanying -Wunreachable-code is in FLUTTER_COPTS (build_defs/cc/copts.bzl),
# since compiler flags do not propagate through dependencies.
cc_library(
    name = "config",
    includes = ["."],
    visibility = ["//visibility:public"],
    deps = ["//engine/src:include_root"],
)

# The engine's Dart package configuration, which `gclient sync` writes (the
# pub_get_offline hook) and GN's Dart compiles read (--packages). What the
# frontend server resolves `package:` imports through; the fixtures compiled
# so far import none, so nothing it points at is declared.
filegroup(
    name = "package_config",
    srcs = [".dart_tool/package_config.json"],
    visibility = ["//visibility:public"],
)

# config("export_dynamic_symbols") in BUILD.gn: the symbols a test binary
# keeps in its dynamic symbol table, for the Dart VM to resolve at runtime
# (the snapshot symbols, dart:ffi's lookups). GNU --dynamic-list on ELF, the
# macOS linker's exported symbols list on a Mac; the files are
# //flutter/common's.
cc_library(
    name = "export_dynamic_symbols",
    additional_linker_inputs = select({
        "@platforms//os:macos": ["//engine/src/flutter/common:exported_symbols_mac.sym"],
        "//conditions:default": ["//engine/src/flutter/common:exported_symbols.sym"],
    }),
    linkopts = select({
        "@platforms//os:macos": [
            "-Xlinker",
            "-exported_symbols_list",
            "-Xlinker",
            "$(execpath //engine/src/flutter/common:exported_symbols_mac.sym)",
        ],
        "//conditions:default": [
            "-Wl,--dynamic-list=$(execpath //engine/src/flutter/common:exported_symbols.sym)",
        ],
    }),
    visibility = ["//visibility:public"],
)

# config("export_dynamic_test_symbols") in BUILD.gn: the list above plus the
# symbol flutter_tester exposes to its Dart tests.
cc_library(
    name = "export_dynamic_test_symbols",
    additional_linker_inputs = select({
        "@platforms//os:macos": ["//engine/src/flutter/common:exported_test_symbols_mac.sym"],
        "//conditions:default": ["//engine/src/flutter/common:exported_test_symbols.sym"],
    }),
    linkopts = select({
        "@platforms//os:macos": [
            "-Xlinker",
            "-exported_symbols_list",
            "-Xlinker",
            "$(execpath //engine/src/flutter/common:exported_test_symbols_mac.sym)",
        ],
        "//conditions:default": [
            "-Wl,--dynamic-list=$(execpath //engine/src/flutter/common:exported_test_symbols.sym)",
        ],
    }),
    visibility = ["//visibility:public"],
)

# What the tests of the engine's Dart tools read from directories of this
# package (testing/run_tests.py --type dart-host; the tests themselves are
# dart_package_test targets in the packages' own directories, see the suite
# below): .ci.yaml (engine_build_configs, engine_tool; the builder
# configurations are //engine/src/flutter/ci's) and bin/et (engine_tool's
# entry-point test). The web engine's sources are //engine/src/flutter/lib/web_ui's;
# its tests' Skia Gold client reads the release version file.
exports_files([
    ".ci.yaml",
    ".engine-release.version",
])

# The embedder examples' directory, which flutter_tools' create_test creates a
# project in (the SDK facsimile its tests run from needs the directory to
# exist; packages/flutter_tools/BUILD.bazel).
exports_files(["examples/glfw/README.md"])

filegroup(
    name = "et_entry_points",
    srcs = glob(["bin/et*"]),
    visibility = ["//visibility:public"],
)

# The scripts of tools/ that actions of other packages run (the Android
# embedding's: shell/platform/android/BUILD.gn's gen_android_build_config_java
# and check_imports). A script of a package's own directory needs no export.
exports_files([
    "tools/android_illegal_imports.py",
    "tools/androidx/files.json",
    "tools/androidx/generate_pom_file.py",
    "tools/gen_android_buildconfig.py",
    "tools/javadoc/android_reference",
    "tools/javadoc/gen_javadoc.py",
])

# ci/host_debug_unopt's "Tests of tools/gn" (linux_unopt.json): `python3
# flutter/tools/gn_test.py`, the unit tests of tools/gn -- its argument
# parsing and the GN arguments it writes -- run from tools/ as the step runs
# them (the script loads `gn` from its own directory). In the checkout
# itself: to_gn_args() asks git for the engine's, Skia's and Dart's
# revisions and runs the content-aware hash, which no view has. tools/ has
# no package of its own: the root package's files, a test of this file.
checkout_script_test(
    name = "gn_test",
    srcs = [
        "tools/gn",
        "tools/gn_test.py",
    ],
    # tools/gn looks the Apple SDKs up under prebuilts/SDKs unless it runs
    # on a LUCI bot, where the step runs; a Linux checkout has none.
    env = {"LUCI_CONTEXT": "bazel"},
    in_checkout = True,
    script = "tools/gn_test.py",
)

# run_tests.py --type dart-host: `dart test` in each Dart package of
# build_dart_host_test_list, as dart_package_test runs it
# (build_defs/dart/package_test.bzl). Thirteen packages there, eleven here:
# ci's tests format files they write into the checkout and add to the git
# index (format_test.dart), and clang_tidy's read a GN build directory's
# compile_commands.json; both run with `dart test` in the checkout, not from
# a build (ci/BUILD.bazel and tools/clang_tidy/BUILD.bazel say so).
test_suite(
    name = "dart_host_tests",
    tests = [
        "//engine/src/flutter/flutter_frontend_server:tests",
        "//engine/src/flutter/testing/skia_gold_client:tests",
        "//engine/src/flutter/tools/api_check:tests",
        "//engine/src/flutter/tools/bazel_tools:tests",
        "//engine/src/flutter/tools/build_bucket_golden_scraper:tests",
        "//engine/src/flutter/tools/engine_tool:tests",
        "//engine/src/flutter/tools/githooks:tests",
        "//engine/src/flutter/tools/header_guard_check:tests",
        "//engine/src/flutter/tools/pkg/engine_build_configs:tests",
        "//engine/src/flutter/tools/pkg/engine_repo_tools:tests",
        "//engine/src/flutter/tools/pkg/git_repo_tools:tests",
    ],
)

# run_tests.py --type benchmarks (run_engine_benchmarks; CI's host_release_test
# alone asks for it): the six benchmark executables it runs, each with ICU's
# data file (the converter's benchmarkRuns). They are tests tagged `manual`,
# as is this suite, so a wildcard run leaves them out as every other builder
# does; `bazel test //engine/src/flutter:benchmarks` is the type -- less its
# Dart test (run_benchmark_tests: testing/benchmark/test/parse_and_send_test
# .dart), which reads the checkout's git log and stays with `dart` there.
test_suite(
    name = "benchmarks",
    tags = ["manual"],
    tests = [
        "//engine/src/flutter/display_list:display_list_builder_benchmarks",
        "//engine/src/flutter/fml:fml_benchmarks",
        "//engine/src/flutter/impeller/geometry:geometry_benchmarks",
        "//engine/src/flutter/lib/ui:ui_benchmarks",
        "//engine/src/flutter/shell/common:shell_benchmarks",
        "//engine/src/flutter/txt:txt_benchmarks",
    ],
)

# The benchmark executables host_release_test builds (its target list): the
# six above and the four nobody runs. Through this filegroup a wildcard build
# compiles them all, as GN's does, manual tags notwithstanding.
filegroup(
    name = "benchmark_binaries",
    testonly = True,
    srcs = [
        "//engine/src/flutter/display_list:display_list_benchmarks",
        "//engine/src/flutter/display_list:display_list_builder_benchmarks",
        "//engine/src/flutter/display_list:display_list_region_benchmarks",
        "//engine/src/flutter/display_list:display_list_transform_benchmarks",
        "//engine/src/flutter/display_list:primitive_rendering_benchmarks",
        "//engine/src/flutter/fml:fml_benchmarks",
        "//engine/src/flutter/impeller/geometry:geometry_benchmarks",
        "//engine/src/flutter/lib/ui:ui_benchmarks",
        "//engine/src/flutter/shell/common:shell_benchmarks",
        "//engine/src/flutter/txt:txt_benchmarks",
    ],
)

# What the flutter tool reads from a developer's build, where Bazel built
# it: `local_engine` writes local_engine.json beside the files
# (build_defs/dist/local_engine.bzl; NEED_DECISION D15), a map from each
# GN path the tool reads to Bazel's file, and `--local-engine` /
# `--local-engine-host` take the directory holding it -- the Gradle plugin
# and the desktop CMake re-entry included. For a Linux host build:
# flutter_tester, gen_snapshot, icudtl.dat, impellerc and its libraries,
# font-subset, the GTK library and headers, the Dart SDK, the patched SDK,
# the core snapshot under gen/flutter/lib/snapshot/, the frontend server
# under gen/, the sky_engine package under gen/dart-pkg/ (assembled as one
# directory, as package:sky_engine's root, and so is impellerc's
# shader_lib, which the tool passes whole as --include), the embedder
# library with its header. For an Android build (the developer's android_*
# configurations, whose GN build is ninja's default target -- the root group
# `flutter`, which engine/src's //:default depends on): what that group
# lays -- libflutter.so and its lib.stripped/ copy, the host gen_snapshot
# under clang_x64/, the embedding's jars and poms (which the Gradle plugin
# resolves through the manifest), the Android archives and the javadoc under
# zip_archives/, ICU's data file for the target. The Maven tree and the
# dist archives are the builders' targets, not the default's, as under GN.
# A cross build's directory is named after its platform
# (bazel-out/android_arm64-opt/; the root .bazelrc's
# --experimental_platform_in_output_dir), so that it and the host build it
# pairs with are both on disk:
#
#   bazel build //engine/src/flutter:local_engine
#   flutter test --local-engine=$PWD/engine/src/out/bazel-bin/engine/src/flutter \
#       --local-engine-host=$PWD/engine/src/out/bazel-bin/engine/src/flutter
#   bazel build --config=android_debug_arm64 //engine/src/flutter:local_engine
#   bazel build --config=host_debug //engine/src/flutter:local_engine
#   flutter build apk --local-engine=$PWD/engine/src/out/bazel-out/android_arm64-opt/bin/engine/src/flutter \
#       --local-engine-host=$PWD/engine/src/out/bazel-out/k8-opt/bin/engine/src/flutter
#
# Not here: GN's own bookkeeping -- args.gn (nothing in the tree reads it:
# testing/run_tests.py defines an is_asan() over it that nothing calls; a
# GN marker in a Bazel tree would only mislead gn and ninja),
# compile_commands.json (tools/gn_to_bazel/tool/compile_commands.py writes
# it on demand, `et lint --backend bazel` runs that) and ninja's .d files.
# The web SDK is the wasm builds' (ci/builders:wasm_release and the rest),
# not the host build directory's, as under GN. The builders' own targets --
# what each CI build of ci/builders/{linux,mac}_*.json builds, into its
# --target-dir, under its `--config` (an `install` into GN's layout, which
# the recipes read) -- are generated into ci/builders/BUILD.bazel.
local_engine(
    name = "local_engine",
    # The root group is testonly (GN's `testonly = true`).
    testonly = True,
    # The host build's assembled directories; an Android build has neither
    # (its contents are the root group's).
    assemble = select({
        "@platforms//os:android": [],
        "//conditions:default": [
            "gen/dart-pkg/sky_engine",
            "shader_lib",
        ],
    }),
    # The targets that place their own files (BuildDirectoryInfo).
    contents = select({
        # GN's default target is the root group `flutter` (engine/src's
        # //:default depends on //flutter alone): the Android shell with its
        # jars and archives, the host gen_snapshot, the snapshots, the
        # Impeller SDK, the embedder archive. The Maven tree and the dist
        # archives are not in it; the builders name them as targets.
        "@platforms//os:android": [":flutter"],
        # The sky_engine package (gen/dart-pkg/sky_engine): the targets of
        # sky/packages/sky_engine place their own files (BuildDirectoryInfo).
        # impellerc's GLSL library, which GN's shader_lib group copies beside
        # the compiler (shader_lib/flutter/runtime_effect.glsl,
        # shader_lib/impeller/*.glsl): the flutter tool hands the directory to
        # impellerc as --include when it compiles a package's shaders.
        "//conditions:default": [
            "//engine/src/flutter/impeller/compiler/shader_lib/flutter",
            "//engine/src/flutter/impeller/compiler/shader_lib/impeller",
            "//engine/src/flutter/sky/packages/sky_engine",
        ],
    }),
    # The files by the directory that holds them, under the build root.
    files = select({
        # copy("copy_icudata"): ICU's data file for the target at the build
        # root (android/icudtl.dat; @icu's filegroup selects it), as GN's
        # icudata group lays it.
        "@platforms//os:android": {"@icu//:icudata": ""},
        "//conditions:default": {
            "//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot": "",
            "//engine/src/flutter/flutter_frontend_server:frontend_server": "gen",
            "//engine/src/flutter/impeller/compiler:impellerc": "",
            "//engine/src/flutter/impeller/tessellator:libtessellator.so": "",
            "//engine/src/flutter/lib/snapshot:flutter_patched_sdk/platform_strong.dill": "flutter_patched_sdk",
            "//engine/src/flutter/lib/snapshot:flutter_patched_sdk/vm_outline_strong.dill": "flutter_patched_sdk",
            "//engine/src/flutter/lib/snapshot:isolate_snapshot.bin": "gen/flutter/lib/snapshot",
            "//engine/src/flutter/lib/snapshot:isolate_snapshot_instructions.bin": "gen/flutter/lib/snapshot",
            "//engine/src/flutter/lib/snapshot:vm_isolate_snapshot.bin": "gen/flutter/lib/snapshot",
            "//engine/src/flutter/lib/snapshot:vm_snapshot_instructions.bin": "gen/flutter/lib/snapshot",
            "//engine/src/flutter/shell/platform/embedder:copy_headers": "",
            "//engine/src/flutter/shell/platform/embedder:libflutter_engine.so": "",
            "//engine/src/flutter/shell/platform/linux:flutter_linux_gtk": "",
            "//engine/src/flutter/shell/testing:flutter_tester": "",
            "//engine/src/flutter/tools/font_subset:font-subset": "",
            "//engine/src/flutter/tools/path_ops:libpath_ops.so": "",
            # copy("copy_icudata"): the full data file, where artifacts.zip
            # carries the trimmed flutter/icudtl.dat.
            "@icu//:icudata": "",
        },
    }),
    # The trees: the Dart SDK and the GTK headers, at their paths.
    trees = select({
        "@platforms//os:android": [],
        "//conditions:default": [
            "//engine/src/flutter/build/archives:dart_sdk_archive_dart-sdk",
            "//engine/src/flutter/shell/platform/linux:flutter_gtk_publish_headers_linux",
        ],
    }),
)
''',
  ),
  // GN's config("flutter_config") is feature_defines_list, which copts.bzl
  // keeps as FLUTTER_FEATURE_DEFINES over the flags below: the Bazel side
  // of config.gni's arguments, which no GN file declares as targets.
  ConvertedFile(
    '//flutter/common',
    appendix: r'''
load("@bazel_skylib//lib:selects.bzl", "selects")
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

# The complements, for `flutter_runtime_mode != "<mode>"` inside a
# conjunction (the Android archives' directory, zip_bundle.gni's
# android_zip_archive_dir): any of the other three.
[
    selects.config_setting_group(
        name = "not_runtime_mode_" + mode,
        match_any = [
            ":runtime_mode_" + other
            for other in [
                "debug",
                "profile",
                "release",
                "jit_release",
            ]
            if other != mode
        ],
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

# GN's enable_backtrace, as tools/gn sets it (--backtrace, which every
# builder leaves on): the host's own build or a desktop target -- Linux,
# macOS, Windows -- and iOS in debug mode; off elsewhere, which is where
# fml compiles backtrace_stub.cc.
selects.config_setting_group(
    name = "backtrace_enabled",
    match_any = [
        "@platforms//os:linux",
        "@platforms//os:macos",
        "@platforms//os:windows",
        ":ios_debug",
    ],
)

selects.config_setting_group(
    name = "ios_debug",
    match_all = [
        "@platforms//os:ios",
        ":runtime_mode_debug",
    ],
)

# Its complement, for the denied term of a disjunction (fml's
# `!enable_backtrace || is_wasm`, the stub's branch).
selects.config_setting_group(
    name = "backtrace_disabled",
    match_any = [
        "@platforms//os:android",
        "@platforms//os:emscripten",
        "@platforms//os:fuchsia",
        "@platforms//os:qnx",
        ":ios_not_debug",
    ],
)

selects.config_setting_group(
    name = "ios_not_debug",
    match_all = [
        "@platforms//os:ios",
        ":runtime_mode_not_debug",
    ],
)

selects.config_setting_group(
    name = "runtime_mode_not_debug",
    match_any = [
        ":runtime_mode_jit_release",
        ":runtime_mode_profile",
        ":runtime_mode_release",
    ],
)

# GN's build_engine_artifacts (config.gni's formula over
# flutter_build_engine_artifacts, which tools/gn leaves true: the host's own
# build or a Linux, macOS or Windows target, never Android): where the
# host-side development artifacts -- the archives, font-subset -- are
# built. The formula's 32-bit Linux arm exclusion has no CPU constraint
# here yet.
selects.config_setting_group(
    name = "engine_artifacts",
    match_any = [
        "@platforms//os:linux",
        "@platforms//os:macos",
        "@platforms//os:windows",
    ],
)

# GN's full_target_platform_name (config.gni: `<target_platform_name>-<target_cpu>`,
# mac spelled darwin and win windows), the pairs tools/gn builds, each the
# group of its OS and CPU constraints: the archives' and font-subset's
# paths are spelled out per pair (one select() case each), so a string
# such as "$full_target_platform_name/font-subset.zip" needs no string
# arithmetic in Starlark.
_TARGET_PLATFORMS = {
    "android-arm": [
        "@platforms//os:android",
        "@platforms//cpu:armv7",
    ],
    "android-arm64": [
        "@platforms//os:android",
        "@platforms//cpu:aarch64",
    ],
    "android-riscv64": [
        "@platforms//os:android",
        "@platforms//cpu:riscv64",
    ],
    "android-x64": [
        "@platforms//os:android",
        "@platforms//cpu:x86_64",
    ],
    "android-x86": [
        "@platforms//os:android",
        "@platforms//cpu:x86_32",
    ],
    "darwin-arm64": [
        "@platforms//os:macos",
        "@platforms//cpu:aarch64",
    ],
    "darwin-x64": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
    ],
    "fuchsia-arm64": [
        "@platforms//os:fuchsia",
        "@platforms//cpu:aarch64",
    ],
    "fuchsia-x64": [
        "@platforms//os:fuchsia",
        "@platforms//cpu:x86_64",
    ],
    "ios-arm64": [
        "@platforms//os:ios",
        "@platforms//cpu:aarch64",
    ],
    "ios-x64": [
        "@platforms//os:ios",
        "@platforms//cpu:x86_64",
    ],
    "linux-arm64": [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    "linux-x64": [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    "wasm-wasm": [
        "@platforms//os:emscripten",
        "@platforms//cpu:wasm32",
    ],
    "windows-arm64": [
        "@platforms//os:windows",
        "@platforms//cpu:aarch64",
    ],
    "windows-x64": [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
}

[
    selects.config_setting_group(
        name = "platform_" + name.replace("-", "_"),
        match_all = constraints,
    )
    for name, constraints in _TARGET_PLATFORMS.items()
]

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
  // fml's trace_event.h includes the Dart timeline API's header. GN's web
  // build has no dependency for it (fml/BUILD.gn: the Dart runtime's build
  // files cannot be loaded for target_os == "wasm") and finds the header
  // through the source root; Bazel's headers-only @dart//:dart_api_headers
  // loads anywhere, so it is listed in every configuration.
  ConvertedFile('//flutter/fml', implicitDeps: <String>['@dart//:dart_api_headers']),
  // The web build's wasm toolchains as platforms carrying their arguments as
  // flags (skwasm's two, CanvasKit's three), and the copies that place each
  // module's outputs in the web SDK's directory (flutter_web_sdk/canvaskit),
  // each naming the toolchain its module is built in.
  ConvertedFile('//flutter/third_party/canvaskit'),
  // The client ICU's bidi library: a few of ICU's source/common files under
  // Skia's own library suffix, which skunicode links where
  // skia_use_client_icu holds (the skwasm and wimp variants).
  ConvertedFile('//flutter/third_party/canvaskit/icu_bidi'),
  // skwasm, the web engine's rendering module: three wasm_lib variants over
  // display_list, Skia's paragraph and unicode modules, and Skia or
  // Impeller -- wasm_module rules, each built for its toolchain's platform.
  ConvertedFile('//flutter/skwasm'),
  // The benchmark library (google/benchmark through @benchmark) and the
  // engine's wrapper of it, for the benchmark executables run_tests.py
  // --type benchmarks runs (benchmarkRuns).
  ConvertedFile('//flutter/benchmarking'),
  // path_ops, the SDK's path operations library (a shared library over
  // Skia that artifacts.zip ships).
  ConvertedFile('//flutter/tools/path_ops'),
  // The sky_engine package (the local engine's gen/dart-pkg/sky_engine,
  // which the flutter tool lists as a build input and the analyzer reads
  // dart:ui and the core libraries from): copies of the Dart SDK's library
  // sources and dart:ui's, dart:ui_web rewritten by web_sdk's sdk_rewriter,
  // the embedder specification, and the package assembled by dart_pkg.py.
  ConvertedFile(
    '//flutter/sky/packages/sky_engine',
    appendix: '''
load("//build_defs/dist:local_engine.bzl", "assembled_directory")

# The package as the SDK cache holds it (bin/cache/pkg/sky_engine): one
# directory of what the targets above place under gen/dart-pkg/sky_engine,
# for a test that runs the real pub or the analyzer on a project of its own
# (a dart_test's cache_files lays it there, where pub looks for the SDK's
# packages and the analyzer for dart:ui).
assembled_directory(
    name = "package",
    contents = [":sky_engine"],
    prefix = "gen/dart-pkg/sky_engine",
)
''',
  ),
  // The web SDK's Dart side (build_defs/web/web_sdk.bzl): the seven libraries
  // sdk_rewriter rewrites into flutter_web_sdk/lib, libraries.json beside
  // them, the three platform kernels and the two DDC compilations of the
  // SDK -- the file's own templates over the prebuilt SDK's kernel_worker
  // and dartdevc, mapped to rules reading the tree web_sdk_root stages
  // (the appendix), and the archive: zip_bundle_from_file over everything
  // the tree holds, the modules included, which is one build_directory_tree
  // over the bundle's deps.
  ConvertedFile(
    '//flutter/web_sdk',
    appendix: '''
load("//build_defs/config:configuration.bzl", "in_configuration")
load("//build_defs/dist:local_engine.bzl", "bundle_directory")
load("//build_defs/web:web_sdk.bzl", "WEB_ENGINE_LIBRARIES", "web_sdk_root")

exports_files(["sdk_rewriter.dart"])

# The flutter_web_sdk tree the compilers above read, staged beside the
# prebuilt SDK (BUILD.gn's web_engine_libraries; web_sdk.bzl).
web_sdk_root(
    name = "flutter_web_sdk_root",
    libraries = WEB_ENGINE_LIBRARIES,
)

# The web SDK as the flutter tool's cache lays it (bin/cache/flutter_web_sdk:
# flutter-web-sdk.zip unpacked), for the tests' SDK facsimile (a dart_test's
# cache_files): the archive built as the web builder builds it, under the
# release mode and the Emscripten platform (in_configuration).
in_configuration(
    name = "flutter_web_sdk_archive_release",
    platform = "//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten",
    runtime_mode = "release",
    target = ":flutter_web_sdk_archive",
)

bundle_directory(
    name = "web_sdk_directory",
    bundles = [":flutter_web_sdk_archive_release"],
)

# The two Dart packages of this directory the web engine's unit tests and
# felt reach (lib/web_ui's pubspec: web_engine_tester, the test harness's
# host page and golden matcher; web_test_utils, the image comparison), each
# as a pub package: its pubspec and library, for a pub_package_config.
filegroup(
    name = "web_engine_tester_package",
    srcs = ["web_engine_tester/pubspec.yaml"] + glob(["web_engine_tester/lib/**"]),
    visibility = ["//engine/src/flutter/lib/web_ui:__pkg__"],
)

filegroup(
    name = "web_test_utils_package",
    srcs = ["web_test_utils/pubspec.yaml"] + glob(["web_test_utils/lib/**"]),
    visibility = ["//engine/src/flutter/lib/web_ui:__pkg__"],
)

# The test harness's host page -- its static files, and host.dart for the
# dart2js compile the web engine's tests lay beside them (web_ui_tests.bzl).
filegroup(
    name = "web_engine_tester_host_files",
    srcs = [
        "web_engine_tester/lib/static/favicon.ico",
        "web_engine_tester/lib/static/host.css",
        "web_engine_tester/lib/static/index.html",
    ],
    visibility = ["//engine/src/flutter/lib/web_ui:__pkg__"],
)

exports_files(
    ["web_engine_tester/lib/static/host.dart"],
    visibility = ["//engine/src/flutter/lib/web_ui:__pkg__"],
)
''',
  ),
  // flutter.js, the web SDK's loader: its sources copied under
  // flutter_web_sdk/flutter_js and bundled by esbuild (build/esbuild).
  ConvertedFile('//flutter/lib/web_ui/flutter_js'),
  // The archives a host build uploads (research/09): artifacts.zip, the
  // patched SDK's, the prebuilt Dart SDK's, the embedder's. The
  // entitlement lists are the macOS signing step's.
  ConvertedFile(
    '//flutter/build/archives',
    // The macOS archives (darwin-<cpu>/artifacts.zip, dart-sdk-darwin-<cpu>.zip
    // with their entitlements lists -- generated_files over the tools'
    // metadata, walked at conversion time -- and the rest) are the Mac's
    // branches of this file; `host_os == "mac"` is the host's setting
    // (hostOsCases: the .dylib names of the host's libraries).
    assume: hostOsCases,
    appendix: '''
load("//build_defs/android:build_tools.bzl", "android_engine_artifacts")
load("//build_defs/dist:local_engine.bzl", "bundle_directory")
load("//build_defs/config:configuration.bzl", "in_configuration")

# The GN file, for the wrapped GN builds that read //flutter/build
# (//engine/src/flutter/build:gn_files; a glob does not enter a package).
filegroup(
    name = "gn_files",
    srcs = ["BUILD.gn"],
    visibility = ["//engine/src/flutter/build:__pkg__"],
)

# The host's development artifacts unpacked as the flutter tool's cache lays
# them, for the tests' SDK facsimile (a dart_test's cache_files; what
# `flutter precache --linux` downloads): bin/cache/artifacts/engine/<host> is
# artifacts.zip, font-subset.zip and the debug desktop embedding's archive
# unpacked together, <host>-profile and <host>-release the other modes'
# (gen_snapshot and the embedding, built under that mode's configuration:
# in_configuration), common/ the patched SDK's debug and product archives.
# The Linux host's for now: the desktop embedding here is the GTK shell's
# (a Mac's facsimile takes FlutterMacOS.framework, when the tool's macOS
# tests come), so the directory is incompatible elsewhere rather than
# failing a Mac's analysis of the package.
bundle_directory(
    name = "host_engine_directory",
    bundles = [
        ":artifacts",
        "//engine/src/flutter/shell/platform/linux:flutter_gtk",
        "//engine/src/flutter/tools/font_subset:font_subset",
    ],
    target_compatible_with = ["@platforms//os:linux"],
)

in_configuration(
    name = "artifacts_profile",
    runtime_mode = "profile",
    target = ":artifacts",
)

in_configuration(
    name = "flutter_gtk_profile",
    runtime_mode = "profile",
    target = "//engine/src/flutter/shell/platform/linux:flutter_gtk",
)

bundle_directory(
    name = "host_engine_profile_directory",
    bundles = [
        ":artifacts_profile",
        ":flutter_gtk_profile",
    ],
)

in_configuration(
    name = "artifacts_release",
    runtime_mode = "release",
    target = ":artifacts",
)

in_configuration(
    name = "flutter_gtk_release",
    runtime_mode = "release",
    target = "//engine/src/flutter/shell/platform/linux:flutter_gtk",
)

bundle_directory(
    name = "host_engine_release_directory",
    bundles = [
        ":artifacts_release",
        ":flutter_gtk_release",
    ],
)

in_configuration(
    name = "flutter_patched_sdk_release",
    runtime_mode = "release",
    target = ":flutter_patched_sdk",
)

bundle_directory(
    name = "common_engine_directory",
    bundles = [
        ":flutter_patched_sdk",
        ":flutter_patched_sdk_release",
    ],
)

# The Android artifacts the same way, for the tests that run `flutter
# build apk` (//build_defs/android:build_tools.bzl): gen_snapshot per CPU
# and AOT mode as android-<cpu>-<mode>/linux-x64, and the embedding's Maven
# artifacts as a repository (android_engine_maven) -- the engine built for
# arm, arm64 and x64 in debug, profile and release, the Android builders'
# configurations, through in_configuration.
android_engine_artifacts(name = "android_engine")
''',
  ),
  // font-subset, the SDK's font subsetting tool (run_tests.py --type
  // font-subset runs its test.py against the built binary and its
  // archive, GN's zip_bundle). The entitlements list is the macOS bundle's.
  ConvertedFile(
    '//flutter/tools/font_subset',
    // The macOS archive (darwin-<cpu>/font-subset.zip) carries the tool's
    // without-entitlements list, a generated_file over the tool's metadata
    // (walked at conversion time).
    appendix: '''
load("//build_defs/testing:checkout_script_test.bzl", "checkout_script_test")

# run_tests.py --type font-subset: `python3 test.py --variant <build
# directory>` from this directory, against the binary and the archive at
# their places in the build directory.
checkout_script_test(
    name = "font_subset_test",
    build_directory = {
        ":font-subset": "",
        ":font_subset": "zip_archives/linux-x64",
    },
    script = "test.py",
    script_args = [
        "--variant",
        "{variant}",
    ],
)
''',
  ),
  // licenses_cpp, the license checker ci/licenses.sh runs over the
  // checkout (the host_release_licenses builder builds it and runs its
  // test runner from the build directory).
  ConvertedFile('//flutter/tools/licenses_cpp'),
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
    # The display wrapper of flutter_display_test (testing.bzl).
    "xvfb_run.sh",
    # The gtest-parallel wrapper of flutter_cc_test (testing.bzl).
    "gtest_parallel_run.sh",
    # CI's sanitizer environment, which the test launchers source under the
    # asan flag (build_defs/cc/sanitizers.bzl).
    "sanitizer_suppressions.sh",
    "lsan_suppressions.txt",
    "tsan_suppressions.txt",
    "ubsan_suppressions.txt",
])

# testing.gni's enable_unittests: `current_toolchain == host_toolchain ||
# is_fuchsia || is_mac` -- the host's own build (its OS and its CPU:
# //engine/src/flutter/build/bazel:host_toolchain; the Linux arm64 cross
# build has no tests, as GN's clang_arm64 toolchain has none), Fuchsia, macOS.
selects.config_setting_group(
    name = "unittests_enabled",
    match_any = [
        "//engine/src/flutter/build/bazel:host_toolchain",
        "@platforms//os:fuchsia",
        "@platforms//os:macos",
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
  // impellerc's shader library: GN copies the GLSL files beside the
  // compiler in the build directory, and artifacts.zip ships the source
  // directory whole (zip.py walks it, BUILD files and all), which is the
  // `all_files` filegroups: each package's files, the parent's gathering
  // its subpackages' (a glob stops at a package boundary).
  ConvertedFile(
    '//flutter/impeller/compiler/shader_lib',
    appendix: '''
# The directory as artifacts.zip ships it (directorySources in the
# converter's bazel_mapping.dart).
filegroup(
    name = "all_files",
    srcs = glob(["*"]) + [
        "//engine/src/flutter/impeller/compiler/shader_lib/flutter:all_files",
        "//engine/src/flutter/impeller/compiler/shader_lib/impeller:all_files",
    ],
)
''',
  ),
  ConvertedFile(
    '//flutter/impeller/compiler/shader_lib/flutter',
    appendix: '''
filegroup(
    name = "all_files",
    srcs = glob(["*"]),
)
''',
  ),
  ConvertedFile(
    '//flutter/impeller/compiler/shader_lib/impeller',
    appendix: '''
filegroup(
    name = "all_files",
    srcs = glob(["*"]),
)
''',
  ),
  // The shader pipeline's users (research/08, step 4): impeller_shaders()
  // invocations become the macro in build_defs/impeller.
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
    // The Impeller SDK: its shared library is libimpeller.so or .dylib by
    // platform (flutter_shared_library), its archive darwin-<cpu>/
    // impeller_sdk.zip on a Mac, where the Metal example builds too.
    '//flutter/impeller/toolkit/interop',
  ),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend'),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend/gles'),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend/metal', condition: 'is_mac'),
  ConvertedFile('//flutter/impeller/toolkit/interop/backend/vulkan'),
  // The EGL, GLES and GL-Vulkan interop toolkits, which the Android shell
  // links (EGL's library under is_android).
  // The platform shells, by OS: the Android group (its symbols archive; the
  // Java targets are skipped in its file) and the Linux one. What the root
  // group reaches through //flutter/sky.
  // The darwin packages the shell's Metal test fixtures and the embedder's
  // Mac build reach (research/20 §9): the Metal/Impeller context, and
  // what the Flutter frameworks share -- the channels and codecs, the
  // tracing bindings, and the Swift module behind them
  // (InternalFlutterSwiftCommon, a flutter_swift_library). Their unit
  // tests wait for the Apple test phase: the Objective-C suite links
  // OCMock and XCTest from the platform's Developer directory
  // (`:test_config`), the Swift suite the Testing framework.
  ConvertedFile('//flutter/shell/platform/darwin/graphics', condition: 'is_mac'),
  ConvertedFile(
    '//flutter/shell/platform/darwin/common',
    condition: 'is_mac',
    skip: <String, String>{
      'framework_common_unittests': "OCMock and XCTest from the platform's Developer directory (test_config): the Apple test phase",
      'framework_common_swift_unittests':
          "the Testing framework from the platform's Developer directory: the Apple test phase",
      'test_utils_swift': 'a helper of framework_common_swift_unittests: the Apple test phase',
      'swift_testing_main': "the Testing framework's runner: the Apple test phase",
      // Their configs: the platform's Developer directory (XCTest, Testing)
      // by a machine path, which only the skipped suites list.
      'test_config':
          "the platform's Developer directory for the suites above: the Apple test phase",
      'swift_testing_config': "the Testing framework's search path and rpath: the Apple test phase",
    },
  ),
  // The macOS shell: FlutterMacOS.framework (the Objective-C++ sources, the
  // Swift run loop and resize synchronizer, the dylib, the copies into the
  // bundle, package_framework.py's symlinks, the xcframework, the archive and
  // its without-entitlements list). `macos` (what the root reaches through
  // shell/platform:platform and darwin) and `universal_flutter_framework`
  // are groups of things to build over the packaging actions, which nothing
  // links. Its two suites wait for the Apple test phase; the umbrella-import
  // check links against the assembled bundle in the build directory
  // (`-F$root_out_dir`), which a cc rule cannot name yet (research/20 §11).
  ConvertedFile(
    '//flutter/shell/platform/darwin/macos',
    condition: 'is_mac',
    filesGroups: <String>{'macos', 'universal_flutter_framework'},
    // The file is a Mac's alone: host_os is mac, and the archive's name
    // (`$full_platform_name-$flutter_runtime_mode/FlutterMacOS.framework.zip`,
    // the host's platform name) is the target's, darwin-<cpu>, since the
    // macOS shell is built for the Mac that builds it (tools/gn's --mac-cpu
    // is the bot's own CPU on every builder of mac_host_engine.json).
    assume: macHostAssumptions,
    skip: <String, String>{
      'flutter_desktop_darwin_unittests':
          "OCMock and the fixtures' Dart entry point, run as a test: the Apple test phase",
      'flutter_desktop_darwin_swift_unittests':
          "the Testing framework from the platform's Developer directory: the Apple test phase",
      '_generate_symlinks_and_verify_framework_module':
          r'a shared library linked against the assembled FlutterMacOS.framework in the build directory '
          r'(-F$root_out_dir, frameworks = ["FlutterMacOS.framework"]): a verification target that '
          'ships nothing, for a rule that takes the bundle as a link input (research/20 §11)',
      'flutter_framework':
          'create_xcframework.py over the assembled bundle (xcodebuild -create-xcframework): a rule '
          'that lays the bundle out for it, links and all, is next (research/20 §11)',
    },
  ),
  // The darwin platforms' group: `macos` on a Mac (under
  // enable_desktop_embeddings), the iOS framework on iOS; what
  // shell/platform:platform reaches on an Apple host. A group of things to
  // build (the root's family).
  ConvertedFile(
    '//flutter/shell/platform/darwin',
    condition: 'is_mac',
    filesGroups: <String>{'darwin'},
    appendix: '''
# The iOS embedding's AccessibilityFeatures, which api_check's tests read
# (the enum mirrors dart:ui's): a file of this package until
# shell/platform/darwin/ios has a build file of its own.
exports_files(["ios/framework/Source/AccessibilityFeatures.swift"])
''',
  ),
  ConvertedFile('//flutter/shell/platform', filesGroups: <String>{'platform'}),
  ConvertedFile(
    '//flutter/sky',
    filesGroups: <String>{'sky'},
    appendix: '''
# The scripts of other packages' actions: sky/dist's copy of the assembled
# sky_engine package for release, the macOS shell's framework headers and
# its xcframework (shell/platform/darwin/macos).
exports_files([
    "tools/create_xcframework.py",
    "tools/dist_dart_pkg.py",
    "tools/install_framework_headers.py",
])
''',
  ),
  ConvertedFile('//flutter/sky/packages', filesGroups: <String>{'packages'}),
  ConvertedFile('//flutter/impeller/toolkit/egl'),
  ConvertedFile('//flutter/impeller/toolkit/gles'),
  // The GL-over-Vulkan trampoline: its header includes the Vulkan backend's
  // hardware-buffer texture source, a file that exists under is_android only,
  // and only the Android shell depends on it.
  ConvertedFile('//flutter/impeller/toolkit/glvk', condition: 'is_android'),
  // The Android toolkit (NDK surface control, hardware buffers, the
  // choreographer), which the Vulkan backend and the Android shell reach
  // under is_android; its suite is an Android executable and an APK.
  ConvertedFile(
    '//flutter/impeller/toolkit/android',
    condition: 'is_android',
    skip: <String, String>{
      'apk_unittests': 'an APK of the suite (native_activity_apk): the Android test phase',
    },
  ),
  ConvertedFile('//flutter/impeller/playground/image'),
  ConvertedFile('//flutter/impeller/playground/imgui'),
  ConvertedFile('//flutter/impeller/playground'),
  // The test fixtures: two shader libraries, the runtime stages and shader
  // bundles (impellerc invoked directly) and the files, with the Dart entry
  // point of the Flutter GPU tests.
  ConvertedFile(
    '//flutter/impeller/fixtures',
    // The file fixtures take a Mac's emoji font (`host_os == "mac"`): the
    // host's setting selects it (hostOsCases; the font from @host_files).
    assume: hostOsCases,
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
  // both convert under is_mac (the tree's files below, the bridge through
  // targetConditions) for the macOS shell.
  ConvertedFile('//flutter/shell/geometry'),
  ConvertedFile(
    '//flutter/shell/platform/common',
    // The accessibility bridge is defined outright but compiles for the
    // macOS and Windows shells alone (gfx::NativeWindow is theirs; GN
    // never builds it on Linux): a Mac's for now, as its tree is.
    targetConditions: <String, String>{'common_cpp_accessibility': 'is_mac'},
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
  ConvertedFile('//flutter/shell/platform/linux'),
  // The Android embedding's host-testable pieces (the JNI facade with its
  // mock, the native window, the context, the surfaces, the external view
  // embedder, the platform view delegate) with the three suites
  // run_tests.py runs on every non-Windows host.
  // android_rendering_selector.h, an enum of the parent directory that no
  // GN target lists (the shell's source set could not carry it for them:
  // its visibility excludes these packages), comes from the hand-written
  // parent package.
  // The Android shell itself: libflutter.so (flutter_shell_native, under
  // GN's output_name "flutter", with its export list), its sources, the
  // symbols archive. GN reaches the file under is_android alone. The Java
  // half -- the embedding's sources through javac and d8 (build/android/
  // gyp), flutter.jar and the ABI jars, the Maven tree, the javadoc -- is
  // the Android phase's second part (NEED_DECISION D10), as are the host
  // tools' archives for the AOT builders (gen_snapshot, analyze_snapshot:
  // get_label_info over the host toolchain) and the `android` group that
  // gathers them. The header the sub-packages share and the Java enums
  // tools/api_check reads are in the appendix, as the hand-written file had
  // them.
  ConvertedFile(
    '//flutter/shell/platform/android',
    condition: 'is_android',
    filesGroups: <String>{'android'},
    skip: <String, String>{
      'android_entitlement_config': "generated_file over metadata: the Apple phase's",
    },
    appendix: '''
load("//build_defs/java:robolectric.bzl", "android_test_apk", "java_classes", "robolectric_tests")

# android_rendering_selector.h, an enum the shell and its sub-packages share,
# which no GN target lists (the shell's source set could not carry it for
# them: its visibility excludes the sub-packages that include it) and which
# the sub-packages converted for the host suites take as an implicit
# dependency (the manifest).
cc_library(
    name = "rendering_selector",
    hdrs = ["android_rendering_selector.h"],
)

# The Java enums that mirror dart:ui's, which tools/api_check's tests parse
# (run_tests.py --type dart-host).
exports_files([
    "io/flutter/embedding/engine/systemchannels/LifecycleChannel.java",
    "io/flutter/view/AccessibilityBridge.java",
])

# The embedding's Java tests (test/; run_tests.py --type java runs them
# through Gradle in test_runner/): compiled against this build's flutter.jar,
# android.jar and the pinned Maven test dependencies, and run one class per
# target under Robolectric on the engine's JDK (build_defs/java/robolectric.bzl;
# NEED_DECISION D12). Under an Android configuration, as flutter.jar is.
java_classes(
    name = "java_tests_classes",
    # The tests and their helpers, as Gradle's source set takes the directory.
    srcs = glob(["test/**/*.java"]),  # buildifier: disable=bad-recursive-glob
    bootclasspath = "@android_tools//:sdk/platforms/android-37.0/android.jar",
    classpath = [
        ":android_jar",
        "@android_tools//:sdk/build-tools/37.0.0/core-lambda-stubs.jar",
        "@maven_android_tests//:jars",
    ],
)

# What AGP's unit tests hand Robolectric (includeAndroidResources): the
# test module's manifest merged (its namespace, the SDK levels), linked with
# the androidx libraries' resources into a resource APK by aapt2, and the R
# classes over its ids.
android_test_apk(
    name = "java_tests_apk",
    aapt2 = "@android_tools//:sdk/build-tools/37.0.0/aapt2",
    android_jar = "@android_tools//:sdk/platforms/android-37.0/android.jar",
    library_manifests = ["@maven_android_tests//:aar_manifests"],
    library_resources = ["@maven_android_tests//:aar_resources"],
    manifest = "test_runner/src/main/AndroidManifest.xml",
    namespace = "io.flutter.app.test",
)

robolectric_tests(
    name = "java_tests",
    android_all = "@maven_android_tests//:android_all",
    apk = ":java_tests_apk",
    classes = ":java_tests_classes",
    javaagent = "@maven_android_tests//:org_mockito_mockito_core",
    robolectric_properties = "test_runner/src/main/resources/robolectric.properties",
    # android.jar last, as AGP's mockable android jar: the runner's own
    # classes name framework types (Config's Application default) before
    # Robolectric's sandbox loads the real framework from android-all.
    runtime_classpath = [
        ":android_jar",
        "@maven_android_tests//:jars",
        "@android_tools//:sdk/platforms/android-37.0/android.jar",
    ],
    tests = glob(["test/**/*Test.java"]),  # buildifier: disable=bad-recursive-glob
)
''',
  ),
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
    // txt_fixtures take a Mac's emoji font (`host_os == "mac"`): the host's
    // setting selects it (hostOsCases; the font from @host_files).
    assume: hostOsCases,
    // The fonts are fixtures of other packages' tests (display_list's).
    // GN's flutter_use_fontconfig (declared here) and Skia's
    // skia_use_fontconfig, which tools/gn sets together from
    // --enable-fontconfig: one flag, off by default as both arguments are,
    // and the setting the generated files select() on (conditionSettings).
    appendix: '''
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")

exports_files(glob(["third_party/fonts/*"]))

# tools/gn's --enable-fontconfig: flutter_use_fontconfig (this file's
# argument) and skia_use_fontconfig at once. Off, as in every host build; the
# Linux desktop builders turn it on (ci/builders/configs.bazelrc), and with
# it txt's Linux font manager is Skia's fontconfig one (SkFontMgr_fontconfig,
# SK_FONTMGR_FONTCONFIG_AVAILABLE) over the sysroot's libfontconfig.
bool_flag(
    name = "use_fontconfig",
    build_setting_default = False,
)

config_setting(
    name = "fontconfig",
    flag_values = {":use_fontconfig": "True"},
)
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
  // //flutter/flow need) and their test suites, on the playground. The
  // Metal backend is a Mac's (or iOS's) alone: Objective-C++ over
  // Metal.framework, its shaders by Xcode's metal compiler
  // (build_defs/impeller/shaders.bzl's mtl backend; research/20 M4).
  ConvertedFile('//flutter/impeller/renderer/backend/gles'),
  ConvertedFile('//flutter/impeller/renderer/backend/metal', condition: 'is_mac'),
  ConvertedFile(
    '//flutter/impeller/renderer/backend/vulkan',
    skip: <String, String>{
      // Under is_android: the suite as an APK (testing/android's
      // native_activity_apk template, which the converter does not know);
      // the Android test phase's. The same suite as an Android executable
      // (vulkan_android_unittests, impeller_vulkan_android_unittests by
      // output_name) converts: run_tests.py --type android pushes it.
      'vulkan_android_apk_unittests':
          'an APK of the suite (native_activity_apk): the Android test phase',
    },
  ),
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

# The same sources and the fix data by name, for the copies
# sky/packages/sky_engine makes into the sky_engine package.
exports_files(glob(["*.dart"]) + ["fix_dart_ui.yaml"])
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

# The package directory as flutter_gpu.zip ships it (lib/gpu/dist; the
# converter's directorySources names it): every file of this package and of
# its dist subpackage, as zip.py's walk of //flutter/lib/gpu takes them.
filegroup(
    name = "all_files",
    srcs = glob(["**"]) + ["//engine/src/flutter/lib/gpu/dist:all_files"],
    visibility = ["//engine/src/flutter/lib/gpu/dist:__pkg__"],
)
''',
  ),
  // The Flutter GPU package's release archives (flutter_gpu.zip at the
  // Android archive directory and at the root of zip_archives, the old
  // location the tool still reads): zip_bundles over the package directory,
  // which only the Android builders build.
  ConvertedFile(
    '//flutter/lib/gpu/dist',
    condition: 'is_android',
    filesGroups: <String>{'dist'},
    appendix: '''
# This package's own files, for //engine/src/flutter/lib/gpu:all_files (the
# archive walks the whole of lib/gpu, this directory included).
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//engine/src/flutter/lib/gpu:__pkg__"],
)
''',
  ),
  // The sky_engine package's release archives (sky_engine.zip, likewise at
  // two locations): dist_dart_pkg.py copies the assembled package
  // (gen/dart-pkg/sky_engine, a dart_pkg's directory) to
  // dist/packages/sky_engine, a directory output under the build directory
  // (actionDirectoryOutputs), which the zip_bundles walk.
  ConvertedFile('//flutter/sky/dist', condition: 'is_android', filesGroups: <String>{'dist'}),
  // The shell proper needs the Dart runtime glue (lib/ui, runtime, tonic)
  // and the GPU surfaces; what converts now is what //flutter/common/graphics
  // and the shell's own small libraries need.
  // The shell's directory: its one group gathers the platform shells
  // (//flutter/shell/platform); the file is also here for shell/config.gni's
  // arguments, which the appendix defines as the settings their formulas
  // and tools/gn give.
  ConvertedFile(
    '//flutter/shell',
    filesGroups: <String>{'shell'},
    appendix: '''
load("@bazel_skylib//lib:selects.bzl", "selects")

# GN's shell_enable_gl, shell_enable_metal, shell_enable_vulkan,
# shell_enable_software and the test_enable_* beside them
# (shell/config.gni): which rendering backends the shell and its tests are
# built with, by platform, as config.gni's defaults and tools/gn decide
# them. OpenGL: config.gni's `!is_fuchsia && !is_mac`, and tools/gn turns it
# off on iOS. Metal: tools/gn, on iOS and for macOS targets (built on a
# macOS host). Vulkan: tools/gn, everywhere but iOS and macOS. Software:
# everywhere. The tests follow the shell's (test_enable_vulkan: on Fuchsia
# or wherever the GL ones run, the same set as the shell's Vulkan). The
# complements serve conjunctions (`shell_enable_vulkan && !is_wasm`).
_ALL_PLATFORMS = [
    "@platforms//os:android",
    "@platforms//os:emscripten",
    "@platforms//os:fuchsia",
    "@platforms//os:ios",
    "@platforms//os:linux",
    "@platforms//os:macos",
    "@platforms//os:qnx",
    "@platforms//os:windows",
]

_BACKEND_PLATFORMS = {
    "gl": [
        "@platforms//os:android",
        "@platforms//os:emscripten",
        "@platforms//os:linux",
        "@platforms//os:qnx",
        "@platforms//os:windows",
    ],
    "metal": [
        "@platforms//os:ios",
        "@platforms//os:macos",
    ],
    "software": _ALL_PLATFORMS,
    "vulkan": [
        "@platforms//os:android",
        "@platforms//os:emscripten",
        "@platforms//os:fuchsia",
        "@platforms//os:linux",
        "@platforms//os:qnx",
        "@platforms//os:windows",
    ],
}

[
    selects.config_setting_group(
        name = "enable_" + backend,
        match_any = platforms,
    )
    for backend, platforms in _BACKEND_PLATFORMS.items()
]

[
    selects.config_setting_group(
        name = "not_enable_" + backend,
        match_any = [
            os
            for os in _ALL_PLATFORMS
            if os not in platforms
        ],
    )
    for backend, platforms in _BACKEND_PLATFORMS.items()
    if len(platforms) < len(_ALL_PLATFORMS)
]

# The tests' arguments are the shell's (test_enable_vulkan's formula,
# `is_fuchsia || shell_enable_gl`, names the Vulkan set).
[
    alias(
        name = "test_enable_" + backend,
        actual = ":enable_" + backend,
    )
    for backend in _BACKEND_PLATFORMS.keys()
]

''',
  ),
  ConvertedFile('//flutter/shell/common'),
  // The embedder API: its libraries, its shared library and its three suites,
  // and its artifact side -- the header copied into the build root, the
  // group over it and the library, the CI archive (linux-x64-embedder.zip).
  // On a Mac the dylib is packaged as FlutterEmbedder.framework: the group
  // over the packaging action is a group of files to build, nothing links it.
  ConvertedFile(
    '//flutter/shell/platform/embedder',
    filesGroups: <String>{'flutter_embedder_framework'},
    // The framework's archive is named by the host's platform
    // (`$full_platform_name/FlutterEmbedder.framework.zip`): darwin-<cpu>
    // on the Mac that builds it (hostPlatformNameCases).
    assume: <String, GnValue>{'full_platform_name': hostPlatformNameCases},
  ),
  // The accessibility tree the desktop embeddings' bridge builds on
  // (Chromium's ui/accessibility, trimmed): the macOS and Windows shells'
  // alone -- on Linux it neither compiles nor is reached (see
  // shell/platform/common above) -- so a Mac's for now. Its include
  // directory is the tree's root, which the root's config carries
  // (includeDirLibraries).
  ConvertedFile('//flutter/third_party/accessibility', condition: 'is_mac'),
  ConvertedFile('//flutter/third_party/accessibility/ax', condition: 'is_mac'),
  ConvertedFile('//flutter/third_party/accessibility/ax_build', condition: 'is_mac'),
  ConvertedFile('//flutter/third_party/accessibility/base', condition: 'is_mac'),
  ConvertedFile('//flutter/third_party/accessibility/base/numerics', condition: 'is_mac'),
  ConvertedFile('//flutter/third_party/accessibility/gfx', condition: 'is_mac'),
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

# The same tree whole (its pngsuite/ and orientation/ too), which the web
# engine's unit tests read as /test_images/ (felt's copy_artifacts_step;
# @flutter//build_defs/web:web_ui_tests.bzl).
filegroup(
    name = "resources_images_tree",
    srcs = glob(["resources/images/**"]),
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
  // CanvasKit, the web SDK's other rendering module: the engine's GN over
  // Skia's modules/canvaskit sources, an executable in a wasm toolchain
  // (output_extension = "js", the toolchain's .js/.wasm/.js.symbols link) --
  // a wasm_executable here -- and the group the web SDK's copies name in
  // each of its three toolchains (third_party/canvaskit). Its sources are
  // the package's own (modules/canvaskit of the Skia tree); Skia's headers
  // come as for the other modules.
  ConvertedFile('//flutter/skia/modules/canvaskit', implicitDeps: <String>['@skia//:skia_headers']),
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
  // Google's cpu_features (the src/ subtree is the synced repository, the
  // GN file the engine's): the NDK-compatible cpu-features.c that libwebp
  // reads on Android. Its public headers sit under src/include, the
  // compatibility header under src/ndk_compat, and the .inl files the
  // implementations include beside them.
  ConvertedFile(
    '//flutter/third_party/cpu_features',
    implicitDeps: <String>['@cpu_features//:cpu_features_headers'],
    appendix: '''
cc_library(
    name = "cpu_features_headers",
    hdrs = glob([
        "src/include/**/*.h",
        "src/ndk_compat/*.h",
    ]),
    textual_hdrs = glob(["src/src/*.inl"]),
)

# What a GN build reads of this tree (the Dart wrap's zlib, under Android).
filegroup(
    name = "build_tree",
    srcs = ["BUILD.gn"] + glob(
        ["src/**"],
        exclude = [
            "**/.git/**",
            "**/BUILD.bazel",
        ],
    ),
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
  // Brotli's decoder (FreeType's WOFF2 support, the web build's
  // flutter_use_freetype_woff2), over a tree whose headers GN never
  // declares: the public ones under c/include, the decoder's own beside its
  // sources.
  ConvertedFile(
    '//third_party/brotli',
    implicitDeps: <String>['@brotli//:brotli_headers'],
    appendix: '''
cc_library(
    name = "brotli_headers",
    hdrs = glob(["c/**/*.h"]),
)
''',
  ),
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
    // header stubs, diff/) are in no GN list. The tree's root as an
    // include directory (root_include) is what the Vulkan validation
    // layer's GN lists (vvl_glslang_dir; includeDirLibraries).
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
        "source/**/*.h",
    ]),
)

cc_library(
    name = "root_include",
    hdrs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
        "source/**/*.h",
    ]),
    includes = ["."],
)
''',
  ),
  // The Vulkan validation layer (VkLayer_khronos_validation: the engine's
  // GN in the secondary tree over the synced tree) and the layer-settings
  // library of vulkan-utility-libraries it links. The Android embedding's
  // debug jar packs the layer for arm64, built at API level 26.
  ConvertedFile(
    '//third_party/vulkan_validation_layers',
    // The group over the layer (its data_deps): a group of files, which the
    // Android embedding's jar action depends on.
    filesGroups: <String>{'vulkan_validation_layers'},
    skip: <String, String>{
      'vulkan_stateless_validation_config':
          'a config of compiler flags that no target lists (a remnant of the upstream file)',
    },
    implicitDeps: <String>['@vulkan_validation_layers//:headers'],
    // The headers the layer's sources include beyond GN's list (the
    // generated ones under layers/vulkan/generated, the externals).
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob(["layers/**/*.h"]),
)
''',
  ),
  ConvertedFile(
    '//flutter/third_party/vulkan-deps/vulkan-utility-libraries/src',
    implicitDeps: <String>['@vulkan-utility-libraries//:headers'],
    // GN lists some of the public headers; the sources include others
    // (vk_small_containers.hpp).
    appendix: '''
cc_library(
    name = "headers",
    hdrs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
        "src/**/*.hpp",
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
  // GN's //build: its files are inputs of the wrapped GN builds, and
  // build/android/gyp's scripts the Android embedding's actions.
  'engine/src/build',
  'engine/src/flutter',
  // //flutter/build: the engine's GN additions (wrapped builds' inputs),
  // zip_bundle.gni's script, and android_artifacts.py.
  'engine/src/flutter/build',
  'engine/src/flutter/impeller/tools',
  'engine/src/flutter/lib/snapshot',
  // The web engine's sources (web_sdk/BUILD.gn's sdk_rewriter inputs and API
  // files) and its unit tests.
  'engine/src/flutter/lib/web_ui',
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
