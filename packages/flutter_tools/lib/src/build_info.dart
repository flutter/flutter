// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'base/utils.dart';
import 'globals.dart';

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
  });

  final BuildMode mode;

  /// Represents a custom Android product flavor or an Xcode scheme, null for
  /// using the default.
  ///
  /// If not null, the Gradle build task will be `assembleFlavorMode` (e.g.
  /// `assemblePaidRelease`), and the Xcode build configuration will be
  /// Mode-Flavor (e.g. Release-Paid).
  final String flavor;

  final List<String> fileSystemRoots;
  final String fileSystemScheme;

  /// Whether the build should track widget creation locations.
  final bool trackWidgetCreation;

  /// Extra command-line options for front-end.
  final String extraFrontEndOptions;

  /// Extra command-line options for gen_snapshot.
  final String extraGenSnapshotOptions;

  /// Internal version number (not displayed to users).
  /// Each build must have a unique number to differentiate it from previous builds.
  /// It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
  /// On Android it is used as versionCode.
  /// On Xcode builds it is used as CFBundleVersion.
  final String buildNumber;

  /// A "x.y.z" string used as the version number shown to users.
  /// For each new version of your app, you will provide a version number to differentiate it from previous versions.
  /// On Android it is used as versionName.
  /// On Xcode builds it is used as CFBundleShortVersionString,
  final String buildName;

  static const BuildInfo debug = BuildInfo(BuildMode.debug, null);
  static const BuildInfo profile = BuildInfo(BuildMode.profile, null);
  static const BuildInfo release = BuildInfo(BuildMode.release, null);

  /// Returns whether a debug build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], or [isRelease] is true.
  bool get isDebug => mode == BuildMode.debug;

  /// Returns whether a profile build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], or [isRelease] is true.
  bool get isProfile => mode == BuildMode.profile;

  /// Returns whether a release build is requested.
  ///
  /// Exactly one of [isDebug], [isProfile], or [isRelease] is true.
  bool get isRelease => mode == BuildMode.release;

  bool get usesAot => isAotBuildMode(mode);
  bool get supportsEmulator => isEmulatorBuildMode(mode);
  bool get supportsSimulator => isEmulatorBuildMode(mode);
  String get modeName => getModeName(mode);
  String get friendlyModeName => getFriendlyModeName(mode);
}

/// Information about an Android build to be performed or used.
class AndroidBuildInfo {
  const AndroidBuildInfo(
    this.buildInfo, {
    this.targetArchs = const <AndroidArch>[
      AndroidArch.armeabi_v7a,
      AndroidArch.arm64_v8a,
    ],
    this.splitPerAbi = false,
    this.proguard = false,
  });

  // The build info containing the mode and flavor.
  final BuildInfo buildInfo;

  /// Whether to split the shared library per ABI.
  ///
  /// When this is false, multiple ABIs will be contained within one primary
  /// build artifact. When this is true, multiple build artifacts (one per ABI)
  /// will be produced.
  final bool splitPerAbi;

  /// Whether to enable Proguard on release mode.
  final bool proguard;

  /// The target platforms for the build.
  final Iterable<AndroidArch> targetArchs;
}

/// The type of build.
enum BuildMode {
  debug,
  profile,
  release,
}

const List<String> _kBuildModes = <String>[
  'debug',
  'profile',
  'release',
];

/// Return the name for the build mode, or "any" if null.
String getNameForBuildMode(BuildMode buildMode) {
  return _kBuildModes[buildMode.index];
}

/// Returns the [BuildMode] for a particular `name`.
BuildMode getBuildModeForName(String name) {
  switch (name) {
    case 'debug':
      return BuildMode.debug;
    case 'profile':
      return BuildMode.profile;
    case 'release':
      return BuildMode.release;
  }
  return null;
}

String validatedBuildNumberForPlatform(TargetPlatform targetPlatform, String buildNumber) {
  if (buildNumber == null) {
    return null;
  }
  if (targetPlatform == TargetPlatform.ios ||
      targetPlatform == TargetPlatform.darwin_x64) {
    // See CFBundleVersion at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
    final RegExp disallowed = RegExp(r'[^\d\.]');
    String tmpBuildNumber = buildNumber.replaceAll(disallowed, '');
    final List<String> segments = tmpBuildNumber
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      segments.add('0');
    }
    tmpBuildNumber = segments.join('.');
    if (tmpBuildNumber != buildNumber) {
      printTrace('Invalid build-number: $buildNumber for iOS/macOS, overridden by $tmpBuildNumber.\n'
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
      printTrace('Invalid build-number: $buildNumber for Android, overridden by $tmpBuildNumberStr.\n'
          'See versionCode at https://developer.android.com/studio/publish/versioning');
    }
    return tmpBuildNumberStr;
  }
  return buildNumber;
}

String validatedBuildNameForPlatform(TargetPlatform targetPlatform, String buildName) {
  if (buildName == null) {
    return null;
  }
  if (targetPlatform == TargetPlatform.ios ||
      targetPlatform == TargetPlatform.darwin_x64) {
    // See CFBundleShortVersionString at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
    final RegExp disallowed = RegExp(r'[^\d\.]');
    String tmpBuildName = buildName.replaceAll(disallowed, '');
    final List<String> segments = tmpBuildName
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    while (segments.length < 3) {
      segments.add('0');
    }
    tmpBuildName = segments.join('.');
    if (tmpBuildName != buildName) {
      printTrace('Invalid build-name: $buildName for iOS/macOS, overridden by $tmpBuildName.\n'
          'See CFBundleShortVersionString at https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html');
    }
    return tmpBuildName;
  }
  if (targetPlatform == TargetPlatform.android_arm ||
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
  linux_x64,
  windows_x64,
}

String getNameForHostPlatform(HostPlatform platform) {
  switch (platform) {
    case HostPlatform.darwin_x64:
      return 'darwin-x64';
    case HostPlatform.linux_x64:
      return 'linux-x64';
    case HostPlatform.windows_x64:
      return 'windows-x64';
  }
  assert(false);
  return null;
}

enum TargetPlatform {
  android_arm,
  android_arm64,
  android_x64,
  android_x86,
  ios,
  darwin_x64,
  linux_x64,
  windows_x64,
  fuchsia,
  tester,
  web_javascript,
}

/// iOS and macOS target device architecture.
//
// TODO(cbracken): split TargetPlatform.ios into ios_armv7, ios_arm64.
enum DarwinArch {
  armv7,
  arm64,
  x86_64,
}

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
      return DarwinArch.armv7;
    case 'arm64':
      return DarwinArch.arm64;
  }
  assert(false);
  return null;
}

String getNameForTargetPlatform(TargetPlatform platform) {
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
      return 'ios';
    case TargetPlatform.darwin_x64:
      return 'darwin-x64';
    case TargetPlatform.linux_x64:
      return 'linux-x64';
    case TargetPlatform.windows_x64:
      return 'windows-x64';
    case TargetPlatform.fuchsia:
      return 'fuchsia';
    case TargetPlatform.tester:
      return 'flutter-tester';
    case TargetPlatform.web_javascript:
      return 'web-javascript';
  }
  assert(false);
  return null;
}

TargetPlatform getTargetPlatformForName(String platform) {
  switch (platform) {
    case 'android-arm':
      return TargetPlatform.android_arm;
    case 'android-arm64':
      return TargetPlatform.android_arm64;
    case 'android-x64':
      return TargetPlatform.android_x64;
    case 'android-x86':
      return TargetPlatform.android_x86;
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
  assert(false);
  return null;
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

HostPlatform getCurrentHostPlatform() {
  if (platform.isMacOS)
    return HostPlatform.darwin_x64;
  if (platform.isLinux)
    return HostPlatform.linux_x64;
  if (platform.isWindows)
    return HostPlatform.windows_x64;

  printError('Unsupported host platform, defaulting to Linux');

  return HostPlatform.linux_x64;
}

/// Returns the top-level build output directory.
String getBuildDirectory() {
  // TODO(johnmccutchan): Stop calling this function as part of setting
  // up command line argument processing.
  if (context == null || config == null)
    return 'build';

  final String buildDir = config.getValue('build-dir') ?? 'build';
  if (fs.path.isAbsolute(buildDir)) {
    throw Exception(
        'build-dir config setting in ${config.configPath} must be relative');
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
  return fs.path.join(getBuildDirectory(), 'aot');
}

/// Returns the asset build output directory.
String getAssetBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'flutter_assets');
}

/// Returns the iOS build output directory.
String getIosBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'ios');
}

/// Returns the macOS build output directory.
String getMacOSBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'macos');
}

/// Returns the web build output directory.
String getWebBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'web');
}

/// Returns the Linux build output directory.
String getLinuxBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'linux');
}

/// Returns the Windows build output directory.
String getWindowsBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'windows');
}

/// Returns the Fuchsia build output directory.
String getFuchsiaBuildDirectory() {
  return fs.path.join(getBuildDirectory(), 'fuchsia');
}
