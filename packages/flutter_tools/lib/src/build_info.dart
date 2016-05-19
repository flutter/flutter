// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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

// Returns true if the selected build mode uses ahead-of-time compilation.
bool isAotBuildMode(BuildMode mode) {
  return mode == BuildMode.profile || mode == BuildMode.release;
}

enum HostPlatform {
  darwin_x64,
  linux_x64,
}

String getNameForHostPlatform(HostPlatform platform) {
  switch (platform) {
    case HostPlatform.darwin_x64:
      return 'darwin-x64';
    case HostPlatform.linux_x64:
      return 'linux-x64';
  }
  assert(false);
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
      return 'ios_release';
    case TargetPlatform.darwin_x64:
      return 'darwin-x64';
    case TargetPlatform.linux_x64:
      return 'linux-x64';
  }
  assert(false);
}

HostPlatform getCurrentHostPlatform() {
  if (Platform.isMacOS)
    return HostPlatform.darwin_x64;
  if (Platform.isLinux)
    return HostPlatform.linux_x64;

  printError('Unsupported host platform, defaulting to Linux');

  return HostPlatform.linux_x64;
}

String getTargetBuildTypeName(TargetPlatform platform, BuildMode buildMode) {
  return getNameForTargetPlatform(platform) + '-' + getModeName(buildMode);
}
