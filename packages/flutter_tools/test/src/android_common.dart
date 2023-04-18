// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';

/// A fake implementation of [AndroidBuilder].
class FakeAndroidBuilder implements AndroidBuilder {
  @override
  Future<void> buildAar({
    required final FlutterProject project,
    required final Set<AndroidBuildInfo> androidBuildInfo,
    required final String target,
    final String? outputDirectoryPath,
    required final String buildNumber,
  }) async {}

  @override
  Future<void> buildApk({
    required final FlutterProject project,
    required final AndroidBuildInfo androidBuildInfo,
    required final String target,
    final bool configOnly = false,
  }) async {}

  @override
  Future<void> buildAab({
    required final FlutterProject project,
    required final AndroidBuildInfo androidBuildInfo,
    required final String target,
    final bool validateDeferredComponents = true,
    final bool deferredComponentsEnabled = false,
    final bool configOnly = false,
  }) async {}
}

/// Creates a [FlutterProject] in a directory named [flutter_project]
/// within [directoryOverride].
class FakeFlutterProjectFactory extends FlutterProjectFactory {
  FakeFlutterProjectFactory(this.directoryOverride) :
    super(
      fileSystem: globals.fs,
      logger: globals.logger,
    );

  final Directory directoryOverride;

  @override
  FlutterProject fromDirectory(final Directory _) {
    projects.clear();
    return super.fromDirectory(directoryOverride.childDirectory('flutter_project'));
  }
}
