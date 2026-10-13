// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cmake.dart';
import '../cmake_project.dart';

abstract class LinuxApp extends ApplicationPackage {
  LinuxApp({required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [LinuxApp] from a linux sub project.
  factory LinuxApp.fromLinuxProject(
    LinuxProject project, {
    required Config config,
    required OperatingSystemUtils operatingSystemUtils,
    required Platform platform,
  }) {
    return BuildableLinuxApp(
      project: project,
      config: config,
      operatingSystemUtils: operatingSystemUtils,
      platform: platform,
    );
  }

  /// Creates a new [LinuxApp] from an existing executable.
  ///
  /// `applicationBinary` is the path to the executable.
  factory LinuxApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    return PrebuiltLinuxApp(executable: applicationBinary.path);
  }

  @override
  String get displayName => id;

  String executable(BuildMode buildMode, [String? flavor]);
}

class PrebuiltLinuxApp extends LinuxApp {
  PrebuiltLinuxApp({required String executable})
    : _executable = executable,
      super(projectBundleId: executable);

  final String _executable;

  @override
  String executable(BuildMode buildMode, [String? flavor]) => _executable;

  @override
  String get name => _executable;
}

class BuildableLinuxApp extends LinuxApp {
  BuildableLinuxApp({
    required this.project,
    required this._config,
    required this._operatingSystemUtils,
    required this._platform,
  }) : super(projectBundleId: project.parent.manifest.appName);

  final LinuxProject project;
  final Config _config;
  final OperatingSystemUtils _operatingSystemUtils;
  final Platform _platform;

  @override
  String executable(BuildMode buildMode, [String? flavor]) {
    final String? binaryName = getCmakeExecutableName(project);
    final FileSystem fileSystem = project.cmakeFile.fileSystem;
    return fileSystem.path.join(
      getLinuxBuildDirectory(
        null,
        config: _config,
        fileSystem: fileSystem,
        flavor: flavor,
        operatingSystemUtils: _operatingSystemUtils,
        platform: _platform,
      ),
      buildMode.cliName,
      'bundle',
      binaryName,
    );
  }

  @override
  String get name => project.parent.manifest.appName;
}
