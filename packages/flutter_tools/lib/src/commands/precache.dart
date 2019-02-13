// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class PrecacheCommand extends FlutterCommand {
  PrecacheCommand() {
    argParser.addFlag('all-platforms', abbr: 'a', negatable: false,
        help: 'Precache artifacts for all platforms.');
    argParser.addFlag('force', abbr: 'f', negatable: false,
        help: 'Force download of new cached artifacts');
  }

  @override
  final String name = 'precache';

  @override
  final String description = 'Populates the Flutter tool\'s cache of binary artifacts.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults['all-platforms']) {
      cache.includeAllPlatforms = true;
    }
    final UpdateResult result = cache.isUpToDate(skipUnknown: false);
    if (result.isUpToDate && !result.clobber && !argResults['force']) {
      printStatus('Already up-to-date.');
    } else {
      await cache.updateAll(
        skipUnknown: false,
        clobber: argResults['force'] || result.clobber,
      );
    }
    return const FlutterCommandResult(ExitStatus.success);
  }
}
