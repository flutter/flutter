// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../cmake.dart';
import '../cmake_project.dart';

abstract class WindowsApp extends ApplicationPackage {
  WindowsApp({required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [WindowsApp] from a windows sub project.
  factory WindowsApp.fromWindowsProject(WindowsProject project) {
    return BuildableWindowsApp(project: project);
  }

  /// Creates a new [WindowsApp] from an existing executable or a zip archive.
  ///
  /// `applicationBinary` is the path to the executable or the zipped archive.
  static WindowsApp? fromPrebuiltApp(
    FileSystemEntity applicationBinary, {
    required FileSystem fileSystem,
    required Logger logger,
    required OperatingSystemUtils operatingSystemUtils,
  }) {
    if (!applicationBinary.existsSync()) {
      logger.printError('File "${applicationBinary.path}" does not exist.');
      return null;
    }

    if (applicationBinary.path.endsWith('.exe')) {
      return PrebuiltWindowsApp(
        executable: applicationBinary.path,
        applicationPackage: applicationBinary,
      );
    }

    if (!applicationBinary.path.endsWith('.zip')) {
      // Unknown file type
      logger.printError('Unknown windows application type.');
      return null;
    }

    // Try to unpack as a zip.
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_app.');
    try {
      operatingSystemUtils.unzip(fileSystem.file(applicationBinary), tempDir);
    } on ArchiveException {
      logger.printError('Invalid prebuilt Windows app. Unable to extract from archive.');
      return null;
    }
    final exeFilesFound = <FileSystemEntity>[
      for (final FileSystemEntity file in tempDir.listSync())
        if (file.basename.endsWith('.exe')) file,
    ];

    if (exeFilesFound.isEmpty) {
      logger.printError('Cannot find .exe files in the zip archive.');
      return null;
    }

    if (exeFilesFound.length > 1) {
      logger.printError('Archive "${applicationBinary.path}" contains more than one .exe files.');
      return null;
    }

    return PrebuiltWindowsApp(
      executable: exeFilesFound.single.path,
      applicationPackage: applicationBinary,
    );
  }

  @override
  String get displayName => id;

  String executable(BuildMode buildMode, TargetPlatform targetPlatform, [String? flavor]);
}

class PrebuiltWindowsApp extends WindowsApp implements PrebuiltApplicationPackage {
  PrebuiltWindowsApp({required String executable, required this.applicationPackage})
    : _executable = executable,
      super(projectBundleId: executable);

  final String _executable;

  @override
  String executable(BuildMode buildMode, TargetPlatform targetPlatform, [String? flavor]) =>
      _executable;

  @override
  String get name => _executable;

  @override
  final FileSystemEntity applicationPackage;
}

class BuildableWindowsApp extends WindowsApp {
  BuildableWindowsApp({required this.project})
    : super(projectBundleId: project.parent.manifest.appName);

  final WindowsProject project;

  @override
  String executable(BuildMode buildMode, TargetPlatform targetPlatform, [String? flavor]) {
    final String? binaryName = getCmakeExecutableName(project);
    return project.cmakeFile.fileSystem.path.join(
      getWindowsBuildDirectory(targetPlatform, flavor),
      'runner',
      buildMode.uppercaseName,
      '$binaryName.exe',
    );
  }

  @override
  String get name => project.parent.manifest.appName;
}
