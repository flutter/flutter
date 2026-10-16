// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux implementation of [CleanService].
///
/// Demonstrates the [CleanService] protocol by removing Linux build and
/// ephemeral directories before the host `CleanCommand` performs its own
/// directory deletion.
final class LinuxCleanService extends CleanService {
  @override
  Future<void> clean(CleanEnvironment environment) async {
    final linuxBuildDir = Directory.fromUri(environment.buildDir.resolve('linux/'));
    if (linuxBuildDir.existsSync()) {
      linuxBuildDir.deleteSync(recursive: true);
    }

    final linuxEphemeralDir = Directory.fromUri(
      environment.projectRoot.resolve('linux/flutter/ephemeral/'),
    );
    if (linuxEphemeralDir.existsSync()) {
      linuxEphemeralDir.deleteSync(recursive: true);
    }
  }
}
