// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/project_migrator.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/web.dart';
import '../cache.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../version.dart';
import 'compiler_config.dart';
import 'file_generators/flutter_service_worker_js.dart';
import 'migrations/scrub_generated_plugin_registrant.dart';
import 'web_constants.dart';

export 'compiler_config.dart';

class WebBuilder {
  WebBuilder({
    required Logger logger,
    required ProcessManager processManager,
    required BuildSystem buildSystem,
    required Usage usage,
    required FlutterVersion flutterVersion,
    required FileSystem fileSystem,
  })  : _logger = logger,
        _processManager = processManager,
        _buildSystem = buildSystem,
        _flutterUsage = usage,
        _flutterVersion = flutterVersion,
        _fileSystem = fileSystem;

  final Logger _logger;
  final ProcessManager _processManager;
  final BuildSystem _buildSystem;
  final Usage _flutterUsage;
  final FlutterVersion _flutterVersion;
  final FileSystem _fileSystem;

  Future<void> buildWeb(
    FlutterProject flutterProject,
    String target,
    BuildInfo buildInfo,
    ServiceWorkerStrategy serviceWorkerStrategy, {
    required WebCompilerConfig compilerConfig,
    String? baseHref,
    String? outputDirectoryPath,
  }) async {
    if (compilerConfig.isWasm) {
      globals.logger.printBox(
        title: 'Experimental feature',
        '''
  WebAssembly compilation is experimental.
  $kWasmMoreInfo''',
      );
    }

    final bool hasWebPlugins =
        (await findPlugins(flutterProject)).any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
    final Directory outputDirectory = outputDirectoryPath == null
        ? _fileSystem.directory(getWebBuildDirectory(compilerConfig.isWasm))
        : _fileSystem.directory(outputDirectoryPath);
    outputDirectory.createSync(recursive: true);

    // The migrators to apply to a Web project.
    final List<ProjectMigrator> migrators = <ProjectMigrator>[
      ScrubGeneratedPluginRegistrant(flutterProject.web, _logger),
    ];

    final ProjectMigration migration = ProjectMigration(migrators);
    migration.run();

    final Status status = _logger.startProgress('Compiling $target for the Web...');
    final Stopwatch sw = Stopwatch()..start();
    try {
      final BuildResult result = await _buildSystem.build(
          WebServiceWorker(_fileSystem, buildInfo.webRenderer, isWasm: compilerConfig.isWasm),
          Environment(
            projectDir: _fileSystem.currentDirectory,
            outputDir: outputDirectory,
            buildDir: flutterProject.directory.childDirectory('.dart_tool').childDirectory('flutter_build'),
            defines: <String, String>{
              kTargetFile: target,
              kHasWebPlugins: hasWebPlugins.toString(),
              if (baseHref != null) kBaseHref: baseHref,
              kServiceWorkerStrategy: serviceWorkerStrategy.cliName,
              ...compilerConfig.toBuildSystemEnvironment(),
              ...buildInfo.toBuildSystemEnvironment(),
            },
            artifacts: globals.artifacts!,
            fileSystem: _fileSystem,
            logger: _logger,
            processManager: _processManager,
            platform: globals.platform,
            usage: _flutterUsage,
            cacheDir: globals.cache.getRoot(),
            engineVersion: globals.artifacts!.isLocalEngine ? null : _flutterVersion.engineRevision,
            flutterRootDir: _fileSystem.directory(Cache.flutterRoot),
            // Web uses a different Dart plugin registry.
            // https://github.com/flutter/flutter/issues/80406
            generateDartPluginRegistry: false,
          ));
      if (!result.success) {
        for (final ExceptionMeasurement measurement in result.exceptions.values) {
          _logger.printError(
            'Target ${measurement.target} failed: ${measurement.exception}',
            stackTrace: measurement.fatal ? measurement.stackTrace : null,
          );
        }
        throwToolExit('Failed to compile application for the Web.');
      }
    } on Exception catch (err) {
      throwToolExit(err.toString());
    } finally {
      status.stop();
    }
    BuildEvent(
      'web-compile',
      type: 'web',
      settings: _buildEventAnalyticsSettings(
        config: compilerConfig,
        buildInfo: buildInfo,
      ),
      flutterUsage: _flutterUsage,
    ).send();

    _flutterUsage.sendTiming(
      'build',
      compilerConfig.isWasm ? 'dart2wasm' : 'dart2js',
      Duration(milliseconds: sw.elapsedMilliseconds),
    );
  }
}

/// Web rendering backend mode.
enum WebRendererMode implements CliEnum {
  /// Auto detects which rendering backend to use.
  auto,

  /// Always uses canvaskit.
  canvaskit,

  /// Always uses html.
  html,

  /// Always use skwasm.
  skwasm;

  @override
  String get cliName => snakeCase(name, '-');

  @override
  String get helpText => switch (this) {
        auto =>
          'Use the HTML renderer on mobile devices, and CanvasKit on desktop devices.',
        canvaskit =>
          'Always use the CanvasKit renderer. This renderer uses WebGL and WebAssembly to render graphics.',
        html =>
          'Always use the HTML renderer. This renderer uses a combination of HTML, CSS, SVG, 2D Canvas, and WebGL.',
        skwasm => 'Always use the experimental skwasm renderer.'
      };

  Iterable<String> get dartDefines => switch (this) {
        WebRendererMode.auto => <String>[
            'FLUTTER_WEB_AUTO_DETECT=true',
          ],
        WebRendererMode.canvaskit => <String>[
            'FLUTTER_WEB_AUTO_DETECT=false',
            'FLUTTER_WEB_USE_SKIA=true',
          ],
        WebRendererMode.html => <String>[
            'FLUTTER_WEB_AUTO_DETECT=false',
            'FLUTTER_WEB_USE_SKIA=false',
          ],
        WebRendererMode.skwasm => <String>[
            'FLUTTER_WEB_AUTO_DETECT=false',
            'FLUTTER_WEB_USE_SKIA=false',
            'FLUTTER_WEB_USE_SKWASM=true',
          ]
      };
}

/// The correct precompiled artifact to use for each build and render mode.
const Map<WebRendererMode, Map<NullSafetyMode, HostArtifact>> kDartSdkJsArtifactMap = <WebRendererMode, Map<NullSafetyMode, HostArtifact>>{
  WebRendererMode.auto: <NullSafetyMode, HostArtifact> {
    NullSafetyMode.sound: HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdk,
    NullSafetyMode.unsound: HostArtifact.webPrecompiledCanvaskitAndHtmlSdk,
  },
  WebRendererMode.canvaskit: <NullSafetyMode, HostArtifact> {
    NullSafetyMode.sound: HostArtifact.webPrecompiledCanvaskitSoundSdk,
    NullSafetyMode.unsound: HostArtifact.webPrecompiledCanvaskitSdk,
  },
  WebRendererMode.html: <NullSafetyMode, HostArtifact> {
    NullSafetyMode.sound: HostArtifact.webPrecompiledSoundSdk,
    NullSafetyMode.unsound: HostArtifact.webPrecompiledSdk,
  },
};

/// The correct source map artifact to use for each build and render mode.
const Map<WebRendererMode, Map<NullSafetyMode, HostArtifact>> kDartSdkJsMapArtifactMap = <WebRendererMode, Map<NullSafetyMode, HostArtifact>>{
  WebRendererMode.auto: <NullSafetyMode, HostArtifact> {
    NullSafetyMode.sound: HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdkSourcemaps,
    NullSafetyMode.unsound: HostArtifact.webPrecompiledCanvaskitAndHtmlSdkSourcemaps,
  },
  WebRendererMode.canvaskit: <NullSafetyMode, HostArtifact> {
    NullSafetyMode.sound: HostArtifact.webPrecompiledCanvaskitSoundSdkSourcemaps,
    NullSafetyMode.unsound: HostArtifact.webPrecompiledCanvaskitSdkSourcemaps,
  },
  WebRendererMode.html: <NullSafetyMode, HostArtifact> {
    NullSafetyMode.sound: HostArtifact.webPrecompiledSoundSdkSourcemaps,
    NullSafetyMode.unsound: HostArtifact.webPrecompiledSdkSourcemaps,
  },
};

String _buildEventAnalyticsSettings({
  required WebCompilerConfig config,
  required BuildInfo buildInfo,
}) {
  final Map<String, Object> values = <String, Object>{
    ...config.buildEventAnalyticsValues,
    'web-renderer': buildInfo.webRenderer.cliName,
  };

  final List<String> sortedList = values.entries
      .map((MapEntry<String, Object> e) => '${e.key}: ${e.value};')
      .toList()
    ..sort();

  return sortedList.join(' ');
}
