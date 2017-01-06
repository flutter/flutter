// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../base/file_system.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';

final RegExp _settingExpr = new RegExp(r'(\w+)\s*=\s*(\S+)');
final RegExp _varExpr = new RegExp(r'\$\((.*)\)');

void updateXcodeGeneratedProperties(String projectPath, BuildMode mode, String target) {
  StringBuffer localsBuffer = new StringBuffer();

  localsBuffer.writeln('// This is a generated file; do not edit or check into version control.');

  String flutterRoot = path.normalize(Cache.flutterRoot);
  localsBuffer.writeln('FLUTTER_ROOT=$flutterRoot');

  // This holds because requiresProjectRoot is true for this command
  String applicationRoot = path.normalize(fs.currentDirectory.path);
  localsBuffer.writeln('FLUTTER_APPLICATION_PATH=$applicationRoot');

  // Relative to FLUTTER_APPLICATION_PATH, which is [Directory.current].
  localsBuffer.writeln('FLUTTER_TARGET=$target');

  // The runtime mode for the current build.
  localsBuffer.writeln('FLUTTER_BUILD_MODE=${getModeName(mode)}');

  // The build outputs directory, relative to FLUTTER_APPLICATION_PATH.
  localsBuffer.writeln('FLUTTER_BUILD_DIR=${getBuildDirectory()}');

  localsBuffer.writeln('SYMROOT=\${SOURCE_ROOT}/../${getIosBuildDirectory()}');

  String flutterFrameworkDir = path.normalize(tools.getEngineArtifactsDirectory(TargetPlatform.ios, mode).path);
  localsBuffer.writeln('FLUTTER_FRAMEWORK_DIR=$flutterFrameworkDir');

  if (tools.isLocalEngine)
    localsBuffer.writeln('LOCAL_ENGINE=${tools.engineBuildPath}');

  File localsFile = fs.file(path.join(projectPath, 'ios', 'Flutter', 'Generated.xcconfig'));
  localsFile.createSync(recursive: true);
  localsFile.writeAsStringSync(localsBuffer.toString());
}

Map<String, String> getXcodeBuildSettings(String xcodeProjPath, String target) {
  String absProjPath = path.absolute(xcodeProjPath);
  String out = runCheckedSync(<String>[
    '/usr/bin/xcodebuild', '-project', absProjPath, '-target', target, '-showBuildSettings'
  ]);
  Map<String, String> settings = <String, String>{};
  for (String line in out.split('\n').where(_settingExpr.hasMatch)) {
    Match match = _settingExpr.firstMatch(line);
    settings[match[1]] = match[2];
  }
  return settings;
}


/// Substitutes variables in [str] with their values from the specified Xcode
/// project and target.
String substituteXcodeVariables(String str, String xcodeProjPath, String target) {
  Iterable<Match> matches = _varExpr.allMatches(str);
  if (matches.isEmpty)
    return str;

  Map<String, String> settings = getXcodeBuildSettings(xcodeProjPath, target);
  return str.replaceAllMapped(_varExpr, (Match m) => settings[m[1]] ?? m[0]);
}
