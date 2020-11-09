// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../build_info.dart';
import '../build_system/targets/web.dart';
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
        'none will generate a service worker with no body. This is useful for '
        'local testing or in cases where the service worker caching functionality '
        'is not desirable',
      allowed: <String>[
        kOfflineFirst,
        kNoneWorker,
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
