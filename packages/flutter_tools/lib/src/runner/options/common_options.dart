// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../build_info.dart';
import '../flutter_command.dart';
import '../flutter_command_runner.dart';

/// Common typed option descriptors across flutter commands.
abstract final class CommonOptions {
  static const ci = FlagOptionDescriptor(
    name: FlutterGlobalOptions.kContinuousIntegrationFlag,
    negatable: false,
    scope: OptionScope.global,
    verboseOnly: true,
    help: 'Enable a set of CI-specific test debug settings.',
  );

  static const treeShakeIcons = FlagOptionDescriptor(
    name: 'tree-shake-icons',
    defaultsTo: true,
    help: 'Tree shake icon fonts so that only glyphs used by the application are included.',
  );

  static const target = DefaultedStringOptionDescriptor(
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
    verboseOnly: true,
    help: 'Build a JIT release version of your app.',
  );

  static const fatalWarnings = FlagOptionDescriptor(
    name: FlutterOptions.kFatalWarnings,
    verboseOnly: true,
    help:
        'Causes the command to fail if warnings are sent to the console '
        'during its execution.',
  );

  static const machine = FlagOptionDescriptor(
    name: FlutterGlobalOptions.kMachineFlag,
    negatable: false,
    verboseOnly: true,
    help: 'Outputs in a machine readable structured JSON format.',
  );

  static const packages = StringOptionDescriptor(
    name: FlutterGlobalOptions.kPackagesOption,
    scope: OptionScope.global,
    verboseOnly: true,
    help: 'Path to your "package_config.json" file.',
  );

  static const debugLogsDir = StringOptionDescriptor(
    name: FlutterGlobalOptions.kDebugLogsDirectoryFlag,
    scope: OptionScope.global,
    verboseOnly: true,
    help: 'Path to a directory where logs for debugging may be added.',
  );

  static const printDtd = FlagOptionDescriptor(
    name: FlutterGlobalOptions.kPrintDtd,
    negatable: false,
    scope: OptionScope.global,
    verboseOnly: true,
    help: 'Print the address of the Dart Tooling Daemon, if one is hosted by the Flutter CLI.',
  );

  static const localWebSdk = StringOptionDescriptor(
    name: FlutterGlobalOptions.kLocalWebSDKOption,
    scope: OptionScope.global,
    verboseOnly: true,
    help:
        'Name of a build output within the engine out directory, if you are building Flutter locally.\n'
        'Use this to select a specific version of the web sdk if you have built multiple engine targets.\n'
        'This path is relative to "--local-engine-src-path" (see above).',
  );

  static const offline = FlagOptionDescriptor(
    name: 'offline',
    help:
        'When "flutter pub get" is run by the create command, this indicates '
        'whether to run it in offline mode or not. In offline mode, it will need to '
        'have all dependencies already available in the pub cache to succeed.',
  );

  static const deviceUser = StringOptionDescriptor(
    name: FlutterOptions.kDeviceUser,
    valueHelp: '10',
    help:
        'Identifier number for a user or work profile on Android only. '
        'Run "adb shell pm list users" for available identifiers.',
  );

  static const deviceTimeout = StringOptionDescriptor(
    name: FlutterOptions.kDeviceTimeout,
    valueHelp: '10',
    help:
        'Time in seconds to wait for devices to attach. '
        'Longer timeouts may be necessary for networked devices.',
  );

  static const deviceConnection = DefaultedStringOptionDescriptor(
    name: FlutterOptions.kDeviceConnection,
    defaultsTo: 'both',
    help: 'Discover devices based on connection type.',
    allowed: <String>['attached', 'wireless', 'both'],
    allowedHelp: <String, String>{
      'both': 'Searches for both attached and wireless devices.',
      'attached': 'Only searches for devices connected by USB or built-in (such as simulators/emulators, MacOS/Windows, Chrome)',
      'wireless': 'Only searches for devices connected wirelessly. Discovering wireless devices may take longer.',
    },
  );

  static const useApplicationBinary = StringOptionDescriptor(
    name: FlutterOptions.kUseApplicationBinary,
    valueHelp: 'path/to/app.apk',
    help:
        'Specify a pre-built application binary to use when running. For Android applications, '
        'this must be the path to an APK. For iOS applications, the path to an IPA. Other device types '
        'do not yet support prebuilt application binaries.',
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
    verboseOnly: true,
    help: 'Whether to enable the Gradle daemon when performing an Android build.',
  );

  static const androidProjectArg = MultiOptionDescriptor(
    name: FlutterOptions.kAndroidProjectArgs,
    abbr: 'P',
    aliases: <String>['android-project-args'],
    verboseOnly: true,
    help:
        'Additional arguments specified as key=value that are passed directly to the gradle project '
        'via the -P flag. These can be accessed in build.gradle via the "project.property" API.',
  );

  static const androidProjectCacheDir = StringOptionDescriptor(
    name: FlutterOptions.kAndroidGradleProjectCacheDir,
    valueHelp: 'path/to/project/cache/',
    verboseOnly: true,
    help:
        'In an Android build, this flag allows the Gradle project cache directory to be specified '
        'to an absolute path. Setting this is roughly equivalent to setting the '
        'GRADLE_PROJECT_CACHE_DIR environment variable.',
  );

  static const androidSkipBuildDependencyValidation = FlagOptionDescriptor(
    name: FlutterOptions.kAndroidSkipBuildDependencyValidation,
    verboseOnly: true,
    help: 'Skips Android Gradle project dependency verification.',
  );

  static const performanceMeasurementFile = StringOptionDescriptor(
    name: FlutterOptions.kPerformanceMeasurementFile,
    help: 'Output individual target performance to a JSON file.',
  );

  static const configOnly = FlagOptionDescriptor(
    name: 'config-only',
    help:
        'Update the project configuration without performing a build. '
        'This can be used in CI/CD process that create an archive to avoid '
        'performing duplicate work.',
  );

  static const shrink = FlagOptionDescriptor(
    name: 'shrink',
    verboseOnly: true,
    help:
        'This flag has no effect. Code shrinking is always enabled in release builds. '
        'To learn more, see: https://developer.android.com/studio/build/shrink-code',
  );

  static const ignoreDeprecation = FlagOptionDescriptor(
    name: 'ignore-deprecation',
    negatable: false,
    help:
        'Indicates that the app should ignore deprecation warnings and continue to build '
        'using deprecated APIs. Use of this flag may cause your app to fail to build when '
        'deprecated APIs are removed.',
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

  static const codesignIdentity = StringOptionDescriptor(
    name: FlutterOptions.kCodesignIdentity,
    help:
        'The identity to use for code-signing XCFrameworks. If an identity is not provided and '
        '"${FlutterOptions.kCodesign}" is enabled, a code signing identity will be selected '
        "automatically from the Flutter app's Xcode project settings or Flutter config. To see "
        'a list of valid identities run "security find-identity -p codesigning -v".',
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

  static const outputDill = StringOptionDescriptor(
    name: 'output-dill',
    verboseOnly: true,
    help: 'Specify the path to frontend server output kernel file.',
  );

  static const fileSystemRoot = MultiOptionDescriptor(
    name: FlutterOptions.kFileSystemRoot,
    verboseOnly: true,
    help:
        'Specify the path that is used as the root of a virtual file system '
        'during compilation. The input file name should be specified as a URL '
        'using the scheme given in "--${FlutterOptions.kFileSystemScheme}".\n'
        'Requires the "--output-dill" option to be explicitly specified.',
  );

  static const fileSystemScheme = DefaultedStringOptionDescriptor(
    name: FlutterOptions.kFileSystemScheme,
    defaultsTo: 'org-dartlang-root',
    verboseOnly: true,
    help:
        'Specify the scheme that is used for virtual file system used in '
        'compilation. See also the "--${FlutterOptions.kFileSystemRoot}" option.',
  );

  static const nativeAssetsYamlFile = StringOptionDescriptor(
    name: FlutterOptions.kNativeAssetsYamlFile,
    verboseOnly: true,
    help:
        'Initializes the resident compiler with a custom native assets '
        'yaml file instead of the default cached location.',
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
  const BuildModeOptionsBundle({
    this.defaultToRelease = true,
    this.excludeDebug = false,
    this.excludeRelease = false,
  }) : assert(defaultToRelease || !excludeDebug),
       assert(!defaultToRelease || !excludeRelease);

  final bool defaultToRelease;
  final bool excludeDebug;
  final bool excludeRelease;

  @override
  void onRegister(FlutterCommand command) {
    command.configureBuildModes(
      defaultToRelease: defaultToRelease,
      excludeDebug: excludeDebug,
      excludeRelease: excludeRelease,
    );
  }

  @override
  List<OptionDescriptor<Object?>> get descriptors => <OptionDescriptor<Object?>>[
    if (!excludeDebug) CommonOptions.debugMode,
    CommonOptions.profileMode,
    if (!excludeRelease) ...const <OptionDescriptor<Object?>>[
      CommonOptions.releaseMode,
      CommonOptions.jitReleaseMode,
    ],
  ];
}

/// A bundle encapsulating device discovery options (`--device-timeout`, `--device-connection`, and optionally `--device-user`).
class DeviceDiscoveryOptionsBundle extends OptionBundle {
  const DeviceDiscoveryOptionsBundle({this.includeDeviceUser = false});

  final bool includeDeviceUser;

  @override
  List<OptionDescriptor<Object?>> get descriptors => <OptionDescriptor<Object?>>[
    CommonOptions.deviceTimeout,
    CommonOptions.deviceConnection,
    if (includeDeviceUser) CommonOptions.deviceUser,
  ];
}

/// A bundle encapsulating virtual filesystem options (`--output-dill`, `--filesystem-root`, `--filesystem-scheme`).
class FilesystemOptionsBundle extends OptionBundle {
  const FilesystemOptionsBundle();

  @override
  List<OptionDescriptor<Object?>> get descriptors => const <OptionDescriptor<Object?>>[
    BuildInfoOptions.outputDill,
    BuildInfoOptions.fileSystemRoot,
    BuildInfoOptions.fileSystemScheme,
  ];
}

/// A bundle encapsulating Dart VM Service port and IPv6 options (`--vm-service-port`, `--device-vmservice-port`, `--host-vmservice-port`, and optionally `--ipv6`).
class VmServicePortOptionsBundle extends OptionBundle {
  const VmServicePortOptionsBundle({this.includeIpv6 = true});

  final bool includeIpv6;

  @override
  void onRegister(FlutterCommand command) {
    command.enableUsesPortOption();
    if (includeIpv6) {
      command.enableUsesIpv6Flag();
    }
  }

  @override
  List<OptionDescriptor<Object?>> get descriptors => <OptionDescriptor<Object?>>[
    DebuggingOptionDescriptors.vmServicePort,
    DebuggingOptionDescriptors.deviceVmservicePort,
    DebuggingOptionDescriptors.hostVmservicePort,
    if (includeIpv6) DebuggingOptionDescriptors.ipv6,
  ];
}

/// A bundle encapsulating DDS and DevTools options (`--dds`, `--dds-port`, `--disable-dds`, `--devtools`, `--devtools-server-address`).
class DdsAndDevToolsOptionsBundle extends OptionBundle {
  const DdsAndDevToolsOptionsBundle({
    this.includeDevTools = true,
    this.includeEnableDevTools = true,
  });

  final bool includeDevTools;
  final bool includeEnableDevTools;

  @override
  List<OptionDescriptor<Object?>> get descriptors => <OptionDescriptor<Object?>>[
    DebuggingOptionDescriptors.ddsPort,
    DebuggingOptionDescriptors.dds,
    DebuggingOptionDescriptors.disableDds,
    if (includeDevTools) ...<OptionDescriptor<Object?>>[
      if (includeEnableDevTools) DebuggingOptionDescriptors.enableDevTools,
      DebuggingOptionDescriptors.devToolsServerAddress(
        includeEnableDevTools: includeEnableDevTools,
      ),
    ],
  ];
}

/// A bundle encapsulating resident compiler options (`--initialize-from-dill`, `--assume-initialize-from-dill-up-to-date`, `--native-assets-yaml-file`, and optional compiler flags).
class ResidentCompilerOptionsBundle extends OptionBundle {
  const ResidentCompilerOptionsBundle({
    this.includeFrontendServerStarterPath = false,
    this.includeExtraDartFlags = false,
  });

  final bool includeFrontendServerStarterPath;
  final bool includeExtraDartFlags;

  @override
  List<OptionDescriptor<Object?>> get descriptors => <OptionDescriptor<Object?>>[
    BuildInfoOptions.initializeFromDill,
    BuildInfoOptions.assumeInitializeFromDillUpToDate,
    BuildInfoOptions.nativeAssetsYamlFile,
    if (includeFrontendServerStarterPath) BuildInfoOptions.frontendServerStarterPath,
    if (includeExtraDartFlags) ...const <OptionDescriptor<Object?>>[
      BuildInfoOptions.extraFrontEndOptions,
      BuildInfoOptions.extraGenSnapshotOptions,
    ],
  ];
}

/// A bundle encapsulating Impeller and Flutter GPU rendering engine flags.
class EngineRenderingFlagsBundle extends OptionBundle {
  const EngineRenderingFlagsBundle({
    this.includeVulkanAndEmbedder = true,
    this.includeTestFlag = false,
  });

  final bool includeVulkanAndEmbedder;
  final bool includeTestFlag;

  @override
  List<OptionDescriptor<Object?>> get descriptors => <OptionDescriptor<Object?>>[
    DebuggingOptionDescriptors.enableImpeller,
    DebuggingOptionDescriptors.enableFlutterGpu,
    DebuggingOptionDescriptors.enableHcpp,
    if (includeVulkanAndEmbedder) ...const <OptionDescriptor<Object?>>[
      DebuggingOptionDescriptors.enableVulkanValidation,
      DebuggingOptionDescriptors.enableEmbedderApi,
    ],
    if (includeTestFlag) DebuggingOptionDescriptors.testFlag,
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
  ];
}

/// A bundle encapsulating basic build parameters (target, pub, build-number/name).
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
    CommonOptions.pub,
    CommonOptions.buildNumber,
    CommonOptions.buildName,
  ];
}

/// A bundle encapsulating Gradle-specific Android build options.
class AndroidGradleOptionsBundle extends OptionBundle {
  const AndroidGradleOptionsBundle();

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    BuildInfoOptions.androidGradleDaemon,
    BuildInfoOptions.androidSkipBuildDependencyValidation,
    BuildInfoOptions.androidProjectArg,
    BuildInfoOptions.androidProjectCacheDir,
  ];
}

/// A bundle encapsulating general options for Android builds.
class AndroidBuildOptionsBundle extends OptionBundle {
  const AndroidBuildOptionsBundle();

  static const _kAndroidTargetPlatforms = <String>['android-arm', 'android-arm64', 'android-x64'];

  static const targetPlatform = MultiOptionDescriptor(
    name: 'target-platform',
    allowed: _kAndroidTargetPlatforms,
    help: 'The target platform for which the app is compiled.',
  );

  static const targetPlatformWithDefaults = MultiOptionDescriptor(
    name: 'target-platform',
    defaultsTo: _kAndroidTargetPlatforms,
    allowed: _kAndroidTargetPlatforms,
    help: 'The target platform for which the app is compiled.',
  );

  @override
  List<OptionBundle> get subBundles => const [AndroidGradleOptionsBundle()];

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    BuildInfoOptions.flavor,
    BuildInfoOptions.shrink,
    BuildInfoOptions.splitDebugInfo,
    BuildInfoOptions.obfuscate,
    BuildInfoOptions.extraFrontEndOptions,
    BuildInfoOptions.extraGenSnapshotOptions,
    BuildInfoOptions.performanceMeasurementFile,
    BuildInfoOptions.analyzeSize,
    BuildInfoOptions.codeSizeDirectory,
    BuildInfoOptions.trackWidgetCreation,
    BuildInfoOptions.ignoreDeprecation,
    DebuggingOptionDescriptors.enableHcpp,
  ];
}

/// A bundle encapsulating general options for Apple (iOS and macOS) builds.
class AppleBuildOptionsBundle extends OptionBundle {
  const AppleBuildOptionsBundle();

  static const FlagOptionDescriptor configOnly = BuildInfoOptions.configOnly;

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    BuildInfoOptions.flavor,
    BuildInfoOptions.splitDebugInfo,
    BuildInfoOptions.obfuscate,
    BuildInfoOptions.extraFrontEndOptions,
    BuildInfoOptions.extraGenSnapshotOptions,
    BuildInfoOptions.performanceMeasurementFile,
    BuildInfoOptions.analyzeSize,
    BuildInfoOptions.codeSizeDirectory,
  ];
}

/// A bundle encapsulating Darwin XCFramework code-signing options (`--codesign` and `--codesign-identity`).
class DarwinCodeSignXCFrameworksOptionsBundle extends OptionBundle {
  const DarwinCodeSignXCFrameworksOptionsBundle();

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    BuildInfoOptions.codesign,
    BuildInfoOptions.codesignIdentity,
  ];
}

/// A bundle encapsulating shared options for Darwin Add-to-App builds (`build ios-framework`, `build macos-framework`, and `build swift-package`).
class DarwinAddToAppOptionsBundle extends OptionBundle {
  const DarwinAddToAppOptionsBundle();

  static const staticFrameworks = FlagOptionDescriptor(
    name: 'static',
    help:
        'Build plugins as static frameworks. Link on, but do not embed these '
        'frameworks in the existing Xcode project.',
  );

  @override
  void onRegister(FlutterCommand command) {
    command.enableUsesTargetOption();
    command.enableUsesPubOption();
  }

  @override
  List<OptionBundle> get subBundles => const [
    DartCompileOptionsBundle(),
    DarwinCodeSignXCFrameworksOptionsBundle(),
  ];

  @override
  List<OptionDescriptor<Object?>> get descriptors => const [
    CommonOptions.treeShakeIcons,
    CommonOptions.target,
    CommonOptions.pub,
    BuildInfoOptions.splitDebugInfo,
    BuildInfoOptions.obfuscate,
    BuildInfoOptions.extraFrontEndOptions,
    BuildInfoOptions.extraGenSnapshotOptions,
    staticFrameworks,
  ];
}

/// A bundle encapsulating general options for desktop (`linux` and `windows`) builds.
class DesktopBuildOptionsBundle extends OptionBundle {
  const DesktopBuildOptionsBundle();

  static const FlagOptionDescriptor configOnly = BuildInfoOptions.configOnly;

  @override
  List<OptionBundle> get subBundles => const <OptionBundle>[
    CommonBuildOptionsBundle(),
    BuildModeOptionsBundle(),
    DartCompileOptionsBundle(),
  ];

  @override
  List<OptionDescriptor<Object?>> get descriptors => const <OptionDescriptor<Object?>>[
    BuildInfoOptions.flavor,
    BuildInfoOptions.splitDebugInfo,
    BuildInfoOptions.obfuscate,
    BuildInfoOptions.extraFrontEndOptions,
    BuildInfoOptions.extraGenSnapshotOptions,
    BuildInfoOptions.performanceMeasurementFile,
    BuildInfoOptions.analyzeSize,
    BuildInfoOptions.codeSizeDirectory,
    BuildInfoOptions.trackWidgetCreation,
    configOnly,
  ];
}

/// Typed option descriptors specific to `DebuggingOptions` and resident runners (`run`, `drive`, `test`).
abstract final class DebuggingOptionDescriptors {
  static const enableImpeller = NullableFlagOptionDescriptor(
    name: FlutterOptions.kEnableImpeller,
    verboseOnly: true,
    help:
        'Whether to enable the Impeller rendering engine. '
        'Impeller is the default renderer on iOS. On Android, Impeller '
        'is available but not the default. This flag will cause Impeller '
        'to be used on Android. On other platforms, this flag will be '
        'ignored.',
  );

  static const enableFlutterGpu = NullableFlagOptionDescriptor(
    name: 'enable-flutter-gpu',
    verboseOnly: true,
    help:
        'Whether to enable the Flutter GPU API (https://api.flutter.dev/flutter/flutter_gpu/). '
        'This feature is only supported with the Impeller rendering engine, '
        'which can be enabled via the "--${FlutterOptions.kEnableImpeller}" '
        'option.',
  );

  static const enableVulkanValidation = FlagOptionDescriptor(
    name: 'enable-vulkan-validation',
    verboseOnly: true,
    help:
        'Enable vulkan validation on the Impeller rendering backend if '
        'Vulkan is in use and the validation layers are available to the '
        'application.',
  );

  static const enableEmbedderApi = FlagOptionDescriptor(
    name: 'enable-embedder-api',
    verboseOnly: true,
    help: 'Whether to enable the experimental embedder API on iOS.',
  );

  static const enableHcpp = NullableFlagOptionDescriptor(
    name: 'enable-hcpp',
    verboseOnly: true,
    help:
        'Enable the use of the HCPP platform view rendering mode on the Impeller rendering '
        'backend. An explicit value takes priority over the EnableHcpp metadata in '
        'AndroidManifest.xml: build commands write it into the manifest of the artifact they '
        'produce, and "run", "test", and "drive" additionally apply it at launch. Without the '
        'flag, the manifest decides, and if the manifest does not set it either, the '
        'enable-hcpp feature flag does.',
  );

  static const testFlag = FlagOptionDescriptor(
    name: 'test-flag',
    verboseOnly: true,
    help: 'No-op flag for testing purposes; use for testing flag priorities only.',
  );

  static const adbLogFiltering = FlagOptionDescriptor(
    name: 'adb-log-filtering',
    defaultsTo: true,
    help:
        'Filter adb logs so that logs not emitted by the current flutter application are not '
        'displayed.',
  );

  static const dds = FlagOptionDescriptor(
    name: 'dds',
    defaultsTo: true,
    help:
        'Enable the Dart Developer Service (DDS).\n'
        'It may be necessary to disable this when attaching to an application with '
        'an existing DDS instance (e.g., attaching to an application currently '
        'connected to by "flutter run"), or when running certain tests.\n'
        'Disabling this feature may degrade IDE functionality if a DDS instance is '
        'not already connected to the target application.',
  );

  static const ddsPort = DefaultedIntOptionDescriptor(
    name: 'dds-port',
    defaultsTo: 0,
    help:
        'When this value is provided, the Dart Development Service (DDS) will be '
        'bound to the provided port.\n'
        'Specifying port 0 (the default) will find a random free port.',
  );

  static const publishPort = FlagOptionDescriptor(
    name: 'publish-port',
    defaultsTo: true,
    verboseOnly: true,
    help:
        'Publish the VM service port over mDNS. Disable to prevent the '
        'local network permission app dialog in debug and profile build modes (iOS devices only).',
  );

  static FlagOptionDescriptor publishPortOption({bool enabledByDefault = true}) {
    if (enabledByDefault) {
      return publishPort;
    }
    return const FlagOptionDescriptor(
      name: 'publish-port',
      verboseOnly: true,
      help:
          'Publish the VM service port over mDNS. Disable to prevent the '
          'local network permission app dialog in debug and profile build modes (iOS devices only).',
    );
  }

  static const disableDds = FlagOptionDescriptor(
    name: 'disable-dds',
    verboseOnly: true,
    help:
        '(deprecated; use "--no-dds" instead) '
        'Disable the Dart Developer Service (DDS).',
  );

  static const enableDevTools = FlagOptionDescriptor(
    name: FlutterCommand.kEnableDevTools,
    defaultsTo: true,
    verboseOnly: true,
    help:
        'Enable (or disable, with "--no-${FlutterCommand.kEnableDevTools}") the launching of the '
        'Flutter DevTools debugger and profiler. '
        'If "--no-${FlutterCommand.kEnableDevTools}" is specified, "--${FlutterCommand.kDevToolsServerAddress}" is ignored.',
  );

  static StringOptionDescriptor devToolsServerAddress({bool includeEnableDevTools = true}) {
    final ignoredMessage = includeEnableDevTools
        ? ' Ignored if "--no-${FlutterCommand.kEnableDevTools}" is specified.'
        : '';
    return StringOptionDescriptor(
      name: FlutterCommand.kDevToolsServerAddress,
      verboseOnly: true,
      help:
          'When this value is provided, the Flutter tool will not spin up a '
          'new DevTools server instance, and will instead use the one provided '
          'at the given address.$ignoredMessage',
    );
  }

  static const devToolsServerAddressOption = StringOptionDescriptor(
    name: FlutterCommand.kDevToolsServerAddress,
    verboseOnly: true,
    help:
        'When this value is provided, the Flutter tool will not spin up a '
        'new DevTools server instance, and will instead use the one provided '
        'at the given address.',
  );

  static const ipv6 = FlagOptionDescriptor(
    name: FlutterCommand.ipv6Flag,
    negatable: false,
    verboseOnly: true,
    help:
        'Binds to IPv6 localhost instead of IPv4 when the flutter tool '
        'forwards the host port to a device port.',
  );

  static const traceStartup = FlagOptionDescriptor(
    name: 'trace-startup',
    negatable: false,
    help:
        'Trace application startup, then exit, saving the trace to a file. '
        'By default, this will be saved in the "build" directory. If the '
        'FLUTTER_TEST_OUTPUTS_DIR environment variable is set, the file '
        'will be written there instead.',
  );

  static const cacheStartupProfile = FlagOptionDescriptor(
    name: 'cache-startup-profile',
    help:
        'Caches the CPU profile collected before the first frame for startup '
        'analysis.',
  );

  static const verboseSystemLogs = FlagOptionDescriptor(
    name: 'verbose-system-logs',
    negatable: false,
    help: 'Include verbose logging from the Flutter engine.',
  );

  static const purgePersistentCache = FlagOptionDescriptor(
    name: 'purge-persistent-cache',
    negatable: false,
    help:
        'Removes all existing persistent caches. This allows reproducing '
        'shader compilation jank that normally only happens the first time '
        'an app is run, or for reliable testing of compilation jank fixes '
        '(e.g. shader warm-up).',
  );

  static const route = StringOptionDescriptor(
    name: 'route',
    help: 'Which route to load when running the app.',
  );

  static const vmserviceOutFile = StringOptionDescriptor(
    name: 'vmservice-out-file',
    valueHelp: 'project/example/out.txt',
    verboseOnly: true,
    help:
        'A file to write the attached vmservice URL to after an '
        'application is started.',
  );

  static const disableServiceAuthCodes = FlagOptionDescriptor(
    name: 'disable-service-auth-codes',
    negatable: false,
    verboseOnly: true,
    help:
        '(deprecated) Allow connections to the VM service without using authentication codes. '
        '(Not recommended! This can open your device to remote code execution attacks!)',
  );

  static const disableServiceOriginCheck = FlagOptionDescriptor(
    name: 'disable-service-origin-check',
    negatable: false,
    verboseOnly: true,
    help:
        'Allow connections to the VM service from any origin. '
        '(Not recommended. This can open your device to remote code execution attacks.)',
  );

  static FlagOptionDescriptor startPaused({bool defaultsTo = false}) => FlagOptionDescriptor(
    name: 'start-paused',
    defaultsTo: defaultsTo,
    help: 'Start in a paused mode and wait for a debugger to connect.',
  );

  static const startPausedOption = FlagOptionDescriptor(
    name: 'start-paused',
    help: 'Start in a paused mode and wait for a debugger to connect.',
  );

  static const dartFlags = StringOptionDescriptor(
    name: 'dart-flags',
    verboseOnly: true,
    help:
        'Pass a list of comma separated flags to the Dart instance at '
        'application startup. Flags passed through this option must be '
        'present on the allowlist defined within the Flutter engine. If '
        'a disallowed flag is encountered, the process will be '
        'terminated immediately.\n\n'
        'This flag is not available on the stable channel and is only '
        'applied in debug and profile modes. This option should only '
        'be used for experiments and should not be used by typical users.',
  );

  static const endlessTraceBuffer = FlagOptionDescriptor(
    name: 'endless-trace-buffer',
    negatable: false,
    help:
        'Enable tracing to an infinite buffer, instead of a ring buffer. '
        'This is useful when recording large traces. To use an endless buffer to '
        'record startup traces, combine this with "--trace-startup".',
  );

  static const traceSystrace = FlagOptionDescriptor(
    name: 'trace-systrace',
    negatable: false,
    help:
        'Enable tracing to the system tracer. This is only useful on '
        'platforms where such a tracer is available (Android, iOS, '
        'macOS and Fuchsia).',
  );

  static const traceToFile = StringOptionDescriptor(
    name: 'trace-to-file',
    valueHelp: 'path/to/trace.binpb',
    help:
        'Write the timeline trace to a file at the specified path. The '
        "file will be in Perfetto's proto format; it will be possible to "
        "load the file into Perfetto's trace viewer.",
  );

  static const profileMicrotasks = FlagOptionDescriptor(
    name: 'profile-microtasks',
    negatable: false,
    verboseOnly: true,
    help:
        'Enable collection of information about each microtask. '
        'Information about completed microtasks will be written to the '
        '"Microtask" timeline stream. Information about queued microtasks '
        'will be accessible from Dart / Flutter DevTools.',
  );

  static const traceSkia = FlagOptionDescriptor(
    name: 'trace-skia',
    negatable: false,
    help:
        'Enable tracing of Skia code. This is useful when debugging '
        'the raster thread (formerly known as the GPU thread). '
        'By default, Flutter will not log Skia code, as it introduces significant '
        'overhead that may affect recorded performance metrics in a misleading way.',
  );

  static const traceAllowlist = StringOptionDescriptor(
    name: 'trace-allowlist',
    valueHelp: 'foo,bar',
    verboseOnly: true,
    help:
        'Filters out all trace events except those that are specified in '
        'this comma separated list of allowed prefixes.',
  );

  static const traceSkiaAllowlist = StringOptionDescriptor(
    name: 'trace-skia-allowlist',
    valueHelp: 'skia.gpu,skia.shaders',
    verboseOnly: true,
    help:
        'Filters out all Skia trace events except those that are specified in '
        'this comma separated list of allowed prefixes.',
  );

  static const enableDartProfiling = FlagOptionDescriptor(
    name: 'enable-dart-profiling',
    defaultsTo: true,
    help:
        'Whether the Dart VM sampling CPU profiler is enabled. This flag '
        'is only meaningful in debug and profile builds.',
  );

  static const profileStartup = FlagOptionDescriptor(
    name: 'profile-startup',
    negatable: false,
    verboseOnly: true,
    help:
        'Make the profiler discard new samples once the profiler sample '
        'buffer is full. When this flag is not set, the profiler sample '
        'buffer is used as a ring buffer, meaning that once it is full, '
        'new samples start overwriting the oldest ones.',
  );

  static const enableSoftwareRendering = FlagOptionDescriptor(
    name: 'enable-software-rendering',
    negatable: false,
    verboseOnly: true,
    help:
        '(deprecated) Enable rendering using the Skia software backend. '
        'This is useful when testing Flutter on emulators. By default, '
        'Flutter will attempt to either use OpenGL or Vulkan and fall back '
        'to software when neither is available. This option is not supported '
        'when using the Impeller rendering engine.',
  );

  static const skiaDeterministicRendering = FlagOptionDescriptor(
    name: 'skia-deterministic-rendering',
    negatable: false,
    verboseOnly: true,
    help:
        '(deprecated) When combined with "--enable-software-rendering", this should provide completely '
        'deterministic (i.e. reproducible) Skia rendering. This is useful for testing purposes '
        '(e.g. when comparing screenshots). This option is not supported '
        'when using the Impeller rendering engine.',
  );

  static const dartEntrypointArgs = MultiOptionDescriptor(
    name: 'dart-entrypoint-args',
    abbr: 'a',
    help:
        'Pass a list of arguments to the Dart entrypoint at application '
        'startup. By default this is main(List<String> args). Specify '
        'this option multiple times each with one argument to pass '
        'multiple arguments to the Dart entrypoint. Currently this is '
        'only supported on desktop platforms.',
  );

  static const uninstallFirst = FlagOptionDescriptor(
    name: 'uninstall-first',
    verboseOnly: true,
    help:
        'Uninstall previous versions of the app on the device '
        'before reinstalling. Currently only supported on iOS.',
  );

  static const iosProfileDebugger = NullableFlagOptionDescriptor(
    name: 'ios-profile-debugger',
    negatable: false,
    help: 'Whether to attach the LLDB debugger when running in profile mode on a physical iOS device. Only available with Xcode 26.',
  );

  static const useTestFonts = FlagOptionDescriptor(
    name: 'use-test-fonts',
    help:
        'Enable (and default to) the "Ahem" font. This is a special font '
        'used in tests to remove any dependencies on the font metrics. It '
        'is enabled when you use "flutter test". Set this flag when running '
        'a test using "flutter run" for debugging purposes. This flag is '
        'only available when running in debug mode.',
  );

  static const vmServicePort = StringOptionDescriptor(
    name: FlutterCommand.vmServicePortOption,
    verboseOnly: true,
    help:
        '(deprecated; use host-vmservice-port instead) '
        'Listen to the given port for a Dart VM Service connection.\n'
        'Specifying port 0 (the default) will find a random free port.\n '
        'if the Dart Development Service (DDS) is enabled, this will not be the port '
        'of the VmService instance advertised on the command line.',
  );

  static const deviceVmservicePort = StringOptionDescriptor(
    name: 'device-vmservice-port',
    help:
        'Look for vmservice connections only from the specified port.\n'
        'Specifying port 0 (the default) will accept the first vmservice '
        'discovered.',
  );

  static const hostVmservicePort = StringOptionDescriptor(
    name: 'host-vmservice-port',
    help:
        'When a device-side vmservice port is forwarded to a host-side '
        'port, use this value as the host port.\nSpecifying port 0 '
        '(the default) will find a random free host port.',
  );

  static const fuchsiaTargetModel = DefaultedStringOptionDescriptor(
    name: 'target-model',
    defaultsTo: 'flutter',
    allowed: <String>['flutter', 'flutter_runner'],
    verboseOnly: true,
    help: 'Target model that determines what core libraries are available.',
  );

  static const fuchsiaModule = StringOptionDescriptor(
    name: 'module',
    abbr: 'm',
    valueHelp: 'module-name',
    verboseOnly: true,
    help: 'The name of the module (required if attaching to a fuchsia device).',
  );

  static const pidFile = StringOptionDescriptor(
    name: 'pid-file',
    help:
        'Specify a file to write the process ID to. '
        'You can send SIGUSR1 to trigger a hot reload '
        'and SIGUSR2 to trigger a hot restart. '
        'The file is created when the signal handlers '
        'are hooked and deleted when they are removed.',
  );

  static const reportReady = FlagOptionDescriptor(
    name: 'report-ready',
    verboseOnly: true,
    help:
        'Print "ready" to the console after handling a keyboard command.\n'
        'This is primarily useful for tests and other automation, but consider '
        'using "--machine" instead.',
  );

  static const projectRoot = StringOptionDescriptor(
    name: 'project-root',
    verboseOnly: true,
    help: 'Specify the project root directory.',
  );

  static const build = FlagOptionDescriptor(
    name: 'build',
    defaultsTo: true,
    verboseOnly: true,
    help:
        '(deprecated) If necessary, build the app before running. To use an existing app, '
        'pass the "--${FlutterOptions.kUseApplicationBinary}" flag with an existing application artifact.',
  );

  static FlagOptionDescriptor buildOption({bool verboseOnly = true}) {
    if (verboseOnly) {
      return build;
    }
    return const FlagOptionDescriptor(
      name: 'build',
      defaultsTo: true,
      help:
          '(deprecated) If necessary, build the app before running. To use an existing app, '
          'pass the "--${FlutterOptions.kUseApplicationBinary}" flag with an existing application artifact.',
    );
  }
}
