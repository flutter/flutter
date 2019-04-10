// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

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
    argParser.addFlag('linux', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for linux desktop development');
    argParser.addFlag('windows', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for windows desktop development');
    argParser.addFlag('macos', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for macOS desktop development');
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
    if (!FlutterVersion.instance.isStable) {
      if (argResults['web']) {
        requiredArtifacts.add(DevelopmentArtifact.web);
      }
      if (argResults['linux']) {
        requiredArtifacts.add(DevelopmentArtifact.linux);
      }
      if (argResults['windows']) {
        requiredArtifacts.add(DevelopmentArtifact.windows);
      }
      if (argResults['macos']) {
        requiredArtifacts.add(DevelopmentArtifact.macOS);
      }
    }

    if (cache.isUpToDate()) {
      printStatus('Already up-to-date.');
    } else {
      await cache.updateAll(requiredArtifacts);
    }
    return null;
  }
}
