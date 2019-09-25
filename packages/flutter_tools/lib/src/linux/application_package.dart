// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../project.dart';
import 'makefile.dart';

abstract class LinuxApp extends ApplicationPackage {
  LinuxApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [LinuxApp] from a linux sub project.
  factory LinuxApp.fromLinuxProject(LinuxProject project) {
    return BuildableLinuxApp(
      project: project,
    );
  }

  /// Creates a new [LinuxApp] from an existing executable.
  ///
  /// `applicationBinary` is the path to the executable.
  factory LinuxApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    return PrebuiltLinuxApp(
      executable: applicationBinary.path,
    );
  }

  @override
  String get displayName => id;

  String executable(BuildMode buildMode);
}

class PrebuiltLinuxApp extends LinuxApp {
  PrebuiltLinuxApp({
    @required String executable,
  }) : _executable = executable,
       super(projectBundleId: executable);

  final String _executable;

  @override
  String executable(BuildMode buildMode) => _executable;

  @override
  String get name => _executable;
}

class BuildableLinuxApp extends LinuxApp {
  BuildableLinuxApp({this.project}) : super(projectBundleId: project.project.manifest.appName);

  final LinuxProject project;

  @override
  String executable(BuildMode buildMode) {
    final String binaryName = makefileExecutableName(project);
    return fs.path.join(getLinuxBuildDirectory(), getNameForBuildMode(buildMode), binaryName);
  }

  @override
  String get name => project.project.manifest.appName;
}
