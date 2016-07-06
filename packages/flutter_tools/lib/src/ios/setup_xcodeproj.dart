// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';

void updateXcodeGeneratedProperties(String projectPath, BuildMode mode, String target) {
  StringBuffer localsBuffer = new StringBuffer();

  localsBuffer.writeln('// This is a generated file; do not edit or check into version control.');

  String flutterRoot = path.normalize(Cache.flutterRoot);
  localsBuffer.writeln('FLUTTER_ROOT=$flutterRoot');

  // This holds because requiresProjectRoot is true for this command
  String applicationRoot = path.normalize(Directory.current.path);
  localsBuffer.writeln('FLUTTER_APPLICATION_PATH=$applicationRoot');

  // Relative to FLUTTER_APPLICATION_PATH, which is [Directory.current].
  localsBuffer.writeln('FLUTTER_TARGET=$target');

  // The runtime mode for the current build.
  localsBuffer.writeln('FLUTTER_BUILD_MODE=${getModeName(mode)}');

  String flutterFrameworkDir = path.normalize(tools.getEngineArtifactsDirectory(TargetPlatform.ios, mode).path);
  localsBuffer.writeln('FLUTTER_FRAMEWORK_DIR=$flutterFrameworkDir');

  if (tools.isLocalEngine)
    localsBuffer.writeln('LOCAL_ENGINE=${tools.engineBuildPath}');

  File localsFile = new File(path.join(projectPath, 'ios', 'Flutter', 'Generated.xcconfig'));
  localsFile.createSync(recursive: true);
  localsFile.writeAsStringSync(localsBuffer.toString());
}
