// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:meta/meta.dart';

import '../base/common.dart';
import '../build_info.dart';
import '../features.dart';
import '../project.dart';
import '../runner/flutter_command.dart'
    show DevelopmentArtifact, FlutterCommandResult;
import '../web/compile.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand({
    @required bool verboseHelp,
  }) {
    addTreeShakeIconsFlag(enabledByDefault: false);
    usesTargetOption();
    usesPubOption();
    addBuildModeFlags(excludeDebug: true);
    usesDartDefineOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    argParser.addFlag('web-initialize-platform',
        defaultsTo: true,
        negatable: true,
        hide: true,
        help: 'Whether to automatically invoke webOnlyInitializePlatform.',
    );
    argParser.addFlag('csp',
      defaultsTo: false,
      negatable: false,
      help: 'Disable dynamic generation of code in the generated output. '
        'This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).'
    );
    argParser.addOption('pwa-strategy',
      defaultsTo: kOfflineFirst,
      help:
        'The caching strategy to be used by the PWA service worker.\n'
        'offline-first will attempt to cache the app shell eagerly and '
        'then lazily cache all subsequent assets as they are loaded. When '
        'making a network request for an asset, the offline cache will be '
        'preferred.\n'
        'online-first will always attempt to make a network request for an '
        'asset, including the app shell. If this fails for any reason, the '
        'app will fallback on a cached version if available. This cache will '
        'be lazily populated as resources are requested.\n'
        'online-only will never attempt to perform offline caching of resources. '
        'if there is no network connectivity, the application will fail to load.',
      allowed: <String>[
        kOfflineFirst,
        kOnlineFirst,
        kOnlineOnly,
      ]
    );
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async =>
      const <DevelopmentArtifact>{
        DevelopmentArtifact.web,
      };

  @override
  final String name = 'web';

  @override
  bool get hidden => !featureFlags.isWebEnabled;

  @override
  final String description = 'Build a web application bundle.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!featureFlags.isWebEnabled) {
      throwToolExit('"build web" is not currently supported.');
    }
    final FlutterProject flutterProject = FlutterProject.current();
    final String target = stringArg('target');
    final BuildInfo buildInfo = getBuildInfo();
    if (buildInfo.isDebug) {
      throwToolExit('debug builds cannot be built directly for the web. Try using "flutter run"');
    }
    await buildWeb(
      flutterProject,
      target,
      buildInfo,
      boolArg('web-initialize-platform'),
      boolArg('csp'),
      stringArg('pwa-strategy'),
    );
    return FlutterCommandResult.success();
  }
}
