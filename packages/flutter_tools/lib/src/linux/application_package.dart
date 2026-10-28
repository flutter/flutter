// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../cmake.dart';
import '../cmake_project.dart';
import '../context/tool_context.dart';

abstract class LinuxApp extends ApplicationPackage {
  LinuxApp({required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [LinuxApp] from a linux sub project.
  factory LinuxApp.fromLinuxProject(LinuxProject project, {required ToolContext toolContext}) {
    return BuildableLinuxApp(project: project, toolContext: toolContext);
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
  BuildableLinuxApp({required this.project, required ToolContext toolContext})
    : _toolContext = toolContext,
      super(projectBundleId: project.parent.manifest.appName);

  final LinuxProject project;
  final ToolContext _toolContext;

  @override
  String executable(BuildInfo buildInfo) {
    final String? binaryName = getCmakeExecutableName(project);
    final FileSystem fileSystem = project.cmakeFile.fileSystem;
    return fileSystem.path.join(
      getLinuxBuildDirectory(
        null,
        flavor: buildInfo.flavor,
        linuxGtkVersion: buildInfo.linuxGtkVersion,
        toolContext: _toolContext,
      ),
      buildInfo.mode.cliName,
      'bundle',
      binaryName,
    );
  }

  @override
  String get name => project.parent.manifest.appName;
}
