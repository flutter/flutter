// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux implementation of [CleanService].
///
/// Demonstrates the [CleanService] protocol by removing Linux build and
/// ephemeral directories before the host `CleanCommand` performs its own
/// directory deletion.
final class LinuxCleanService extends CleanService {
  LinuxCleanService({required this._dependencies});

  final ExtensionDependencies _dependencies;

  @override
  Future<void> clean(CleanEnvironment environment) async {
    final ExtensionDirectory linuxBuildDir = _dependencies.fileSystem.directory(
      environment.buildDir.resolve('linux/'),
    );
    if (linuxBuildDir.existsSync()) {
      await linuxBuildDir.delete(recursive: true);
    }

    final ExtensionDirectory linuxEphemeralDir = _dependencies.fileSystem.directory(
      environment.projectRoot.resolve('linux/flutter/ephemeral/'),
    );
    if (linuxEphemeralDir.existsSync()) {
      await linuxEphemeralDir.delete(recursive: true);
    }
  }
}
