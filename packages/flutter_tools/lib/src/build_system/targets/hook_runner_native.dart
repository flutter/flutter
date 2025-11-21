// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../asset.dart';
import '../../base/logger.dart' show Logger;
import '../../build_info.dart';
import '../../globals.dart' as globals;
import '../../hook_runner.dart' show FlutterHookRunner;
import '../../isolated/native_assets/dart_hook_result.dart' show DartHooksResult;
import '../build_system.dart' show BuildResult, Environment, ExceptionMeasurement;
import 'native_assets.dart' show DartBuild;

class FlutterHookRunnerNative implements FlutterHookRunner {
  FlutterHookResult? _flutterHookResult;

  @visibleForTesting
  static const kHooksOutputDirectory = 'native_hooks';

  @override
  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
    Logger? logger,
  }) async {
    logger?.printTrace('runHooks() with ${environment.defines} and $targetPlatform');
    if (_flutterHookResult != null &&
        !_flutterHookResult!.hasAnyModifiedFiles(environment.fileSystem)) {
      logger?.printTrace('runHooks() - up-to-date already');
      return _flutterHookResult!;
    }
    logger?.printTrace('runHooks() - will perform dart build');

    // Use a clone of the environment with a different output directory
    // to avoid conflicts with the primary build's outputs.
    final String outputDirPath = environment.fileSystem.path.join(
      environment.outputDir.path,
      kHooksOutputDirectory,
    );
    final Environment hooksEnvironment = environment.copyWith(
      outputDir: environment.fileSystem.directory(outputDirPath),
    );
    final BuildResult lastBuild = await globals.buildSystem.build(
      DartBuild(specifiedTargetPlatform: targetPlatform),
      hooksEnvironment,
    );
    if (!lastBuild.success) {
      for (final ExceptionMeasurement exceptionMeasurement in lastBuild.exceptions.values) {
        logger?.printError(
          exceptionMeasurement.exception.toString(),
          stackTrace: logger.isVerbose ? exceptionMeasurement.stackTrace : null,
        );
      }
    }

    final DartHooksResult dartHooksResult = await DartBuild.loadHookResult(environment);
    final FlutterHookResult flutterHookResult = dartHooksResult.asFlutterResult;
    _flutterHookResult = flutterHookResult;
    logger?.printTrace('runHooks() - done');
    return flutterHookResult;
  }
}
