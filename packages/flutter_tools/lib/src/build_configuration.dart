// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

final Logger _logging = new Logger('sky_tools.build_configuration');

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
  linux,
}

HostPlatform getCurrentHostPlatform() {
  if (Platform.isMacOS)
    return HostPlatform.mac;
  if (Platform.isLinux)
    return HostPlatform.linux;
  _logging.warning('Unsupported host platform, defaulting to Linux');
  return HostPlatform.linux;
}

class BuildConfiguration {
  BuildConfiguration.prebuilt({ this.hostPlatform, this.targetPlatform })
    : type = BuildType.prebuilt, buildDir = null;

  BuildConfiguration.local({
    this.type,
    this.hostPlatform,
    this.targetPlatform,
    String enginePath,
    String buildPath
  }) : buildDir = path.normalize(path.join(enginePath, buildPath)) {
    assert(type == BuildType.debug || type == BuildType.release);
  }

  final BuildType type;
  final HostPlatform hostPlatform;
  final TargetPlatform targetPlatform;
  final String buildDir;
}
