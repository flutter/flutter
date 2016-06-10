// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/process.dart';
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

  File localsFile = new File(path.join(projectPath, 'ios', '.generated', 'Flutter', 'Generated.xcconfig'));
  localsFile.createSync(recursive: true);
  localsFile.writeAsStringSync(localsBuffer.toString());
}

bool xcodeProjectRequiresUpdate(BuildMode mode) {
  File revisionFile = new File(path.join(Directory.current.path, 'ios', '.generated', 'REVISION'));

  // If the revision stamp does not exist, the Xcode project definitely requires
  // an update
  if (!revisionFile.existsSync()) {
    printTrace("A revision stamp does not exist. The Xcode project has never been initialized.");
    return true;
  }

  if (revisionFile.readAsStringSync() != '${Cache.engineRevision}-${getModeName(mode)}') {
    printTrace("The revision stamp and the Flutter engine revision differ or the build mode has changed.");
    printTrace("Project needs to be updated.");
    return true;
  }

  printTrace("Xcode project is up to date.");
  return false;
}

Future<int> setupXcodeProjectHarness(String flutterProjectPath, BuildMode mode, String target) async {
  // Step 1: Copy templates into user project directory
  String iosFilesPath = path.join(flutterProjectPath, 'ios');
  String xcodeProjPath = path.join(iosFilesPath, '.generated');
  String templatesPath = path.join(Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'build-ios');
  _copyFolderSync(templatesPath, xcodeProjPath);

  // Step 2: Populate the Generated.xcconfig with project specific paths
  updateXcodeGeneratedProperties(flutterProjectPath, mode, target);

  // Step 3: Write the REVISION file
  File revisionFile = new File(path.join(xcodeProjPath, 'REVISION'));
  revisionFile.createSync();
  revisionFile.writeAsStringSync('${Cache.engineRevision}-${getModeName(mode)}');

  // Step 4: Tell the user the location of the generated project.
  printStatus('Xcode project created in $iosFilesPath/.');

  return 0;
}

void _copyFolderSync(String srcPath, String destPath) {
  Directory srcDir = new Directory(srcPath);
  if (!srcDir.existsSync())
    throw new Exception('Source directory "${srcDir.path}" does not exist, nothing to copy');

  Directory destDir = new Directory(destPath);
  if (!destDir.existsSync())
    destDir.createSync(recursive: true);

  srcDir.listSync().forEach((FileSystemEntity entity) {
    String newPath = path.join(destDir.path, path.basename(entity.path));
    if (entity is File) {
      File newFile = new File(newPath);
      newFile.writeAsBytesSync(entity.readAsBytesSync());
    } else if (entity is Directory) {
      _copyFolderSync(entity.path, newPath);
    } else {
      throw new Exception('${entity.path} is neither File nor Directory');
    }
  });
}
