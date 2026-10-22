// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Linux builds of `ci/builders/*.json` -- the x64 host's own, the web's,
/// the Linux arm64 cross builds' and Android's -- as Bazel configurations and
/// install targets.
///
/// Each builder file describes builds: a `tools/gn` flag list, the ninja
/// targets to build, the archives to upload, the tests to run. The Bazel
/// build has settings for some of what the flags set (the runtime mode, the
/// compilation mode, the target platform) and assumptions for the rest;
/// this module turns each Linux build into a `--config=<name>` of a
/// generated bazelrc (`ci/builders/configs.bazelrc`, which the root
/// `.bazelrc` imports) when every flag maps, and into an `install` target
/// of a generated BUILD file (`ci/builders/BUILD.bazel`) over the Bazel
/// counterparts of its ninja targets, installing into GN's build directory
/// (`--target-dir`, or the directory tools/gn names for the flags). A flag
/// the Bazel build cannot express yet costs the build its configuration,
/// with the reason on record in the generated file; a ninja target with no
/// Bazel counterpart is listed the same way.
library;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:path/path.dart' as p;

import 'bazel_mapping.dart';
import 'gn_eval.dart';
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

  /// `--web`: a target platform the Bazel build has, which the
  /// configuration's `--platforms` names ([GnFlag.bazelFlag]).
  platform,

  /// `--target-os <os>`, `--linux-cpu <cpu>`, `--android`,
  /// `--android-cpu <cpu>`: the target, from which [BuilderBuild.of] decides
  /// the platform (the Linux arm64 cross build and the Android CPUs of
  /// [androidPlatforms] are platforms; an Android CPU without one is a flag
  /// the build cannot express; another OS is out of scope; Linux on the
  /// host's CPU is the host's own build).
  target,

  /// `--lto`/`--no-lto`: whether the optimized build compiles and links
  /// with LTO: the `lto` setting for the clang toolchains (Linux, Android);
  /// the wasm platform's optimized build always has it.
  lto,

  /// `--stripped`/`--no-stripped`: tools/gn's stripped_symbols, whether the
  /// shared libraries a build ships are stripped (executables always are);
  /// the `stripped` setting for the Linux and Android platforms (tools/gn's
  /// default is on, except for Android), nothing for the wasm platform,
  /// whose toolchain strips nothing.
  stripped,

  /// A flag the Bazel build has a setting for ([GnFlag.bazelFlag]).
  setting,

  /// `--gn-args=<name>=<value>`: a setting when [gnArguments] has the
  /// argument, unsupported otherwise.
  gnArgument,

  /// What the generated files assume already (the prebuilt Dart SDK).
  assumed,

  /// Infrastructure, or something a configuration cannot carry (targets).
  ignored,

  /// Something the Bazel build has no setting for yet.
  unsupported,

  /// `--enable-vulkan-validation-layers`: impeller_enable_vulkan_validation_layers
  /// forced on, which GN's default formula (impeller/tools/args.gni) has on
  /// for the debug runtime mode on arm64 already -- the Bazel build follows
  /// the formula (a select() in the Android shell's file) and has no setting
  /// to force it elsewhere: supported where the formula agrees, unsupported
  /// otherwise. (vulkan/config.gni's enable_vulkan_validation_layers, which
  /// the flag sets too, is read by Fuchsia's files alone.)
  validationLayers,

  /// A platform the Bazel build has none for yet (Fuchsia, iOS, macOS,
  /// Windows): the build is out of scope.
  otherPlatform,
}

/// One `tools/gn` flag.
final class GnFlag {
  const GnFlag(
    this.effect, {
    this.takesValue = false,
    this.note,
    this.bazelFlag,
    this.alongside = const <String>[],
  });

  final GnFlagEffect effect;

  /// Whether the flag takes the next argument (or `=value`) as its value.
  final bool takesValue;

  /// Why it is assumed, ignored or unsupported.
  final String? note;

  /// The Bazel flag a [GnFlagEffect.setting] flag amounts to, or the
  /// `--platforms` of a [GnFlagEffect.platform] one.
  final String? bazelFlag;

  /// Bazel options the configuration carries besides [bazelFlag]: what the
  /// setting implies for the run that `tools/gn` has no flag for.
  final List<String> alongside;
}

/// The Bazel platforms a build's flags select: `--web` the wasm platform
/// (build/bazel/toolchains/emscripten), `--target-os=linux --linux-cpu=arm64`
/// the Linux arm64 cross build (build/bazel/toolchains).
const String wasmPlatform =
    '//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten';
const String linuxArm64Platform = '//engine/src/flutter/build/bazel/toolchains:linux_arm64';

/// The Android platforms by tools/gn's `--android-cpu` (all but x86, which
/// has none yet).
const Map<String, String> androidPlatforms = <String, String>{
  'arm': '//engine/src/flutter/build/bazel/toolchains:android_arm',
  'arm64': '//engine/src/flutter/build/bazel/toolchains:android_arm64',
  'riscv64': '//engine/src/flutter/build/bazel/toolchains:android_riscv64',
  'x64': '//engine/src/flutter/build/bazel/toolchains:android_x64',
};

/// tools/gn's `--android-cpu` choices, and its default.
const List<String> androidCpus = <String>['arm', 'x64', 'x86', 'arm64', 'riscv64'];
const String defaultAndroidCpu = 'arm';

/// The `tools/gn` flags of the Linux builder files, as far as they appear.
const Map<String, GnFlag> gnFlags = <String, GnFlag>{
  '--runtime-mode': GnFlag(GnFlagEffect.runtimeMode, takesValue: true),
  '--unoptimized': GnFlag(GnFlagEffect.unoptimized),
  // argparse takes a flag's unambiguous prefix; local_engine.json writes this one.
  '--unopt': GnFlag(GnFlagEffect.unoptimized),
  // tools/gn: stripped_symbols is on unless --no-stripped (local_engine.json's
  // developer builds), and off for Android. GN's Linux toolchains strip every
  // executable regardless and shared libraries under it (gcc_toolchain.gni);
  // the wasm toolchain strips nothing.
  '--stripped': GnFlag(GnFlagEffect.stripped),
  '--no-stripped': GnFlag(GnFlagEffect.stripped),
  '--xcode-symlinks': GnFlag(GnFlagEffect.ignored, note: 'a macOS build directory matter'),
  '--target-dir': GnFlag(GnFlagEffect.buildDirectory, takesValue: true),
  '--prebuilt-dart-sdk': GnFlag(
    GnFlagEffect.assumed,
    note: 'flutter_prebuilt_dart_sdk is true in every generated file',
  ),
  '--no-prebuilt-dart-sdk': GnFlag(
    GnFlagEffect.unsupported,
    note: 'the generated files assume the prebuilt Dart SDK',
  ),
  // tools/gn: LTO is on unless --no-lto, and off in unoptimized builds.
  // Whether the Bazel build can follow is the platform's (BuilderBuild.of).
  '--no-lto': GnFlag(GnFlagEffect.lto),
  '--lto': GnFlag(GnFlagEffect.lto),
  '--rbe': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--no-rbe': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--goma': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--no-goma': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--build-embedder-examples': GnFlag(
    GnFlagEffect.ignored,
    note: 'adds targets to the build, which a configuration cannot name',
  ),
  // flutter_use_fontconfig and skia_use_fontconfig at once: the flag in
  // //flutter/txt's appendix (conditionSettings).
  '--enable-fontconfig': GnFlag(
    GnFlagEffect.setting,
    bazelFlag: '--//engine/src/flutter/txt:use_fontconfig',
  ),
  // build/config/sanitizers' is_asan: the build-wide flag, which the
  // toolchain's asan feature and the wrapped GN builds select() on, and
  // under which the test launchers export CI's sanitizer environment. An
  // instrumented build's tests, on a Debug VM, run several times slower
  // than the sizes the test targets declare allow for; run_tests.py has no
  // per-test timeout, so the configuration gives each size four times
  // Bazel's default (measured: the suites that overran their 60 s and 300 s
  // in a loaded run pass in 59 s, 180 s and 254 s alone).
  '--asan': GnFlag(
    GnFlagEffect.setting,
    bazelFlag: '--//engine/src/flutter/build/bazel:asan',
    alongside: <String>['--test_timeout=240,1200,3600,14400'],
  ),
  // runtime_args.gni's dart_debug: the wrap's flag (build/bazel/dart_wrap),
  // which @dart//:dart_config follows for the engine's own file under it.
  '--dart-debug': GnFlag(
    GnFlagEffect.setting,
    bazelFlag: '--//engine/src/flutter/build/bazel/dart_wrap:dart_debug',
  ),
  // GN: glfw_vulkan_library, which puts SwiftShader, the Vulkan loader and
  // the validation layers beside impeller_unittests; the Bazel suites always
  // carry the wrapped backends (gpuBackendTests).
  '--use-glfw-swiftshader': GnFlag(
    GnFlagEffect.assumed,
    note: 'the Impeller suites always run on the wrapped SwiftShader and loader here',
  ),
  // runtime_args.gni's dart_disable_secure_socket (the size-experiment
  // builders): the Dart wrap's flag, which the archives' names read too
  // (`-size-exp`).
  '--no-dart-secure-socket': GnFlag(
    GnFlagEffect.setting,
    bazelFlag: '--//engine/src/flutter/build/bazel/dart_wrap:dart_disable_secure_socket',
  ),
  '--enable-vulkan-validation-layers': GnFlag(GnFlagEffect.validationLayers),
  // An arbitrary GN argument; the ones the builders pass are in gnArguments.
  '--gn-args': GnFlag(GnFlagEffect.gnArgument, takesValue: true, note: 'an arbitrary GN argument'),
  '--android': GnFlag(GnFlagEffect.target),
  '--android-cpu': GnFlag(GnFlagEffect.target, takesValue: true),
  '--fuchsia': GnFlag(GnFlagEffect.otherPlatform),
  '--fuchsia-cpu': GnFlag(GnFlagEffect.otherPlatform, takesValue: true),
  '--ios': GnFlag(GnFlagEffect.otherPlatform),
  '--mac': GnFlag(GnFlagEffect.otherPlatform),
  // tools/gn's --web: target_os wasm, the web build's GN arguments
  // (to_gn_wasm_args), which the wasm platform's flags carry.
  '--web': GnFlag(GnFlagEffect.platform, bazelFlag: '--platforms=$wasmPlatform'),
  '--windows': GnFlag(GnFlagEffect.otherPlatform),
  '--target-os': GnFlag(GnFlagEffect.target, takesValue: true),
  '--linux-cpu': GnFlag(GnFlagEffect.target, takesValue: true),
  '--embedder-for-target': GnFlag(GnFlagEffect.otherPlatform),
};

/// The `--gn-args=<name>=<value>` arguments the builder files pass, as the
/// Bazel flags they amount to; any other is unsupported.
const Map<String, String> gnArguments = <String, String>{
  // runtime_args.gni's dart_dynamic_modules: the Dart wrap's flag, which the
  // archives' names read too (the `_ddm` builders).
  'dart_dynamic_modules=true': '--//engine/src/flutter/build/bazel/dart_wrap:dart_dynamic_modules',
};

/// The runtime mode setting of the Bazel build.
const String runtimeModeSetting = '//engine/src/flutter/common:runtime_mode';

/// The stripped setting of the Bazel build (build/bazel/BUILD.bazel): whether
/// the shared libraries an install or an archive ships are stripped.
const String strippedSetting = '//engine/src/flutter/build/bazel:stripped';

/// The LTO setting of the Bazel build (build/bazel/BUILD.bazel): -flto on
/// the compiles and links of an optimized build.
const String ltoSetting = '//engine/src/flutter/build/bazel:lto';

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
    required this.platform,
    required this.unsupported,
    required this.otherPlatform,
    required this.testTypes,
    required this.binaryTests,
    required this.otherTests,
  }) : configName = bareName(name);

  /// Reads [build] of the builder file [file] (`linux_host_engine.json`).
  factory BuilderBuild.of(String file, Build build) {
    final flags = <String>[];
    final settings = <String>[];
    final unsupported = <String>[];
    var otherPlatform = false;
    var unoptimized = false;
    var lto = true;
    bool? stripped;
    String? runtimeMode;
    String? buildDirectory;
    String? platform;
    String? targetOs;
    String? linuxCpu;
    String? androidCpu;
    var validationLayers = false;
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
        case GnFlagEffect.platform:
          platform = known.bazelFlag;
        case GnFlagEffect.target:
          switch (flag) {
            case '--target-os':
              targetOs = value;
            case '--android':
              targetOs = 'android';
            case '--android-cpu':
              androidCpu = value;
            default:
              linuxCpu = value;
          }
        case GnFlagEffect.lto:
          lto = flag == '--lto';
        case GnFlagEffect.stripped:
          stripped = flag == '--stripped';
        case GnFlagEffect.setting:
          final String setting = known.bazelFlag! + (value == null ? '' : '=$value');
          for (final option in <String>[setting, ...known.alongside]) {
            if (!settings.contains(option)) {
              settings.add(option);
            }
          }
        case GnFlagEffect.gnArgument:
          final String? argument = gnArguments[value];
          if (argument == null) {
            unsupported.add('$flag=$value (${known.note})');
          } else if (!settings.contains(argument)) {
            settings.add(argument);
          }
        case GnFlagEffect.assumed:
        case GnFlagEffect.ignored:
          break;
        case GnFlagEffect.unsupported:
          unsupported.add('$flag${value == null ? '' : '=$value'} (${known.note})');
        case GnFlagEffect.validationLayers:
          validationLayers = true;
        case GnFlagEffect.otherPlatform:
          otherPlatform = true;
      }
    }
    // --enable-vulkan-validation-layers: where GN's default formula has the
    // layer already (the debug runtime mode on Android arm64), the flag
    // changes nothing the Bazel build reads; elsewhere it would force a
    // value the build cannot (GnFlagEffect.validationLayers).
    if (validationLayers &&
        !(targetOs == 'android' &&
            (androidCpu ?? defaultAndroidCpu) == 'arm64' &&
            (runtimeMode ?? 'debug') == 'debug')) {
      unsupported.add(
        "--enable-vulkan-validation-layers (the Bazel build packs the layer where GN's default "
        'formula has it, the debug runtime mode on arm64, and has no setting to force it elsewhere)',
      );
    }
    // The target: --target-os=linux --linux-cpu=arm64 is the Linux arm64
    // cross build, a platform of the Bazel build (tools/gn counts it a host
    // build: the prebuilt Dart SDK is the target's); --target-os=linux on
    // the host's CPU is the host's own build; --android --android-cpu=arm64
    // is the Android arm64 platform, and another Android CPU (tools/gn's
    // default is arm) a platform the Bazel build has not got yet, which
    // costs the build its configuration; any other OS, or Linux CPU, is out
    // of scope.
    if (targetOs == 'android') {
      final String cpu = androidCpu ?? defaultAndroidCpu;
      final String? androidPlatform = androidPlatforms[cpu];
      if (androidPlatform != null) {
        platform = '--platforms=$androidPlatform';
      } else {
        unsupported.add(
          '--android-cpu=$cpu${androidCpu == null ? " (tools/gn's default)" : ''} '
          '(the Bazel build has Android ${androidPlatforms.keys.join(' and ')} platforms only)',
        );
      }
    } else if (targetOs != null && targetOs != 'linux') {
      otherPlatform = true;
    } else if (linuxCpu == 'arm64') {
      platform = '--platforms=$linuxArm64Platform';
    } else if (linuxCpu != null && linuxCpu != 'x64') {
      otherPlatform = true;
    }
    // tools/gn: LTO is on unless --no-lto, and off in unoptimized builds.
    // An optimized build with it (the Android AOT builders) sets the `lto`
    // setting of the clang toolchains; the wasm platform links the
    // optimized build with LTO, as GN's web build does, and has no setting
    // that turns it off.
    final wasm = platform == '--platforms=$wasmPlatform';
    if (!unoptimized && lto && !wasm) {
      settings.add('--$ltoSetting');
    } else if (!unoptimized && !lto && wasm) {
      unsupported.add('--no-lto (the wasm platform links the optimized build with LTO)');
    }
    // tools/gn: stripped_symbols is on unless --no-stripped, except for
    // Android, where it is off unless --stripped (the build directory's
    // libflutter.so is the unstripped one; the Android toolchain's strip step
    // writes lib.stripped/ beside it). The Linux and Android toolchains strip
    // what they ship (executables always, shared libraries under the
    // setting); the wasm toolchain strips nothing, so for the web the flag
    // is nothing either way.
    stripped ??= targetOs != 'android';
    if (!stripped && !wasm) {
      settings.add('--$strippedSetting=false');
    }
    flags.add(unoptimized ? '--compilation_mode=fastbuild' : '--compilation_mode=opt');
    flags.add('--$runtimeModeSetting=${runtimeMode ?? 'debug'}');
    if (platform != null) {
      flags.add(platform);
    }
    flags.addAll(settings);
    // The tests: run_tests.py's types, the test executables a step runs
    // from the build directory, and every other step by name.
    final testTypes = <String>[];
    final binaryTests = <String>[];
    final otherTests = <String>[];
    final String? outPrefix = buildDirectory == null ? null : 'out/$buildDirectory/';
    for (final BuildTest test in build.tests) {
      if (outPrefix != null && test.script.startsWith(outPrefix)) {
        binaryTests.add(test.script.substring(outPrefix.length));
        continue;
      }
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
      platform: platform,
      unsupported: unsupported,
      otherPlatform: otherPlatform,
      testTypes: testTypes,
      binaryTests: binaryTests,
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

  /// The `--platforms` of a build for another platform than the host's own
  /// (`--web`: [wasmPlatform]; `--target-os=linux --linux-cpu=arm64`:
  /// [linuxArm64Platform]; `--android --android-cpu=<cpu>`:
  /// [androidPlatforms]); null for the host's own build.
  final String? platform;

  /// The flags the Bazel build cannot express, with the reason each.
  final List<String> unsupported;

  /// Whether the build targets a platform the Bazel build has none for yet.
  final bool otherPlatform;

  /// The types its run_tests.py steps run (`dart`, `engine`, ...).
  final List<String> testTypes;

  /// The test executables its steps run directly from the build directory
  /// (`out/<dir>/licenses_cpp_testrunner`), by name: each a Bazel test.
  final List<String> binaryTests;

  /// Its other test steps, by name (scripts a Bazel test does not stand for).
  final List<String> otherTests;

  /// The configuration's name, and the install target's and the test
  /// suite's: the build's without CI's `ci/` prefix or local_engine.json's
  /// `linux/` (`host_debug` for both `ci/host_debug` and `linux/host_debug`,
  /// which set the same flags) -- unless a CI build's flags differ from the
  /// developer's build of the same bare name, in which case the developer's
  /// keeps the name `et build --config <name>` knows and CI's keeps its
  /// prefix as GN's build directory does: `ci_host_debug_unopt`
  /// (`out/ci/host_debug_unopt`: asan and a Debug VM) beside
  /// `host_debug_unopt` (`out/host_debug_unopt`). [linuxHostBuilds] decides
  /// that once every build is read.
  String configName;

  /// [name] without its `ci/` or `linux/` prefix, `/` as `_`.
  static String bareName(String name) {
    final String bare = name.startsWith('ci/')
        ? name.substring(3)
        : name.startsWith('linux/')
        ? name.substring(6)
        : name;
    return bare.replaceAll('/', '_');
  }
}

/// The Linux builds of [configs] (a builder file's name to its
/// configuration), by file and build order: the `linux_*.json` files' builds
/// that target the host, the web, Linux arm64 or Android, and
/// local_engine.json's `linux/` builds -- the developer's configurations,
/// which `et build --config <name>` runs.
List<BuilderBuild> linuxBuilds(Map<String, BuilderConfig> configs) {
  final builds = <BuilderBuild>[];
  final List<String> files =
      configs.keys.where((String f) => f.startsWith('linux_') || f == 'local_engine').toList()
        ..sort();
  for (final file in files) {
    for (final Build build in configs[file]!.builds) {
      if (file == 'local_engine' && !build.name.startsWith('linux/')) {
        continue;
      }
      final read = BuilderBuild.of('$file.json', build);
      if (!read.otherPlatform && read.gn.isNotEmpty) {
        builds.add(read);
      }
    }
  }
  // A CI build with the developer's name and other flags keeps its `ci/`.
  final developers = <String, BuilderBuild>{
    for (final build in builds)
      if (build.file == 'local_engine.json') build.configName: build,
  };
  for (final build in builds) {
    final BuilderBuild? developer = developers[build.configName];
    if (build.name.startsWith('ci/') &&
        developer != null &&
        developer.bazelFlags.join(' ') != build.bazelFlags.join(' ')) {
      build.configName = 'ci_${build.configName}';
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
    ..writeln("# Each Linux build of the builder files -- the x64 host's own, the web's, the")
    ..writeln("# Linux arm64 cross builds' and Android's -- as a Bazel configuration: `bazel")
    ..writeln("# build --config=<name> ...` sets what the build's tools/gn flags set, as far")
    ..writeln('# as the Bazel build has settings for them (gnFlags in')
    ..writeln('# tools/gn_to_bazel/lib/src/builders.dart says what each flag amounts to;')
    ..writeln('# --web is the wasm platform, --target-os=linux --linux-cpu=arm64 the Linux')
    ..writeln('# arm64 one, --android --android-cpu=arm64 the Android arm64 one). A build')
    ..writeln('# with a flag the Bazel build cannot express yet is listed with')
    ..writeln('# the reason and gets no configuration; the install target of each build is')
    ..writeln('# in BUILD.bazel beside this file.');
  // A name may be two builds' (CI's ci/host_debug and the developer's
  // linux/host_debug): one configuration, if they set the same flags.
  final written = <String, BuilderBuild>{};
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
    final BuilderBuild? earlier = written[build.configName];
    if (earlier != null) {
      if (earlier.bazelFlags.join(' ') != build.bazelFlags.join(' ')) {
        throw FormatException(
          "${build.file}'s ${build.name} and ${earlier.file}'s ${earlier.name} would both be "
          '--config=${build.configName} with different flags: ${build.bazelFlags.join(' ')} '
          'against ${earlier.bazelFlags.join(' ')}',
        );
      }
      out.writeln("# The same configuration as ${earlier.file}'s ${earlier.name}, above.");
      continue;
    }
    written[build.configName] = build;
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
    ..writeln("# An install target per Linux build of the builder files (the x64 host's own,")
    ..writeln("# the web's, the Linux arm64 cross builds' and Android's), over the Bazel")
    ..writeln('# counterparts of its ninja targets: `bazel run --config=<name> :<name>` builds')
    ..writeln("# what the build builds and lays it into GN's build directory for it")
    ..writeln('# (--target-dir, or the directory tools/gn names for the flags), as the')
    ..writeln("# builder's recipe expects to find it. A ninja target with no Bazel")
    ..writeln('# counterpart yet is listed; a build whose configuration the Bazel build')
    ..writeln('# cannot express yet (configs.bazelrc) is built with the flags of the nearest')
    ..writeln('# one; a test executable among the targets is not installed, since `bazel')
    ..writeln('# test` runs tests from their own place. A build with tests has a <name>_tests')
    ..writeln('# suite over the Bazel suites that stand for its run_tests.py types')
    ..writeln('# (runTestsTypeSuites, runTestsEngineSuites in builders.dart): `bazel test')
    ..writeln('# --config=<name> :<name>_tests` runs what the build runs, with its other test')
    ..writeln('# steps (scripts of the checkout) listed. The suites are manual: each stands')
    ..writeln('# for one builder, named; a wildcard run of the tree has the tests themselves.')
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
  // A name may be two builds' (CI's ci/wasm_release and the developer's
  // linux/wasm_release, one configuration): one install and one suite, if
  // they build and run the same.
  final installs = <String, (BuilderBuild, String)>{};
  final suites = <String, (BuilderBuild, String)>{};
  for (final build in builds) {
    final resolved = <String>[];
    final missing = <String>[];
    final tests = <String>[];
    for (final String target in build.ninjaTargets) {
      // A build output named by its path (`clang_x64/gen_snapshot`, the AOT
      // builders' host gen_snapshot): the target that produces it, when the
      // build-output table has it.
      final String? output = buildOutputLabels['$buildDirRoot/$target'];
      if (output != null) {
        if (!resolved.contains(output)) {
          resolved.add(output);
        }
        continue;
      }
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
    if (build.ninjaTargets.isEmpty) {
      // GN's default target: the whole build, which the root package's
      // install lays out.
      out.writeln(
        "#   ninja's default target, everything: "
        'bazel run --config=${build.configName} //engine/src/flutter:install',
      );
      continue;
    }
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
      _testSuiteInto(out, build, convertedTests, suites);
      continue;
    }
    resolved.sort(compareBuildifierStrings);
    final install = '${resolved.join(' ')} into ${build.buildDirectory ?? 'the variant'}';
    final (BuilderBuild, String)? earlier = installs[build.configName];
    if (earlier != null) {
      if (earlier.$2 != install) {
        throw FormatException(
          "${build.file}'s ${build.name} and ${earlier.$1.file}'s ${earlier.$1.name} would both be "
          'the install :${build.configName} with different contents: $install against ${earlier.$2}',
        );
      }
      out.writeln("# The same install as ${earlier.$1.file}'s ${earlier.$1.name}, above.");
      _testSuiteInto(out, build, convertedTests, suites);
      continue;
    }
    installs[build.configName] = (build, install);
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
      for (final label in resolved) {
        out.writeln('        "$label",');
      }
      out.writeln('    ],');
    }
    if (build.buildDirectory != null) {
      out.writeln('    directory = "${build.buildDirectory}",');
    }
    out.writeln(')');
    _testSuiteInto(out, build, convertedTests, suites);
  }
  return out.toString();
}

/// `<name>_tests`: the suites of [build]'s run_tests.py types. [written]
/// has the suites written so far by name: a second build of a name gets a
/// note instead, when it runs the same.
void _testSuiteInto(
  StringBuffer out,
  BuilderBuild build,
  Map<String, Set<String>> convertedTests,
  Map<String, (BuilderBuild, String)> written,
) {
  if (build.testTypes.isEmpty && build.binaryTests.isEmpty && build.otherTests.isEmpty) {
    return;
  }
  final suites = <String>[];
  final missing = <String>[];
  for (final String name in build.binaryTests) {
    final String? label = _ninjaTargetLabel(name, convertedTests);
    if (label == null) {
      missing.add('$name (run from the build directory)');
    } else if (!suites.contains(label)) {
      suites.add(label);
    }
  }
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
  if (build.binaryTests.isNotEmpty) {
    out.writeln(
      "# ${build.name}'s tests run from the build directory: ${build.binaryTests.join(', ')}.",
    );
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
  suites.sort(compareBuildifierStrings);
  final (BuilderBuild, String)? earlier = written[build.configName];
  if (earlier != null) {
    if (earlier.$2 != suites.join(' ')) {
      throw FormatException(
        "${build.file}'s ${build.name} and ${earlier.$1.file}'s ${earlier.$1.name} would both be "
        'the suite :${build.configName}_tests with different tests: ${suites.join(' ')} '
        'against ${earlier.$2}',
      );
    }
    out.writeln("# The same suite as ${earlier.$1.file}'s ${earlier.$1.name}, above.");
    return;
  }
  written[build.configName] = (build, suites.join(' '));
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
    for (final label in suites) {
      out.writeln('        "$label",');
    }
    out.writeln('    ],');
  }
  out.writeln(')');
}

/// The Bazel label of a ninja target of a build (`flutter/build/archives:artifacts`,
/// `flutter/tools/font_subset`, `sky_engine`, `clang_x64/gen_snapshot`), or
/// null when nothing converted answers to it. GN's ninja targets are labels
/// without the leading `//`, a directory for its target of the same name, a
/// bare target name when it is unique in the build, an output's path under
/// the build directory, or ninja's `default`; a word is a directory before
/// it is a name (`flutter` is `//flutter:flutter`).
String? _ninjaTargetLabel(String target, Map<String, Set<String>> convertedTargets) {
  // ninja's `default` is every target of the GN build (the root BUILD.gn
  // has no group of that name); the root group `flutter` -- what `ninja
  // flutter` builds, and all the artifacts a build lays -- stands for it.
  if (target == 'default') {
    target = 'flutter';
  }
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
