// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../dependencies.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'fetch' command.
final class FetchCommand extends CommandBase {
  /// Constructs the 'fetch' command.
  FetchCommand({
    required super.environment,
  });

  @override
  String get name => 'fetch';

  @override
  String get description => "Download the Flutter engine's dependencies";

  @override
  List<String> get aliases => const <String>['sync'];

  @override
  Future<int> run() {
    final bool verbose = globalResults![verboseFlag] as bool;
    return fetchDependencies(environment, verbose: verbose);
  }
}
