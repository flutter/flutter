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
  const BuildInfo(this.mode, this.flavor,
      {this.previewDart2,
      this.trackWidgetCreation,
      this.extraFrontEndOptions,
      this.extraGenSnapshotOptions,
      this.preferSharedLibrary,
      this.targetPlatform});

  final BuildMode mode;
  /// Represents a custom Android product flavor or an Xcode scheme, null for
  /// using the default.
  ///
  /// If not null, the Gradle build task will be `assembleFlavorMode` (e.g.
  /// `assemblePaidRelease`), and the Xcode build configuration will be
  /// Mode-Flavor (e.g. Release-Paid).
  final String flavor;

  // Whether build should be done using Dart2 Frontend parser.
  final bool previewDart2;

  /// Whether the build should track widget creation locations.
  final bool trackWidgetCreation;

  /// Extra command-line options for front-end.
  final String extraFrontEndOptions;

  /// Extra command-line options for gen_snapshot.
  final String extraGenSnapshotOptions;

  // Whether to prefer AOT compiling to a *so file.
  final bool preferSharedLibrary;

  /// Target platform for the build (e.g. android_arm versus android_arm64).
  final TargetPlatform targetPlatform;

  static const BuildInfo debug = const BuildInfo(BuildMode.debug, null);
  static const BuildInfo profile = const BuildInfo(BuildMode.profile, null);
  static const BuildInfo release = const BuildInfo(BuildMode.release, null);

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

  BuildInfo withTargetPlatform(TargetPlatform targetPlatform) =>
      new BuildInfo(mode, flavor,
          previewDart2: previewDart2,
          trackWidgetCreation: trackWidgetCreation,
          extraFrontEndOptions: extraFrontEndOptions,
          extraGenSnapshotOptions: extraGenSnapshotOptions,
          preferSharedLibrary: preferSharedLibrary,
          targetPlatform: targetPlatform);
}

/// The type of build - `debug`, `profile`, or `release`.
enum BuildMode {
  debug,
  profile,
  release
}

String getModeName(BuildMode mode) => getEnumName(mode);

BuildMode getBuildModeForName(String mode) {
  if (mode == 'debug')
    return BuildMode.debug;
  if (mode == 'profile')
    return BuildMode.profile;
  if (mode == 'release')
    return BuildMode.release;
  return null;
}

// Returns true if the selected build mode uses ahead-of-time compilation.
bool isAotBuildMode(BuildMode mode) {
  return mode == BuildMode.profile || mode == BuildMode.release;
}

// Returns true if the given build mode can be used on emulators / simulators.
bool isEmulatorBuildMode(BuildMode mode) => mode == BuildMode.debug;

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
  }
  assert(platform != null);
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
    throw new Exception(
        'build-dir config setting in ${config.configPath} must be relative');
  }
  return buildDir;
}

/// Returns the Android build output directory.
String getAndroidBuildDirectory() {
  // TODO(cbracken) move to android subdir.
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

/// Returns directory used by incremental compiler (IKG - incremental kernel
/// generator) to store cached intermediate state.
String getIncrementalCompilerByteStoreDirectory() {
  return fs.path.join(getBuildDirectory(), 'ikg_byte_store');
}
