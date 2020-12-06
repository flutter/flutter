// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_system/targets/icon_tree_shaker.dart';
import 'globals.dart' as globals;

/// Information about a build to be performed or used.
class BuildInfo {
  const BuildInfo(
    this.mode,
    this.flavor, {
    this.trackWidgetCreation = false,
    this.extraFrontEndOptions,
    this.extraGenSnapshotOptions,
    this.fileSystemRoots,
    this.fileSystemScheme,
    this.buildNumber,
    this.buildName,
    this.splitDebugInfoPath,
    this.dartObfuscation = false,
    this.dartDefines = const <String>[],
    this.bundleSkSLPath,
    this.dartExperiments = const <String>[],
    @required this.treeShakeIcons,
    this.performanceMeasurementFile,
    this.packagesPath = '.packages',
    this.nullSafetyMode = NullSafetyMode.autodetect,
    this.codeSizeDirectory,
  });

  final BuildMode mode;

  /// The null safety mode the application should be run in.
  ///
  /// If not provided, defaults to [NullSafetyMode.autodetect].
  final NullSafetyMode nullSafetyMode;

  /// Whether the build should subdset icon fonts.
  final bool treeShakeIcons;

  /// Represents a custom Android product flavor or an Xcode scheme, null for
  /// using the default.
  ///
  /// If not null, the Gradle build task will be `assembleFlavorMode` (e.g.
  /// `assemblePaidRelease`), and the Xcode build configuration will be
  /// Mode-Flavor (e.g. Release-Paid).
  final String flavor;

  /// The path to the .packages file to use for compilation.
  ///
  /// This is used by package:package_config to locate the actual package_config.json
  /// file. If not provded, defaults to `.packages`.
  final String packagesPath;

  final List<String> fileSystemRoots;
  final String fileSystemScheme;

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
  final String buildNumber;

  /// A "x.y.z" string used as the version number shown to users.
  /// For each new version of your app, you will provide a version number to differentiate it from previous versions.
  /// On Android it is used as versionName.
  /// On Xcode builds it is used as CFBundleShortVersionString.
  final String buildName;

  /// An optional directory path to save debugging information from dwarf stack
  /// traces. If null, stack trace information is not stripped from the
  /// executable.
  final String splitDebugInfoPath;

  /// Whether to apply dart source code obfuscation.
  final bool dartObfuscation;

  /// An optional path to a JSON containing object SkSL shaders.
  ///
  /// Currently this is only supported for Android builds.
  final String bundleSkSLPath;

  /// Additional constant values to be made available in the Dart program.
  ///
  /// These values can be used with the const `fromEnvironment` constructors of
  /// [bool], [String], [int], and [double].
  final List<String> dartDefines;

  /// A list of Dart experiments.
  final List<String> dartExperiments;

  /// The name of a file where flutter assemble will output performance
  /// information in a JSON format.
  ///
  /// This is not considered a build input and will not force assemble to
  /// rerun tasks.
  final String performanceMeasurementFile;

  /// If provided, an output directory where one or more v8-style heapsnapshots
  /// will be written for code size profiling.
  final String codeSizeDirectory;

  static const BuildInfo debug = BuildInfo(BuildMode.debug, null, treeShakeIcons: false);
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

  /// Convert to a structued string encoded structure appropriate for usage as
  /// environment variables or to embed in other scripts.
  ///
  /// Fields that are `null` are excluded from this configration.
  Map<String, String> toEnvironmentConfig() {
    return <String, String>{
      if (dartDefines?.isNotEmpty ?? false)
        'DART_DEFINES': encodeDartDefines(dartDefines),
      if (dartObfuscation != null)
        'DART_OBFUSCATION': dartObfuscation.toString(),
      if (extraFrontEndOptions?.isNotEmpty ?? false)
        'EXTRA_FRONT_END_OPTIONS': encodeDartDefines(extraFrontEndOptions),
      if (extraGenSnapshotOptions?.isNotEmpty ?? false)
        'EXTRA_GEN_SNAPSHOT_OPTIONS': encodeDartDefines(extraGenSnapshotOptions),
      if (splitDebugInfoPath != null)
        'SPLIT_DEBUG_INFO': splitDebugInfoPath,
      if (trackWidgetCreation != null)
        'TRACK_WIDGET_CREATION': trackWidgetCreation.toString(),
      if (treeShakeIcons != null)
        'TREE_SHAKE_ICONS': treeShakeIcons.toString(),
      if (performanceMeasurementFile != null)
        'PERFORMANCE_MEASUREMENT_FILE': performanceMeasurementFile,
      if (bundleSkSLPath != null)
        'BUNDLE_SKSL_PATH': bundleSkSLPath,
      if (packagesPath != null)
        'PACKAGE_CONFIG': packagesPath,
      if (codeSizeDirectory != null)
        'CODE_SIZE_DIRECTORY': codeSizeDirectory,
    };
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
    this.shrink = false,
    this.fastStart = false,
  });

  // The build info containing the mode and flavor.
  final BuildInfo buildInfo;

  /// Whether to split the shared library per ABI.
  ///
  /// When this is false, multiple ABIs will be contained within one primary
  /// build artifact. When this is true, multiple build artifacts (one per ABI)
  /// will be produced.
  final bool splitPerAbi;

  /// Whether to enable code shrinking on release mode.
  final bool shrink;

  /// The target platforms for the build.
  final Iterable<AndroidArch> targetArchs;

  /// Whether to bootstrap an empty application.
  final bool fastStart;
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

  /// Built in JIT mode with no optimizations, enabled asserts, and an observatory.
  static const BuildMode debug = BuildMode._('debug');

  /// Built in AOT mode with some optimizations and an observatory.
  static const BuildMode profile = BuildMode._('profile');

  /// Built in AOT mode with all optimizations and no observatory.
  static const BuildMode release = BuildMode._('release');

  /// Built in JIT mode with all optimizations and no observatory.
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

String validatedBuildNumberForPlatform(TargetPlatform targetPlatform, String buildNumber, Logger logger) {
  if (buildNumber == null) {
    return null;
  }
  if (targetPlatform == TargetPlatform.ios ||
      targetPlatform == TargetPlatform.darwin_x64) {
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

String validatedBuildNameForPlatform(TargetPlatform targetPlatform, String buildName, Logger logger) {
  if (buildName == null) {
    return null;
  }
  if (targetPlatform == TargetPlatform.ios ||
      targetPlatform == TargetPlatform.darwin_x64) {
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

enum HostPlatform {
  darwin_x64,
  darwin_arm,
  linux_x64,
  windows_x64,
}

String getNameForHostPlatform(HostPlatform platform) {
  switch (platform) {
    case HostPlatform.darwin_x64:
      return 'darwin-x64';
    case HostPlatform.darwin_arm:
      return 'darwin-arm';
    case HostPlatform.linux_x64:
      return 'linux-x64';
    case HostPlatform.windows_x64:
      return 'windows-x64';
  }
  assert(false);
  return null;
}

enum TargetPlatform {
  android,
  ios,
  // darwin_arm64 not yet supported, macOS desktop targets run in Rosetta as x86.
  darwin_x64,
  linux_x64,
  windows_x64,
  fuchsia_arm64,
  fuchsia_x64,
  tester,
  web_javascript,
  // The arch specific android target platforms are soft-depreacted.
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
  armv7,
  arm64,
  x86_64,
}

// TODO(jonahwilliams): replace all android TargetPlatform usage with AndroidArch.
enum AndroidArch {
  armeabi_v7a,
  arm64_v8a,
  x86,
  x86_64,
}

/// The default set of iOS device architectures to build for.
const List<DarwinArch> defaultIOSArchs = <DarwinArch>[
  DarwinArch.arm64,
];

String getNameForDarwinArch(DarwinArch arch) {
  switch (arch) {
    case DarwinArch.armv7:
      return 'armv7';
    case DarwinArch.arm64:
      return 'arm64';
    case DarwinArch.x86_64:
      return 'x86_64';
  }
  assert(false);
  return null;
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

String getNameForTargetPlatform(TargetPlatform platform, {DarwinArch darwinArch}) {
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
    case TargetPlatform.darwin_x64:
      return 'darwin-x64';
    case TargetPlatform.linux_x64:
      return 'linux-x64';
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
  assert(false);
  return null;
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
    case 'darwin-x64':
      return TargetPlatform.darwin_x64;
    case 'linux-x64':
      return TargetPlatform.linux_x64;
    case 'windows-x64':
      return TargetPlatform.windows_x64;
    case 'web-javascript':
      return TargetPlatform.web_javascript;
  }
  assert(platform != null);
  return null;
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
  assert(false);
  return null;
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
  assert(false);
  return null;
}

String fuchsiaArchForTargetPlatform(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.fuchsia_arm64:
      return 'arm64';
    case TargetPlatform.fuchsia_x64:
      return 'x64';
    default:
      assert(false);
      return null;
  }
}

HostPlatform getCurrentHostPlatform() {
  if (globals.platform.isMacOS) {
    return HostPlatform.darwin_x64;
  }
  if (globals.platform.isLinux) {
    return HostPlatform.linux_x64;
  }
  if (globals.platform.isWindows) {
    return HostPlatform.windows_x64;
  }

  globals.printError('Unsupported host platform, defaulting to Linux');

  return HostPlatform.linux_x64;
}

/// Returns the top-level build output directory.
String getBuildDirectory([Config config, FileSystem fileSystem]) {
  // TODO(johnmccutchan): Stop calling this function as part of setting
  // up command line argument processing.
  if (context == null) {
    return 'build';
  }
  final Config localConfig = config ?? globals.config;
  final FileSystem localFilesystem = fileSystem ?? globals.fs;
  if (localConfig == null) {
    return 'build';
  }

  final String buildDir = localConfig.getValue('build-dir') as String ?? 'build';
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
String getWebBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'web');
}

/// Returns the Linux build output directory.
String getLinuxBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'linux');
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

/// Encode a List of dart defines in a URI string.
String encodeDartDefines(List<String> defines) {
  return defines.map(Uri.encodeComponent).join(',');
}

/// Dart defines are encoded inside [environmentDefines] as a comma-separated list.
List<String> decodeDartDefines(Map<String, String> environmentDefines, String key) {
  if (!environmentDefines.containsKey(key) || environmentDefines[key].isEmpty) {
    return <String>[];
  }
  return environmentDefines[key]
    .split(',')
    .map<Object>(Uri.decodeComponent)
    .cast<String>()
    .toList();
}

/// The null safety runtime mode the app should be built in.
enum NullSafetyMode {
  sound,
  unsound,
  autodetect,
}
