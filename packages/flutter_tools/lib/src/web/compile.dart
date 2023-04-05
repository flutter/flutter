// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/project_migrator.dart';
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
import 'migrations/scrub_generated_plugin_registrant.dart';

export '../build_system/targets/web.dart' show kDart2jsDefaultOptimizationLevel;

class WebBuilder {
  WebBuilder({
    required Logger logger,
    required BuildSystem buildSystem,
    required Usage usage,
    required FlutterVersion flutterVersion,
    required FileSystem fileSystem,
  })  : _logger = logger,
        _buildSystem = buildSystem,
        _flutterUsage = usage,
        _flutterVersion = flutterVersion,
        _fileSystem = fileSystem;

  final Logger _logger;
  final BuildSystem _buildSystem;
  final Usage _flutterUsage;
  final FlutterVersion _flutterVersion;
  final FileSystem _fileSystem;

  Future<void> buildWeb(
    FlutterProject flutterProject,
    String target,
    BuildInfo buildInfo,
    bool csp,
    String serviceWorkerStrategy,
    bool sourceMaps,
    bool nativeNullAssertions,
    bool isWasm, {
    String dart2jsOptimization = kDart2jsDefaultOptimizationLevel,
    String? baseHref,
    bool dumpInfo = false,
    bool noFrequencyBasedMinification = false,
    String? outputDirectoryPath,
  }) async {
    if (isWasm) {
      globals.logger.printBox(
        title: 'Experimental feature',
        '''
  WebAssembly compilation is experimental.
  See $kWasmPreviewUri for more information.''',
      );
    }

    final bool hasWebPlugins =
        (await findPlugins(flutterProject)).any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
    final Directory outputDirectory = outputDirectoryPath == null
        ? _fileSystem.directory(getWebBuildDirectory(isWasm))
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
          WebServiceWorker(_fileSystem, buildInfo.webRenderer, isWasm: isWasm),
          Environment(
            projectDir: _fileSystem.currentDirectory,
            outputDir: outputDirectory,
            buildDir: flutterProject.directory.childDirectory('.dart_tool').childDirectory('flutter_build'),
            defines: <String, String>{
              kTargetFile: target,
              kHasWebPlugins: hasWebPlugins.toString(),
              kCspMode: csp.toString(),
              if (baseHref != null) kBaseHref: baseHref,
              kSourceMapsEnabled: sourceMaps.toString(),
              kNativeNullAssertions: nativeNullAssertions.toString(),
              kServiceWorkerStrategy: serviceWorkerStrategy,
              kDart2jsOptimization: dart2jsOptimization,
              kDart2jsDumpInfo: dumpInfo.toString(),
              kDart2jsNoFrequencyBasedMinification: noFrequencyBasedMinification.toString(),
              ...buildInfo.toBuildSystemEnvironment(),
            },
            artifacts: globals.artifacts!,
            fileSystem: _fileSystem,
            logger: _logger,
            processManager: globals.processManager,
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
    _flutterUsage.sendTiming('build', 'dart2js', Duration(milliseconds: sw.elapsedMilliseconds));
  }
}

/// Web rendering backend mode.
enum WebRendererMode {
  /// Auto detects which rendering backend to use.
  autoDetect,
  /// Always uses canvaskit.
  canvaskit,
  /// Always uses html.
  html,
}

/// The correct precompiled artifact to use for each build and render mode.
const Map<WebRendererMode, Map<NullSafetyMode, HostArtifact>> kDartSdkJsArtifactMap = <WebRendererMode, Map<NullSafetyMode, HostArtifact>>{
  WebRendererMode.autoDetect: <NullSafetyMode, HostArtifact> {
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
  WebRendererMode.autoDetect: <NullSafetyMode, HostArtifact> {
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

const String kWasmPreviewUri = 'https://flutter.dev/wasm';
