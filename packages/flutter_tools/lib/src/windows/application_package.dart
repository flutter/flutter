// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cmake.dart';
import '../globals_null_migrated.dart' as globals;
import '../project.dart';

abstract class WindowsApp extends ApplicationPackage {
  WindowsApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [WindowsApp] from a windows sub project.
  factory WindowsApp.fromWindowsProject(WindowsProject project) {
    return BuildableWindowsApp(
      project: project,
    );
  }

  /// Creates a new [WindowsApp] from an existing executable.
  ///
  /// `applicationBinary` is the path to the executable.
  factory WindowsApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    return PrebuiltWindowsApp(
      executable: applicationBinary.path,
    );
  }

  @override
  String get displayName => id;

  String executable(BuildMode buildMode);
}

class PrebuiltWindowsApp extends WindowsApp {
  PrebuiltWindowsApp({
    @required String executable,
  }) : _executable = executable,
       super(projectBundleId: executable);

  final String _executable;

  @override
  String executable(BuildMode buildMode) => _executable;

  @override
  String get name => _executable;
}

class BuildableWindowsApp extends WindowsApp {
  BuildableWindowsApp({
    @required this.project,
  }) : super(projectBundleId: project.parent.manifest.appName);

  final WindowsProject project;

  @override
  String executable(BuildMode buildMode) {
    final String binaryName = getCmakeExecutableName(project);
    return globals.fs.path.join(
        getWindowsBuildDirectory(),
        'runner',
        toTitleCase(getNameForBuildMode(buildMode)),
        '$binaryName.exe',
    );
  }

  @override
  String get name => project.parent.manifest.appName;
}
