// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../cmake.dart';
import '../cmake_project.dart';
import '../globals.dart' as globals;

abstract class LinuxApp extends ApplicationPackage {
  LinuxApp({required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [LinuxApp] from a linux sub project.
  factory LinuxApp.fromLinuxProject(LinuxProject project) {
    return BuildableLinuxApp(project: project);
  }

  /// Creates a new [LinuxApp] from an existing executable.
  ///
  /// `applicationBinary` is the path to the executable.
  factory LinuxApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    return PrebuiltLinuxApp(executable: applicationBinary.path);
  }

  @override
  String get displayName => id;

  String executable(BuildInfo buildInfo);
}

class PrebuiltLinuxApp extends LinuxApp {
  PrebuiltLinuxApp({required String executable})
    : _executable = executable,
      super(projectBundleId: executable);

  final String _executable;

  @override
  String executable(BuildInfo buildInfo) => _executable;

  @override
  String get name => _executable;
}

class BuildableLinuxApp extends LinuxApp {
  BuildableLinuxApp({required this.project})
    : super(projectBundleId: project.parent.manifest.appName);

  final LinuxProject project;

  @override
  String executable(BuildInfo buildInfo) {
    final String? binaryName = getCmakeExecutableName(project);
    final String linuxGtkVersion = buildInfo.linuxGtkVersion ?? 'gtk3';
    return globals.fs.path.join(
      getLinuxBuildDirectory(null, linuxGtkVersion),
      buildInfo.mode.cliName,
      'bundle',
      binaryName,
    );
  }

  @override
  String get name => project.parent.manifest.appName;
}
