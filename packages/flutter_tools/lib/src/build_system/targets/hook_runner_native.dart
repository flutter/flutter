// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  @override
  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
    Logger? logger,
  }) async {
    logger?.printTrace('runHooks() with ${environment.defines} and $targetPlatform');
    if (_flutterHookResult != null && !_flutterHookResult!.hasAnyModifiedFiles(globals.fs)) {
      logger?.printTrace('runHooks() - up-to-date already');
      return _flutterHookResult!;
    }
    logger?.printTrace('runHooks() - will perform dart build');

    final BuildResult lastBuild = await globals.buildSystem.build(
      DartBuild(specifiedTargetPlatform: targetPlatform),
      environment,
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
