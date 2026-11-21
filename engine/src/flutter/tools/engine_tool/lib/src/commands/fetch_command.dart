// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../bazel.dart';
import '../build_plan.dart';
import '../dependencies.dart';
import 'command.dart';

/// The root 'fetch' command.
final class FetchCommand extends CommandBase {
  /// Constructs the 'fetch' command.
  FetchCommand({required super.environment, super.usageLineLength}) {
    BuildPlan.addBackendOption(argParser, environment);
  }

  @override
  String get name => 'fetch';

  @override
  String get description => "Download the Flutter engine's dependencies";

  @override
  List<String> get aliases => const <String>['sync'];

  @override
  Future<int> run() async {
    if (BuildPlan.backendFromArgResults(argResults!, environment) == BuildBackend.bazel) {
      // gclient and the checkout's .gclient are the GN build's. Bazel reads
      // what `gclient sync` put into the checkout and fetches the rest
      // itself, each dependency when a build first reads it.
      environment.logger.status(
        'Nothing to fetch ahead of a Bazel build: Bazel downloads each '
        'dependency that the checkout lacks when a build first reads it.',
      );
      return 0;
    }
    return fetchDependencies(environment);
  }
}
