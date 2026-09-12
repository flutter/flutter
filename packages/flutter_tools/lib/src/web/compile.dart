// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/project_migrator.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../flutter_plugins.dart';
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../version.dart';
import 'compiler_config.dart';
import 'file_generators/flutter_service_worker_js.dart';
import 'migrations/scrub_generated_plugin_registrant.dart';

export 'compiler_config.dart';

/// Whether the application has web plugins.
const kHasWebPlugins = 'HasWebPlugins';

/// Base href to set in index.html in flutter build command
const kBaseHref = 'baseHref';

/// Static assets url to set in index.html in flutter build command
const kStaticAssetsUrl = 'staticAssetsUrl';

/// The caching strategy to use for service worker generation.
const kServiceWorkerStrategy = 'ServiceWorkerStrategy';

/// Prefix for web-define variables stored in [Environment.defines].
const kWebDefinePrefix = 'webDefine:';

class WebBuilder {
  WebBuilder({
    required Analytics analytics,
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    BuildTargets? buildTargets,
  }) : this.fromParameters(
         analytics: analytics,
         artifacts: toolContext.artifacts,
         buildSystem: buildSystem,
         buildTargets: buildTargets,
         cache: toolContext.cache,
         config: toolContext.config,
         fileSystem: toolContext.fs,
         flutterVersion: toolContext.flutterVersion,
         logger: toolContext.logger,
         platform: toolContext.platform,
         processManager: toolContext.processManager,
         terminal: toolContext.terminal,
       );

  WebBuilder.fromParameters({
    required this.analytics,
    required this.artifacts,
    required this.buildSystem,
    required this.cache,
    required this.config,
    required this.fileSystem,
    required this.flutterVersion,
    required this.logger,
    required this.platform,
    required this.processManager,
    required this.terminal,
    BuildTargets? buildTargets,
  }) : _buildTargets = buildTargets ?? const NoOpBuildTargets();

  final Analytics analytics;
  final Artifacts artifacts;
  final BuildSystem buildSystem;
  final BuildTargets _buildTargets;
  final Cache cache;
  final Config config;
  final FileSystem fileSystem;
  final FlutterVersion flutterVersion;
  final Logger logger;
  final Platform platform;
  final ProcessManager processManager;
  final Terminal terminal;

  /// Builds the web application using the specified compiler configurations
  /// and generates the necessary web assets in the output directory.
  Future<void> buildWeb(
    FlutterProject flutterProject,
    String target,
    BuildInfo buildInfo,
    ServiceWorkerStrategy? serviceWorkerStrategy, {
    required List<WebCompilerConfig> compilerConfigs,
    String? baseHref,
    String? staticAssetsUrl,
    String? outputDirectoryPath,
    Map<String, String> webDefines = const <String, String>{},
  }) async {
    if (serviceWorkerStrategy != null) {
      logger.printWarning(
        'The --pwa-strategy option is deprecated and will be removed in a future Flutter release.\n'
        'For more information, see: https://github.com/flutter/flutter/issues/156910',
      );
    }

    final bool hasWebPlugins = (await findPlugins(
      flutterProject,
      logger: logger,
    )).any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
    final Directory outputDirectory = outputDirectoryPath == null
        ? fileSystem.directory(
            fileSystem.path.join(
              flutterProject.directory.path,
              getWebBuildDirectory(config: config, fileSystem: fileSystem),
            ),
          )
        : fileSystem.directory(outputDirectoryPath);
    outputDirectory.createSync(recursive: true);

    // The migrators to apply to a Web project.
    final migrators = <ProjectMigrator>[ScrubGeneratedPluginRegistrant(flutterProject.web, logger)];

    final migration = ProjectMigration(migrators);
    await migration.run();

    final Status status = logger.startProgress('Compiling $target for the Web...');
    final sw = Stopwatch()..start();
    try {
      final BuildResult result = await buildSystem.build(
        _buildTargets.webServiceWorker(fileSystem, compilerConfigs, analytics),
        Environment(
          projectDir: flutterProject.directory,
          outputDir: outputDirectory,
          buildDir: flutterProject.directory
              .childDirectory('.dart_tool')
              .childDirectory('flutter_build'),
          defines: <String, String>{
            kTargetFile: target,
            kHasWebPlugins: hasWebPlugins.toString(),
            kBaseHref: ?baseHref,
            kStaticAssetsUrl: ?staticAssetsUrl,
            kServiceWorkerStrategy:
                serviceWorkerStrategy?.cliName ?? ServiceWorkerStrategy.offlineFirst.cliName,
            ...buildInfo.toBuildSystemEnvironment(),
            for (final MapEntry(:key, :value) in webDefines.entries) '$kWebDefinePrefix$key': value,
          },
          packageConfigPath: buildInfo.packageConfigPath,
          artifacts: artifacts,
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
          platform: platform,
          analytics: analytics,
          cacheDir: cache.getRoot(),
          engineVersion: artifacts.usesLocalArtifacts ? null : flutterVersion.engineRevision,
          flutterRootDir: fileSystem.directory(Cache.flutterRoot),
          // Web uses a different Dart plugin registry.
          // https://github.com/flutter/flutter/issues/80406
          generateDartPluginRegistry: false,
        ),
      );
      if (!result.success) {
        for (final ExceptionMeasurement measurement in result.exceptions.values) {
          logger.printError(
            'Target ${measurement.target} failed: ${measurement.exception}',
            stackTrace: (measurement.fatal && measurement.exception is! ToolExit)
                ? measurement.stackTrace
                : null,
          );
        }
        throwToolExit('Failed to compile application for the Web.');
      }
    } on Exception catch (err) {
      throwToolExit(err.toString());
    } finally {
      status.stop();
    }

    // We don't print a size because the output directory can contain
    // optional files not needed by the user.
    logger.printStatus(
      '${terminal.successMark} '
      'Built ${fileSystem.path.relative(outputDirectory.path)}',
      color: TerminalColor.green,
    );

    final String buildSettingsString = _buildEventAnalyticsSettings(configs: compilerConfigs);

    analytics.send(
      Event.flutterBuildInfo(label: 'web-compile', buildType: 'web', settings: buildSettingsString),
    );

    final Duration elapsedDuration = sw.elapsed;
    final variableName = compilerConfigs.length > 1 ? 'dual-compile' : 'dart2js';
    analytics.send(
      Event.timing(
        workflow: 'build',
        variableName: variableName,
        elapsedMilliseconds: elapsedDuration.inMilliseconds,
      ),
    );
  }
}

/// Web rendering backend mode.
enum WebRendererMode {
  /// Always uses canvaskit.
  canvaskit,

  /// Always use skwasm.
  skwasm;

  factory WebRendererMode.fromDartDefines(Iterable<String> defines, {required bool useWasm}) {
    if (defines.contains('FLUTTER_WEB_USE_SKIA=false') &&
        defines.contains('FLUTTER_WEB_USE_SKWASM=true')) {
      return skwasm;
    } else if (defines.contains('FLUTTER_WEB_USE_SKIA=true') &&
        defines.contains('FLUTTER_WEB_USE_SKWASM=false')) {
      return canvaskit;
    }
    return getDefault(useWasm: useWasm);
  }

  static WebRendererMode getDefault({required bool useWasm}) {
    return useWasm ? defaultForWasm : defaultForJs;
  }

  static const WebRendererMode defaultForJs = WebRendererMode.canvaskit;
  static const WebRendererMode defaultForWasm = WebRendererMode.skwasm;

  /// Returns [dartDefines] in a way usable from the CLI.
  ///
  /// This is used to start integration tests.
  Iterable<String> get toCliDartDefines =>
      dartDefines.map((String define) => '--dart-define=$define');

  Iterable<String> get dartDefines => switch (this) {
    canvaskit => const <String>{'FLUTTER_WEB_USE_SKIA=true', 'FLUTTER_WEB_USE_SKWASM=false'},
    skwasm => const <String>{'FLUTTER_WEB_USE_SKIA=false', 'FLUTTER_WEB_USE_SKWASM=true'},
  };

  /// Sets the dart defines for the currently selected WebRendererMode
  List<String> updateDartDefines(List<String> inputDefines) {
    final Set<String> dartDefinesSet = inputDefines.toSet();

    dartDefinesSet
      ..removeWhere((String d) {
        return d.startsWith('FLUTTER_WEB_USE_SKIA=') || d.startsWith('FLUTTER_WEB_USE_SKWASM=');
      })
      ..addAll(dartDefines);

    return dartDefinesSet.toList();
  }
}

/// The correct precompiled artifact to use for each build and render mode for DDC with AMD modules.
// TODO(markzipan): delete this when DDC's AMD module system is deprecated, https://github.com/flutter/flutter/issues/142060.
const kAmdDartSdkJsArtifactMap = <WebRendererMode, HostArtifact>{
  WebRendererMode.canvaskit: HostArtifact.webPrecompiledAmdCanvaskitSdk,
};

/// The correct source map artifact to use for each build and render mode for DDC with AMD modules.
// TODO(markzipan): delete this when DDC's AMD module system is deprecated, https://github.com/flutter/flutter/issues/142060.
const kAmdDartSdkJsMapArtifactMap = <WebRendererMode, HostArtifact>{
  WebRendererMode.canvaskit: HostArtifact.webPrecompiledAmdCanvaskitSdkSourcemaps,
};

/// The correct precompiled artifact to use for each build and render mode for
/// DDC with DDC library bundle module format.
const kDdcLibraryBundleDartSdkJsArtifactMap = <WebRendererMode, HostArtifact>{
  WebRendererMode.canvaskit: HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdk,
};

/// The correct source map artifact to use for each build and render mode for
/// DDC with DDC library bundle module format.
const kDdcLibraryBundleDartSdkJsMapArtifactMap = <WebRendererMode, HostArtifact>{
  WebRendererMode.canvaskit: HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdkSourcemaps,
};

String _buildEventAnalyticsSettings({required List<WebCompilerConfig> configs}) {
  final values = <String, Object>{};
  final renderers = <String>[];
  final targets = <String>[];
  for (final config in configs) {
    values.addAll(config.buildEventAnalyticsValues);
    renderers.add(config.renderer.name);
    targets.add(config.compileTarget.name);
  }
  values['web-renderer'] = renderers.join(',');
  values['web-target'] = targets.join(',');

  final List<String> sortedList =
      values.entries.map((MapEntry<String, Object> e) => '${e.key}: ${e.value};').toList()..sort();

  return sortedList.join(' ');
}
