// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

enum BuildType {
  prebuilt,
  release,
  debug,
}

enum BuildPlatform {
  android,
  iOS,
  iOSSimulator,
  mac,
  linux,
}

class BuildConfiguration {
  BuildConfiguration.prebuilt({ this.platform })
    : type = BuildType.prebuilt, buildDir = null;

  BuildConfiguration.local({
    this.type,
    this.platform,
    String enginePath,
    String buildPath
  }) : buildDir = path.normalize(path.join(enginePath, buildPath)) {
    assert(type == BuildType.debug || type == BuildType.release);
  }

  final BuildType type;
  final BuildPlatform platform;
  final String buildDir;
}
