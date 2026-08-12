// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../build_info.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'compile.dart';
import 'file_generators/flutter_service_worker_js.dart';
import 'web_options.dart';

/// A typed, validated specification for executing a Flutter Web build.
class WebBuildSpecification {
  const WebBuildSpecification({
    required this.project,
    required this.target,
    required this.buildInfo,
    required this.compilerConfigs,
    this.serviceWorkerStrategy,
    this.baseHref,
    this.staticAssetsUrl,
    this.outputDirectoryPath,
    this.webDefines = const <String, String>{},
  });

  /// Constructs a [WebBuildSpecification] from [command] using typed option descriptors.
  factory WebBuildSpecification.fromCommand(
    FlutterCommand command, {
    required FlutterProject project,
    required String target,
    required BuildInfo buildInfo,
    required List<WebCompilerConfig> compilerConfigs,
    Map<String, String> webDefines = const <String, String>{},
  }) {
    final String? pwaStrategyRaw = command.getString(WebOptions.pwaStrategy);
    final ServiceWorkerStrategy? pwaStrategy = pwaStrategyRaw != null
        ? ServiceWorkerStrategy.fromCliName(pwaStrategyRaw)
        : null;

    final String? outputDirectoryPath =
        command.getString(CommonOptions.outputDir) ??
        (command.argResults != null && command.argResults!.options.contains('output')
            ? command.stringArg('output')
            : null);

    return WebBuildSpecification(
      project: project,
      target: target,
      buildInfo: buildInfo,
      compilerConfigs: compilerConfigs,
      serviceWorkerStrategy: pwaStrategy,
      baseHref: command.getString(WebOptions.baseHref),
      staticAssetsUrl: command.getString(WebOptions.staticAssetsUrl),
      outputDirectoryPath: outputDirectoryPath,
      webDefines: webDefines,
    );
  }

  /// The Flutter project being compiled.
  final FlutterProject project;

  /// The path to the main Dart entrypoint file.
  final String target;

  /// Generic build mode and compiler configuration.
  final BuildInfo buildInfo;

  /// The web compiler configurations (e.g. dart2js, dart2wasm).
  final List<WebCompilerConfig> compilerConfigs;

  /// The PWA service worker caching strategy.
  final ServiceWorkerStrategy? serviceWorkerStrategy;

  /// Overrides the `<base href="...">` in `web/index.html`.
  final String? baseHref;

  /// URL prefix for hosting static assets from a separate CDN.
  final String? staticAssetsUrl;

  /// The custom output directory path, if specified.
  final String? outputDirectoryPath;

  /// Custom key-value pairs passed via `--web-define`.
  final Map<String, String> webDefines;
}
