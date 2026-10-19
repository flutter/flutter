// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Linux x64 host builds of `ci/builders/*.json` as Bazel configurations
/// and install targets.
///
/// Each builder file describes builds: a `tools/gn` flag list, the ninja
/// targets to build, the archives to upload, the tests to run. The Bazel
/// build has settings for some of what the flags set (the runtime mode, the
/// compilation mode) and assumptions for the rest; this module turns each
/// Linux x64 host build into a `--config=<name>` of a generated bazelrc
/// (`ci/builders/configs.bazelrc`, which the root `.bazelrc` imports) when
/// every flag maps, and into an `install` target of a generated BUILD file
/// (`ci/builders/BUILD.bazel`) over the Bazel counterparts of its ninja
/// targets, installing into GN's build directory (`--target-dir`). A flag
/// the Bazel build cannot express yet costs the build its configuration,
/// with the reason on record in the generated file; a ninja target with no
/// Bazel counterpart is listed the same way.
library;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:path/path.dart' as p;

import 'bazel_mapping.dart';
import 'manifest.dart';
import 'starlark_emitter.dart';

/// What a `tools/gn` flag amounts to under Bazel.
enum GnFlagEffect {
  /// `--runtime-mode <mode>`: the runtime mode setting.
  runtimeMode,

  /// `--unoptimized`: Bazel's default compilation mode; its absence is `-c opt`.
  unoptimized,

  /// `--target-dir <dir>`: the build directory under engine/src/out.
  buildDirectory,

  /// What the generated files assume already (the prebuilt Dart SDK, no LTO).
  assumed,

  /// Infrastructure, or something a configuration cannot carry (targets).
  ignored,

  /// Something the Bazel build has no setting for yet.
  unsupported,

  /// A platform other than the Linux x64 host: the build is out of scope.
  otherPlatform,
}

/// One `tools/gn` flag.
final class GnFlag {
  const GnFlag(this.effect, {this.takesValue = false, this.note});

  final GnFlagEffect effect;

  /// Whether the flag takes the next argument (or `=value`) as its value.
  final bool takesValue;

  /// Why it is assumed, ignored or unsupported.
  final String? note;
}

/// The `tools/gn` flags of the Linux builder files, as far as they appear.
const Map<String, GnFlag> gnFlags = <String, GnFlag>{
  '--runtime-mode': GnFlag(GnFlagEffect.runtimeMode, takesValue: true),
  '--unoptimized': GnFlag(GnFlagEffect.unoptimized),
  '--target-dir': GnFlag(GnFlagEffect.buildDirectory, takesValue: true),
  '--prebuilt-dart-sdk': GnFlag(
    GnFlagEffect.assumed,
    note: 'flutter_prebuilt_dart_sdk is true in every generated file',
  ),
  '--no-prebuilt-dart-sdk': GnFlag(
    GnFlagEffect.unsupported,
    note: 'the generated files assume the prebuilt Dart SDK',
  ),
  '--no-lto': GnFlag(
    GnFlagEffect.assumed,
    note: 'the Bazel toolchain never links with LTO (enable_lto is false)',
  ),
  '--lto': GnFlag(GnFlagEffect.unsupported, note: 'the Bazel toolchain has no LTO'),
  '--rbe': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--no-rbe': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--goma': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--no-goma': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--build-embedder-examples': GnFlag(
    GnFlagEffect.ignored,
    note: 'adds targets to the build, which a configuration cannot name',
  ),
  '--enable-fontconfig': GnFlag(
    GnFlagEffect.unsupported,
    note: 'flutter_use_fontconfig and skia_use_fontconfig are false in the generated files',
  ),
  '--asan': GnFlag(GnFlagEffect.unsupported, note: 'the toolchain has no sanitizer feature yet'),
  '--dart-debug': GnFlag(
    GnFlagEffect.unsupported,
    note: 'the wrapped Dart SDK build is not parameterized by dart_debug',
  ),
  '--use-glfw-swiftshader': GnFlag(
    GnFlagEffect.unsupported,
    note: 'the Impeller test backends are not parameterized by it',
  ),
  '--gn-args': GnFlag(GnFlagEffect.unsupported, takesValue: true, note: 'an arbitrary GN argument'),
  '--android': GnFlag(GnFlagEffect.otherPlatform),
  '--android-cpu': GnFlag(GnFlagEffect.otherPlatform, takesValue: true),
  '--fuchsia': GnFlag(GnFlagEffect.otherPlatform),
  '--fuchsia-cpu': GnFlag(GnFlagEffect.otherPlatform, takesValue: true),
  '--ios': GnFlag(GnFlagEffect.otherPlatform),
  '--mac': GnFlag(GnFlagEffect.otherPlatform),
  '--web': GnFlag(GnFlagEffect.otherPlatform),
  '--windows': GnFlag(GnFlagEffect.otherPlatform),
  '--target-os': GnFlag(GnFlagEffect.otherPlatform, takesValue: true),
  '--linux-cpu': GnFlag(GnFlagEffect.otherPlatform, takesValue: true),
  '--embedder-for-target': GnFlag(GnFlagEffect.otherPlatform),
};

/// The runtime mode setting of the Bazel build.
const String runtimeModeSetting = '//engine/src/flutter/common:runtime_mode';

/// testing/run_tests.py's test types, as the Bazel suites that run the same
/// tests: `dart` is the Dart tests under flutter_tester with the VM
/// service's and the smoke test (gather_dart_smoke_test, gather_dart_tests),
/// `dart-host` the Dart packages' own tests (build_dart_host_test_list),
/// `benchmarks` the engine benchmarks (run_engine_benchmarks),
/// `font-subset` font-subset's test, `impeller` the Impeller suite alone.
/// `engine` is [runTestsEngineSuites], resolved among the converted targets.
const Map<String, List<String>> runTestsTypeSuites = <String, List<String>>{
  'dart': <String>[
    '//engine/src/flutter/testing/dart:dart',
    '//engine/src/flutter/testing/dart/vm_service:vm_service',
    '//engine/src/flutter/testing/smoke_test_failure:smoke_test_failure',
  ],
  'dart-host': <String>['//engine/src/flutter:dart_host_tests'],
  'benchmarks': <String>['//engine/src/flutter:benchmarks'],
  'font-subset': <String>['//engine/src/flutter/tools/font_subset:font_subset_test'],
  'impeller': <String>['//engine/src/flutter/impeller:impeller_unittests'],
};

/// The executables run_tests.py's `engine` type runs on Linux
/// (run_cc_tests: the common list, the non-Windows additions, the Linux
/// ones), by the executable's name, which is the GN target's; each is the
/// converted test of that name. The test suite checks the list against the
/// script.
const List<String> runTestsEngineSuites = <String>[
  'assets_unittests',
  'client_wrapper_glfw_unittests',
  'client_wrapper_unittests',
  'common_cpp_core_unittests',
  'common_cpp_unittests',
  'dart_plugin_registrant_unittests',
  'display_list_rendertests',
  'display_list_unittests',
  'embedder_a11y_unittests',
  'embedder_proctable_unittests',
  'embedder_unittests',
  'fml_unittests',
  'geometry_unittests',
  'gpu_surface_unittests',
  'no_dart_plugin_registrant_unittests',
  'runtime_unittests',
  'testing_unittests',
  'tonic_unittests',
  'ui_unittests',
  'android_external_view_embedder_unittests',
  'jni_unittests',
  'platform_view_android_delegate_unittests',
  'shell_unittests',
  'flow_unittests',
  'flutter_glfw_unittests',
  'flutter_linux_unittests',
  'txt_unittests',
];

/// One build of a builder file, read for Bazel.
final class BuilderBuild {
  BuilderBuild._({
    required this.file,
    required this.name,
    required this.gn,
    required this.ninjaTargets,
    required this.archives,
    required this.bazelFlags,
    required this.buildDirectory,
    required this.unsupported,
    required this.otherPlatform,
    required this.testTypes,
    required this.otherTests,
  });

  /// Reads [build] of the builder file [file] (`linux_host_engine.json`).
  factory BuilderBuild.of(String file, Build build) {
    final flags = <String>[];
    final unsupported = <String>[];
    var otherPlatform = false;
    var unoptimized = false;
    var lto = true;
    String? runtimeMode;
    String? buildDirectory;
    final List<String> gn = build.gn;
    for (var i = 0; i < gn.length; i++) {
      String flag = gn[i];
      String? value;
      final int equals = flag.indexOf('=');
      if (equals > 0) {
        value = flag.substring(equals + 1);
        flag = flag.substring(0, equals);
      }
      final GnFlag? known = gnFlags[flag];
      if (known != null && known.takesValue && value == null) {
        if (i + 1 >= gn.length) {
          unsupported.add('$flag (no value)');
          continue;
        }
        value = gn[++i];
      }
      if (known == null) {
        unsupported.add("$flag (not in the converter's table of tools/gn flags)");
        continue;
      }
      switch (known.effect) {
        case GnFlagEffect.runtimeMode:
          runtimeMode = value;
        case GnFlagEffect.unoptimized:
          unoptimized = true;
        case GnFlagEffect.buildDirectory:
          buildDirectory = value;
        case GnFlagEffect.assumed:
          if (flag == '--no-lto') {
            lto = false;
          }
        case GnFlagEffect.ignored:
          break;
        case GnFlagEffect.unsupported:
          unsupported.add('$flag${value == null ? '' : '=$value'} (${known.note})');
        case GnFlagEffect.otherPlatform:
          otherPlatform = true;
      }
    }
    // tools/gn: LTO is on unless --no-lto, and off in unoptimized builds.
    if (lto && !unoptimized) {
      unsupported.add('LTO, which tools/gn enables without --no-lto (${gnFlags['--lto']!.note})');
    }
    flags.add(unoptimized ? '--compilation_mode=fastbuild' : '--compilation_mode=opt');
    flags.add('--$runtimeModeSetting=${runtimeMode ?? 'debug'}');
    // The tests: run_tests.py's types, and every other step by name.
    final testTypes = <String>[];
    final otherTests = <String>[];
    for (final BuildTest test in build.tests) {
      if (!test.script.endsWith('testing/run_tests.py')) {
        otherTests.add(test.name);
        continue;
      }
      final int type = test.parameters.indexOf('--type');
      if (type < 0 || type + 1 >= test.parameters.length) {
        otherTests.add('${test.name} (run_tests.py without --type: every type)');
        continue;
      }
      for (final String t in test.parameters[type + 1].split(',')) {
        if (!testTypes.contains(t)) {
          testTypes.add(t);
        }
      }
    }
    return BuilderBuild._(
      file: file,
      name: build.name,
      gn: gn,
      ninjaTargets: build.ninja.targets,
      archives: <String>[
        for (final BuildArchive archive in build.archives) ...archive.includePaths,
      ],
      bazelFlags: flags,
      buildDirectory: buildDirectory,
      unsupported: unsupported,
      otherPlatform: otherPlatform,
      testTypes: testTypes,
      otherTests: otherTests,
    );
  }

  /// The builder file's name (`linux_host_engine.json`).
  final String file;

  /// The build's name (`ci/host_debug`).
  final String name;

  /// GN's flags as written.
  final List<String> gn;

  /// The ninja targets the build makes.
  final List<String> ninjaTargets;

  /// The archives it uploads, as paths under engine/src/out.
  final List<String> archives;

  /// The Bazel flags its GN flags amount to.
  final List<String> bazelFlags;

  /// GN's `--target-dir`, under engine/src/out.
  final String? buildDirectory;

  /// The flags the Bazel build cannot express, with the reason each.
  final List<String> unsupported;

  /// Whether the build targets another platform than the Linux x64 host.
  final bool otherPlatform;

  /// The types its run_tests.py steps run (`dart`, `engine`, ...).
  final List<String> testTypes;

  /// Its other test steps, by name (scripts a Bazel test does not stand for).
  final List<String> otherTests;

  /// The configuration's name: the build's, without CI's `ci/` prefix.
  String get configName {
    final String bare = name.startsWith('ci/') ? name.substring(3) : name;
    return bare.replaceAll('/', '_');
  }
}

/// The Linux x64 host builds of [configs] (a builder file's name to its
/// configuration), by file and build order.
List<BuilderBuild> linuxHostBuilds(Map<String, BuilderConfig> configs) {
  final builds = <BuilderBuild>[];
  final List<String> files = configs.keys.where((String f) => f.startsWith('linux_')).toList()
    ..sort();
  for (final file in files) {
    for (final Build build in configs[file]!.builds) {
      final read = BuilderBuild.of('$file.json', build);
      if (!read.otherPlatform && read.gn.isNotEmpty) {
        builds.add(read);
      }
    }
  }
  return builds;
}

/// The generated bazelrc: a `--config=<name>` per build whose flags all map.
String configsBazelrc(List<BuilderBuild> builds) {
  final out = StringBuffer()
    ..writeln('# Copyright 2013 The Flutter Authors. All rights reserved.')
    ..writeln('# Use of this source code is governed by a BSD-style license that can be')
    ..writeln('# found in the LICENSE file.')
    ..writeln()
    ..writeln('# Generated from ci/builders/linux_*.json by gn_to_bazel; do not edit.')
    ..writeln('#')
    ..writeln('# Each Linux x64 host build of the builder files as a Bazel configuration:')
    ..writeln("# `bazel build --config=<name> ...` sets what the build's tools/gn flags")
    ..writeln('# set, as far as the Bazel build has settings for them (gnFlags in')
    ..writeln('# tools/gn_to_bazel/lib/src/builders.dart says what each flag amounts to).')
    ..writeln('# A build with a flag the Bazel build cannot express yet is listed with the')
    ..writeln('# reason and gets no configuration; the install target of each build is in')
    ..writeln('# BUILD.bazel beside this file.');
  for (final build in builds) {
    out
      ..writeln()
      ..writeln('# ${build.file}: ${build.name}')
      ..writeln('#   ${build.gn.join(' ')}');
    if (build.unsupported.isNotEmpty) {
      out.writeln('# No configuration: the Bazel build cannot express');
      for (final String reason in build.unsupported) {
        out.writeln('#   $reason');
      }
      continue;
    }
    out.writeln('build:${build.configName} ${build.bazelFlags.join(' ')}');
  }
  return out.toString();
}

/// The generated BUILD file: an `install` per build over the Bazel
/// counterparts of its ninja targets, and a `test_suite` per build with
/// tests over the suites that stand for its run_tests.py types.
/// [convertedTargets] maps each converted GN package
/// (`//flutter/build/archives`) to its targets' names, [convertedTests] to
/// the names of those that are tests.
String buildersBuildFile(
  List<BuilderBuild> builds,
  Map<String, Set<String>> convertedTargets, {
  Map<String, Set<String>> convertedTests = const <String, Set<String>>{},
}) {
  final out = StringBuffer()
    ..writeln('# Copyright 2013 The Flutter Authors. All rights reserved.')
    ..writeln('# Use of this source code is governed by a BSD-style license that can be')
    ..writeln('# found in the LICENSE file.')
    ..writeln()
    ..writeln('# Generated from ci/builders/linux_*.json by gn_to_bazel; do not edit.')
    ..writeln('#')
    ..writeln('# An install target per Linux x64 host build of the builder files, over the')
    ..writeln('# Bazel counterparts of its ninja targets: `bazel run --config=<name> :<name>`')
    ..writeln("# builds what the build builds and lays it into GN's build directory for it")
    ..writeln("# (--target-dir), as the builder's recipe expects to find it. A ninja target")
    ..writeln('# with no Bazel counterpart yet is listed; a build whose configuration the')
    ..writeln('# Bazel build cannot express yet (configs.bazelrc) is built with the flags')
    ..writeln('# of the nearest one; a test executable among the targets is not installed,')
    ..writeln('# since `bazel test` runs tests from their own place. A build with tests has')
    ..writeln('# a <name>_tests suite over the Bazel suites that stand for its run_tests.py')
    ..writeln('# types (runTestsTypeSuites, runTestsEngineSuites in builders.dart):')
    ..writeln('# `bazel test --config=<name> :<name>_tests` runs what the build runs, with')
    ..writeln('# its other test steps (scripts of the checkout) listed. The suites are')
    ..writeln('# manual: each stands for one builder, named; a wildcard run of the tree')
    ..writeln('# has the tests themselves.')
    ..writeln()
    ..writeln('load("//engine/src/flutter/build/bazel:install.bzl", "install")')
    ..writeln()
    ..writeln('package(default_visibility = ["//visibility:public"])')
    ..writeln()
    ..writeln('# The builder files themselves, for the tests of the packages that read')
    ..writeln('# them (//engine/src/flutter/ci:builder_configs).')
    ..writeln('filegroup(')
    ..writeln('    name = "json",')
    ..writeln('    srcs = glob(["**/*.json"]),')
    ..writeln(')');
  for (final build in builds) {
    final resolved = <String>[];
    final missing = <String>[];
    final tests = <String>[];
    for (final String target in build.ninjaTargets) {
      if (_ninjaTargetLabel(target, convertedTests) != null) {
        // A test executable: GN builds it for run_tests.py to run from the
        // build directory; here `bazel test` runs it from its own place
        // (the build's <name>_tests suite), and an install depending on a
        // test would besides put the test in a second, trimmed
        // configuration beside the one `bazel test` analyzes.
        if (!tests.contains(target)) {
          tests.add(target);
        }
        continue;
      }
      final String? label = _ninjaTargetLabel(target, convertedTargets);
      if (label == null) {
        missing.add(target);
      } else if (!resolved.contains(label)) {
        resolved.add(label);
      }
    }
    out
      ..writeln()
      ..writeln('# ${build.file}: ${build.name}');
    if (build.unsupported.isEmpty) {
      out.writeln('#   bazel run --config=${build.configName} :${build.configName}');
    } else {
      out.writeln('#   no configuration (configs.bazelrc); the flags would be:');
      out.writeln('#   ${build.bazelFlags.join(' ')}');
    }
    if (missing.isNotEmpty) {
      out.writeln('# Not built, no Bazel counterpart yet: ${missing.join(', ')}.');
    }
    if (tests.isNotEmpty) {
      out.writeln('# Tests, run by `bazel test` rather than installed: ${tests.join(', ')}.');
    }
    if (resolved.isEmpty) {
      out.writeln('# Nothing to install.');
      _testSuiteInto(out, build, convertedTests);
      continue;
    }
    // A build's ninja targets include its test executables; the install
    // of them is testonly, as anything depending on a test must be.
    out
      ..writeln('install(')
      ..writeln('    name = "${build.configName}",')
      ..writeln('    testonly = True,');
    if (resolved.length == 1) {
      out.writeln('    contents = ["${resolved.single}"],');
    } else {
      out.writeln('    contents = [');
      for (final label in resolved..sort(compareBuildifierStrings)) {
        out.writeln('        "$label",');
      }
      out.writeln('    ],');
    }
    if (build.buildDirectory != null) {
      out.writeln('    directory = "${build.buildDirectory}",');
    }
    out.writeln(')');
    _testSuiteInto(out, build, convertedTests);
  }
  return out.toString();
}

/// `<name>_tests`: the suites of [build]'s run_tests.py types.
void _testSuiteInto(StringBuffer out, BuilderBuild build, Map<String, Set<String>> convertedTests) {
  if (build.testTypes.isEmpty && build.otherTests.isEmpty) {
    return;
  }
  final suites = <String>[];
  final missing = <String>[];
  for (final String type in build.testTypes) {
    if (type == 'engine') {
      for (final String name in runTestsEngineSuites) {
        final String? label = _ninjaTargetLabel(name, convertedTests);
        if (label == null) {
          missing.add('$name (engine)');
        } else if (!suites.contains(label)) {
          suites.add(label);
        }
      }
      continue;
    }
    final List<String>? known = runTestsTypeSuites[type];
    if (known == null) {
      missing.add('the $type type');
      continue;
    }
    for (final String label in known) {
      if (!suites.contains(label)) {
        suites.add(label);
      }
    }
  }
  out.writeln();
  if (build.testTypes.isNotEmpty) {
    out.writeln("# ${build.name}'s tests: run_tests.py --type ${build.testTypes.join(',')}.");
  }
  if (missing.isNotEmpty) {
    out.writeln('# Not run, no Bazel test yet: ${missing.join(', ')}.');
  }
  if (build.otherTests.isNotEmpty) {
    out.writeln('# Other steps, scripts of the checkout: ${build.otherTests.join('; ')}.');
  }
  if (suites.isEmpty) {
    out.writeln('# Nothing to run.');
    return;
  }
  // Manual: a suite stands for one builder's run, invoked by name; a
  // wildcard run of the tree would otherwise run the builders' suites over
  // again, the benchmarks among them, which are manual for a reason.
  out
    ..writeln('test_suite(')
    ..writeln('    name = "${build.configName}_tests",')
    ..writeln('    tags = ["manual"],');
  if (suites.length == 1) {
    out.writeln('    tests = ["${suites.single}"],');
  } else {
    out.writeln('    tests = [');
    for (final label in suites..sort(compareBuildifierStrings)) {
      out.writeln('        "$label",');
    }
    out.writeln('    ],');
  }
  out.writeln(')');
}

/// The Bazel label of a ninja target of a build (`flutter/build/archives:artifacts`,
/// `flutter/tools/font_subset`, `sky_engine`), or null when nothing
/// converted answers to it. GN's ninja targets are labels without the
/// leading `//`, a directory for its target of the same name, or a bare
/// target name when it is unique in the build; a word is a directory
/// before it is a name (`flutter` is `//flutter:flutter`).
String? _ninjaTargetLabel(String target, Map<String, Set<String>> convertedTargets) {
  String gnPackage;
  String name;
  if (target.contains(':')) {
    final int colon = target.indexOf(':');
    gnPackage = '//${target.substring(0, colon)}';
    name = target.substring(colon + 1);
  } else if (target.contains('/') ||
      mainRepositoryLayout.owningPackage('engine/src/$target') == 'engine/src/$target') {
    gnPackage = '//$target';
    name = p.basename(target);
  } else {
    // A bare name: the one converted target of that name, if there is one.
    final candidates = <String>[
      for (final MapEntry<String, Set<String>> entry in convertedTargets.entries)
        if (entry.value.contains(target)) entry.key,
    ];
    if (candidates.length != 1) {
      return null;
    }
    gnPackage = candidates.single;
    name = target;
  }
  if (!(convertedTargets[gnPackage]?.contains(name) ?? false)) {
    return null;
  }
  return bazelLabel('$gnPackage:$name', package: gnPackage);
}
