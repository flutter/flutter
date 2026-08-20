// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../build_info.dart';
import '../flutter_command.dart';

/// Common typed option descriptors across flutter commands.
abstract final class CommonOptions {
  static const treeShakeIcons = FlagOptionDescriptor(
    name: 'tree-shake-icons',
    defaultsTo: true,
    help: 'Tree shake icon fonts so that only glyphs used by the application are included.',
  );

  static const target = StringOptionDescriptor(
    name: 'target',
    abbr: 't',
    defaultsTo: 'lib/main.dart',
    help:
        'The main entrypoint file of the application, as run on the device.\n'
        'If the "--target" option is omitted, but a file name is provided on '
        'the command line, then that file is used instead.',
  );

  static const outputDir = StringOptionDescriptor(
    name: 'output',
    abbr: 'o',
    aliases: <String>['output-dir'],
    help:
        'The absolute path to the directory where the repository is generated. '
        'By default, this is <current-directory>/build/<target-platform>.\n'
        'Currently supported for subcommands: aar, web.',
  );

  static const pub = FlagOptionDescriptor(
    name: 'pub',
    defaultsTo: true,
    help: 'Whether to run "flutter pub get" before executing this command.',
  );

  static const buildNumber = StringOptionDescriptor(
    name: 'build-number',
    valueHelp: '1.0.0',
    help:
        'An identifier used as an internal version number.\n'
        'Each build must have a unique identifier to differentiate it from previous builds.',
  );

  static const buildName = StringOptionDescriptor(
    name: 'build-name',
    valueHelp: 'x.y.z',
    help:
        'A "x.y.z" string used as the version number shown to users.\n'
        'For each new version of your app, you will provide a version number to differentiate it.',
  );

  static const debugMode = FlagOptionDescriptor(
    name: 'debug',
    negatable: false,
    help: 'Build a debug version of your app.',
  );

  static const profileMode = FlagOptionDescriptor(
    name: 'profile',
    negatable: false,
    help: 'Build a version of your app specialized for performance profiling.',
  );

  static const releaseMode = FlagOptionDescriptor(
    name: 'release',
    negatable: false,
    help: 'Build a release version of your app.',
  );

  static const jitReleaseMode = FlagOptionDescriptor(
    name: 'jit-release',
    negatable: false,
    help: 'Build a JIT release version of your app.',
  );

  static const dartDefines = MultiOptionDescriptor(
    name: FlutterOptions.kDartDefinesOption,
    abbr: 'D',
    splitCommas: false,
    aliases: <String>['dart-defines'],
    help:
        'Additional key-value pairs that will be available as constants '
        'from the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment '
        'constructors. Multiple defines can be passed by repeating "--dart-define".',
    valueHelp: 'foo=bar',
  );

  static const dartDefineFromFile = MultiOptionDescriptor(
    name: FlutterOptions.kDartDefineFromFileOption,
    help:
        'The path of a .json or .env file containing key-value pairs that will be available as environment '
        'variables. These can be accessed using the String.fromEnvironment, bool.fromEnvironment, and '
        'int.fromEnvironment constructors. Multiple define files can be passed by repeating "--dart-define-from-file".',
    valueHelp: 'use-keys.json',
  );

  static const enableExperiment = MultiOptionDescriptor(
    name: FlutterOptions.kEnableExperiment,
    help:
        'The name of an experimental Dart feature to enable. '
        'Multiple experiments can be enabled by repeating "--enable-experiment".',
    valueHelp: 'experiment-name',
  );

  static const nullAssertions = FlagOptionDescriptor(
    name: 'null-assertions',
    negatable: false,
    help:
        'Perform additional checks in sound mode to catch dereferences of null '
        'values, and runtime type checks on types containing the Never type.',
  );

  static const nativeNullAssertions = FlagOptionDescriptor(
    name: 'native-null-assertions',
    defaultsTo: true,
    help:
        'Enables additional runtime null checks in web applications to ensure '
        'the correct nullability of native (such as in dart:html) and external '
        '(such as with JS interop) types. This is enabled by default but only takes '
        'effect in sound mode. To report an issue with a null assertion failure in '
        'dart:html or the other dart web libraries, please file a bug at: '
        'https://github.com/dart-lang/sdk/issues/labels/web-libraries',
  );
}

/// A bundle encapsulating standard build mode flags (`--debug`, `--profile`, `--release`, `--jit-release`).
class BuildModeOptionsBundle extends OptionBundle {
  const BuildModeOptionsBundle({this.defaultToRelease = true, this.verboseHelp = false});

  final bool defaultToRelease;
  final bool verboseHelp;

  @override
  void onRegister(FlutterCommand command) {
    command.defaultBuildMode = defaultToRelease ? BuildMode.release : BuildMode.debug;
  }

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    CommonOptions.debugMode,
    CommonOptions.profileMode,
    CommonOptions.releaseMode,
    CommonOptions.jitReleaseMode,
  ];
}

/// A bundle encapsulating general Dart compilation options.
class DartCompileOptionsBundle extends OptionBundle {
  const DartCompileOptionsBundle({this.verboseHelp = false});

  final bool verboseHelp;

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    CommonOptions.dartDefines,
    CommonOptions.dartDefineFromFile,
    CommonOptions.enableExperiment,
    CommonOptions.nativeNullAssertions,
  ];
}

/// A bundle encapsulating basic build parameters (target, output-dir, pub, build-number/name).
class CommonBuildOptionsBundle extends OptionBundle {
  const CommonBuildOptionsBundle({this.verboseHelp = false});

  final bool verboseHelp;

  @override
  void onRegister(FlutterCommand command) {
    command.enableUsesTargetOption();
    command.enableUsesPubOption();
  }

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    CommonOptions.treeShakeIcons,
    CommonOptions.target,
    CommonOptions.outputDir,
    CommonOptions.pub,
    CommonOptions.buildNumber,
    CommonOptions.buildName,
  ];
}
