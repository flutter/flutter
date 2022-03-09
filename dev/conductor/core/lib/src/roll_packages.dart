// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:platform/platform.dart';

import 'git.dart';
import 'globals.dart';
import 'repository.dart';
import 'stdio.dart';

class RollPackagesContext {
  RollPackagesContext._({
    required this.flutterRoot,
    required this.checkouts,
  }) : git = Git(checkouts.processManager), stdio = checkouts.stdio, platform = checkouts.platform;

  factory RollPackagesContext.fromCommandLine({
    required Directory flutterRoot,
    required Checkouts checkouts,
    required List<String> args,
  }) {
    final ArgParser parser = ArgParser();
    final ArgResults results = parser.parse(args);
    return RollPackagesContext._(flutterRoot: flutterRoot, checkouts: checkouts);
  }

  final Checkouts checkouts;
  final Directory flutterRoot;
  final Git git;
  final Platform platform;
  final Stdio stdio;
  String get token {
    const String key = 'GITHUB_TOKEN';
    final String? envValue = platform.environment[key];
    if (envValue == null) {
      throw ConductorException('The env var $key is required but not present');
    }
    return envValue;
  }

  Future<void> run() async {
    final FrameworkRepository framework = FrameworkRepository(checkouts);
  }
}
