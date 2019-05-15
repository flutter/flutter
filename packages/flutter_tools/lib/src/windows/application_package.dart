// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
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
    final ProcessResult result = processManager.runSync(<String>[
      project.nameScript.path,
      buildMode == BuildMode.debug ? 'debug' : 'release',
    ]);
    if (result.exitCode != 0) {
      throwToolExit('Failed to find Windows project name');
    }
    return result.stdout.toString().trim();
  }

  @override
  String get name => project.project.manifest.appName;
}
