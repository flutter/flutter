// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:package_config/package_config.dart';

/// Writes a `.dart_tool/package_config.json` that includes [packages].
///
/// - If [entity] is a [File], it is written to assuming it _is_ `package_config.json`.
/// - If [entity] is a [Directory], `.dart_tool/package_config.json` is written relative to that directory.
void writePackageConfig(FileSystemEntity entity, {Iterable<Package> packages = const <Package>[]}) {
  switch (entity) {
    case Directory():
      writePackageConfigForProject(FlutterProject.fromDirectoryTest(entity), packages: packages);
    case File():
      const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');
      entity
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncoder.convert(PackageConfig(packages)));
  }
}

/// Writes a `.dart_tool/package_config.json` that includes [packages].
///
/// This is a convenience function for:
/// ```dart
/// writePackageConfig(project.packageConfig);
/// ```
void writePackageConfigForProject(
  FlutterProject project, {
  Iterable<Package> packages = const <Package>[],
}) {
  writePackageConfig(project.packageConfig, packages: packages);
}
