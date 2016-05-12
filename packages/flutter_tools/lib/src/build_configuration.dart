// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

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
      return "mac_debug";
    case HostPlatform.linux_x64:
      return "linux-x64";
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
      return "android-arm";
    case TargetPlatform.android_x64:
      return "android-x64";
    case TargetPlatform.android_x86:
      return "android-x86";
    case TargetPlatform.ios:
      return "ios_release";
    case TargetPlatform.darwin_x64:
      return "mac_debug";
    case TargetPlatform.linux_x64:
      return "linux-x64";
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

TargetPlatform getCurrentHostPlatformAsTarget() {
  if (Platform.isMacOS)
    return TargetPlatform.darwin_x64;
  if (Platform.isLinux)
    return TargetPlatform.linux_x64;
  printError('Unsupported host platform, defaulting to Linux');
  return TargetPlatform.linux_x64;
}

class BuildConfiguration {
  BuildConfiguration.prebuilt({
    this.hostPlatform,
    this.targetPlatform,
    this.testable: false
  }) : type = BuildType.prebuilt, buildDir = null;

  BuildConfiguration.local({
    this.type,
    this.hostPlatform,
    this.targetPlatform,
    String enginePath,
    String buildPath,
    this.testable: false
  }) : buildDir = path.normalize(path.join(enginePath, buildPath)) {
    assert(type == BuildType.debug || type == BuildType.release);
  }

  final BuildType type;
  final HostPlatform hostPlatform;
  final TargetPlatform targetPlatform;
  final String buildDir;
  final bool testable;
}
