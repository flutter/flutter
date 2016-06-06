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

bool _inflateXcodeArchive(String directory, List<int> archiveBytes) {
  printStatus('Unzipping Xcode project to local directory...');

  // We cannot use ArchiveFile because this archive contains files that are exectuable
  // and there is currently no provision to modify file permissions during
  // or after creation. See https://github.com/dart-lang/sdk/issues/15078.
  // So we depend on the platform to unzip the archive for us.

  Directory tempDir = Directory.systemTemp.createTempSync('flutter_xcode');
  File tempFile = new File(path.join(tempDir.path, 'FlutterXcode.zip'))..createSync();
  tempFile.writeAsBytesSync(archiveBytes);

  try {
    Directory dir = new Directory(directory);

    // Remove the old generated project if one is present
    if (dir.existsSync())
      dir.deleteSync(recursive: true);

    // Create the directory so unzip can write to it
    dir.createSync(recursive: true);

    // Unzip the Xcode project into the new empty directory
    runCheckedSync(<String>['/usr/bin/unzip', tempFile.path, '-d', dir.path]);
  } catch (error) {
    printTrace('$error');
    return false;
  }

  // Cleanup the temp directory after unzipping
  tempDir.deleteSync(recursive: true);

  // Verify that we have an Xcode project
  Directory flutterProj = new Directory(path.join(directory, 'FlutterApplication.xcodeproj'));
  if (!flutterProj.existsSync()) {
    printError("${flutterProj.path} does not exist");
    return false;
  }

  return true;
}

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
  // Step 1: Fetch the archive from the cloud
  String iosFilesPath = path.join(flutterProjectPath, 'ios');
  String xcodeprojPath = path.join(iosFilesPath, '.generated');

  Directory toolDir = tools.getEngineArtifactsDirectory(TargetPlatform.ios, mode);
  File archiveFile = new File(path.join(toolDir.path, 'FlutterXcode.zip'));
  List<int> archiveBytes = archiveFile.readAsBytesSync();

  if (archiveBytes.isEmpty) {
    printError('Error: No archive bytes received.');
    return 1;
  }

  // Step 2: Inflate the archive into the user project directory
  bool result = _inflateXcodeArchive(xcodeprojPath, archiveBytes);
  if (!result) {
    printError('Could not inflate the Xcode project archive.');
    return 1;
  }

  // Step 3: Populate the Generated.xcconfig with project specific paths
  updateXcodeGeneratedProperties(flutterProjectPath, mode, target);

  // Step 4: Write the REVISION file
  File revisionFile = new File(path.join(xcodeprojPath, 'REVISION'));
  revisionFile.createSync();
  revisionFile.writeAsStringSync('${Cache.engineRevision}-${getModeName(mode)}');

  // Step 5: Tell the user the location of the generated project.
  printStatus('Xcode project created in $iosFilesPath/.');

  return 0;
}
