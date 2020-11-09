// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/plist_parser.dart';
import '../project.dart';

/// Tests whether a [FileSystemEntity] is an macOS bundle directory.
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
    final _ExecutableAndId executableAndId = _executableFromBundle(applicationBinary);
    final Directory applicationBundle = globals.fs.directory(applicationBinary);
    return PrebuiltMacOSApp(
      bundleDir: applicationBundle,
      bundleName: applicationBundle.path,
      projectBundleId: executableAndId.id,
      executable: executableAndId.executable,
    );
  }

  /// Look up the executable name for a macOS application bundle.
  static _ExecutableAndId _executableFromBundle(FileSystemEntity applicationBundle) {
    final FileSystemEntityType entityType = globals.fs.typeSync(applicationBundle.path);
    if (entityType == FileSystemEntityType.notFound) {
      globals.printError('File "${applicationBundle.path}" does not exist.');
      return null;
    }
    Directory bundleDir;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = globals.fs.directory(applicationBundle);
      if (!_isBundleDirectory(directory)) {
        globals.printError('Folder "${applicationBundle.path}" is not an app bundle.');
        return null;
      }
      bundleDir = globals.fs.directory(applicationBundle);
    } else {
      globals.printError('Folder "${applicationBundle.path}" is not an app bundle.');
      return null;
    }
    final String plistPath = globals.fs.path.join(bundleDir.path, 'Contents', 'Info.plist');
    if (!globals.fs.file(plistPath).existsSync()) {
      globals.printError('Invalid prebuilt macOS app. Does not contain Info.plist.');
      return null;
    }
    final Map<String, dynamic> propertyValues = globals.plistParser.parseFile(plistPath);
    final String id = propertyValues[PlistParser.kCFBundleIdentifierKey] as String;
    final String executableName = propertyValues[PlistParser.kCFBundleExecutable] as String;
    if (id == null) {
      globals.printError('Invalid prebuilt macOS app. Info.plist does not contain bundle identifier');
      return null;
    }
    final String executable = globals.fs.path.join(bundleDir.path, 'Contents', 'MacOS', executableName);
    if (!globals.fs.file(executable).existsSync()) {
      globals.printError('Could not find macOS binary at $executable');
    }
    return _ExecutableAndId(executable, id);
  }

  @override
  String get displayName => id;

  String applicationBundle(BuildMode buildMode);

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
  String applicationBundle(BuildMode buildMode) => bundleDir.path;

  @override
  String executable(BuildMode buildMode) => _executable;
}

class BuildableMacOSApp extends MacOSApp {
  BuildableMacOSApp(this.project);

  final MacOSProject project;

  @override
  String get name => 'macOS';

  @override
  String applicationBundle(BuildMode buildMode) {
    final File appBundleNameFile = project.nameFile;
    if (!appBundleNameFile.existsSync()) {
      globals.printError('Unable to find app name. ${appBundleNameFile.path} does not exist');
      return null;
    }
    return globals.fs.path.join(
        getMacOSBuildDirectory(),
        'Build',
        'Products',
        toTitleCase(getNameForBuildMode(buildMode)),
        appBundleNameFile.readAsStringSync().trim());
  }

  @override
  String executable(BuildMode buildMode) {
    final String directory = applicationBundle(buildMode);
    if (directory == null) {
      return null;
    }
    final _ExecutableAndId executableAndId = MacOSApp._executableFromBundle(globals.fs.directory(directory));
    return executableAndId?.executable;
  }
}

class _ExecutableAndId {
  _ExecutableAndId(this.executable, this.id);

  final String executable;
  final String id;
}
