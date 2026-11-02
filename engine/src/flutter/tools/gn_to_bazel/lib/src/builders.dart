// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Linux and Mac builds of `ci/builders/*.json` -- the Linux x64 host's
/// own, the web's, the Linux arm64 cross builds', Android's, and the Mac's
/// (its host builds for either CPU and its `--mac` builds) -- as Bazel
/// configurations and install targets.
///
/// Each builder file describes builds: a `tools/gn` flag list, the ninja
/// targets to build, the archives to upload, the tests to run. The Bazel
/// build has settings for some of what the flags set (the runtime mode, the
/// compilation mode, the target platform) and assumptions for the rest;
/// this module turns each build into a `--config=<name>` of a
/// generated bazelrc (`ci/builders/configs.bazelrc`, which the root
/// `.bazelrc` imports) when every flag maps, and into an `install` target
/// of a generated BUILD file (`ci/builders/BUILD.bazel`) over the Bazel
/// counterparts of its ninja targets, installing into GN's build directory
/// (`--target-dir`, or the directory tools/gn names for the flags). A flag
/// the Bazel build cannot express yet costs the build its configuration,
/// with the reason on record in the generated file; a ninja target with no
/// Bazel counterpart is listed the same way.
///
/// The Mac's builds (the `mac_*.json` files and local_engine.json's `macos/`
/// builds) are always a platform of the Bazel build: GN's `--mac-cpu` names
/// the CPU a Mac builds for, x64 unless given, rather than the Mac's own --
/// a Mac's `host_debug` is an x64 build on an arm64 bot -- so each gets
/// `--platforms` for its CPU, where a Linux host build gets none. A Mac
/// build with a Linux build's name is the same configuration when its
/// flags, ninja targets and tests are the same (the web's `wasm_release`,
/// the developer's Android builds) and keeps its OS otherwise:
/// `mac_host_debug`, the configuration, the install and the suite alike.
library;

import 'dart:convert';

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

  /// `--unoptimized`: `-c dbg`, GN's `is_debug` build (`-O0 -g2`); its
  /// absence is `-c opt`. (Bazel's default mode, fastbuild, is -O0 with line
  /// tables only, which no GN build is: a configuration names dbg so that
  /// a developer's host_debug_unopt debugs as GN's does.)
  unoptimized,

  /// `--target-dir <dir>`: the build directory under engine/src/out.
  buildDirectory,

  /// `--web`: a target platform the Bazel build has, which the
  /// configuration's `--platforms` names ([GnFlag.bazelFlag]).
  platform,

  /// `--target-os <os>`, `--linux-cpu <cpu>`, `--android`,
  /// `--android-cpu <cpu>`, `--mac`, `--mac-cpu <cpu>`: the target, from
  /// which [BuilderBuild.of] decides the platform (the Linux arm64 cross
  /// build, the Android CPUs of [androidPlatforms] and the Mac's CPUs of
  /// [macosPlatforms] are platforms; an Android CPU without one is a flag
  /// the build cannot express; another OS is out of scope; Linux on the
  /// host's CPU is the host's own build; a Mac's host build is the
  /// platform of its `--mac-cpu`, x64 unless given).
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

  /// A platform the Bazel build has none for yet (Fuchsia, iOS, Windows):
  /// the build is out of scope.
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
/// the Linux arm64 cross build (build/bazel/toolchains), and the Linux
/// host's own for a host build on Linux. Each is the base of its runtime
/// modes' platforms (`<platform>_<mode>`, build_defs/config/platforms.bzl:
/// the mode as a platform flag, so that every mode's outputs have a
/// directory of their own, as GN's build directories are per mode); a
/// configuration names the mode's platform ([runtimeModePlatform]).
const String wasmPlatform =
    '//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten';
const String linuxArm64Platform = '//engine/src/flutter/build/bazel/toolchains:linux_arm64';
const String linuxX64Platform = '//engine/src/flutter/build/bazel/toolchains:linux_x64';

/// The platform of [platform]'s runtime [mode]: `<platform>_<mode>`
/// (platforms.bzl's runtime_mode_platforms).
String runtimeModePlatform(String platform, String mode) => '${platform}_$mode';

/// The Android platforms by tools/gn's `--android-cpu` (all but x86, which
/// has none yet).
const Map<String, String> androidPlatforms = <String, String>{
  'arm': '//engine/src/flutter/build/bazel/toolchains:android_arm',
  'arm64': '//engine/src/flutter/build/bazel/toolchains:android_arm64',
  'riscv64': '//engine/src/flutter/build/bazel/toolchains:android_riscv64',
  'x64': '//engine/src/flutter/build/bazel/toolchains:android_x64',
};

/// The macOS platforms by tools/gn's `--mac-cpu` (build/bazel/toolchains:
/// the macOS toolchains, research/20): a Mac's `--mac` builds and its host
/// builds alike, since tools/gn's target CPU for a Mac host build is
/// `--mac-cpu` (x64 unless given), not the Mac's own.
const Map<String, String> macosPlatforms = <String, String>{
  'arm64': '//engine/src/flutter/build/bazel/toolchains:macos_arm64',
  'x64': '//engine/src/flutter/build/bazel/toolchains:macos_x64',
};

/// tools/gn's `--mac-cpu` default.
const String defaultMacCpu = 'x64';

/// The iOS platforms (build/bazel/toolchains: the iOS toolchains,
/// research/21): a device's, and the simulator's by tools/gn's
/// `--simulator-cpu` (x64 unless given).
const String iosDevicePlatform = '//engine/src/flutter/build/bazel/toolchains:ios_arm64';
const Map<String, String> iosSimulatorPlatforms = <String, String>{
  'arm64': '//engine/src/flutter/build/bazel/toolchains:ios_sim_arm64',
  'x64': '//engine/src/flutter/build/bazel/toolchains:ios_sim_x64',
};

/// tools/gn's `--simulator-cpu` default.
const String defaultSimulatorCpu = 'x64';

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
    note: "the default: the Dart wrap's flutter_prebuilt_dart_sdk setting is on",
  ),
  // common/config.gni's flutter_prebuilt_dart_sdk off: the Dart wrap's
  // setting (build/bazel/dart_wrap), under which the host's own build
  // compiles the Dart SDK from the synced tree and runs the kernel compiles
  // with its frontend server (ci/host_debug_no_prebuilt_dart_sdk).
  '--no-prebuilt-dart-sdk': GnFlag(
    GnFlagEffect.setting,
    bazelFlag: '--//engine/src/flutter/build/bazel/dart_wrap:flutter_prebuilt_dart_sdk=false',
  ),
  // tools/gn: LTO is on unless --no-lto, and off in unoptimized builds.
  // Whether the Bazel build can follow is the platform's (BuilderBuild.of).
  '--no-lto': GnFlag(GnFlagEffect.lto),
  '--lto': GnFlag(GnFlagEffect.lto),
  '--rbe': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--no-rbe': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--goma': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  '--no-goma': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
  // tools/gn --bazel: the build runs under Bazel through the unchanged recipe
  // (build/bazel/ci.md); the configuration is the one the other flags name.
  '--bazel': GnFlag(GnFlagEffect.ignored, note: 'where the build runs'),
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
  // iOS: --ios is target_os ios (a device, arm64), --simulator the
  // simulator (--simulator-cpu its CPU, x64 unless given): the iOS
  // platforms (research/21).
  '--ios': GnFlag(GnFlagEffect.target),
  '--simulator': GnFlag(GnFlagEffect.target),
  '--simulator-cpu': GnFlag(GnFlagEffect.target, takesValue: true),
  // darwin_extension_safe: tools/gn names the build directory
  // `_extension_safe` and passes the argument, which no GN file reads (the
  // iOS framework is built app-extension-safe always:
  // //build/config/ios:ios_application_extension); the build is its
  // counterpart's, under another configuration name.
  '--darwin-extension-safe': GnFlag(
    GnFlagEffect.assumed,
    note: 'the iOS framework is app-extension-safe in every build; the same build under this name',
  ),
  // The Mac: --mac is target_os mac, --mac-cpu the CPU of a --mac build and
  // of a Mac's host build (tools/gn's get_target_cpu).
  '--mac': GnFlag(GnFlagEffect.target),
  '--mac-cpu': GnFlag(GnFlagEffect.target, takesValue: true),
  // tools/gn's --web: target_os wasm, the web build's GN arguments
  // (to_gn_wasm_args), which the wasm platform's flags carry.
  '--web': GnFlag(GnFlagEffect.platform, bazelFlag: '--platforms=$wasmPlatform'),
  '--windows': GnFlag(GnFlagEffect.otherPlatform),
  '--target-os': GnFlag(GnFlagEffect.target, takesValue: true),
  '--linux-cpu': GnFlag(GnFlagEffect.target, takesValue: true),
  // The embedder API's library for the target too (embedder.gni's
  // embedder_for_target), a setting; ci/android_embedder_debug_unopt's flag.
  '--embedder-for-target': GnFlag(
    GnFlagEffect.setting,
    bazelFlag: '--//engine/src/flutter/build/bazel:embedder_for_target',
  ),
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
/// `font-subset` font-subset's test, `impeller` the Impeller suite alone,
/// `java` the Android embedding's Robolectric tests (run_java_tests: Gradle in
/// shell/platform/android/test_runner over the build's flutter.jar; the
/// Bazel suite runs the same classes under an Android configuration,
/// build_defs/java/robolectric.bzl), `objc` the iOS embedding's XCTest run
/// (run_objc_tests: xcodebuild over testing/ios/IosUnitTests on a simulator,
/// against the build's libios_test_flutter.dylib and Flutter.framework;
/// build_defs/testing/ios_xctest.bzl), `impeller-golden` the golden suite as
/// run_impeller_golden_tests runs it (a Mac's: `--working_dir` into the
/// test's own directory, the Metal and Vulkan validation environments, ANGLE
/// and SwiftShader beside it -- testRuns; the Skia Gold comparison that
/// follows is CI's step, which no Bazel test makes). `engine` is
/// [runTestsEngineSuites], resolved among the converted targets.
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
  'impeller-golden': <String>['//engine/src/flutter/impeller/golden_tests:impeller_golden_tests'],
  'java': <String>['//engine/src/flutter/shell/platform/android:java_tests'],
  'objc': <String>['//engine/src/flutter/testing/ios:ios_unit_tests'],
};

/// The test steps that run a script of the checkout (not run_tests.py, not
/// an executable of the build directory), by the step's script path as the
/// builder file writes it, each as the Bazel test that runs the same thing:
/// tools/gn's unit tests, the GeneratedPluginRegistrant.java ban and its
/// test, the builder files' check, the VM service protocol test over
/// flutter_tester. A step whose script is not here is listed in the
/// generated file as a step the Bazel build has no test for.
const Map<String, String> checkoutScriptTests = <String, String>{
  'flutter/tools/gn_test.py': '//engine/src/flutter:gn_test',
  'flutter/ci/ban_generated_plugin_registrant_java.sh':
      '//engine/src/flutter/ci:ban_generated_plugin_registrant_java',
  'flutter/ci/test/ban_generated_plugin_registrant_java_test.sh':
      '//engine/src/flutter/ci:ban_generated_plugin_registrant_java_test',
  'flutter/ci/check_build_configs.sh':
      '//engine/src/flutter/tools/pkg/engine_build_configs:check_build_configs',
  'flutter/shell/testing/vm_service/test.dart':
      '//engine/src/flutter/shell/testing/vm_service:service_protocol_test',
  // The iOS scenario app's integration tests (xcodebuild over the project
  // the build copies into the build directory, on a simulator).
  'flutter/testing/ios_scenario_app/run_ios_tests.sh':
      '//engine/src/flutter/testing/ios_scenario_app:ios_scenario_tests',
};

/// The executables run_tests.py's `engine` type runs on Linux
/// (run_cc_tests: the common list, the non-Windows additions, the Linux
/// ones), by the executable's name, which is the GN target's; each is the
/// converted test of that name. The test suite checks the list against the
/// script. [runTestsEngineSuitesMac] is the Mac's.
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

/// The executables run_tests.py's `engine` type runs on a Mac (run_cc_tests:
/// the common list, the non-Windows additions, the Objective-C ones,
/// flow_unittests without the golden test, then the Swift and Darwin desktop
/// suites and the Impeller suites run by name -- impeller_unittests twice,
/// with the Metal validation environment, and the Flutter GPU suite).
const List<String> runTestsEngineSuitesMac = <String>[
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
  'accessibility_unittests',
  'availability_version_check_unittests',
  'framework_common_swift_unittests',
  'framework_common_unittests',
  'spring_animation_unittests',
  'flow_unittests',
  'flutter_desktop_darwin_swift_unittests',
  'flutter_desktop_darwin_unittests',
  'impeller_unittests',
  'impeller_dart_unittests',
];

/// The flags naming a platform the Bazel build has none for, as against
/// their qualifiers.
const Set<String> _otherPlatformOsFlags = <String>{'--fuchsia', '--ios', '--windows'};

/// The host a builder file's builds run on: `linux_*.json` and
/// local_engine.json's `linux/` builds on Linux, `mac_*.json` and `macos/`
/// on a Mac.
enum BuilderHost { linux, mac }

/// One build of a builder file, read for Bazel.
final class BuilderBuild {
  BuilderBuild._({
    required this.file,
    required this.host,
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
    required this.scriptTests,
    required this.otherTests,
  }) : configName = bareName(name);

  /// Reads [build] of the builder file [file] (`linux_host_engine.json`,
  /// `mac_host_engine.json`; local_engine.json's builds say their host by
  /// their `linux/` or `macos/` prefix).
  factory BuilderBuild.of(String file, Build build) {
    final BuilderHost host = file.startsWith('mac_') || build.name.startsWith('macos/')
        ? BuilderHost.mac
        : BuilderHost.linux;
    final flags = <String>[];
    final settings = <String>[];
    final unsupported = <String>[];
    String? otherPlatform;
    var unoptimized = false;
    var lto = true;
    bool? stripped;
    String? runtimeMode;
    String? buildDirectory;
    String? platform;
    String? targetOs;
    String? linuxCpu;
    String? androidCpu;
    String? macCpu;
    var simulator = false;
    String? simulatorCpu;
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
            case '--mac':
              targetOs = 'mac';
            case '--mac-cpu':
              macCpu = value;
            case '--ios':
              targetOs = 'ios';
            case '--simulator':
              simulator = true;
            case '--simulator-cpu':
              simulatorCpu = value;
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
          // The OS flag names the platform; its qualifiers (--fuchsia-cpu,
          // --simulator) do not displace it.
          if (otherPlatform == null ||
              (!_otherPlatformOsFlags.contains(otherPlatform) &&
                  _otherPlatformOsFlags.contains(flag))) {
            otherPlatform = flag;
          }
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
    // costs the build its configuration; --mac --mac-cpu=<cpu>, and a Mac's
    // host build (its CPU is --mac-cpu too, x64 unless given, whatever the
    // Mac), is the macOS platform of that CPU; any other OS, or Linux CPU,
    // is out of scope.
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
    } else if (targetOs == 'mac' ||
        (targetOs == null && platform == null && host == BuilderHost.mac)) {
      final String cpu = macCpu ?? defaultMacCpu;
      final String? macosPlatform = macosPlatforms[cpu];
      if (macosPlatform != null) {
        platform = '--platforms=$macosPlatform';
      } else {
        unsupported.add(
          '--mac-cpu=$cpu (the Bazel build has macOS ${macosPlatforms.keys.join(' and ')} '
          'platforms only)',
        );
      }
    } else if (targetOs == 'ios') {
      // --ios: a device (arm64); --simulator the simulator of
      // --simulator-cpu (x64 unless given).
      if (simulator) {
        final String cpu = simulatorCpu ?? defaultSimulatorCpu;
        final String? simulatorPlatform = iosSimulatorPlatforms[cpu];
        if (simulatorPlatform != null) {
          platform = '--platforms=$simulatorPlatform';
        } else {
          unsupported.add(
            '--simulator-cpu=$cpu (the Bazel build has iOS simulator '
            '${iosSimulatorPlatforms.keys.join(' and ')} platforms only)',
          );
        }
      } else {
        platform = '--platforms=$iosDevicePlatform';
      }
    } else if (targetOs != null && targetOs != 'linux') {
      otherPlatform = '--target-os=$targetOs';
    } else if (linuxCpu == 'arm64') {
      platform = '--platforms=$linuxArm64Platform';
    } else if (linuxCpu != null && linuxCpu != 'x64') {
      otherPlatform ??= '--linux-cpu=$linuxCpu';
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
    flags.add(unoptimized ? '--compilation_mode=dbg' : '--compilation_mode=opt');
    // The runtime mode twice: on the command line, for the execution
    // configuration the build's tools are built in (gen_snapshot in the
    // Dart wrap: GN builds its host tools in the build's mode), and as the
    // target platform's own flag -- the mode's platform, whose name is the
    // output directory's (platforms.bzl); a Linux host build, which named no
    // platform (Bazel's host platform), names the host's for the same
    // reason. A build the Bazel build has no platform for (otherPlatform)
    // names none, as before.
    final String mode = runtimeMode ?? 'debug';
    flags.add('--$runtimeModeSetting=$mode');
    final String? base = platform == null
        ? (otherPlatform == null && host == BuilderHost.linux ? linuxX64Platform : null)
        : platform.substring('--platforms='.length);
    if (base != null) {
      flags.add('--platforms=${runtimeModePlatform(base, mode)}');
    }
    flags.addAll(settings);
    // The tests: run_tests.py's types, the test executables a step runs
    // from the build directory, and every other step by name.
    final testTypes = <String>[];
    final binaryTests = <String>[];
    final scriptTests = <String>[];
    final otherTests = <String>[];
    final String? outPrefix = buildDirectory == null ? null : 'out/$buildDirectory/';
    for (final BuildTest test in build.tests) {
      if (outPrefix != null && test.script.startsWith(outPrefix)) {
        binaryTests.add(test.script.substring(outPrefix.length));
        continue;
      }
      final String? scriptTest = checkoutScriptTests[test.script];
      if (scriptTest != null) {
        if (!scriptTests.contains(scriptTest)) {
          scriptTests.add(scriptTest);
        }
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
      host: host,
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
      scriptTests: scriptTests,
      otherTests: otherTests,
    );
  }

  /// The builder file's name (`linux_host_engine.json`).
  final String file;

  /// The host the build runs on.
  final BuilderHost host;

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
  /// [androidPlatforms]; a Mac's builds: [macosPlatforms]); null for the
  /// Linux host's own build.
  final String? platform;

  /// The flags the Bazel build cannot express, with the reason each.
  final List<String> unsupported;

  /// The flag naming a platform the Bazel build has none for yet
  /// (`--fuchsia`), when the build targets one: such a build is left out of
  /// the configurations, and named among [leftOutLinuxBuilds].
  final String? otherPlatform;

  /// The types its run_tests.py steps run (`dart`, `engine`, ...).
  final List<String> testTypes;

  /// The test executables its steps run directly from the build directory
  /// (`out/<dir>/licenses_cpp_testrunner`), by name: each a Bazel test.
  final List<String> binaryTests;

  /// The Bazel tests of its steps that run a script of the checkout
  /// ([checkoutScriptTests]), by label.
  final List<String> scriptTests;

  /// Its other test steps, by name (scripts a Bazel test does not stand for).
  final List<String> otherTests;

  /// The configuration's name, and the install target's and the test
  /// suite's: the build's without CI's `ci/` prefix or local_engine.json's
  /// `linux/` or `macos/` (`host_debug` for both `ci/host_debug` and
  /// `linux/host_debug`, which set the same flags) -- unless a CI build's
  /// flags differ from the developer's build of the same bare name, in
  /// which case the developer's keeps the name `et build --config <name>`
  /// knows and CI's keeps its prefix as GN's build directory does:
  /// `ci_host_debug_unopt` (`out/ci/host_debug_unopt`: asan and a Debug VM)
  /// beside `host_debug_unopt` (`out/host_debug_unopt`); and a Mac build
  /// with a Linux build's bare name keeps its OS, `mac_host_debug`, unless
  /// the two are the same build (flags, ninja targets and tests alike:
  /// `wasm_release` from either host; a developer's build of everything
  /// with no tests, on its flags alone). [builderBuilds] decides that once
  /// every build is read.
  String configName;

  /// [name] without its `ci/`, `linux/` or `macos/` prefix, `/` as `_`.
  static String bareName(String name) {
    final String bare = name.startsWith('ci/')
        ? name.substring(3)
        : name.startsWith('linux/')
        ? name.substring(6)
        : name.startsWith('macos/')
        ? name.substring(6)
        : name;
    return bare.replaceAll('/', '_');
  }

  /// What makes two builds of one name one build: their Bazel flags, their
  /// ninja targets and their test steps.
  String get _identity =>
      '${bazelFlags.join(' ')} | ${ninjaTargets.join(' ')} | ${testTypes.join(',')} '
      '${binaryTests.join(',')} ${scriptTests.join(',')} ${otherTests.join(';')}';

  /// Whether this is a build of everything with no tests (the developer's
  /// builds of local_engine.json): it gets no install and no suite, so it
  /// is the same build as any of its name with the same flags.
  bool get _isEverythingWithoutTests =>
      ninjaTargets.isEmpty &&
      testTypes.isEmpty &&
      binaryTests.isEmpty &&
      scriptTests.isEmpty &&
      otherTests.isEmpty;

  /// Whether [other], a build of the same name on the other host, is this
  /// build: the same flags, and the same ninja targets and tests unless
  /// this build names none.
  bool _sameBuildAs(BuilderBuild other) {
    if (bazelFlags.join(' ') != other.bazelFlags.join(' ')) {
      return false;
    }
    return _isEverythingWithoutTests || _identity == other._identity;
  }
}

/// The builds of [configs] (a builder file's name to its configuration)
/// in the order the generated files take: the `linux_*.json` files' builds
/// that target the host, the web, Linux arm64 or Android, then
/// local_engine.json's `linux/` builds -- the developer's configurations,
/// which `et build --config <name>` runs -- then the `mac_*.json` files'
/// builds for the Mac's CPUs, Android and the web, then local_engine.json's
/// `macos/` builds. iOS's and Fuchsia's are left out ([leftOutBuilds]).
List<BuilderBuild> builderBuilds(Map<String, BuilderConfig> configs) {
  final builds = <BuilderBuild>[];
  for (final BuilderHost host in BuilderHost.values) {
    for (final Build build in _buildsOf(configs, host)) {
      final read = BuilderBuild.of(_fileOf(configs, build), build);
      if (read.otherPlatform == null && read.gn.isNotEmpty) {
        builds.add(read);
      }
    }
  }
  // A Mac build with a Linux build's name keeps its OS, unless it is the
  // same build (a web build from either host; the developer's Android
  // builds, which set what CI's set and name no target of their own).
  final linuxNames = <String, List<BuilderBuild>>{};
  for (final build in builds) {
    if (build.host == BuilderHost.linux) {
      linuxNames.putIfAbsent(build.configName, () => <BuilderBuild>[]).add(build);
    }
  }
  for (final build in builds) {
    final List<BuilderBuild>? linux = linuxNames[build.configName];
    if (build.host == BuilderHost.mac &&
        linux != null &&
        !linux.any((BuilderBuild l) => build._sameBuildAs(l))) {
      build.configName = 'mac_${build.configName}';
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

/// The builds of [host]'s builder files, by file name and build order, then
/// local_engine.json's builds of that host.
List<Build> _buildsOf(Map<String, BuilderConfig> configs, BuilderHost host) {
  final prefix = host == BuilderHost.linux ? 'linux_' : 'mac_';
  final developer = host == BuilderHost.linux ? 'linux/' : 'macos/';
  // The Bazel variants of builder files (*_bazel.json: the same builds with
  // `--bazel`, for CI without a recipe change) mirror builds listed here
  // already; they are checked against them instead (bazelVariantErrors).
  final List<String> files =
      configs.keys.where((String f) => f.startsWith(prefix) && !isBazelVariant(f)).toList()..sort();
  return <Build>[
    for (final file in files) ...configs[file]!.builds,
    if (configs.containsKey('local_engine'))
      for (final Build build in configs['local_engine']!.builds)
        if (build.name.startsWith(developer)) build,
  ];
}

/// Whether a builder file (by its name without `.json`, as
/// BuildConfigLoader keys them) is the Bazel variant of another:
/// `linux_unopt_bazel` of `linux_unopt`.
bool isBazelVariant(String file) => file.endsWith('_bazel');

/// The `tools/gn` flags of a build as a Bazel variant's are matched against
/// the original's: `--x=v` as `--x v`, without the flags that say where the
/// build runs (`--bazel`, `--rbe`, `--no-rbe`, `--goma`, `--no-goma`; what
/// bazel_ci.py's normalized_flags does on the bot).
List<String> _matchedFlags(List<String> gn) {
  const infrastructure = <String>{'--bazel', '--rbe', '--no-rbe', '--goma', '--no-goma'};
  final out = <String>[];
  for (final flag in gn) {
    if (infrastructure.contains(flag)) {
      continue;
    }
    if (flag.startsWith('--') && flag.contains('=')) {
      final int equals = flag.indexOf('=');
      out
        ..add(flag.substring(0, equals))
        ..add(flag.substring(equals + 1));
    } else {
      out.add(flag);
    }
  }
  return out;
}

/// The Bazel variants of the builder files (`<file>_bazel.json`) checked
/// against the files they mirror: every build of a variant must carry
/// `--bazel` and be, flags apart from the infrastructure ones, a build of
/// the original file that has a Bazel configuration and an install (what
/// `tools/gn --bazel` on the bot will look up in build/bazel/builds.json).
/// Returns the errors, one line each.
List<String> bazelVariantErrors(Map<String, BuilderConfig> configs, List<BuilderBuild> builds) {
  final errors = <String>[];
  for (final MapEntry<String, BuilderConfig> entry in configs.entries) {
    if (!isBazelVariant(entry.key)) {
      continue;
    }
    final variant = '${entry.key}.json';
    final original = '${entry.key.substring(0, entry.key.length - '_bazel'.length)}.json';
    if (!configs.containsKey(original.substring(0, original.length - 5))) {
      errors.add('$variant: no $original to mirror');
      continue;
    }
    for (final Build build in entry.value.builds) {
      if (!build.gn.contains('--bazel')) {
        errors.add("$variant's ${build.name} lacks --bazel");
      }
      final String wanted = _matchedFlags(build.gn).join(' ');
      final Iterable<BuilderBuild> matches = builds.where(
        (BuilderBuild b) => b.file == original && _matchedFlags(b.gn).join(' ') == wanted,
      );
      if (matches.isEmpty) {
        errors.add("$variant's ${build.name} is no build of $original: its flags are `$wanted`");
        continue;
      }
      final BuilderBuild mirrored = matches.first;
      if (mirrored.unsupported.isNotEmpty) {
        errors.add(
          "$variant's ${build.name} mirrors $original's ${mirrored.name}, which has no Bazel "
          'configuration (${mirrored.unsupported.join('; ')})',
        );
      } else if (mirrored.ninjaTargets.isEmpty) {
        errors.add(
          "$variant's ${build.name} mirrors $original's ${mirrored.name}, ninja's default "
          'target, which has no install',
        );
      }
    }
  }
  return errors;
}

/// The builds of the builder files that carry `--bazel` themselves (a Linux
/// builder that builds with Bazel on the bot, build/bazel/ci.md) checked the
/// way a variant's are: each must have a Bazel configuration and an install,
/// or `tools/gn --bazel` fails on the bot. Returns the errors, one line each.
List<String> bazelBuildErrors(List<BuilderBuild> builds) {
  final errors = <String>[];
  for (final build in builds) {
    if (!build.gn.contains('--bazel')) {
      continue;
    }
    if (build.unsupported.isNotEmpty) {
      errors.add(
        "${build.file}'s ${build.name} carries --bazel but has no Bazel configuration "
        '(${build.unsupported.join('; ')})',
      );
    } else if (build.ninjaTargets.isEmpty) {
      errors.add(
        "${build.file}'s ${build.name} carries --bazel but builds ninja's default target, "
        'which has no install',
      );
    }
  }
  return errors;
}

/// The builder file's name (`linux_host_engine.json`) of [build].
String _fileOf(Map<String, BuilderConfig> configs, Build build) {
  for (final MapEntry<String, BuilderConfig> entry in configs.entries) {
    if (entry.value.builds.contains(build)) {
      return '${entry.key}.json';
    }
  }
  throw ArgumentError('${build.name} is in no builder file');
}

/// A build of the builder files that [builderBuilds] leaves out, and why.
typedef LeftOutBuild = ({String file, String name, String reason});

/// The builds of the Linux and Mac builder files that are not builds of this
/// scope: those of another platform (Fuchsia's: `--fuchsia`; iOS's: `--ios`)
/// and those with no `tools/gn` step (the web test bundles, which test
/// another build's artifacts). Listed at the end of the generated bazelrc,
/// so that a build missing from it is missing for a reason the file states
/// -- the Android embedder build went unlisted for a week behind a misfiled
/// flag.
List<LeftOutBuild> leftOutBuilds(Map<String, BuilderConfig> configs) {
  final leftOut = <LeftOutBuild>[];
  for (final BuilderHost host in BuilderHost.values) {
    for (final Build build in _buildsOf(configs, host)) {
      final read = BuilderBuild.of(_fileOf(configs, build), build);
      final String? platformFlag = read.otherPlatform;
      if (platformFlag != null) {
        leftOut.add((
          file: read.file,
          name: read.name,
          reason: 'a platform the Bazel build has none for yet ($platformFlag)',
        ));
      } else if (read.gn.isEmpty) {
        leftOut.add((file: read.file, name: read.name, reason: 'no tools/gn step: not a build'));
      }
    }
  }
  return leftOut;
}

/// The generated bazelrc: a `--config=<name>` per build whose flags all map,
/// and, last, the builder files' builds that are not builds of this scope
/// ([leftOut]), each with its reason.
String configsBazelrc(List<BuilderBuild> builds, {List<LeftOutBuild> leftOut = const []}) {
  final out = StringBuffer()
    ..writeln('# Copyright 2013 The Flutter Authors. All rights reserved.')
    ..writeln('# Use of this source code is governed by a BSD-style license that can be')
    ..writeln('# found in the LICENSE file.')
    ..writeln()
    ..writeln('# Generated from ci/builders/{linux,mac}_*.json by gn_to_bazel; do not edit.')
    ..writeln('#')
    ..writeln("# Each Linux and Mac build of the builder files -- the Linux x64 host's own,")
    ..writeln("# the web's, the Linux arm64 cross builds', Android's, the Mac's for either")
    ..writeln('# CPU -- as a Bazel configuration: `bazel build --config=<name> ...` sets')
    ..writeln("# what the build's tools/gn flags set, as far as the Bazel build has settings")
    ..writeln('# for them (gnFlags in tools/gn_to_bazel/lib/src/builders.dart says what each')
    ..writeln('# flag amounts to; --web is the wasm platform, --target-os=linux')
    ..writeln('# --linux-cpu=arm64 the Linux arm64 one, --android --android-cpu=arm64 the')
    ..writeln("# Android arm64 one, and a Mac's build is the macOS platform of its --mac-cpu,")
    ..writeln("# x64 unless given, as tools/gn's target CPU on a Mac is: a Mac's host_debug")
    ..writeln("# is an x64 build on an arm64 bot). A Mac build with a Linux build's name")
    ..writeln('# is the same configuration when it is the same build and mac_<name>')
    ..writeln('# otherwise. A build with a flag the Bazel build cannot express yet is')
    ..writeln('# listed with the reason and gets no configuration; the install target of')
    ..writeln('# each build is in BUILD.bazel beside this file.');
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
  if (leftOut.isNotEmpty) {
    out
      ..writeln()
      ..writeln('# Not configurations: the builds of these files that are not builds of this')
      ..writeln("# scope -- another platform's, or a test-only build with no tools/gn step.")
      ..writeln('# Every other build of the Linux and Mac builder files is above.');
    for (final build in leftOut) {
      out.writeln('#   ${build.file}: ${build.name} -- ${build.reason}');
    }
  }
  return out.toString();
}

/// What a build's ninja targets amount to for its install: the Bazel labels
/// of the targets to install (`resolved`), the targets with no Bazel
/// counterpart yet (`missing`), and the test executables among them
/// (`tests`), which `bazel test` runs from their own place rather than the
/// install laying them.
({List<String> resolved, List<String> missing, List<String> tests}) _installContents(
  BuilderBuild build,
  Map<String, Set<String>> convertedTargets, {
  required Map<String, Set<String>> convertedTests,
  required Map<String, String?> packageConditions,
}) {
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
    if (_ninjaTargetLabel(target, convertedTests, build, packageConditions) != null) {
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
    final String? label = _ninjaTargetLabel(target, convertedTargets, build, packageConditions);
    if (label == null) {
      missing.add(target);
    } else if (!resolved.contains(label)) {
      resolved.add(label);
    }
  }
  return (resolved: resolved, missing: missing, tests: tests);
}

/// The Bazel suites of a build's tests, by what the builder file runs: each
/// run_tests.py type (`engine` resolved to the converted tests of
/// [runTestsEngineSuites] or the Mac's; the others [runTestsTypeSuites]),
/// the test executables a step runs from the build directory (`binaries`;
/// under `run_tests.py --type binaries`, the test executables among the
/// build's ninja targets), and the steps that run a script of the checkout
/// (`scripts`, [checkoutScriptTests]); `missing` names what has no Bazel
/// test yet.
({
  Map<String, List<String>> types,
  List<String> binaries,
  List<String> scripts,
  List<String> missing,
})
_testSuites(
  BuilderBuild build,
  Map<String, Set<String>> convertedTests, {
  required Map<String, String?> packageConditions,
}) {
  final binaries = <String>[];
  final missing = <String>[];
  for (final String name in build.binaryTests) {
    final String? label = _ninjaTargetLabel(name, convertedTests, build, packageConditions);
    if (label == null) {
      missing.add('$name (run from the build directory)');
    } else if (!binaries.contains(label)) {
      binaries.add(label);
    }
  }
  // `run_tests.py --type binaries`, a Bazel build's form of a step that runs
  // a test executable from the build directory: the test executables among
  // the build's ninja targets (what such a step would have run).
  if (build.testTypes.contains('binaries')) {
    var found = false;
    for (final String name in build.ninjaTargets) {
      final String? label = _ninjaTargetLabel(name, convertedTests, build, packageConditions);
      if (label == null) {
        continue;
      }
      found = true;
      if (!binaries.contains(label)) {
        binaries.add(label);
      }
    }
    if (!found) {
      missing.add('the binaries type (no test executable among the ninja targets)');
    }
  }
  final types = <String, List<String>>{};
  for (final String type in build.testTypes) {
    if (type == 'binaries') {
      continue;
    }
    final labels = <String>[];
    if (type == 'engine') {
      for (final String name
          in build.host == BuilderHost.mac ? runTestsEngineSuitesMac : runTestsEngineSuites) {
        final String? label = _ninjaTargetLabel(name, convertedTests, build, packageConditions);
        if (label == null) {
          missing.add('$name (engine)');
        } else if (!labels.contains(label)) {
          labels.add(label);
        }
      }
    } else {
      final List<String>? known = runTestsTypeSuites[type];
      if (known == null) {
        missing.add('the $type type');
        continue;
      }
      labels.addAll(known);
    }
    types[type] = labels;
  }
  return (types: types, binaries: binaries, scripts: build.scriptTests, missing: missing);
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
  Map<String, String?> packageConditions = const <String, String?>{},
}) {
  final out = StringBuffer()
    ..writeln('# Copyright 2013 The Flutter Authors. All rights reserved.')
    ..writeln('# Use of this source code is governed by a BSD-style license that can be')
    ..writeln('# found in the LICENSE file.')
    ..writeln()
    ..writeln('# Generated from ci/builders/{linux,mac}_*.json by gn_to_bazel; do not edit.')
    ..writeln('#')
    ..writeln('# An install target per Linux and Mac build of the builder files (the Linux')
    ..writeln("# x64 host's own, the web's, the Linux arm64 cross builds', Android's, the")
    ..writeln("# Mac's for either CPU; a Mac build with a Linux build's name is mac_<name>")
    ..writeln('# unless it is the same build), over the Bazel')
    ..writeln('# counterparts of its ninja targets: `bazel run --config=<name> :<name>` builds')
    ..writeln("# what the build builds and lays it into GN's build directory for it")
    ..writeln('# (--target-dir, or the directory tools/gn names for the flags), as the')
    ..writeln("# builder's recipe expects to find it. A ninja target with no Bazel")
    ..writeln('# counterpart yet is listed; a build whose configuration the Bazel build')
    ..writeln('# cannot express yet (configs.bazelrc) is built with the flags of the nearest')
    ..writeln('# one; a test executable among the targets is not installed, since `bazel')
    ..writeln("# test` runs tests from their own place. A Mac build's install and suite are")
    ..writeln('# compatible with macOS alone, as their contents are: a wildcard build on')
    ..writeln('# Linux skips them. A build with tests has a <name>_tests')
    ..writeln('# suite over the Bazel suites that stand for its run_tests.py types')
    ..writeln('# (runTestsTypeSuites, runTestsEngineSuites and runTestsEngineSuitesMac in')
    ..writeln('# builders.dart): `bazel test')
    ..writeln('# --config=<name> :<name>_tests` runs what the build runs, with its other test')
    ..writeln('# steps (scripts of the checkout) listed. The suites are manual: each stands')
    ..writeln('# for one builder, named; a wildcard run of the tree has the tests themselves.')
    ..writeln()
    ..writeln('load("//build_defs/dist:install.bzl", "install")')
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
    final (
      resolved: List<String> resolved,
      missing: List<String> missing,
      tests: List<String> tests,
    ) = _installContents(
      build,
      convertedTargets,
      convertedTests: convertedTests,
      packageConditions: packageConditions,
    );
    out
      ..writeln()
      ..writeln('# ${build.file}: ${build.name}');
    if (build.ninjaTargets.isEmpty) {
      // GN's default target: the whole build, which the flutter tool reads
      // where Bazel builds it, through the root package's local engine
      // manifest; no install. Its tests (the Mac's test builds name no
      // target) get their suite.
      out.writeln(
        "#   ninja's default target, everything: "
        'bazel build --config=${build.configName} //engine/src/flutter:local_engine',
      );
      _testSuiteInto(out, build, convertedTests, suites, packageConditions: packageConditions);
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
      _testSuiteInto(out, build, convertedTests, suites, packageConditions: packageConditions);
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
      _testSuiteInto(out, build, convertedTests, suites, packageConditions: packageConditions);
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
    // A builder's install is its host's: a Linux builder's on a Linux
    // machine, a Mac's on a Mac (its Android builds included, whose target
    // platform is Android), so that `ci/builders:all` analyzes on either
    // host, skipping the other's.
    final String hostSetting = switch (build.host) {
      BuilderHost.linux => '//engine/src/flutter/build/bazel:host_os_is_linux',
      BuilderHost.mac => '//engine/src/flutter/build/bazel:host_os_is_mac',
    };
    out
      ..writeln('    target_compatible_with = select({')
      ..writeln('        "$hostSetting": [],')
      ..writeln('        "//conditions:default": ["@platforms//:incompatible"],')
      ..writeln('    }),')
      ..writeln(')');
    _testSuiteInto(out, build, convertedTests, suites, packageConditions: packageConditions);
  }
  return out.toString();
}

/// `build/bazel/builds.json`: the builder files' builds as `tools/gn
/// --bazel` and `testing/run_tests.py` read them on a CI bot that builds
/// with Bazel (build/bazel/ci.md, beside bazel_ci.py, which reads it; not
/// under ci/builders, whose every JSON file engine_build_configs loads as a
/// builder file): one entry per build, by host, with the
/// build's tools/gn flags as the builder file writes them (the key tools/gn
/// matches its flags against, infrastructure flags aside), its build
/// directory, its Bazel configuration and install target (null when the
/// Bazel build cannot express the build, with the reasons), the ninja
/// targets the recipe asks ninja for (each gets a phony edge), and the
/// Bazel suites of its run_tests.py types, test executables and checkout
/// scripts. Builds without a configuration or an install are listed all
/// the same, so that tools/gn can say why it refuses them.
String buildersJson(
  List<BuilderBuild> builds,
  Map<String, Set<String>> convertedTargets, {
  Map<String, Set<String>> convertedTests = const <String, Set<String>>{},
  Map<String, String?> packageConditions = const <String, String?>{},
}) {
  final hosts = <String, List<Map<String, Object?>>>{'linux': [], 'mac': []};
  for (final build in builds) {
    final (
      resolved: List<String> resolved,
      missing: List<String> missing,
      tests: List<String> tests,
    ) = _installContents(
      build,
      convertedTargets,
      convertedTests: convertedTests,
      packageConditions: packageConditions,
    );
    final (
      types: Map<String, List<String>> types,
      binaries: List<String> binaries,
      scripts: List<String> scripts,
      missing: List<String> missingTests,
    ) = _testSuites(
      build,
      convertedTests,
      packageConditions: packageConditions,
    );
    final bool configured = build.unsupported.isEmpty;
    final bool installed = configured && build.ninjaTargets.isNotEmpty && resolved.isNotEmpty;
    final bool hasSuite =
        types.values.any((List<String> l) => l.isNotEmpty) ||
        binaries.isNotEmpty ||
        scripts.isNotEmpty;
    hosts[build.host.name]!.add(<String, Object?>{
      'file': build.file,
      'name': build.name,
      'gn': build.gn,
      'build_directory': build.buildDirectory,
      'config': configured ? build.configName : null,
      'unsupported': build.unsupported,
      'install': installed ? '//engine/src/flutter/ci/builders:${build.configName}' : null,
      'ninja_targets': build.ninjaTargets,
      'ninja_targets_not_built': missing,
      'ninja_targets_tested': tests,
      'tests': <String, Object?>{
        'suite': hasSuite ? '//engine/src/flutter/ci/builders:${build.configName}_tests' : null,
        'types': types,
        'binaries': binaries,
        'scripts': scripts,
        'missing': missingTests,
      },
    });
  }
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert(<String, Object?>{'_comment': 'Generated from ci/builders/{linux,mac}_*.json by gn_to_bazel; do not edit. '
      'The builds as tools/gn --bazel and testing/run_tests.py read them (build/bazel/ci.md).', 'builds': hosts})}\n';
}

/// `<name>_tests`: the suites of [build]'s run_tests.py types. [written]
/// has the suites written so far by name: a second build of a name gets a
/// note instead, when it runs the same.
void _testSuiteInto(
  StringBuffer out,
  BuilderBuild build,
  Map<String, Set<String>> convertedTests,
  Map<String, (BuilderBuild, String)> written, {
  Map<String, String?> packageConditions = const <String, String?>{},
}) {
  if (build.testTypes.isEmpty &&
      build.binaryTests.isEmpty &&
      build.scriptTests.isEmpty &&
      build.otherTests.isEmpty) {
    return;
  }
  final (
    types: Map<String, List<String>> types,
    binaries: List<String> binaries,
    scripts: List<String> scripts,
    missing: List<String> missing,
  ) = _testSuites(
    build,
    convertedTests,
    packageConditions: packageConditions,
  );
  final suites = <String>[...scripts];
  for (final label in <String>[...binaries, for (final List<String> t in types.values) ...t]) {
    if (!suites.contains(label)) {
      suites.add(label);
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
  if (build.scriptTests.isNotEmpty) {
    out.writeln(
      "# ${build.name}'s steps that run a script of the checkout, as Bazel tests: "
      '${build.scriptTests.join(', ')}.',
    );
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
String? _ninjaTargetLabel(
  String target,
  Map<String, Set<String>> convertedTargets,
  BuilderBuild build,
  Map<String, String?> packageConditions,
) {
  // ninja's `default` is every target of the GN build (the root BUILD.gn
  // has no group of that name); the root group `flutter` -- what `ninja
  // flutter` builds, and all the artifacts a build lays -- stands for it.
  if (target == 'default') {
    target = 'flutter';
  }
  // A target of a file GN reads under a condition (sky/dist under
  // is_android) exists in the builds the condition holds for and in no
  // other: a bare name unique in a host build (`sky_engine`, the package)
  // is not made ambiguous by an Android-only target of the same name.
  bool exists(String gnPackage) => fileHolds(packageConditions[gnPackage], build);
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
        if (entry.value.contains(target) && exists(entry.key)) entry.key,
    ];
    if (candidates.length != 1) {
      return null;
    }
    gnPackage = candidates.single;
    name = target;
  }
  if (!(convertedTargets[gnPackage]?.contains(name) ?? false) || !exists(gnPackage)) {
    return null;
  }
  return bazelLabel('$gnPackage:$name', package: gnPackage);
}

/// Whether a converted file's [condition] (the manifest's
/// `ConvertedFile.condition`: `is_android`, a disjunction such as `is_ios
/// || is_mac`, or null for a file GN always reads) holds for [build]: the
/// OS predicates against the build's platform; any other condition is
/// taken to hold.
bool fileHolds(String? condition, BuilderBuild build) {
  if (condition == null) {
    return true;
  }
  final String? platform = build.platform;
  final bool android = androidPlatforms.values.any((String p) => platform == '--platforms=$p');
  final bool mac = macosPlatforms.values.any((String p) => platform == '--platforms=$p');
  final bool ios =
      platform == '--platforms=$iosDevicePlatform' ||
      iosSimulatorPlatforms.values.any((String p) => platform == '--platforms=$p');
  final wasm = platform == '--platforms=$wasmPlatform';
  return condition
      .split('||')
      .any(
        (String variable) => switch (variable.trim()) {
          'is_android' => android,
          'is_wasm' => wasm,
          'is_mac' => mac,
          'is_ios' => ios,
          'is_apple' => mac || ios,
          'is_linux' => !android && !wasm && !mac && !ios,
          _ => true,
        },
      );
}
