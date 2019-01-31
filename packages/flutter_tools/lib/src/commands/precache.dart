// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import '../runner/flutter_command.dart';

class PrecacheCommand extends FlutterCommand {
  PrecacheCommand() {
    argParser.addFlag('all-platforms', abbr: 'a', negatable: false,
        help: 'Precache artifacts for all platforms.');
  }

  @override
  final String name = 'precache';

  @override
  final String description = 'Populates the Flutter tool\'s cache of binary artifacts.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults['all-platforms'])
      cache.includeAllPlatforms = true;

    // Intentionally set to null to download all artifacts.
    if (cache.isUpToDate(buildMode: null, targetPlatform: null)) {
      printStatus('Already up-to-date.');
    } else {
      await cache.updateAll(buildMode: null, targetPlatform: null);
    }
    return const FlutterCommandResult(ExitStatus.success);
  }
}
