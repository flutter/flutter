// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/common.dart';
import '../build_system/targets/icon_tree_shaker.dart';
import '../build_system/targets/web.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';

/// The [WebCompilationProxy] instance.
WebCompilationProxy get webCompilationProxy => context.get<WebCompilationProxy>();

Future<void> buildWeb(
  FlutterProject flutterProject,
  String target,
  BuildInfo buildInfo,
  bool initializePlatform,
  bool csp,
  String serviceWorkerStrategy,
) async {
  if (!flutterProject.web.existsSync()) {
    throwToolExit('Missing index.html.');
  }
  final bool hasWebPlugins = (await findPlugins(flutterProject))
    .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
  await injectPlugins(flutterProject, checkProjects: true);
  final Status status = globals.logger.startProgress('Compiling $target for the Web...', timeout: null);
  final Stopwatch sw = Stopwatch()..start();
  try {
    final BuildResult result = await globals.buildSystem.build(const WebServiceWorker(), Environment(
      projectDir: globals.fs.currentDirectory,
      outputDir: globals.fs.directory(getWebBuildDirectory()),
      buildDir: flutterProject.directory
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build'),
      defines: <String, String>{
        kBuildMode: getNameForBuildMode(buildInfo.mode),
        kTargetFile: target,
        kInitializePlatform: initializePlatform.toString(),
        kHasWebPlugins: hasWebPlugins.toString(),
        kDartDefines: encodeDartDefines(buildInfo.dartDefines),
        kCspMode: csp.toString(),
        kIconTreeShakerFlag: buildInfo.treeShakeIcons.toString(),
        if (serviceWorkerStrategy != null)
         kServiceWorkerStrategy: serviceWorkerStrategy,
        if (buildInfo.extraFrontEndOptions?.isNotEmpty ?? false)
          kExtraFrontEndOptions: encodeDartDefines(buildInfo.extraFrontEndOptions),
      },
      artifacts: globals.artifacts,
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      cacheDir: globals.cache.getRoot(),
      engineVersion: globals.artifacts.isLocalEngine
        ? null
        : globals.flutterVersion.engineRevision,
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
    ));
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        globals.printError('Target ${measurement.target} failed: ${measurement.exception}',
          stackTrace: measurement.fatal
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
  globals.flutterUsage.sendTiming('build', 'dart2js', Duration(milliseconds: sw.elapsedMilliseconds));
}

/// An indirection on web compilation.
///
/// Avoids issues with syncing build_runner_core to other repos.
class WebCompilationProxy {
  const WebCompilationProxy();

  /// Initialize the web compiler from the `projectDirectory`.
  ///
  /// Returns whether or not the build was successful.
  ///
  /// `release` controls whether we build the bundle for dartdevc or only
  /// the entry points for dart2js to later take over.
  Future<bool> initialize({
    @required Directory projectDirectory,
    @required String projectName,
    String testOutputDir,
    List<String> testFiles,
    BuildMode mode,
    bool initializePlatform,
  }) async {
    throw UnimplementedError();
  }
}
