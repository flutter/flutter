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
import '../build_system/targets/dart.dart';
import '../build_system/targets/web.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../reporting/reporting.dart';

/// The [WebCompilationProxy] instance.
WebCompilationProxy get webCompilationProxy => context.get<WebCompilationProxy>();

Future<void> buildWeb(
  FlutterProject flutterProject,
  String target,
  BuildInfo buildInfo,
  bool initializePlatform,
  List<String> dartDefines,
) async {
  if (!flutterProject.web.existsSync()) {
    throwToolExit('Missing index.html.');
  }
  final bool hasWebPlugins = findPlugins(flutterProject)
    .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
  await injectPlugins(flutterProject, checkProjects: true);
  final Status status = globals.logger.startProgress('Compiling $target for the Web...', timeout: null);
  final Stopwatch sw = Stopwatch()..start();
  try {
    final BuildResult result = await buildSystem.build(const WebReleaseBundle(), Environment(
      outputDir: globals.fs.directory(getWebBuildDirectory()),
      projectDir: globals.fs.currentDirectory,
      buildDir: flutterProject.directory
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build'),
      defines: <String, String>{
        kBuildMode: getNameForBuildMode(buildInfo.mode),
        kTargetFile: target,
        kInitializePlatform: initializePlatform.toString(),
        kHasWebPlugins: hasWebPlugins.toString(),
        kDartDefines: jsonEncode(dartDefines),
      },
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
  } catch (err) {
    throwToolExit(err.toString());
  } finally {
    status.stop();
  }
  flutterUsage.sendTiming('build', 'dart2js', Duration(milliseconds: sw.elapsedMilliseconds));
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
