// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
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
  }) : super(projectBundleId: project.project.manifest.appName);

  final WindowsProject project;

  @override
  String executable(BuildMode buildMode) {
    final File exeNameFile = project.nameFile;
    if (!exeNameFile.existsSync()) {
      throwToolExit('Failed to find Windows executable name');
    }
    return fs.path.join(
        getWindowsBuildDirectory(),
        'x64',
        toTitleCase(getNameForBuildMode(buildMode)),
        'Runner',
        exeNameFile.readAsStringSync().trim());
  }

  @override
  String get name => project.project.manifest.appName;
}
