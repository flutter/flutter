// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import '../environment/build_environment.dart';
import '../package_graph/apply_builders.dart';
import 'build_directory.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'options.dart';

class BuildRunner {
  final BuildImpl _build;
  BuildRunner._(this._build);

  Future<void> beforeExit() => _build.beforeExit();

  Future<BuildResult> run(Map<AssetId, ChangeType> updates,
          {Set<BuildDirectory> buildDirs, Set<BuildFilter> buildFilters}) =>
      _build.run(updates, buildDirs: buildDirs, buildFilters: buildFilters);

  static Future<BuildRunner> create(
      BuildOptions options,
      BuildEnvironment environment,
      List<BuilderApplication> builders,
      Map<String, Map<String, dynamic>> builderConfigOverrides,
      {bool isReleaseBuild = false}) async {
    return BuildRunner._(await BuildImpl.create(
        options, environment, builders, builderConfigOverrides,
        isReleaseBuild: isReleaseBuild));
  }
}
