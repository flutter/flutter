// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals_null_migrated.dart' as globals;
import '../project.dart';
import 'plist_parser.dart';


/// Tests whether a [Directory] is an iOS bundle directory.
bool _isBundleDirectory(Directory dir) => dir.path.endsWith('.app');

abstract class IOSApp extends ApplicationPackage {
  IOSApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new IOSApp from an existing app bundle or IPA.
  factory IOSApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    final FileSystemEntityType entityType = globals.fs.typeSync(applicationBinary.path);
    if (entityType == FileSystemEntityType.notFound) {
      globals.printError(
          'File "${applicationBinary.path}" does not exist. Use an app bundle or an ipa.');
      return null;
    }
    Directory bundleDir;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = globals.fs.directory(applicationBinary);
      if (!_isBundleDirectory(directory)) {
        globals.printError('Folder "${applicationBinary.path}" is not an app bundle.');
        return null;
      }
      bundleDir = globals.fs.directory(applicationBinary);
    } else {
      // Try to unpack as an ipa.
      final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_app.');
      globals.os.unzip(globals.fs.file(applicationBinary), tempDir);
      final Directory payloadDir = globals.fs.directory(
        globals.fs.path.join(tempDir.path, 'Payload'),
      );
      if (!payloadDir.existsSync()) {
        globals.printError(
            'Invalid prebuilt iOS ipa. Does not contain a "Payload" directory.');
        return null;
      }
      try {
        bundleDir = payloadDir.listSync().whereType<Directory>().singleWhere(_isBundleDirectory);
      } on StateError {
        globals.printError(
            'Invalid prebuilt iOS ipa. Does not contain a single app bundle.');
        return null;
      }
    }
    final String plistPath = globals.fs.path.join(bundleDir.path, 'Info.plist');
    if (!globals.fs.file(plistPath).existsSync()) {
      globals.printError('Invalid prebuilt iOS app. Does not contain Info.plist.');
      return null;
    }
    final String id = globals.plistParser.getValueFromFile(
      plistPath,
      PlistParser.kCFBundleIdentifierKey,
    );
    if (id == null) {
      globals.printError('Invalid prebuilt iOS app. Info.plist does not contain bundle identifier');
      return null;
    }

    return PrebuiltIOSApp(
      bundleDir: bundleDir,
      bundleName: globals.fs.path.basename(bundleDir.path),
      projectBundleId: id,
    );
  }

  static Future<IOSApp> fromIosProject(IosProject project, BuildInfo buildInfo) {
    if (!globals.platform.isMacOS) {
      return null;
    }
    if (!project.exists) {
      // If the project doesn't exist at all the current hint to run flutter
      // create is accurate.
      return null;
    }
    if (!project.xcodeProject.existsSync()) {
      globals.printError('Expected ios/Runner.xcodeproj but this file is missing.');
      return null;
    }
    if (!project.xcodeProjectInfoFile.existsSync()) {
      globals.printError('Expected ios/Runner.xcodeproj/project.pbxproj but this file is missing.');
      return null;
    }
    return BuildableIOSApp.fromProject(project, buildInfo);
  }

  @override
  String get displayName => id;

  String get simulatorBundlePath;

  String get deviceBundlePath;

  /// Directory used by ios-deploy to store incremental installation metadata for
  /// faster second installs.
  Directory get appDeltaDirectory;
}

class BuildableIOSApp extends IOSApp {
  BuildableIOSApp(this.project, String projectBundleId, String hostAppBundleName)
    : _hostAppBundleName = hostAppBundleName,
      super(projectBundleId: projectBundleId);

  static Future<BuildableIOSApp> fromProject(IosProject project, BuildInfo buildInfo) async {
    final String projectBundleId = await project.productBundleIdentifier(buildInfo);
    final String hostAppBundleName = await project.hostAppBundleName(buildInfo);
    return BuildableIOSApp(project, projectBundleId, hostAppBundleName);
  }

  final IosProject project;

  final String _hostAppBundleName;

  @override
  String get name => _hostAppBundleName;

  @override
  String get simulatorBundlePath => _buildAppPath('iphonesimulator');

  @override
  String get deviceBundlePath => _buildAppPath('iphoneos');

  @override
  Directory get appDeltaDirectory => globals.fs.directory(globals.fs.path.join(getIosBuildDirectory(), 'app-delta'));

  // Xcode uses this path for the final archive bundle location,
  // not a top-level output directory.
  // Specifying `build/ios/archive/Runner` will result in `build/ios/archive/Runner.xcarchive`.
  String get archiveBundlePath
    => globals.fs.path.join(getIosBuildDirectory(), 'archive', globals.fs.path.withoutExtension(_hostAppBundleName));

  // The output xcarchive bundle path `build/ios/archive/Runner.xcarchive`.
  String get archiveBundleOutputPath =>
      globals.fs.path.setExtension(archiveBundlePath, '.xcarchive');

  String get ipaOutputPath =>
      globals.fs.path.join(getIosBuildDirectory(), 'ipa');

  String _buildAppPath(String type) {
    return globals.fs.path.join(getIosBuildDirectory(), type, _hostAppBundleName);
  }
}

class PrebuiltIOSApp extends IOSApp {
  PrebuiltIOSApp({
    this.bundleDir,
    this.bundleName,
    @required String projectBundleId,
  }) : super(projectBundleId: projectBundleId);

  final Directory bundleDir;
  final String bundleName;

  @override
  final Directory appDeltaDirectory = null;

  @override
  String get name => bundleName;

  @override
  String get simulatorBundlePath => _bundlePath;

  @override
  String get deviceBundlePath => _bundlePath;

  String get _bundlePath => bundleDir.path;
}
