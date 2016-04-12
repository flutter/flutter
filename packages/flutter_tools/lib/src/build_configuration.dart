// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'globals.dart';

enum BuildType {
  prebuilt,
  release,
  debug,
}

/// The type of build - `develop` or `deploy`.
///
/// TODO(devoncarew): Add a `profile` variant.
enum BuildVariant {
  develop,
  deploy
}

String getVariantName(BuildVariant variant) {
  String name = '$variant';
  int index = name.indexOf('.');
  return index == -1 ? name : name.substring(index + 1);
}

enum HostPlatform {
  mac,
  linux,
}

enum TargetPlatform {
  android_arm,
  android_x64,
  ios,
  darwin_x64,
  linux_x64
}

HostPlatform getCurrentHostPlatform() {
  if (Platform.isMacOS)
    return HostPlatform.mac;
  if (Platform.isLinux)
    return HostPlatform.linux;
  printError('Unsupported host platform, defaulting to Linux');
  return HostPlatform.linux;
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
