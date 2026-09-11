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
    aliases: <String>[kDartDefines, 'dart-defines'],
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
    verboseOnly: true,
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

/// Typed option descriptors specific to [BuildInfo].
abstract final class BuildInfoOptions {
  static const trackWidgetCreation = FlagOptionDescriptor(
    name: 'track-widget-creation',
    defaultsTo: true,
    verboseOnly: true,
    help:
        'Track widget creation locations. This enables features such as the widget inspector. '
        'This parameter is only functional in debug mode (i.e. when compiling JIT, not AOT).',
  );

  static const analyzeSize = FlagOptionDescriptor(
    name: FlutterOptions.kAnalyzeSize,
    help:
        'Whether to produce additional profile information for artifact output size. '
        'This flag is only supported on "--release" builds. When building for Android, a single '
        'ABI must be specified at a time with the "--target-platform" flag. When building for iOS, '
        'only the symbols from the arm64 architecture are used to analyze code size.\n'
        'This flag cannot be combined with "--${FlutterOptions.kSplitDebugInfoOption}".',
  );

  static const codeSizeDirectory = StringOptionDescriptor(
    name: FlutterOptions.kCodeSizeDirectory,
    help:
        'The location to write code size analysis files. If this is not specified, files '
        'are written to a temporary directory under the build directory.',
  );

  static const obfuscate = FlagOptionDescriptor(
    name: FlutterOptions.kDartObfuscationOption,
    help:
        'In a release build, this flag removes identifiers and replaces them '
        'with randomized values for the purposes of source code obfuscation. This '
        'flag must always be combined with "--${FlutterOptions.kSplitDebugInfoOption}", '
        'the mapping between the values and the original identifiers is stored in the '
        'symbol map created in the specified directory. For an app built with this '
        'flag, the "flutter symbolize" command with the right program '
        'symbol file is required to obtain a human readable stack trace.\n'
        'Because all identifiers are renamed, methods like Object.runtimeType, '
        'Type.toString, Enum.toString, Stacktrace.toString, Symbol.toString '
        '(for constant symbols or those generated by runtime system) will '
        'return obfuscated results. Any code or tests that rely on exact names '
        'will break.',
  );

  static const splitDebugInfo = StringOptionDescriptor(
    name: FlutterOptions.kSplitDebugInfoOption,
    valueHelp: 'v1.2.3/',
    help:
        'In a release build, this flag reduces application size by storing '
        'Dart program symbols in a separate file on the host rather than in the '
        'application. The value of the flag should be a directory where program '
        'symbol files can be stored for later use. These symbol files contain '
        'the information needed to symbolize Dart stack traces. For an app built '
        'with this flag, the "flutter symbolize" command with the right program '
        'symbol file is required to obtain a human readable stack trace.\n'
        'This flag cannot be combined with "--${FlutterOptions.kAnalyzeSize}".',
  );

  static const androidGradleDaemon = FlagOptionDescriptor(
    name: FlutterOptions.kAndroidGradleDaemon,
    defaultsTo: true,
    help: 'Whether to enable the Gradle daemon when performing an Android build.',
  );

  static const androidProjectArg = MultiOptionDescriptor(
    name: FlutterOptions.kAndroidProjectArgs,
    abbr: 'P',
    aliases: <String>['android-project-args'],
    help:
        'Additional arguments specified as key=value that are passed directly to the gradle project '
        'via the -P flag. These can be accessed in build.gradle via the "project.property" API.',
  );

  static const androidProjectCacheDir = StringOptionDescriptor(
    name: FlutterOptions.kAndroidGradleProjectCacheDir,
    valueHelp: 'path/to/project/cache/',
    help:
        'In an Android build, this flag allows the Gradle project cache directory to be specified '
        'to an absolute path. Setting this is roughly equivalent to setting the '
        'GRADLE_PROJECT_CACHE_DIR environment variable.',
  );

  static const androidSkipBuildDependencyValidation = FlagOptionDescriptor(
    name: FlutterOptions.kAndroidSkipBuildDependencyValidation,
    help: 'Skips Android Gradle project dependency verification.',
  );

  static const performanceMeasurementFile = StringOptionDescriptor(
    name: FlutterOptions.kPerformanceMeasurementFile,
    help: 'Output file name for performance measurement file.',
  );

  static const flavor = StringOptionDescriptor(
    name: 'flavor',
    help:
        'Build a custom app flavor as defined by platform-specific build setup.\n'
        'Supports the use of product flavors in Android Gradle scripts, and '
        'the use of custom Xcode schemes.\n'
        'Overrides the value of the "default-flavor" entry in the flutter pubspec.',
  );

  static const codesign = FlagOptionDescriptor(
    name: FlutterOptions.kCodesign,
    defaultsTo: true,
    help: 'Whether to code-sign XCFrameworks.',
  );

  static const frontendServerStarterPath = StringOptionDescriptor(
    name: FlutterOptions.kFrontendServerStarterPath,
    verboseOnly: true,
    help:
        'When this value is provided, the frontend server will be started '
        'in JIT mode from the specified file, instead of from the AOT '
        'snapshot shipped with the Dart SDK. The specified file can either '
        'be a dart source file or a kernel file.\n'
        'This flag is not used by most normal users and is for backend '
        'testing only.',
  );

  static const initializeFromDill = StringOptionDescriptor(
    name: FlutterOptions.kInitializeFromDill,
    help:
        'Initializes the resident compiler with a specific kernel file instead of '
        'the default cached location.',
    verboseOnly: true,
  );

  static const extraFrontEndOptions = MultiOptionDescriptor(
    name: FlutterOptions.kExtraFrontEndOptions,
    aliases: <String>[kExtraFrontEndOptions], // supported for historical reasons
    help:
        'A comma-separated list of additional command line arguments that will be passed directly to the Dart front end. '
        'For example, "--${FlutterOptions.kExtraFrontEndOptions}=--enable-experiment=nonfunction-type-aliases".',
    valueHelp: '--foo,--bar',
    verboseOnly: true,
  );

  static const extraGenSnapshotOptions = MultiOptionDescriptor(
    name: FlutterOptions.kExtraGenSnapshotOptions,
    aliases: <String>[kExtraGenSnapshotOptions], // supported for historical reasons
    help:
        'A comma-separated list of additional command line arguments that will be passed directly to the Dart native compiler. '
        '(Requires the "--release", "--profile", or "--jit-release" flag.)',
    valueHelp: '--foo,--bar',
    verboseOnly: true,
  );

  static const assumeInitializeFromDillUpToDate = FlagOptionDescriptor(
    name: FlutterOptions.kAssumeInitializeFromDillUpToDate,
    help:
        'If set, assumes that the file passed in initialize-from-dill is up '
        'to date and skip the check and potential invalidation of files.',
    verboseOnly: true,
  );
}

/// A bundle encapsulating general options for building.
class BuildInfoOptionsBundle extends OptionBundle {
  const BuildInfoOptionsBundle();

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    BuildInfoOptions.trackWidgetCreation,
    BuildInfoOptions.analyzeSize,
    BuildInfoOptions.codeSizeDirectory,
    BuildInfoOptions.obfuscate,
    BuildInfoOptions.splitDebugInfo,
    BuildInfoOptions.androidGradleDaemon,
    BuildInfoOptions.androidProjectArg,
    BuildInfoOptions.androidProjectCacheDir,
    BuildInfoOptions.androidSkipBuildDependencyValidation,
    BuildInfoOptions.performanceMeasurementFile,
    BuildInfoOptions.flavor,
    BuildInfoOptions.codesign,
    BuildInfoOptions.frontendServerStarterPath,
    BuildInfoOptions.initializeFromDill,
    BuildInfoOptions.extraFrontEndOptions,
    BuildInfoOptions.extraGenSnapshotOptions,
    BuildInfoOptions.assumeInitializeFromDillUpToDate,
  ];
}

/// A bundle encapsulating standard build mode flags (`--debug`, `--profile`, `--release`, `--jit-release`).
class BuildModeOptionsBundle extends OptionBundle {
  const BuildModeOptionsBundle({this.defaultToRelease = true});

  final bool defaultToRelease;

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
  const DartCompileOptionsBundle();

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
  const CommonBuildOptionsBundle();

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
