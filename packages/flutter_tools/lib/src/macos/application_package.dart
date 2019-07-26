// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
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
    final ExecutableAndId executableAndId = executableFromBundle(applicationBinary);
    final Directory applicationBundle = fs.directory(applicationBinary);
    return PrebuiltMacOSApp(
      bundleDir: applicationBundle,
      bundleName: applicationBundle.path,
      executableAndId: executableAndId,
    );
  }

  /// Look up the executable name for a macOS application bundle.
  static ExecutableAndId executableFromBundle(Directory applicationBundle) {
    final FileSystemEntityType entityType = fs.typeSync(applicationBundle.path);
    if (entityType == FileSystemEntityType.notFound) {
      printError('File "${applicationBundle.path}" does not exist.');
      return null;
    }
    Directory bundleDir;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = fs.directory(applicationBundle);
      if (!_isBundleDirectory(directory)) {
        printError('Folder "${applicationBundle.path}" is not an app bundle.');
        return null;
      }
      bundleDir = fs.directory(applicationBundle);
    } else {
      printError('Folder "${applicationBundle.path}" is not an app bundle.');
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
    }
    return ExecutableAndId(executable, id);
  }

  @override
  String get displayName => id;
}

class PrebuiltMacOSApp extends MacOSApp {
  PrebuiltMacOSApp({
    @required this.bundleDir,
    @required this.bundleName,
    @required this.executableAndId,
  });

  final Directory bundleDir;
  final String bundleName;
  final ExecutableAndId executableAndId;

  @override
  String get name => bundleName;

  String get executable => executableAndId.executable;
}

class BuildableMacOSApp extends MacOSApp {
  BuildableMacOSApp(this.project);

  final MacOSProject project;

  @override
  String get name => 'macOS';
}

class ExecutableAndId {
  ExecutableAndId(this.executable, this.id);

  final String executable;
  final String id;
}
