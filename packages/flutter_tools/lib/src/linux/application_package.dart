// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../project.dart';

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

  String get executable;
}

class PrebuiltLinuxApp extends LinuxApp {
  PrebuiltLinuxApp({
    @required this.executable,
  }) : super(projectBundleId: executable);

  @override
  final String executable;

  @override
  String get name => executable;
}

class BuildableLinuxApp extends LinuxApp {
  BuildableLinuxApp({this.project}) : super(projectBundleId: project.project.manifest.appName);

  final LinuxProject project;

  @override
  String get executable => null;

  @override
  String get name => project.project.manifest.appName;
}
