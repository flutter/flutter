// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';

import '../globals.dart';
import '../runner/flutter_command.dart';

class PrecacheCommand extends FlutterCommand {
  PrecacheCommand() {
    argParser.addFlag('all-platforms', abbr: 'a', negatable: false,
        help: 'Precache artifacts for all platforms.');
    argParser.addFlag('android', negatable: true, defaultsTo: true,
        help: 'Precache artifacts for Android development');
    argParser.addFlag('ios', negatable: true, defaultsTo: true,
        help: 'Precache artifacts for iOS developemnt');
    argParser.addFlag('web', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for web development');
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
    final Set<DevelopmentArtifact> requiredArtifacts = <DevelopmentArtifact>{ DevelopmentArtifact.universal };
    if (argResults['android']) {
      requiredArtifacts.add(DevelopmentArtifact.android);
    }
    if (argResults['ios']) {
      requiredArtifacts.add(DevelopmentArtifact.iOS);
    }
    if (argResults['web']) {
      requiredArtifacts.add(DevelopmentArtifact.web);
    }

    if (cache.isUpToDate(requiredArtifacts)) {
      printStatus('Already up-to-date.');
    } else {
      await cache.updateAll(requiredArtifacts);
    }
    return null;
  }
}
