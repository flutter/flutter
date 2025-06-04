// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../asset.dart';
import '../../base/logger.dart' show Logger;
import '../../build_info.dart';
import '../../globals.dart' as globals;
import '../../hook_runner.dart' show FlutterHookRunner;
import '../../isolated/native_assets/dart_hook_result.dart' show DartHookResult;
import '../build_system.dart' show BuildResult, Environment, ExceptionMeasurement;
import 'native_assets.dart' show DartBuild;

/// This class is restricted to be used in non-g3 files, such as `isolated/` and
/// `targets`.
/// Its purpose is to run the Dart build and link hooks during a Flutter build
/// and take care of caching.
class FlutterHookRunnerNative implements FlutterHookRunner {
  FlutterHookResult? _flutterHookResult;

  @override
  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
    required Logger? logger,
  }) async {
    logger?.printTrace('runDartBuild() with ${environment.defines} and $targetPlatform');
    final FlutterHookResult? hookResult = _flutterHookResult;
    if (hookResult != null && !hookResult.hasAnyModifiedFiles(globals.fs)) {
      logger?.printTrace('runDartBuild() - up-to-date already');
      return hookResult;
    }
    logger?.printTrace('runDartBuild() - will perform dart build');

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

    final DartHookResult dartHooksResult = await DartBuild.loadHookResult(environment);
    final FlutterHookResult flutterHookResult = dartHooksResult.asFlutterResult;
    _flutterHookResult = flutterHookResult;
    logger?.printTrace('runDartBuild() - done');
    return flutterHookResult;
  }
}
