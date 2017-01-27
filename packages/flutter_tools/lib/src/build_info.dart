// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base/context.dart';
import 'base/platform.dart';
import 'base/utils.dart';
import 'globals.dart';

enum BuildType {
  prebuilt,
  release,
  debug,
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
  android_x64,
  android_x86,
  ios,
  darwin_x64,
  linux_x64
}

String getNameForTargetPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
      return 'android-arm';
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
  }
  assert(false);
  return null;
}

TargetPlatform getTargetPlatformForName(String platform) {
  switch (platform) {
    case 'android-arm':
      return TargetPlatform.android_arm;
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

  String buildDir = config.getValue('build-dir') ?? 'build';
  if (path.isAbsolute(buildDir)) {
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
  return path.join(getBuildDirectory(), 'aot');
}

/// Returns the asset build output directory.
String getAssetBuildDirectory() {
  return path.join(getBuildDirectory(), 'flx');
}

/// Returns the iOS build output directory.
String getIosBuildDirectory() {
  return path.join(getBuildDirectory(), 'ios');
}
