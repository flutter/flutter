// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../globals.dart';
import '../ios/plist_utils.dart' as plist;

 /// Tests whether a [FileSystemEntity] is an iOS bundle directory
bool _isBundleDirectory(FileSystemEntity entity) =>
    entity is Directory && entity.path.endsWith('.app');

abstract class MacOSApp extends ApplicationPackage {
  MacOSApp({@required String projectBundleId}) : super(id: projectBundleId);

   /// Creates a new [MacOSApp] from an existing app bundle.
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
      printError('Invalid prebuilt MacOS app. Does not contain Info.plist.');
      return null;
    }
    final String id = plist.getValueFromFile(plistPath, plist.kCFBundleIdentifierKey);
    if (id == null) {
      printError('Invalid prebuilt MacOS app. Info.plist does not contain bundle identifier');
      return null;
    }
    return PrebuiltMacOSApp(
      bundleDir: bundleDir,
      bundleName: fs.path.basename(bundleDir.path),
      projectBundleId: id,
    );
  }

  @override
  String get displayName => id;

  String get deviceBundlePath;
}

 class PrebuiltMacOSApp extends MacOSApp {
  PrebuiltMacOSApp({
    @required this.bundleDir,
    @required this.bundleName,
    @required this.projectBundleId,
  }) : super(projectBundleId: projectBundleId);

  final Directory bundleDir;
  final String bundleName;
  final String projectBundleId;

  @override
  String get deviceBundlePath => bundleDir.path;

  @override
  String get name => bundleName;
}