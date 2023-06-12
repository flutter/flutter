// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../generate/build_directory.dart';
import '../generate/build_result.dart';
import '../generate/finalized_assets_view.dart';

/// Utilities to interact with the environment in which a build is running.
///
/// All side effects and user interaction should go through the build
/// environment. An IO based environment can write to disk and interact through
/// stdout/stdin, while a theoretical web or remote environment might interact
/// over HTTP.
abstract class BuildEnvironment {
  RunnerAssetReader get reader;
  RunnerAssetWriter get writer;

  void onLog(LogRecord record);

  /// Prompt the user for input.
  ///
  /// The message and choices are displayed to the user and the index of the
  /// chosen option is returned.
  ///
  /// If this environmment is non-interactive (such as when running in a test)
  /// this method should throw [NonInteractiveBuildException].
  Future<int> prompt(String message, List<String> choices);

  /// Invoked after each build, can modify the [BuildResult] in any way, even
  /// converting it to a failure.
  ///
  /// The [finalizedAssetsView] can only be used until the returned [Future]
  /// completes, it will expire afterwords since it can no longer guarantee a
  /// consistent state.
  ///
  /// By default this returns the original result.
  ///
  /// Any operation may be performed, as determined by environment.
  Future<BuildResult> finalizeBuild(
          BuildResult buildResult,
          FinalizedAssetsView finalizedAssetsView,
          AssetReader assetReader,
          Set<BuildDirectory> buildDirs) =>
      Future.value(buildResult);
}

/// Thrown when the build attempts to prompt the users but no prompt is
/// possible.
class NonInteractiveBuildException implements Exception {}
