// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/plist_utils.dart' as plist;
import '../project.dart';

/// Tests whether a [FileSystemEntity] is an macOS bundle directory
bool _isBundleDirectory(FileSystemEntity entity) =>
    entity is Directory && entity.path.endsWith('.app');

abstract class MacOSApp extends ApplicationPackage {
  MacOSApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [MacOSApp] from a macOS project directory.
  factory MacOSApp.fromMacOSProject(MacOSProject project) {
    return BuildableMacOSApp(project);
  }

  /// Creates a new [MacOSApp] from an existing app bundle.
  ///
  /// `applicationBinary` is the path to the framework directory created by an
  /// Xcode build. By default, this is located under
  /// "~/Library/Developer/Xcode/DerivedData/" and contains an executable
  /// which is expected to start the application and send the observatory
  /// port over stdout.
  factory MacOSApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    final FileSystemEntityType entityType = fs.typeSync(applicationBinary.path);
    if (entityType == FileSystemEntityType.notFound) {
      printError('File "${applicationBinary.path}" does not exist.');
      return null;
    }
    Directory bundleDir;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = fs.directory(applicationBinary);
      if (!_isBundleDirectory(directory)) {
        printError('Folder "${applicationBinary.path}" is not an app bundle.');
        return null;
      }
      bundleDir = fs.directory(applicationBinary);
    } else {
      printError('Folder "${applicationBinary.path}" is not an app bundle.');
      return null;
    }
    final String plistPath = fs.path.join(bundleDir.path, 'Contents', 'Info.plist');
    if (!fs.file(plistPath).existsSync()) {
      printError('Invalid prebuilt macOS app. Does not contain Info.plist.');
      return null;
    }
    final String id = plist.getValueFromFile(plistPath, plist.kCFBundleIdentifierKey);
    final String executableName = plist.getValueFromFile(plistPath, plist.kCFBundleExecutable);
    if (id == null) {
      printError('Invalid prebuilt macOS app. Info.plist does not contain bundle identifier');
      return null;
    }
    final String executable = fs.path.join(bundleDir.path, 'Contents', 'MacOS', executableName);
    if (!fs.file(executable).existsSync()) {
      printError('Could not find macOS binary at $executable');
      return null;
    }
    return PrebuiltMacOSApp(
      bundleDir: bundleDir,
      bundleName: fs.path.basename(bundleDir.path),
      projectBundleId: id,
      executable: executable,
    );
  }

  @override
  String get displayName => id;

  String executable(BuildMode buildMode);
}

class PrebuiltMacOSApp extends MacOSApp {
  PrebuiltMacOSApp({
    @required this.bundleDir,
    @required this.bundleName,
    @required this.projectBundleId,
    @required String executable,
  }) : _executable = executable,
       super(projectBundleId: projectBundleId);

  final Directory bundleDir;
  final String bundleName;
  final String projectBundleId;

  final String _executable;

  @override
  String get name => bundleName;

  @override
  String executable(BuildMode buildMode) => _executable;
}

class BuildableMacOSApp extends MacOSApp {
  BuildableMacOSApp(this.project);

  final MacOSProject project;

  @override
  String get name => 'macOS_fde';

  @override
  String executable(BuildMode buildMode) {
    final ProcessResult result = processManager.runSync(<String>[
      project.nameScript.path,
      buildMode == BuildMode.debug ? 'debug' : 'release'
    ], runInShell: true);
    return result.stdout.toString().trim();
  }
}