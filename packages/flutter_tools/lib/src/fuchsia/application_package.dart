// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';

abstract class FuchsiaApp extends ApplicationPackage {
  FuchsiaApp({required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [FuchsiaApp] from a fuchsia sub project.
  static FuchsiaApp? fromFuchsiaProject(FuchsiaProject project) {
    if (!project.existsSync()) {
      // If the project doesn't exist at all the current hint to run flutter
      // create is accurate.
      return null;
    }
    return BuildableFuchsiaApp(
      project: project,
    );
  }

  /// Creates a new [FuchsiaApp] from an existing .far archive.
  ///
  /// [applicationBinary] is the path to the .far archive.
  static FuchsiaApp? fromPrebuiltApp(FileSystemEntity applicationBinary) {
    final FileSystemEntityType entityType = globals.fs.typeSync(applicationBinary.path);
    if (entityType != FileSystemEntityType.file) {
      globals.printError('File "${applicationBinary.path}" does not exist or is not a .far file. Use far archive.');
      return null;
    }
    return PrebuiltFuchsiaApp(
      farArchive: applicationBinary.path,
    );
  }

  @override
  String get displayName => id;

  /// The location of the 'far' archive containing the built app.
  File farArchive(BuildMode buildMode);
}

class PrebuiltFuchsiaApp extends FuchsiaApp {
  PrebuiltFuchsiaApp({
    required String farArchive,
  }) : _farArchive = farArchive,
       // TODO(zanderso): Extract the archive and extract the id from meta/package.
       super(projectBundleId: farArchive);

  final String _farArchive;

  @override
  File farArchive(BuildMode buildMode) => globals.fs.file(_farArchive);

  @override
  String get name => _farArchive;
}

class BuildableFuchsiaApp extends FuchsiaApp {
  BuildableFuchsiaApp({required this.project}) :
      super(projectBundleId: project.project.manifest.appName);

  final FuchsiaProject project;

  @override
  File farArchive(BuildMode buildMode) {
    // TODO(zanderso): Distinguish among build modes.
    final String outDir = getFuchsiaBuildDirectory();
    final String pkgDir = globals.fs.path.join(outDir, 'pkg');
    final String appName = project.project.manifest.appName;
    return globals.fs.file(globals.fs.path.join(pkgDir, '$appName-0.far'));
  }

  @override
  String get name => project.project.manifest.appName;
}
