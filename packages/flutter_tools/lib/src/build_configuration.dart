// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'base/logging.dart';

enum BuildType {
  prebuilt,
  release,
  debug,
}

enum HostPlatform {
  mac,
  linux,
}

enum TargetPlatform {
  android,
  iOS,
  iOSSimulator,
  mac,
  linux,
}

HostPlatform getCurrentHostPlatform() {
  if (Platform.isMacOS)
    return HostPlatform.mac;
  if (Platform.isLinux)
    return HostPlatform.linux;
  logging.warning('Unsupported host platform, defaulting to Linux');
  return HostPlatform.linux;
}

TargetPlatform getCurrentHostPlatformAsTarget() {
  if (Platform.isMacOS)
    return TargetPlatform.mac;
  if (Platform.isLinux)
    return TargetPlatform.linux;
  logging.warning('Unsupported host platform, defaulting to Linux');
  return TargetPlatform.linux;
}

class BuildConfiguration {
  BuildConfiguration.prebuilt({
    this.hostPlatform,
    this.targetPlatform,
    this.deviceId
  }) : type = BuildType.prebuilt, buildDir = null, testable = false;

  BuildConfiguration.local({
    this.type,
    this.hostPlatform,
    this.targetPlatform,
    String enginePath,
    String buildPath,
    this.deviceId,
    this.testable: false
  }) : buildDir = path.normalize(path.join(enginePath, buildPath)) {
    assert(type == BuildType.debug || type == BuildType.release);
  }

  final BuildType type;
  final HostPlatform hostPlatform;
  final TargetPlatform targetPlatform;
  final String buildDir;
  final String deviceId;
  final bool testable;
}
