// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../project.dart';

abstract class WindowsApp extends ApplicationPackage {
  WindowsApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [WindowsApp] from a windows sub project.
  factory WindowsApp.fromLinuxProject(WindowsProject project) {
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

  String get executable;
}

class PrebuiltWindowsApp extends WindowsApp {
  PrebuiltWindowsApp({
    @required this.executable,
  }) : super(projectBundleId: executable);

  @override
  final String executable;

  @override
  String get name => executable;
}

class BuildableWindowsApp extends WindowsApp {
  BuildableWindowsApp({this.project}) : super(projectBundleId: project.project.manifest.appName);

  final WindowsProject project;

  @override
  String get executable => null;

  @override
  String get name => project.project.manifest.appName;
}
