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
    required FlutterProject project,
    required Set<AndroidBuildInfo> androidBuildInfo,
    required String target,
    String? outputDirectoryPath,
    required String buildNumber,
  }) async {}

  @override
  Future<void> buildApk({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool configOnly = false,
  }) async {}

  @override
  Future<void> buildAab({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool validateDeferredComponents = true,
    bool deferredComponentsEnabled = false,
    bool configOnly = false,
  }) async {}

  @override
  Future<List<String>> getBuildVariants({required FlutterProject project}) async => const <String>[];

  @override
  Future<String> outputsAppLinkSettings(
    String buildVariant, {
    required FlutterProject project,
  }) async => '/';
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
  FlutterProject fromDirectory(Directory _) {
    projects.clear();
    return super.fromDirectory(directoryOverride.childDirectory('flutter_project'));
  }
}
