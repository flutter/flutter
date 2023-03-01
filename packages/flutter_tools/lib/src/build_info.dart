// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config_types.dart';

import 'artifacts.dart';
import 'base/config.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/utils.dart';
import 'convert.dart';
import 'globals.dart' as globals;
import 'web/compile.dart';

/// Whether icon font subsetting is enabled by default.
const bool kIconTreeShakerEnabledDefault = true;

/// Information about a build to be performed or used.
class BuildInfo {
  const BuildInfo(
    this.mode,
    this.flavor, {
    this.trackWidgetCreation = false,
    List<String>? extraFrontEndOptions,
    List<String>? extraGenSnapshotOptions,
    List<String>? fileSystemRoots,
    this.androidProjectArgs = const <String>[],
    this.fileSystemScheme,
    this.buildNumber,
    this.buildName,
    this.splitDebugInfoPath,
    this.dartObfuscation = false,
    List<String>? dartDefines,
    this.bundleSkSLPath,
    List<String>? dartExperiments,
    this.webRenderer = WebRendererMode.autoDetect,
    required this.treeShakeIcons,
    this.performanceMeasurementFile,
    this.dartDefineConfigJsonMap,
    this.packagesPath = '.dart_tool/package_config.json', // TODO(zanderso): make this required and remove the default.
    this.nullSafetyMode = NullSafetyMode.sound,
    this.codeSizeDirectory,
    this.androidGradleDaemon = true,
    this.packageConfig = PackageConfig.empty,
    this.initializeFromDill,
    this.assumeInitializeFromDillUpToDate = false,
  }) : extraFrontEndOptions = extraFrontEndOptions ?? const <String>[],
       extraGenSnapshotOptions = extraGenSnapshotOptions ?? const <String>[],
       fileSystemRoots = fileSystemRoots ?? const <String>[],
       dartDefines = dartDefines ?? const <String>[],
       dartExperiments = dartExperiments ?? const <String>[];

  final BuildMode mode;

  /// The null safety mode the application should be run in.
  ///
  /// If not provided, defaults to [NullSafetyMode.autodetect].
  final NullSafetyMode nullSafetyMode;

  /// Whether the build should subset icon fonts.
  final bool treeShakeIcons;

  /// Represents a custom Android product flavor or an Xcode scheme, null for
  /// using the default.
  ///
  /// If not null, the Gradle build task will be `assembleFlavorMode` (e.g.
  /// `assemblePaidRelease`), and the Xcode build configuration will be
  /// Mode-Flavor (e.g. Release-Paid).
  final String? flavor;

  /// The path to the package configuration file to use for compilation.
  ///
  /// This is used by package:package_config to locate the actual package_config.json
  /// file. If not provided, defaults to `.dart_tool/package_config.json`.
  final String packagesPath;

  final List<String> fileSystemRoots;
  final String? fileSystemScheme;

  /// Whether the build should track widget creation locations.
  final bool trackWidgetCreation;

  /// Extra command-line options for front-end.
  final List<String> extraFrontEndOptions;

  /// Extra command-line options for gen_snapshot.
  final List<String> extraGenSnapshotOptions;

  /// Internal version number (not displayed to users).
  /// Each build must have a unique number to differentiate it from previous builds.
  /// It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
  /// On Android it is used as versionCode.
  /// On Xcode builds it is used as CFBundleVersion.
  /// On Windows it is used as the build suffix for the product and file versions.
  final String? buildNumber;

  /// A "x.y.z" string used as the version number shown to users.
  /// For each new version of your app, you will provide a version number to differentiate it from previous versions.
  /// On Android it is used as versionName.
  /// On Xcode builds it is used as CFBundleShortVersionString.
  /// On Windows it is used as the major, minor, and patch parts of the product and file versions.
  final String? buildName;

  /// An optional directory path to save debugging information from dwarf stack
  /// traces. If null, stack trace information is not stripped from the
  /// executable.
  final String? splitDebugInfoPath;

  /// Whether to apply dart source code obfuscation.
  final bool dartObfuscation;

  /// An optional path to a JSON containing object SkSL shaders.
  ///
  /// Currently this is only supported for Android builds.
  final String? bundleSkSLPath;

  /// Additional constant values to be made available in the Dart program.
  ///
  /// These values can be used with the const `fromEnvironment` constructors of
  /// [bool], [String], [int], and [double].
  final List<String> dartDefines;

  /// A list of Dart experiments.
  final List<String> dartExperiments;

  /// When compiling to web, which web renderer mode we are using (html, canvaskit, auto)
  final WebRendererMode webRenderer;

  /// The name of a file where flutter assemble will output performance
  /// information in a JSON format.
  ///
  /// This is not considered a build input and will not force assemble to
  /// rerun tasks.
  final String? performanceMeasurementFile;

  /// Configure a constant pool file.
  /// Additional constant values to be made available in the Dart program.
  ///
  /// These values can be used with the const `fromEnvironment` constructors of
  ///  [String] the key and field are json values
  /// json value
  ///
  /// An additional field `dartDefineConfigJsonMap` is provided to represent the native JSON value of the configuration file
  ///
  final Map<String, Object>? dartDefineConfigJsonMap;

  /// If provided, an output directory where one or more v8-style heap snapshots
  /// will be written for code size profiling.
  final String? codeSizeDirectory;

  /// Whether to enable the Gradle daemon when performing an Android build.
  ///
  /// Starting the daemon is the default behavior of the gradle wrapper script created
  /// in a Flutter project. Setting this value to false will cause the tool to pass
  /// `--no-daemon` to the gradle wrapper script, preventing it from spawning a daemon
  /// process.
  ///
  /// For one-off builds or CI systems, preventing the daemon from spawning will
  /// reduce system resource usage, at the cost of any subsequent builds starting
  /// up slightly slower.
  ///
  /// The Gradle daemon may also be disabled in the Android application's properties file.
  final bool androidGradleDaemon;

  /// Additional key value pairs that are passed directly to the gradle project via the `-P`
  /// flag.
  final List<String> androidProjectArgs;

  /// The package configuration for the loaded application.
  ///
  /// This is captured once during startup, but the actual package configuration
  /// may change during a 'flutter run` workflow.
  final PackageConfig packageConfig;

  /// The kernel file that the resident compiler will be initialized with.
  ///
  /// If this is null, it will be initialized from the default cached location.
  final String? initializeFromDill;

  /// If set, assumes that the file passed in [initializeFromDill] is up to date
  /// and skips the check and potential invalidation of files.
  final bool assumeInitializeFromDillUpToDate;

  static const BuildInfo debug = BuildInfo(BuildMode.debug, null, trackWidgetCreation: true, treeShakeIcons: false);
  static const BuildInfo profile = BuildInfo(BuildMode.profile, null, treeShakeIcons: kIconTreeShakerEnabledDefault);
  static const BuildInfo jitRelease = BuildInfo(BuildMode.jitRelease, null, treeShakeIcons: kIconTreeShakerEnabledDefault);
  static const BuildInfo release = BuildInfo(BuildMode.release, null, treeShakeIcons: kIconTreeShakerEnabledDefault);

  /// Returns whether a debug build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], or [isRelease] is true.
  bool get isDebug => mode == BuildMode.debug;

  /// Returns whether a profile build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], [isJitRelease],
  /// or [isRelease] is true.
  bool get isProfile => mode == BuildMode.profile;

  /// Returns whether a release build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], [isJitRelease],
  /// or [isRelease] is true.
  bool get isRelease => mode == BuildMode.release;

  /// Returns whether a JIT release build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], [isJitRelease],
  /// or [isRelease] is true.
  bool get isJitRelease => mode == BuildMode.jitRelease;

  bool get usesAot => isAotBuildMode(mode);
  bool get supportsEmulator => isEmulatorBuildMode(mode);
  bool get supportsSimulator => isEmulatorBuildMode(mode);
  String get modeName => getModeName(mode);
  String get friendlyModeName => getFriendlyModeName(mode);

  /// the flavor name in the output apk files is lower-cased (see flutter.gradle),
  /// so the lower cased flavor name is used to compute the output file name
  String? get lowerCasedFlavor => flavor?.toLowerCase();

  /// the flavor name in the output bundle files has the first character lower-cased,
  /// so the uncapitalized flavor name is used to compute the output file name
  String? get uncapitalizedFlavor => _uncapitalize(flavor);

  /// Convert to a structured string encoded structure appropriate for usage
  /// in build system [Environment.defines].
  ///
  /// Fields that are `null` are excluded from this configuration.
  Map<String, String> toBuildSystemEnvironment() {
    // packagesPath and performanceMeasurementFile are not passed into
    // the Environment map.
    return <String, String>{
      kBuildMode: getNameForBuildMode(mode),
      if (dartDefines.isNotEmpty)
        kDartDefines: encodeDartDefines(dartDefines),
      kDartObfuscation: dartObfuscation.toString(),
      if (extraFrontEndOptions.isNotEmpty)
        kExtraFrontEndOptions: extraFrontEndOptions.join(','),
      if (extraGenSnapshotOptions.isNotEmpty)
        kExtraGenSnapshotOptions: extraGenSnapshotOptions.join(','),
      if (splitDebugInfoPath != null)
        kSplitDebugInfo: splitDebugInfoPath!,
      kTrackWidgetCreation: trackWidgetCreation.toString(),
      kIconTreeShakerFlag: treeShakeIcons.toString(),
      if (bundleSkSLPath != null)
        kBundleSkSLPath: bundleSkSLPath!,
      if (codeSizeDirectory != null)
        kCodeSizeDirectory: codeSizeDirectory!,
      if (fileSystemRoots.isNotEmpty)
        kFileSystemRoots: fileSystemRoots.join(','),
      if (fileSystemScheme != null)
        kFileSystemScheme: fileSystemScheme!,
      if (buildName != null)
        kBuildName: buildName!,
      if (buildNumber != null)
        kBuildNumber: buildNumber!,
    };
  }


  /// Convert to a structured string encoded structure appropriate for usage as
  /// environment variables or to embed in other scripts.
  ///
  /// Fields that are `null` are excluded from this configuration.
  Map<String, String> toEnvironmentConfig() {
    final Map<String, String> map = <String, String>{};
    dartDefineConfigJsonMap?.forEach((String key, Object value) {
      map[key] = '$value';
    });
    final Map<String, String> environmentMap = <String, String>{
      if (dartDefines.isNotEmpty)
        'DART_DEFINES': encodeDartDefines(dartDefines),
      'DART_OBFUSCATION': dartObfuscation.toString(),
      if (extraFrontEndOptions.isNotEmpty)
        'EXTRA_FRONT_END_OPTIONS': extraFrontEndOptions.join(','),
      if (extraGenSnapshotOptions.isNotEmpty)
        'EXTRA_GEN_SNAPSHOT_OPTIONS': extraGenSnapshotOptions.join(','),
      if (splitDebugInfoPath != null)
        'SPLIT_DEBUG_INFO': splitDebugInfoPath!,
      'TRACK_WIDGET_CREATION': trackWidgetCreation.toString(),
      'TREE_SHAKE_ICONS': treeShakeIcons.toString(),
      if (performanceMeasurementFile != null)
        'PERFORMANCE_MEASUREMENT_FILE': performanceMeasurementFile!,
      if (bundleSkSLPath != null)
        'BUNDLE_SKSL_PATH': bundleSkSLPath!,
      'PACKAGE_CONFIG': packagesPath,
      if (codeSizeDirectory != null)
        'CODE_SIZE_DIRECTORY': codeSizeDirectory!,
    };
    map.forEach((String key, String value) {
      if (environmentMap.containsKey(key)) {
        globals.printWarning(
            'The key: [$key] already exists, you cannot use environment variables that have been used by the system!');
      } else {
        // System priority is greater than user priority
        environmentMap[key] = value;
      }
    });
    return environmentMap;
  }

  /// Convert this config to a series of project level arguments to be passed
  /// on the command line to gradle.
  List<String> toGradleConfig() {
    // PACKAGE_CONFIG not currently supported.
    final List<String> result = <String>[
      if (dartDefines.isNotEmpty)
        '-Pdart-defines=${encodeDartDefines(dartDefines)}',
      '-Pdart-obfuscation=$dartObfuscation',
      if (extraFrontEndOptions.isNotEmpty)
        '-Pextra-front-end-options=${extraFrontEndOptions.join(',')}',
      if (extraGenSnapshotOptions.isNotEmpty)
        '-Pextra-gen-snapshot-options=${extraGenSnapshotOptions.join(',')}',
      if (splitDebugInfoPath != null)
        '-Psplit-debug-info=$splitDebugInfoPath',
      '-Ptrack-widget-creation=$trackWidgetCreation',
      '-Ptree-shake-icons=$treeShakeIcons',
      if (performanceMeasurementFile != null)
        '-Pperformance-measurement-file=$performanceMeasurementFile',
      if (bundleSkSLPath != null)
        '-Pbundle-sksl-path=$bundleSkSLPath',
      if (codeSizeDirectory != null)
        '-Pcode-size-directory=$codeSizeDirectory',
      for (String projectArg in androidProjectArgs)
        '-P$projectArg',
    ];
    if (dartDefineConfigJsonMap != null) {
      final Iterable<String> gradleConfKeys = result.map((final String gradleConf) => gradleConf.split('=')[0].substring(2));
      dartDefineConfigJsonMap!.forEach((String key, Object value) {
        if (gradleConfKeys.contains(key)) {
          globals.printWarning(
              'The key: [$key] already exists, you cannot use gradle variables that have been used by the system!');
        } else {
          result.add('-P$key=$value');
        }
      });
    }
    return result;
  }
}

/// Information about an Android build to be performed or used.
class AndroidBuildInfo {
  const AndroidBuildInfo(
    this.buildInfo, {
    this.targetArchs = const <AndroidArch>[
      AndroidArch.armeabi_v7a,
      AndroidArch.arm64_v8a,
      AndroidArch.x86_64,
    ],
    this.splitPerAbi = false,
    this.fastStart = false,
    this.multidexEnabled = false,
  });

  // The build info containing the mode and flavor.
  final BuildInfo buildInfo;

  /// Whether to split the shared library per ABI.
  ///
  /// When this is false, multiple ABIs will be contained within one primary
  /// build artifact. When this is true, multiple build artifacts (one per ABI)
  /// will be produced.
  final bool splitPerAbi;

  /// The target platforms for the build.
  final Iterable<AndroidArch> targetArchs;

  /// Whether to bootstrap an empty application.
  final bool fastStart;

  /// Whether to enable multidex support for apps with more than 64k methods.
  final bool multidexEnabled;
}

/// A summary of the compilation strategy used for Dart.
class BuildMode {
  const BuildMode._(this.name);

  factory BuildMode.fromName(String value) {
    switch (value) {
      case 'debug':
        return BuildMode.debug;
      case 'profile':
        return BuildMode.profile;
      case 'release':
        return BuildMode.release;
      case 'jit_release':
        return BuildMode.jitRelease;
    }
    throw ArgumentError('$value is not a supported build mode');
  }

  /// Built in JIT mode with no optimizations, enabled asserts, and a VM service.
  static const BuildMode debug = BuildMode._('debug');

  /// Built in AOT mode with some optimizations and a VM service.
  static const BuildMode profile = BuildMode._('profile');

  /// Built in AOT mode with all optimizations and no VM service.
  static const BuildMode release = BuildMode._('release');

  /// Built in JIT mode with all optimizations and no VM service.
  static const BuildMode jitRelease = BuildMode._('jit_release');

  static const List<BuildMode> values = <BuildMode>[
    debug,
    profile,
    release,
    jitRelease,
  ];
  static const Set<BuildMode> releaseModes = <BuildMode>{
    release,
    jitRelease,
  };
  static const Set<BuildMode> jitModes = <BuildMode>{
    debug,
    jitRelease,
  };

  /// Whether this mode is considered release.
  ///
  /// Useful for determining whether we should enable/disable asserts or
  /// other development features.
  bool get isRelease => releaseModes.contains(this);

  /// Whether this mode is using the JIT runtime.
  bool get isJit => jitModes.contains(this);

  /// Whether this mode is using the precompiled runtime.
  bool get isPrecompiled => !isJit;

  /// The name for this build mode.
  final String name;

  @override
  String toString() => name;
}

/// Return the name for the build mode, or "any" if null.
String getNameForBuildMode(BuildMode buildMode) {
  return buildMode.name;
}

/// Returns the [BuildMode] for a particular `name`.
BuildMode getBuildModeForName(String name) {
  return BuildMode.fromName(name);
}

/// Environment type of the target device.
enum EnvironmentType {
  physical,
  simulator,
}

String? validatedBuildNumberForPlatform(TargetPlatform targetPlatform, String? buildNumber, Logger logger) {
  if (buildNumber == null) {
    return null;
  }
  if (targetPlatform == TargetPlatform.ios ||
      targetPlatform == TargetPlatform.darwin) {
    // See CFBundleVersion at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
    final RegExp disallowed = RegExp(r'[^\d\.]');
    String tmpBuildNumber = buildNumber.replaceAll(disallowed, '');
    if (tmpBuildNumber.isEmpty) {
      return null;
    }
    final List<String> segments = tmpBuildNumber
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      segments.add('0');
    }
    tmpBuildNumber = segments.join('.');
    if (tmpBuildNumber != buildNumber) {
      logger.printTrace('Invalid build-number: $buildNumber for iOS/macOS, overridden by $tmpBuildNumber.\n'
          'See CFBundleVersion at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html');
    }
    return tmpBuildNumber;
  }
  if (targetPlatform == TargetPlatform.android_arm ||
      targetPlatform == TargetPlatform.android_arm64 ||
      targetPlatform == TargetPlatform.android_x64 ||
      targetPlatform == TargetPlatform.android_x86) {
    // See versionCode at https://developer.android.com/studio/publish/versioning
    final RegExp disallowed = RegExp(r'[^\d]');
    String tmpBuildNumberStr = buildNumber.replaceAll(disallowed, '');
    int tmpBuildNumberInt = int.tryParse(tmpBuildNumberStr) ?? 0;
    if (tmpBuildNumberInt < 1) {
      tmpBuildNumberInt = 1;
    }
    tmpBuildNumberStr = tmpBuildNumberInt.toString();
    if (tmpBuildNumberStr != buildNumber) {
      logger.printTrace('Invalid build-number: $buildNumber for Android, overridden by $tmpBuildNumberStr.\n'
          'See versionCode at https://developer.android.com/studio/publish/versioning');
    }
    return tmpBuildNumberStr;
  }
  return buildNumber;
}

String? validatedBuildNameForPlatform(TargetPlatform targetPlatform, String? buildName, Logger logger) {
  if (buildName == null) {
    return null;
  }
  if (targetPlatform == TargetPlatform.ios ||
      targetPlatform == TargetPlatform.darwin) {
    // See CFBundleShortVersionString at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
    final RegExp disallowed = RegExp(r'[^\d\.]');
    String tmpBuildName = buildName.replaceAll(disallowed, '');
    if (tmpBuildName.isEmpty) {
      return null;
    }
    final List<String> segments = tmpBuildName
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    while (segments.length < 3) {
      segments.add('0');
    }
    tmpBuildName = segments.join('.');
    if (tmpBuildName != buildName) {
      logger.printTrace('Invalid build-name: $buildName for iOS/macOS, overridden by $tmpBuildName.\n'
          'See CFBundleShortVersionString at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html');
    }
    return tmpBuildName;
  }
  if (targetPlatform == TargetPlatform.android ||
      targetPlatform == TargetPlatform.android_arm ||
      targetPlatform == TargetPlatform.android_arm64 ||
      targetPlatform == TargetPlatform.android_x64 ||
      targetPlatform == TargetPlatform.android_x86) {
    // See versionName at https://developer.android.com/studio/publish/versioning
    return buildName;
  }
  return buildName;
}

String getModeName(BuildMode mode) => getEnumName(mode);

String getFriendlyModeName(BuildMode mode) {
  return snakeCase(getModeName(mode)).replaceAll('_', ' ');
}

// Returns true if the selected build mode uses ahead-of-time compilation.
bool isAotBuildMode(BuildMode mode) {
  return mode == BuildMode.profile || mode == BuildMode.release;
}

// Returns true if the given build mode can be used on emulators / simulators.
bool isEmulatorBuildMode(BuildMode mode) {
  return mode == BuildMode.debug;
}

enum TargetPlatform {
  android,
  ios,
  darwin,
  linux_x64,
  linux_arm64,
  windows_x64,
  fuchsia_arm64,
  fuchsia_x64,
  tester,
  web_javascript,
  // The arch specific android target platforms are soft-deprecated.
  // Instead of using TargetPlatform as a combination arch + platform
  // the code will be updated to carry arch information in [DarwinArch]
  // and [AndroidArch].
  android_arm,
  android_arm64,
  android_x64,
  android_x86,
}

/// iOS and macOS target device architecture.
//
// TODO(cbracken): split TargetPlatform.ios into ios_armv7, ios_arm64.
enum DarwinArch {
  armv7, // Deprecated. Used to display 32-bit unsupported devices.
  arm64,
  x86_64,
}

// TODO(zanderso): replace all android TargetPlatform usage with AndroidArch.
enum AndroidArch {
  armeabi_v7a,
  arm64_v8a,
  x86,
  x86_64,
}

/// The default set of iOS device architectures to build for.
List<DarwinArch> defaultIOSArchsForEnvironment(
  EnvironmentType environmentType,
  Artifacts artifacts,
) {
  // Handle single-arch local engines.
  final LocalEngineInfo? localEngineInfo = artifacts.localEngineInfo;
  if (localEngineInfo != null) {
    final String localEngineName = localEngineInfo.localEngineName;
    if (localEngineName.contains('_arm64')) {
      return <DarwinArch>[ DarwinArch.arm64 ];
    }
    if (localEngineName.contains('_sim')) {
      return <DarwinArch>[ DarwinArch.x86_64 ];
    }
  } else if (environmentType == EnvironmentType.simulator) {
    return <DarwinArch>[
      DarwinArch.x86_64,
      DarwinArch.arm64,
    ];
  }
  return <DarwinArch>[
    DarwinArch.arm64,
  ];
}

/// The default set of macOS device architectures to build for.
List<DarwinArch> defaultMacOSArchsForEnvironment(Artifacts artifacts) {
  // Handle single-arch local engines.
  final LocalEngineInfo? localEngineInfo = artifacts.localEngineInfo;
  if (localEngineInfo != null) {
    if (localEngineInfo.localEngineName.contains('_arm64')) {
      return <DarwinArch>[ DarwinArch.arm64 ];
    }
    return <DarwinArch>[ DarwinArch.x86_64 ];
  }
  return <DarwinArch>[
    DarwinArch.x86_64,
    DarwinArch.arm64,
  ];
}

// Returns the Dart SDK's name for the specified target architecture.
//
// When building for Darwin platforms, the tool invokes architecture-specific
// variants of `gen_snapshot`, one for each target architecture. The output
// instructions are then built into architecture-specific binaries, which are
// merged into a universal binary using the `lipo` tool.
String getDartNameForDarwinArch(DarwinArch arch) {
  switch (arch) {
    case DarwinArch.armv7:
      return 'armv7';
    case DarwinArch.arm64:
      return 'arm64';
    case DarwinArch.x86_64:
      return 'x64';
  }
}

// Returns Apple's name for the specified target architecture.
//
// When invoking Apple tools such as `xcodebuild` or `lipo`, the tool often
// passes one or more target architectures as parameters. The names returned by
// this function reflect Apple's name for the specified architecture.
//
// For consistency with developer expectations, Flutter outputs also use these
// architecture names in its build products for Darwin target platforms.
String getNameForDarwinArch(DarwinArch arch) {
  switch (arch) {
    case DarwinArch.armv7:
      return 'armv7';
    case DarwinArch.arm64:
      return 'arm64';
    case DarwinArch.x86_64:
      return 'x86_64';
  }
}

DarwinArch getIOSArchForName(String arch) {
  switch (arch) {
    case 'armv7':
    case 'armv7f': // iPhone 4S.
    case 'armv7s': // iPad 4.
      return DarwinArch.armv7;
    case 'arm64':
    case 'arm64e': // iPhone XS/XS Max/XR and higher. arm64 runs on arm64e devices.
      return DarwinArch.arm64;
    case 'x86_64':
      return DarwinArch.x86_64;
  }
  throw Exception('Unsupported iOS arch name "$arch"');
}

DarwinArch getDarwinArchForName(String arch) {
  switch (arch) {
    case 'arm64':
      return DarwinArch.arm64;
    case 'x86_64':
      return DarwinArch.x86_64;
  }
  throw Exception('Unsupported MacOS arch name "$arch"');
}

String getNameForTargetPlatform(TargetPlatform platform, {DarwinArch? darwinArch}) {
  switch (platform) {
    case TargetPlatform.android_arm:
      return 'android-arm';
    case TargetPlatform.android_arm64:
      return 'android-arm64';
    case TargetPlatform.android_x64:
      return 'android-x64';
    case TargetPlatform.android_x86:
      return 'android-x86';
    case TargetPlatform.ios:
      if (darwinArch != null) {
        return 'ios-${getNameForDarwinArch(darwinArch)}';
      }
      return 'ios';
    case TargetPlatform.darwin:
      if (darwinArch != null) {
        return 'darwin-${getNameForDarwinArch(darwinArch)}';
      }
      return 'darwin';
    case TargetPlatform.linux_x64:
      return 'linux-x64';
    case TargetPlatform.linux_arm64:
      return 'linux-arm64';
    case TargetPlatform.windows_x64:
      return 'windows-x64';
    case TargetPlatform.fuchsia_arm64:
      return 'fuchsia-arm64';
    case TargetPlatform.fuchsia_x64:
      return 'fuchsia-x64';
    case TargetPlatform.tester:
      return 'flutter-tester';
    case TargetPlatform.web_javascript:
      return 'web-javascript';
    case TargetPlatform.android:
      return 'android';
  }
}

TargetPlatform getTargetPlatformForName(String platform) {
  switch (platform) {
    case 'android':
      return TargetPlatform.android;
    case 'android-arm':
      return TargetPlatform.android_arm;
    case 'android-arm64':
      return TargetPlatform.android_arm64;
    case 'android-x64':
      return TargetPlatform.android_x64;
    case 'android-x86':
      return TargetPlatform.android_x86;
    case 'fuchsia-arm64':
      return TargetPlatform.fuchsia_arm64;
    case 'fuchsia-x64':
      return TargetPlatform.fuchsia_x64;
    case 'ios':
      return TargetPlatform.ios;
    case 'darwin':
    // For backward-compatibility and also for Tester, where it must match
    // host platform name (HostPlatform.darwin_x64)
    case 'darwin-x64':
    case 'darwin-arm64':
      return TargetPlatform.darwin;
    case 'linux-x64':
      return TargetPlatform.linux_x64;
   case 'linux-arm64':
      return TargetPlatform.linux_arm64;
    case 'windows-x64':
      return TargetPlatform.windows_x64;
    case 'web-javascript':
      return TargetPlatform.web_javascript;
  }
  throw Exception('Unsupported platform name "$platform"');
}

AndroidArch getAndroidArchForName(String platform) {
  switch (platform) {
    case 'android-arm':
      return AndroidArch.armeabi_v7a;
    case 'android-arm64':
      return AndroidArch.arm64_v8a;
    case 'android-x64':
      return AndroidArch.x86_64;
    case 'android-x86':
      return AndroidArch.x86;
  }
  throw Exception('Unsupported Android arch name "$platform"');
}

String getNameForAndroidArch(AndroidArch arch) {
  switch (arch) {
    case AndroidArch.armeabi_v7a:
      return 'armeabi-v7a';
    case AndroidArch.arm64_v8a:
      return 'arm64-v8a';
    case AndroidArch.x86_64:
      return 'x86_64';
    case AndroidArch.x86:
      return 'x86';
  }
}

String getPlatformNameForAndroidArch(AndroidArch arch) {
  switch (arch) {
    case AndroidArch.armeabi_v7a:
      return 'android-arm';
    case AndroidArch.arm64_v8a:
      return 'android-arm64';
    case AndroidArch.x86_64:
      return 'android-x64';
    case AndroidArch.x86:
      return 'android-x86';
  }
}

String fuchsiaArchForTargetPlatform(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.fuchsia_arm64:
      return 'arm64';
    case TargetPlatform.fuchsia_x64:
      return 'x64';
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
    case TargetPlatform.darwin:
    case TargetPlatform.ios:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.linux_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.windows_x64:
      throw UnsupportedError('Unexpected Fuchsia platform $targetPlatform');
  }
}

HostPlatform getCurrentHostPlatform() {
  if (globals.platform.isMacOS) {
    return HostPlatform.darwin_x64;
  }
  if (globals.platform.isLinux) {
    // support x64 and arm64 architecture.
    return globals.os.hostPlatform;
  }
  if (globals.platform.isWindows) {
    return HostPlatform.windows_x64;
  }

  globals.printWarning('Unsupported host platform, defaulting to Linux');

  return HostPlatform.linux_x64;
}

FileSystemEntity getWebPlatformBinariesDirectory(Artifacts artifacts, WebRendererMode webRenderer) {
  return artifacts.getHostArtifact(HostArtifact.webPlatformKernelFolder);
}

/// Returns the top-level build output directory.
String getBuildDirectory([Config? config, FileSystem? fileSystem]) {
  // TODO(johnmccutchan): Stop calling this function as part of setting
  // up command line argument processing.
  final Config localConfig = config ?? globals.config;
  final FileSystem localFilesystem = fileSystem ?? globals.fs;

  final String buildDir = localConfig.getValue('build-dir') as String? ?? 'build';
  if (localFilesystem.path.isAbsolute(buildDir)) {
    throw Exception(
        'build-dir config setting in ${globals.config.configPath} must be relative');
  }
  return buildDir;
}

/// Returns the Android build output directory.
String getAndroidBuildDirectory() {
  // TODO(cbracken): move to android subdir.
  return getBuildDirectory();
}

/// Returns the AOT build output directory.
String getAotBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'aot');
}

/// Returns the asset build output directory.
String getAssetBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'flutter_assets');
}

/// Returns the iOS build output directory.
String getIosBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'ios');
}

/// Returns the macOS build output directory.
String getMacOSBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'macos');
}

/// Returns the web build output directory.
String getWebBuildDirectory([bool isWasm = false]) {
  return globals.fs.path.join(getBuildDirectory(), isWasm ? 'web_wasm' : 'web');
}

/// Returns the Linux build output directory.
String getLinuxBuildDirectory([TargetPlatform? targetPlatform]) {
  final String arch = (targetPlatform == null) ?
      _getCurrentHostPlatformArchName() :
      getNameForTargetPlatformArch(targetPlatform);
  final String subDirs = 'linux/$arch';
  return globals.fs.path.join(getBuildDirectory(), subDirs);
}

/// Returns the Windows build output directory.
String getWindowsBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'windows');
}

/// Returns the Fuchsia build output directory.
String getFuchsiaBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'fuchsia');
}

/// Defines specified via the `--dart-define` command-line option.
///
/// These values are URI-encoded and then combined into a comma-separated string.
const String kDartDefines = 'DartDefines';

/// The define to pass a [BuildMode].
const String kBuildMode = 'BuildMode';

/// The define to pass whether we compile 64-bit android-arm code.
const String kTargetPlatform = 'TargetPlatform';

/// The define to control what target file is used.
const String kTargetFile = 'TargetFile';

/// Whether to enable or disable track widget creation.
const String kTrackWidgetCreation = 'TrackWidgetCreation';

/// Additional configuration passed to the dart front end.
///
/// This is expected to be a comma separated list of strings.
const String kExtraFrontEndOptions = 'ExtraFrontEndOptions';

/// Additional configuration passed to gen_snapshot.
///
/// This is expected to be a comma separated list of strings.
const String kExtraGenSnapshotOptions = 'ExtraGenSnapshotOptions';

/// Whether the build should run gen_snapshot as a split aot build for deferred
/// components.
const String kDeferredComponents = 'DeferredComponents';

/// Whether to strip source code information out of release builds and where to save it.
const String kSplitDebugInfo = 'SplitDebugInfo';

/// Alternative scheme for file URIs.
///
/// May be used along with [kFileSystemRoots] to support a multi-root
/// filesystem.
const String kFileSystemScheme = 'FileSystemScheme';

/// Additional filesystem roots.
///
/// If provided, must be used along with [kFileSystemScheme].
const String kFileSystemRoots = 'FileSystemRoots';

/// The define to control what iOS architectures are built for.
///
/// This is expected to be a space-delimited list of architectures. If not
/// provided, defaults to arm64.
const String kIosArchs = 'IosArchs';

/// The define to control what macOS architectures are built for.
///
/// This is expected to be a space-delimited list of architectures. If not
/// provided, defaults to x86_64.
///
/// Supported values are x86_64 and arm64.
const String kDarwinArchs = 'DarwinArchs';

/// Path to the SDK root to be used as the isysroot.
const String kSdkRoot = 'SdkRoot';

/// Whether to enable Dart obfuscation and where to save the symbol map.
const String kDartObfuscation = 'DartObfuscation';

/// An output directory where one or more code-size measurements may be written.
const String kCodeSizeDirectory = 'CodeSizeDirectory';

/// SHA identifier of the Apple developer code signing identity.
///
/// Same as EXPANDED_CODE_SIGN_IDENTITY Xcode build setting.
/// Also discoverable via `security find-identity -p codesigning`.
const String kCodesignIdentity = 'CodesignIdentity';

/// The build define controlling whether icon fonts should be stripped down to
/// only the glyphs used by the application.
const String kIconTreeShakerFlag = 'TreeShakeIcons';

/// The input key for an SkSL bundle path.
const String kBundleSkSLPath = 'BundleSkSLPath';

/// The define to pass build name
const String kBuildName = 'BuildName';

/// The define to pass build number
const String kBuildNumber = 'BuildNumber';

/// The action Xcode is taking.
///
/// Will be "build" when building and "install" when archiving.
const String kXcodeAction = 'Action';

final Converter<String, String> _defineEncoder = utf8.encoder.fuse(base64.encoder);
final Converter<String, String> _defineDecoder = base64.decoder.fuse(utf8.decoder);

/// Encode a List of dart defines in a base64 string.
///
/// This encoding does not include `,`, which is used to distinguish
/// the individual entries, nor does it include `%` which is often a
/// control character on windows command lines.
///
/// When decoding this string, it can be safely split on commas, since any
/// user provided commands will still be encoded.
///
/// If the presence of the `/` character ends up being an issue, this can
/// be changed to use base32 instead.
String encodeDartDefines(List<String> defines) {
  return defines.map(_defineEncoder.convert).join(',');
}

List<String> decodeCommaSeparated(Map<String, String> environmentDefines, String key) {
  if (!environmentDefines.containsKey(key) || environmentDefines[key]!.isEmpty) {
    return <String>[];
  }
  return environmentDefines[key]!
    .split(',')
    .cast<String>()
    .toList();
}

/// Dart defines are encoded inside [environmentDefines] as a comma-separated list.
List<String> decodeDartDefines(Map<String, String> environmentDefines, String key) {
  if (!environmentDefines.containsKey(key) || environmentDefines[key]!.isEmpty) {
    return <String>[];
  }
  return environmentDefines[key]!
    .split(',')
    .map<Object>(_defineDecoder.convert)
    .cast<String>()
    .toList();
}

/// The null safety runtime mode the app should be built in.
enum NullSafetyMode {
  sound,
  unsound,
  /// The null safety mode was not detected. Only supported for 'flutter test'.
  autodetect,
}

String _getCurrentHostPlatformArchName() {
  final HostPlatform hostPlatform = getCurrentHostPlatform();
  return getNameForHostPlatformArch(hostPlatform);
}

String getNameForTargetPlatformArch(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.linux_x64:
    case TargetPlatform.darwin:
    case TargetPlatform.windows_x64:
      return 'x64';
    case TargetPlatform.linux_arm64:
      return 'arm64';
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.ios:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
      throw UnsupportedError('Unexpected target platform $platform');
  }
}

String getNameForHostPlatformArch(HostPlatform platform) {
  switch (platform) {
    case HostPlatform.darwin_x64:
      return 'x64';
    case HostPlatform.darwin_arm64:
      return 'arm64';
    case HostPlatform.linux_x64:
      return 'x64';
    case HostPlatform.linux_arm64:
      return 'arm64';
    case HostPlatform.windows_x64:
      return 'x64';
  }
}

String? _uncapitalize(String? s) {
  if (s == null || s.isEmpty) {
    return s;
  }
  return s.substring(0, 1).toLowerCase() + s.substring(1);
}
