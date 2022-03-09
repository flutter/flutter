// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:platform/platform.dart';

import 'git.dart';
import 'globals.dart';
import 'repository.dart';
import 'stdio.dart';

class RollPackagesCommand extends Command<void> {
  RollPackagesCommand({
    required this.flutterRoot,
    required this.checkouts,
  }) : git = Git(checkouts.processManager), stdio = checkouts.stdio, platform = checkouts.platform {
    //argParser.addOption();
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

  @override
  final String name = 'roll-packages';

  @override
  final String description = 'Update all dart packages in the Flutter SDK.';

  @override
  Future<void> run() async {}
}
